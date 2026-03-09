import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import 'models/log_model.dart';

class LogController {
  LogController() {
    _applyFilter();
    loadFromDisk();
  }

  final Box<LogModel> _myBox = Hive.box<LogModel>('offline_logs');

  final ValueNotifier<List<LogModel>> logsNotifier =
      ValueNotifier<List<LogModel>>(<LogModel>[]);
  final ValueNotifier<List<LogModel>> filteredLogs =
      ValueNotifier<List<LogModel>>(<LogModel>[]);
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

  void searchLog(String query) {
    _searchQuery = query.trim().toLowerCase();
    _applyFilter();
  }

  void addLog(String title, String desc, String category) {
    unawaited(
      _addLogToBox(
        LogModel(
          title: title.trim(),
          description: desc.trim(),
          timestamp: DateTime.now().toIso8601String(),
          category: category.trim().isEmpty ? 'Pribadi' : category.trim(),
        ),
      ),
    );
  }

  void updateLog(int index, String title, String desc, String category) {
    unawaited(_updateLogInBox(index, title, desc, category));
  }

  void removeLog(int index) {
    unawaited(_removeLogFromBox(index));
  }

  Future<void> _addLogToBox(LogModel log) async {
    await _myBox.add(log);
    loadFromDisk();
  }

  Future<void> _updateLogInBox(
    int index,
    String title,
    String desc,
    String category,
  ) async {
    final List<dynamic> keys = _myBox.keys.toList();
    if (index < 0 || index >= keys.length) {
      return;
    }

    final dynamic key = keys[index];
    final LogModel? existingLog = _myBox.get(key);
    if (existingLog == null) {
      return;
    }

    await _myBox.put(
      key,
      LogModel(
        id: existingLog.id,
        title: title.trim(),
        description: desc.trim(),
        timestamp: DateTime.now().toIso8601String(),
        category: category.trim().isEmpty ? 'Pribadi' : category.trim(),
        authorId: existingLog.authorId,
        teamId: existingLog.teamId,
      ),
    );
    loadFromDisk();
  }

  Future<void> _removeLogFromBox(int index) async {
    final List<dynamic> keys = _myBox.keys.toList();
    if (index < 0 || index >= keys.length) {
      return;
    }
    await _myBox.delete(keys[index]);
    loadFromDisk();
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
  }

  void loadFromDisk() {
    logsNotifier.value = _myBox.values.toList();
    _applyFilter();
  }

  void dispose() {
    filteredLogs.dispose();
    logsNotifier.dispose();
  }
}
