import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;

import '../../helpers/log_helper.dart';
import '../../services/access_control_service.dart';
import '../../services/mongo_service.dart';
import 'models/log_model.dart';

class LogController {
  LogController() {
    _applyFilter();
    loadFromDisk();
    unawaited(_initializeConnectivity());
  }

  static const String _source = 'log_controller.dart';
  static final RegExp _objectIdPattern = RegExp(r'^[a-fA-F0-9]{24}$');

  final Box<LogModel> _myBox = Hive.box<LogModel>('offline_logs');
  final Box<dynamic> _syncQueue = Hive.box<dynamic>('sync_queue');
  final MongoService _mongoService = MongoService();
  final Connectivity _connectivity = Connectivity();

  final ValueNotifier<List<LogModel>> logsNotifier =
      ValueNotifier<List<LogModel>>(<LogModel>[]);
  final ValueNotifier<List<LogModel>> filteredLogs =
      ValueNotifier<List<LogModel>>(<LogModel>[]);
  final ValueNotifier<bool> isOnlineNotifier = ValueNotifier<bool>(false);

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  String _currentUserId = 'unknown';
  String _currentUserRole = 'Anggota';
  String _activeTeamId = 'unknown';
  String _searchQuery = '';

  List<LogModel> get logs => List<LogModel>.unmodifiable(logsNotifier.value);

  LogModel? getLogAt(int index) {
    final List<LogModel> currentLogs = logsNotifier.value;
    if (index < 0 || index >= currentLogs.length) {
      return null;
    }
    return currentLogs[index];
  }

  int indexOfLog(LogModel log) {
    return logsNotifier.value.indexOf(log);
  }

  bool isValidInput(String title, String desc) {
    return title.trim().isNotEmpty && desc.trim().isNotEmpty;
  }

  void setSession({
    required String userId,
    required String userRole,
    required String teamId,
  }) {
    _currentUserId = _normalizeUserId(userId);
    _currentUserRole = userRole.trim().isEmpty ? 'Anggota' : userRole.trim();
    _activeTeamId = _normalizeTeamId(teamId);
    _loadFromBoxForActiveTeam();
  }

  void searchLog(String query) {
    _searchQuery = query.trim().toLowerCase();
    _applyFilter();
  }

  void loadLogs(String teamId) {
    _activeTeamId = _normalizeTeamId(teamId);
    _loadFromBoxForActiveTeam();
    unawaited(_syncAndPullFromCloud(_activeTeamId));
  }

  void addLog(
    String title,
    String desc,
    String category, {
    String authorId = 'unknown',
    String teamId = 'unknown',
    String visibility = 'private',
  }) {
    final String resolvedTeamId = _normalizeTeamId(
      teamId == 'unknown' ? _activeTeamId : teamId,
    );

    final LogModel log = LogModel(
      id: ObjectId().oid,
      title: title.trim(),
      description: desc.trim(),
      timestamp: DateTime.now().toIso8601String(),
      category: category.trim().isEmpty ? 'Pribadi' : category.trim(),
      authorId: _normalizeUserId(authorId),
      teamId: resolvedTeamId,
      visibility: _normalizeVisibility(visibility),
      needsSync: true,
    );

    unawaited(_addLogToBoxAndSync(log));
  }

  void updateLog(
    int index,
    String title,
    String desc,
    String category, {
    String authorId = 'unknown',
    String teamId = 'unknown',
    String visibility = 'private',
  }) {
    unawaited(
      _updateLogInBoxAndSync(
        index,
        title,
        desc,
        category,
        authorId: authorId,
        teamId: teamId,
        visibility: visibility,
      ),
    );
  }

  void removeLog(int index) {
    unawaited(_removeLogFromBoxAndSync(index));
  }

