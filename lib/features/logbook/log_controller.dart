import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;

import '../../services/access_control_service.dart';
import 'log_repository.dart';
import 'models/log_model.dart';

class LogController {
  LogController() {
    _initConnectivity();
  }

  final LogRepository _repository = LogRepository();
  
  final ValueNotifier<List<LogModel>> logsNotifier = ValueNotifier([]);
  final ValueNotifier<List<LogModel>> filteredLogs = ValueNotifier([]);
  final ValueNotifier<bool> isOnlineNotifier = ValueNotifier(false);

  StreamSubscription? _connectivitySub;
  String _currentUserId = 'unknown';
  String _currentUserRole = 'Anggota';
  String _activeTeamId = 'unknown';
  String _searchQuery = '';

  String get searchQuery => _searchQuery;

  void setSession({
    required String userId,
    required String userRole,
    required String teamId,
  }) {
    _currentUserId = userId.trim().isEmpty ? 'unknown' : userId;
    _currentUserRole = userRole.trim().isEmpty ? 'Anggota' : userRole;
    _activeTeamId = teamId.trim().isEmpty ? 'unknown' : teamId;
    refreshLogs();
  }

  void refreshLogs() {
    final allLogs = _repository.getLocalLogs(_activeTeamId);
    
    final visibleLogs = allLogs.where((log) {
      return AccessControlService.canReadLog(
        _currentUserRole,
        isOwner: log.authorId == _currentUserId,
        visibility: log.visibility,
      );
    }).toList();

    logsNotifier.value = visibleLogs;
    _applyFilter();
  }

  void loadLogs(String teamId) {
    _activeTeamId = teamId;
    refreshLogs();
    _repository.pullCloudLogs(teamId).then((_) => refreshLogs());
  }

  void searchLog(String query) {
    _searchQuery = query.trim().toLowerCase();
    _applyFilter();
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      filteredLogs.value = List.from(logsNotifier.value);
      return;
    }

    filteredLogs.value = logsNotifier.value.where((log) {
      return log.title.toLowerCase().contains(_searchQuery) ||
             log.description.toLowerCase().contains(_searchQuery) ||
             log.category.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  int indexOfLog(LogModel log) => logsNotifier.value.indexOf(log);

  bool isValidInput(String title, String desc) => 
      title.trim().isNotEmpty && desc.trim().isNotEmpty;

  // --- CRUD Actions ---

  Future<void> addLog(String title, String desc, String category, {
    String authorId = 'unknown',
    String teamId = 'unknown',
    String visibility = 'private',
  }) async {
    final log = LogModel(
      id: ObjectId().oid,
      title: title.trim(),
      description: desc.trim(),
      timestamp: DateTime.now().toIso8601String(),
      category: category,
      authorId: authorId,
      teamId: teamId == 'unknown' ? _activeTeamId : teamId,
      visibility: visibility,
      needsSync: true,
    );

    print('DEBUG: LogController.addLog called for ${log.title}');
    await _repository.saveLog(log);
    refreshLogs();
  }

  Future<void> updateLog(int index, String title, String desc, String category, {
    required String authorId,
    required String teamId,
    required String visibility,
  }) async {
    final oldLog = filteredLogs.value[index];

    final updated = LogModel(
      id: oldLog.id,
      title: title.trim(),
      description: desc.trim(),
      timestamp: DateTime.now().toIso8601String(),
      category: category,
      authorId: oldLog.authorId,
      teamId: oldLog.teamId,
      visibility: visibility,
      needsSync: true,
    );

    print('DEBUG: LogController.updateLog called for ${updated.id}');
    await _repository.saveLog(updated); 
    refreshLogs();
  }

  Future<void> removeLog(int index) async {
    final log = filteredLogs.value[index];
    await _repository.deleteLog(log);
    refreshLogs();
  }

  // --- Connectivity ---

  void _initConnectivity() async {
    final results = await _repository.checkConnectivity();
    isOnlineNotifier.value = !results.contains(ConnectivityResult.none);

    _connectivitySub = _repository.onConnectivityChanged.listen((results) {
      final online = !results.contains(ConnectivityResult.none);
      if (isOnlineNotifier.value != online) {
        isOnlineNotifier.value = online;
        if (online) {
          _repository.syncPendingOperations().then((_) => refreshLogs());
        }
      }
    });
  }

  void dispose() {
    _connectivitySub?.cancel();
    logsNotifier.dispose();
    filteredLogs.dispose();
    isOnlineNotifier.dispose();
  }
}
