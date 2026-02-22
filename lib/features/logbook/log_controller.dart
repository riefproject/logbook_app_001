import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/log_model.dart';

class LogController {
  LogController() {
    unawaited(loadFromDisk());
  }

  static const String _storageKey = 'user_logs_data';

  final ValueNotifier<List<LogModel>> logsNotifier =
      ValueNotifier<List<LogModel>>(<LogModel>[]);

  List<LogModel> get logs => List<LogModel>.unmodifiable(logsNotifier.value);

  LogModel? getLogAt(int index) {
    final List<LogModel> currentLogs = logsNotifier.value;
    if (index < 0 || index >= currentLogs.length) {
      return null;
    }
    return currentLogs[index];
  }

  bool isValidInput(String title, String desc) {
    return title.trim().isNotEmpty && desc.trim().isNotEmpty;
  }

  void addLog(String title, String desc) {
    final List<LogModel> updatedLogs = List<LogModel>.from(logsNotifier.value);
    updatedLogs.insert(
      0,
      LogModel(
        title: title.trim(),
        description: desc.trim(),
        timestamp: DateTime.now().toIso8601String(),
      ),
    );
    logsNotifier.value = updatedLogs;
    unawaited(saveToDisk());
  }

  void updateLog(int index, String title, String desc) {
    final List<LogModel> updatedLogs = List<LogModel>.from(logsNotifier.value);
    if (index < 0 || index >= updatedLogs.length) {
      return;
    }

    updatedLogs[index] = LogModel(
      title: title.trim(),
      description: desc.trim(),
      timestamp: DateTime.now().toIso8601String(),
    );
    logsNotifier.value = updatedLogs;
    unawaited(saveToDisk());
  }

  void removeLog(int index) {
    final List<LogModel> updatedLogs = List<LogModel>.from(logsNotifier.value);
    if (index < 0 || index >= updatedLogs.length) {
      return;
    }
    updatedLogs.removeAt(index);
    logsNotifier.value = updatedLogs;
    unawaited(saveToDisk());
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
      return;
    }

    try {
      final dynamic decoded = jsonDecode(rawLogs);
      if (decoded is! List) {
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
    } on FormatException {
      // komen biar ga warning
    } on TypeError {
      // komen biar ga warning
    }
  }

  void dispose() {
    logsNotifier.dispose();
  }
}
