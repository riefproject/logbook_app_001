import 'package:hive/hive.dart';

class CounterController {
  CounterController({String storageKeyPrefix = 'guest'})
    : _storageKeyPrefix = storageKeyPrefix.trim().toLowerCase();

  static const String _boxName = 'counter_storage';

  String get username => _storageKeyPrefix;
  int _counter = 0;
  int _step = 1;
  final List<String> _history = [];
  final String _storageKeyPrefix;

  int get value => _counter;
  int get step => _step;
  List<String> get history => List.unmodifiable(_history);

  void increment() {
    _counter += _step;
    _addHistory('$username menambahkan nilai sebesar $_step menjadi $_counter');
  }

  void decrement() {
    if (_counter - _step >= 0) {
      _counter -= _step;
      _addHistory(
        '$username mengurangi nilai sebesar $_step menjadi $_counter',
      );
    }
  }

  void reset() {
    _counter = 0;
    _addHistory('$username mereset nilai ke nol');
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
    final Box<dynamic> box = await _openBox();
    await saveLastCounter();
    await box.put(_stepKey, _step);
    await box.put(_historyKey, List<String>.from(_history));
  }

  Future<void> loadData() async {
    final Box<dynamic> box = await _openBox();
    await loadLastCounter();
    _step = (box.get(_stepKey) as int?) ?? _step;

    final dynamic rawHistory = box.get(_historyKey);
    final List<String>? savedHistory = rawHistory is List
        ? rawHistory.map((dynamic item) => item.toString()).toList()
        : null;
    if (savedHistory != null) {
      _history
        ..clear()
        ..addAll(savedHistory.take(5));
    }
  }

  Future<void> saveLastCounter() async {
    final Box<dynamic> box = await _openBox();
    await box.put(_counterKey, _counter);
  }

  Future<void> loadLastCounter() async {
    final Box<dynamic> box = await _openBox();
    _counter = (box.get(_counterKey) as int?) ?? _counter;
  }

  Future<Box<dynamic>> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<dynamic>(_boxName);
    }
    return Hive.openBox<dynamic>(_boxName);
  }

  String get _counterKey => '${_storageKeyPrefix}_counter_value';
  String get _stepKey => '${_storageKeyPrefix}_counter_step';
  String get _historyKey => '${_storageKeyPrefix}_counter_history';
}
