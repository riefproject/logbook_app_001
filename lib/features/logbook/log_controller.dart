import 'models/log_model.dart';

class LogController {
  final List<LogModel> logs = [];

  void addLog(String title, String desc) {
    logs.insert(
      0,
      LogModel(
        title: title,
        description: desc,
        timestamp: DateTime.now().toIso8601String(),
      ),
    );
  }

  void updateLog(int index, String title, String desc) {
    if (index < 0 || index >= logs.length) {
      return;
    }

    logs[index] = LogModel(
      title: title,
      description: desc,
      timestamp: DateTime.now().toIso8601String(),
    );
  }

  void removeLog(int index) {
    if (index < 0 || index >= logs.length) {
      return;
    }
    logs.removeAt(index);
  }
}