  Future<void> _initializeConnectivity() async {
    try {
      final List<ConnectivityResult> initialStatus = await _connectivity
          .checkConnectivity();
      final bool online = _isOnline(initialStatus);
      isOnlineNotifier.value = online;
      if (online) {
        await _syncPendingOperations();
      }
    } catch (error) {
      await _logOfflineWarning('connectivityInit', error);
    }

    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> status,
    ) {
      final bool online = _isOnline(status);
      if (isOnlineNotifier.value != online) {
        isOnlineNotifier.value = online;
      }
      if (online) {
        unawaited(_syncAndPullFromCloud(_activeTeamId));
      }
    });
  }

  bool _isOnline(List<ConnectivityResult> results) {
    return !results.contains(ConnectivityResult.none);
  }

  Future<void> _addLogToBoxAndSync(LogModel log) async {
    final dynamic key = await _myBox.add(log);
    _loadFromBoxForActiveTeam();
    await _syncSingleLogByKey(key);
  }

  Future<void> _updateLogInBoxAndSync(
    int index,
    String title,
    String desc,
    String category, {
    required String authorId,
    required String teamId,
    required String visibility,
  }) async {
    final List<dynamic> keys = _activeTeamVisibleKeys();
    if (index < 0 || index >= keys.length) {
      return;
    }

    final dynamic key = keys[index];
    final LogModel? existingLog = _myBox.get(key);
    if (existingLog == null) {
      return;
    }

    final bool isOwner = existingLog.authorId == _currentUserId;
    final bool canUpdate = AccessControlService.canPerform(
      _currentUserRole,
      AccessControlService.actionUpdate,
      isOwner: isOwner,
    );
    if (!canUpdate) {
      await LogHelper.writeLog(
        'SECURITY BREACH: unauthorized update attempt on log "${existingLog.id}"',
        source: _source,
        level: 1,
      );
      return;
    }

    final LogModel updatedLog = LogModel(
      id: existingLog.id,
      title: title.trim(),
      description: desc.trim(),
      timestamp: DateTime.now().toIso8601String(),
      category: category.trim().isEmpty ? 'Pribadi' : category.trim(),
      authorId: existingLog.authorId == 'unknown'
          ? _normalizeUserId(authorId)
          : existingLog.authorId,
      teamId: existingLog.teamId == 'unknown'
          ? _normalizeTeamId(teamId)
          : existingLog.teamId,
      visibility: _normalizeVisibility(visibility),
      needsSync: true,
    );

    await _myBox.put(key, updatedLog);
    _loadFromBoxForActiveTeam();
    await _syncSingleLogByKey(key);
  }

  Future<void> _removeLogFromBoxAndSync(int index) async {
    final List<dynamic> keys = _activeTeamVisibleKeys();
    if (index < 0 || index >= keys.length) {
      return;
    }

    final dynamic key = keys[index];
    final LogModel? existingLog = _myBox.get(key);
    if (existingLog == null) {
      return;
    }

    final bool isOwner = existingLog.authorId == _currentUserId;
    final bool canDelete = AccessControlService.canPerform(
      _currentUserRole,
      AccessControlService.actionDelete,
      isOwner: isOwner,
    );
    if (!canDelete) {
      await LogHelper.writeLog(
        'SECURITY BREACH: unauthorized delete attempt on log "${existingLog.id}"',
        source: _source,
        level: 1,
      );
      return;
    }

    await _myBox.delete(key);
    _loadFromBoxForActiveTeam();

    if (!_isValidCloudId(existingLog.id)) {
      return;
    }

    if (!isOnlineNotifier.value) {
      await _queueDelete(existingLog.id!, existingLog.teamId);
      return;
    }

    try {
      await _mongoService.deleteLog(
        existingLog.id!,
        teamId: existingLog.teamId,
      );
    } catch (error) {
      await _queueDelete(existingLog.id!, existingLog.teamId);
      await _logOfflineWarning('removeLog', error);
    }
  }

  Future<void> _syncSingleLogByKey(dynamic key) async {
    final LogModel? current = _myBox.get(key);
    if (current == null || !current.needsSync || !isOnlineNotifier.value) {
      return;
    }

    try {
      if (_isValidCloudId(current.id)) {
        await _mongoService.updateLog(current);
        await _myBox.put(key, _copyWith(current, needsSync: false));
      } else {
        final String? cloudId = await _mongoService.insertLog(current);
        if (_isValidCloudId(cloudId)) {
          await _myBox.put(
            key,
            _copyWith(current, id: cloudId, needsSync: false),
          );
        }
      }
      _loadFromBoxForActiveTeam();
    } catch (error) {
      await _logOfflineWarning('syncSingleLog', error);
    }
  }

  Future<void> _syncAndPullFromCloud(String teamId) async {
    try {
      if (isOnlineNotifier.value) {
        await _syncPendingOperations();
      }
      await _pullCloudLogs(teamId);
    } catch (error) {
      await _logOfflineWarning('syncAndPullFromCloud', error);
    }
  }

  Future<void> _syncPendingOperations() async {
    if (!isOnlineNotifier.value) {
      return;
    }

    await _syncPendingDeletes();
    await _syncPendingLogs();
  }

  Future<void> _syncPendingLogs() async {
    final List<dynamic> keys = _myBox.keys.toList(growable: false);
    for (final dynamic key in keys) {
      await _syncSingleLogByKey(key);
    }
  }

  Future<void> _syncPendingDeletes() async {
    final List<dynamic> queueKeys = _syncQueue.keys.toList(growable: false);
    for (final dynamic queueKey in queueKeys) {
      final dynamic entry = _syncQueue.get(queueKey);
      if (entry is! Map) {
        await _syncQueue.delete(queueKey);
        continue;
      }

      final String action = (entry['action'] ?? '').toString();
      if (action != 'delete') {
        await _syncQueue.delete(queueKey);
        continue;
      }

      final String id = (entry['id'] ?? '').toString();
      final String teamId = (entry['teamId'] ?? '').toString();
      if (!_isValidCloudId(id)) {
        await _syncQueue.delete(queueKey);
        continue;
      }

      try {
        await _mongoService.deleteLog(id, teamId: teamId);
        await _syncQueue.delete(queueKey);
      } catch (error) {
        await _logOfflineWarning('syncPendingDelete', error);
      }
    }
  }

  Future<void> _queueDelete(String id, String teamId) async {
    final List<dynamic> queueKeys = _syncQueue.keys.toList(growable: false);
    for (final dynamic queueKey in queueKeys) {
      final dynamic entry = _syncQueue.get(queueKey);
      if (entry is Map &&
          (entry['action'] ?? '') == 'delete' &&
          (entry['id'] ?? '') == id) {
        return;
      }
    }

    await _syncQueue.add(<String, dynamic>{
      'action': 'delete',
      'id': id,
      'teamId': _normalizeTeamId(teamId),
      'queuedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _pullCloudLogs(String teamId) async {
    if (!isOnlineNotifier.value) {
      return;
    }

    try {
      final List<LogModel> cloudLogs = await _mongoService.getLogs(teamId);
      for (final LogModel cloudLog in cloudLogs) {
        final LogModel normalizedCloudLog = _copyWith(
          cloudLog,
          needsSync: false,
        );
        final dynamic existingKey = _findKeyByCloudId(normalizedCloudLog.id);
        if (existingKey == null) {
          await _myBox.add(normalizedCloudLog);
          continue;
        }
        await _myBox.put(existingKey, normalizedCloudLog);
      }

      if (_activeTeamId == teamId) {
        _loadFromBoxForActiveTeam();
      }
    } catch (error) {
      await _logOfflineWarning('loadLogs', error);
    }
  }

  void _loadFromBoxForActiveTeam() {
    logsNotifier.value = _activeTeamVisibleLogs();
    _applyFilter();
  }

  List<LogModel> _activeTeamVisibleLogs() {
    final List<LogModel> logs = <LogModel>[];
    for (final dynamic key in _myBox.keys) {
      final LogModel? log = _myBox.get(key);
      if (log == null || log.teamId != _activeTeamId) {
        continue;
      }

      final bool isOwner = log.authorId == _currentUserId;
      final bool canRead = AccessControlService.canReadLog(
        _currentUserRole,
        isOwner: isOwner,
        visibility: log.visibility,
      );
      if (!canRead) {
        continue;
      }

      logs.add(log);
    }

    logs.sort((LogModel a, LogModel b) => b.timestamp.compareTo(a.timestamp));
    return logs;
  }

  List<dynamic> _activeTeamVisibleKeys() {
    final List<dynamic> keys = <dynamic>[];
    for (final dynamic key in _myBox.keys) {
      final LogModel? log = _myBox.get(key);
      if (log == null || log.teamId != _activeTeamId) {
        continue;
      }

      final bool isOwner = log.authorId == _currentUserId;
      final bool canRead = AccessControlService.canReadLog(
        _currentUserRole,
        isOwner: isOwner,
        visibility: log.visibility,
      );
      if (!canRead) {
        continue;
      }

      keys.add(key);
    }

    keys.sort((dynamic a, dynamic b) {
      final LogModel? first = _myBox.get(a);
      final LogModel? second = _myBox.get(b);
      if (first == null || second == null) {
        return 0;
      }
      return second.timestamp.compareTo(first.timestamp);
    });
    return keys;
  }

  dynamic _findKeyByCloudId(String? cloudId) {
    if (!_isValidCloudId(cloudId)) {
      return null;
    }

    for (final dynamic key in _myBox.keys) {
      final LogModel? current = _myBox.get(key);
      if (current != null && current.id == cloudId) {
        return key;
      }
    }
    return null;
  }

  LogModel _copyWith(
    LogModel source, {
    String? id,
    String? title,
    String? description,
    String? timestamp,
    String? category,
    String? authorId,
    String? teamId,
    String? visibility,
    bool? needsSync,
  }) {
    return LogModel(
      id: id ?? source.id,
      title: title ?? source.title,
      description: description ?? source.description,
      timestamp: timestamp ?? source.timestamp,
      category: category ?? source.category,
      authorId: authorId ?? source.authorId,
      teamId: teamId ?? source.teamId,
      visibility: visibility ?? source.visibility,
      needsSync: needsSync ?? source.needsSync,
    );
  }

  bool _isValidCloudId(String? rawId) {
    if (rawId == null) {
      return false;
    }
    return _objectIdPattern.hasMatch(rawId.trim());
  }

  String _normalizeUserId(String userId) {
    final String normalized = userId.trim();
    return normalized.isEmpty ? 'unknown' : normalized;
  }

  String _normalizeTeamId(String teamId) {
    final String normalized = teamId.trim();
    return normalized.isEmpty ? 'unknown' : normalized;
  }

  String _normalizeVisibility(String visibility) {
    final String normalized = visibility.trim().toLowerCase();
    return normalized == 'public' ? 'public' : 'private';
  }

  Future<void> _logOfflineWarning(String action, Object error) {
    return LogHelper.writeLog(
      '$action() cloud sync deferred: $error',
      source: _source,
      level: 2,
    );
  }

  void _applyFilter() {
    final List<LogModel> source = logsNotifier.value;
    if (_searchQuery.isEmpty) {
      filteredLogs.value = List<LogModel>.from(source);
      return;
    }

    filteredLogs.value = source.where((LogModel log) {
      final String title = log.title.toLowerCase();
      final String description = log.description.toLowerCase();
      final String category = log.category.toLowerCase();

      return title.contains(_searchQuery) ||
          description.contains(_searchQuery) ||
          category.contains(_searchQuery);
    }).toList();
  }

  Future<void> saveToDisk() async {
    await _myBox.flush();
    await _syncQueue.flush();
  }

  void loadFromDisk() {
    _loadFromBoxForActiveTeam();
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    isOnlineNotifier.dispose();
    filteredLogs.dispose();
    logsNotifier.dispose();
  }
}
