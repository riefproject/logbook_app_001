import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'models/log_model.dart';
import '../../services/mongo_service.dart';
import '../../helpers/log_helper.dart';

class LogRepository {
  final Box<LogModel> _myBox = Hive.box<LogModel>('offline_logs');
  final Box<dynamic> _syncQueue = Hive.box<dynamic>('sync_queue');
  final MongoService _mongoService = MongoService();
  final Connectivity _connectivity = Connectivity();

  static final RegExp _objectIdPattern = RegExp(r'^[a-fA-F0-9]{24}$');
  static const String _source = 'log_repository.dart';

  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;

  Future<List<ConnectivityResult>> checkConnectivity() =>
      _connectivity.checkConnectivity();

  List<LogModel> getLocalLogs(String teamId) {
    return _myBox.values.where((log) => log.teamId == teamId).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> saveLog(LogModel log) async {
    // Selalu simpan ke Hive dulu
    await _myBox.put(log.id, log);
    await LogHelper.writeLog(
      'Saved log locally with ID: ${log.id}',
      source: _source,
    );

    // Jika butuh sync, coba sync sekarang
    if (log.needsSync) {
      await syncSingleLog(log.id!);
    }
  }

  Future<void> deleteLog(LogModel log) async {
    final String? idToDelete = log.id;
    final String teamId = log.teamId;

    await _myBox.delete(idToDelete);
    await LogHelper.writeLog(
      'Deleted log locally with ID: $idToDelete',
      source: _source,
    );

    if (!_isValidCloudId(idToDelete)) return;

    try {
      final status = await _connectivity.checkConnectivity();
      if (status.contains(ConnectivityResult.none)) {
        await _queueDelete(idToDelete!, teamId);
      } else {
        await _mongoService.deleteLog(idToDelete!, teamId: teamId);
        await LogHelper.writeLog(
          'Deleted log from cloud: $idToDelete',
          source: _source,
        );
      }
    } catch (error) {
      await LogHelper.writeLog(
        'Error deleting from cloud, queued: $error',
        source: _source,
        level: 1,
      );
      await _queueDelete(idToDelete!, teamId);
    }
  }

  Future<void> syncSingleLog(String id) async {
    final log = _myBox.get(id);
    if (log == null || !log.needsSync) return;

    try {
      if (_isValidCloudId(log.id)) {
        await LogHelper.writeLog(
          'Syncing existing log: ${log.id}',
          source: _source,
        );
        await _mongoService.updateLog(log);
        await _myBox.put(id, _copyWith(log, needsSync: false));
        await LogHelper.writeLog('Sync success: ${log.id}', source: _source);
      } else {
        await LogHelper.writeLog(
          'Syncing new log (insert): ${log.title}',
          source: _source,
        );
        final cloudId = await _mongoService.insertLog(log);
        if (_isValidCloudId(cloudId)) {
          if (cloudId != id) {
            await _myBox.delete(id);
          }
          await _myBox.put(
            cloudId,
            _copyWith(log, id: cloudId, needsSync: false),
          );
          await LogHelper.writeLog(
            'Sync success with new ID: $cloudId',
            source: _source,
          );
        }
      }
    } catch (error) {
      await LogHelper.writeLog(
        'Sync failed for $id: $error',
        source: _source,
        level: 1,
      );
    }
  }

  Future<void> pullCloudLogs(
    String teamId, {
    bool reconcileDeletes = false,
  }) async {
    final results = await _connectivity.checkConnectivity();
    if (results.contains(ConnectivityResult.none)) return;

    try {
      await LogHelper.writeLog(
        'Pulling cloud logs for team: $teamId',
        source: _source,
      );
      final cloudLogs = await _mongoService.getLogs(teamId);
      final Set<String> pendingDeleteIds = _syncQueue.values
          .whereType<Map>()
          .where((entry) => entry['action'] == 'delete')
          .where((entry) => (entry['teamId'] ?? '').toString() == teamId)
          .map((entry) => (entry['id'] ?? '').toString())
          .where((id) => id.trim().isNotEmpty)
          .toSet();
      final Set<String> cloudIds = cloudLogs
          .map((log) => log.id)
          .whereType<String>()
          .toSet();
      for (final cloudLog in cloudLogs) {
        // Jangan menimpa perubahan lokal yang belum tersinkron (needsSync=true).
        final LogModel? existing = cloudLog.id == null
            ? null
            : _myBox.get(cloudLog.id);
        if (existing != null && existing.needsSync) {
          continue;
        }
        if (cloudLog.id != null && pendingDeleteIds.contains(cloudLog.id)) {
          // Log ini sudah dihapus user saat offline dan sedang menunggu sinkron delete.
          continue;
        }
        await _myBox.put(cloudLog.id, _copyWith(cloudLog, needsSync: false));
      }

      // Reconcile juga perlu jalan saat cloud kosong (mis. semua data sudah dihapus).
      if (reconcileDeletes) {
        final localSynced = _myBox.values.where((log) {
          return log.teamId == teamId &&
              !log.needsSync &&
              _isValidCloudId(log.id);
        }).toList();

        for (final log in localSynced) {
          final String? id = log.id;
          if (id == null) continue;
          if (cloudIds.contains(id)) continue;
          await _myBox.delete(id);
          await LogHelper.writeLog(
            'Reconciled cloud delete (removed local): $id',
            source: _source,
            level: 2,
          );
        }
      }
      await LogHelper.writeLog(
        'Pull success: ${cloudLogs.length} logs',
        source: _source,
      );
    } catch (error) {
      await LogHelper.writeLog(
        'Pull failed: $error',
        source: _source,
        level: 1,
      );
    }
  }

  Future<void> reconcileCloudForAllLocalTeams() async {
    final Set<String> teamIds = _myBox.values
        .map((log) => log.teamId.trim())
        .where((teamId) => teamId.isNotEmpty && teamId != 'unknown')
        .toSet();

    for (final teamId in teamIds) {
      await pullCloudLogs(teamId, reconcileDeletes: true);
    }
  }

  Future<void> syncPendingOperations() async {
    final results = await _connectivity.checkConnectivity();
    if (results.contains(ConnectivityResult.none)) return;

    await LogHelper.writeLog('Syncing pending operations...', source: _source);

    final queueKeys = _syncQueue.keys.toList();
    for (final qKey in queueKeys) {
      final entry = _syncQueue.get(qKey);
      if (entry is Map && entry['action'] == 'delete') {
        try {
          await _mongoService.deleteLog(entry['id'], teamId: entry['teamId']);
          await _syncQueue.delete(qKey);
          await LogHelper.writeLog(
            'Pending delete success: ${entry['id']}',
            source: _source,
          );
        } catch (error) {
          await LogHelper.writeLog(
            'Pending delete failed: $error',
            source: _source,
            level: 1,
          );
        }
      }
    }

    final allLogs = _myBox.values.toList();
    for (final log in allLogs) {
      if (log.needsSync && log.id != null) {
        await syncSingleLog(log.id!);
      }
    }
  }

  // --- Private Helpers ---
  Future<void> _queueDelete(String id, String teamId) async {
    await _syncQueue.add({
      'action': 'delete',
      'id': id,
      'teamId': teamId,
      'queuedAt': DateTime.now().toIso8601String(),
    });
    await LogHelper.writeLog('Queued delete for sync: $id', source: _source);
  }

  bool _isValidCloudId(String? id) =>
      id != null && _objectIdPattern.hasMatch(id.trim());

  LogModel _copyWith(LogModel s, {String? id, bool? needsSync}) {
    return LogModel(
      id: id ?? s.id,
      title: s.title,
      description: s.description,
      timestamp: s.timestamp,
      category: s.category,
      authorId: s.authorId,
      teamId: s.teamId,
      visibility: s.visibility,
      needsSync: needsSync ?? s.needsSync,
    );
  }
}
