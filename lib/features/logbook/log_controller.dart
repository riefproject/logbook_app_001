import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/log_model.dart';

class LogController {
  LogController() {
    _applyFilter();
    unawaited(loadFromDisk());
  }

  static const String _storageKey = 'user_logs_data';

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
    final List<LogModel> updatedLogs = List<LogModel>.from(logsNotifier.value);
    updatedLogs.insert(
      0,
      LogModel(
        title: title.trim(),
        description: desc.trim(),
        timestamp: DateTime.now().toIso8601String(),
        category: category.trim().isEmpty ? 'Pribadi' : category.trim(),
      ),
    );
    logsNotifier.value = updatedLogs;
    _applyFilter();
    unawaited(saveToDisk());
  }

  void updateLog(int index, String title, String desc, String category) {
    final List<LogModel> updatedLogs = List<LogModel>.from(logsNotifier.value);
    if (index < 0 || index >= updatedLogs.length) {
      return;
    }

    updatedLogs[index] = LogModel(
      title: title.trim(),
      description: desc.trim(),
      timestamp: DateTime.now().toIso8601String(),
      category: category.trim().isEmpty ? 'Pribadi' : category.trim(),
    );
    logsNotifier.value = updatedLogs;
    _applyFilter();
    unawaited(saveToDisk());
  }

  void removeLog(int index) {
    final List<LogModel> updatedLogs = List<LogModel>.from(logsNotifier.value);
    if (index < 0 || index >= updatedLogs.length) {
      return;
    }
    updatedLogs.removeAt(index);
    logsNotifier.value = updatedLogs;
    _applyFilter();
    unawaited(saveToDisk());
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
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String encodedLogs = jsonEncode(
      logsNotifier.value.map((LogModel log) => log.toMap()).toList(),
    );
    await prefs.setString(_storageKey, encodedLogs);
  }

  Future<void> loadFromDisk() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? rawLogs = prefs.getString(_storageKey);
    if (rawLogs == null || rawLogs.isEmpty) {
      _applyFilter();
      return;
    }

    try {
      final dynamic decoded = jsonDecode(rawLogs);
      if (decoded is! List) {
        _applyFilter();
        return;
      }

      final List<LogModel> restoredLogs = <LogModel>[];
      for (final dynamic item in decoded) {
        if (item is Map<String, dynamic>) {
          restoredLogs.add(LogModel.fromMap(item));
          continue;
        }
        if (item is Map) {
          restoredLogs.add(LogModel.fromMap(Map<String, dynamic>.from(item)));
        }
      }
      logsNotifier.value = restoredLogs;
      _applyFilter();
    } on FormatException {
      _applyFilter();
    } on TypeError {
      _applyFilter();
    }
  }

  void dispose() {
    filteredLogs.dispose();
    logsNotifier.dispose();
  }
}
