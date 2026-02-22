import 'package:flutter/foundation.dart';

import 'models/log_model.dart';

class LogController {
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
  }

  void removeLog(int index) {
    final List<LogModel> updatedLogs = List<LogModel>.from(logsNotifier.value);
    if (index < 0 || index >= updatedLogs.length) {
      return;
    }
    updatedLogs.removeAt(index);
    logsNotifier.value = updatedLogs;
  }

  void dispose() {
    logsNotifier.dispose();
  }
}
