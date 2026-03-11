import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'models/log_model.dart';
import '../../services/mongo_service.dart';

class LogRepository {
  final Box<LogModel> _myBox = Hive.box<LogModel>('offline_logs');
  final Box<dynamic> _syncQueue = Hive.box<dynamic>('sync_queue');
  final MongoService _mongoService = MongoService();
  final Connectivity _connectivity = Connectivity();

  static final RegExp _objectIdPattern = RegExp(r'^[a-fA-F0-9]{24}$');

  Stream<List<ConnectivityResult>> get onConnectivityChanged => _connectivity.onConnectivityChanged;

  Future<List<ConnectivityResult>> checkConnectivity() => _connectivity.checkConnectivity();

  List<LogModel> getLocalLogs(String teamId) {
    return _myBox.values
        .where((log) => log.teamId == teamId)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> saveLog(LogModel log) async {
    // Gunakan log.id sebagai key Hive agar pencarian O(1)
    await _myBox.put(log.id, log);
    if (log.needsSync) {
      await syncSingleLog(log.id!);
    }
  }

  Future<void> deleteLog(LogModel log) async {
    await _myBox.delete(log.id);
    if (!_isValidCloudId(log.id)) return;

    try {
      final status = await _connectivity.checkConnectivity();
      if (status.contains(ConnectivityResult.none)) {
        await _queueDelete(log.id!, log.teamId);
      } else {
        await _mongoService.deleteLog(log.id!, teamId: log.teamId);
      }
    } catch (_) {
      await _queueDelete(log.id!, log.teamId);
    }
  }

  Future<void> syncSingleLog(String id) async {
    final log = _myBox.get(id);
    if (log == null || !log.needsSync) return;

    try {
      await _mongoService.updateLog(log); 
      await _myBox.put(id, _copyWith(log, needsSync: false));
    } catch (_) {}
  }

  Future<void> pullCloudLogs(String teamId) async {
    try {
      final cloudLogs = await _mongoService.getLogs(teamId);
      for (final cloudLog in cloudLogs) {
        await _myBox.put(cloudLog.id, _copyWith(cloudLog, needsSync: false));
      }
    } catch (_) {}
  }

  Future<void> syncPendingOperations() async {
    final queueKeys = _syncQueue.keys.toList();
    for (final qKey in queueKeys) {
      final entry = _syncQueue.get(qKey);
      if (entry is Map && entry['action'] == 'delete') {
        try {
          await _mongoService.deleteLog(entry['id'], teamId: entry['teamId']);
          await _syncQueue.delete(qKey);
        } catch (_) {}
      }
    }

    for (final log in _myBox.values) {
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
  }

  bool _isValidCloudId(String? id) => id != null && _objectIdPattern.hasMatch(id);

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
