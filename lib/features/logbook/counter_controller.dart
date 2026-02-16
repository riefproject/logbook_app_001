import 'package:shared_preferences/shared_preferences.dart';

class CounterController {
  int _counter = 0;
  int _step = 1;
  final List<String> _history = [];
  static const String _counterKey = 'counter_value';
  static const String _stepKey = 'counter_step';
  static const String _historyKey = 'counter_history';

  int get value => _counter;
  int get step => _step;
  List<String> get history => List.unmodifiable(_history);

  void increment() {
    _counter += _step;
    _addHistory('User menambahkan nilai sebesar $_step menjadi $_counter');
  }

  void decrement() {
    if (_counter - _step >= 0) {
      _counter -= _step;
      _addHistory('User mengurangi nilai sebesar $_step menjadi $_counter');
    }
  }

  void reset() {
    _counter = 0;
    _addHistory('User mereset nilai ke nol');
  }

  void setStep(int value) {
    final int safeValue = value < 1 ? 1 : value;
    if (safeValue == _step) {
      return;
    }
    _step = safeValue;
  }

  void _addHistory(String action) {
    final DateTime now = DateTime.now();
    final String time = _formatTime(now);
    _history.insert(0, '[$time] $action');
    if (_history.length > 5) {
      _history.removeLast();
    }
  }

  String _formatTime(DateTime time) {
    final String hour = time.hour.toString().padLeft(2, '0');
    final String minute = time.minute.toString().padLeft(2, '0');
    final String second = time.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

  Future<void> saveData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_counterKey, _counter);
    await prefs.setInt(_stepKey, _step);
    await prefs.setStringList(_historyKey, _history);
  }

  Future<void> loadData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _counter = prefs.getInt(_counterKey) ?? _counter;
    _step = prefs.getInt(_stepKey) ?? _step;

    final List<String>? savedHistory = prefs.getStringList(_historyKey);
    if (savedHistory != null) {
      _history
        ..clear()
        ..addAll(savedHistory.take(5));
    }
  }
}
