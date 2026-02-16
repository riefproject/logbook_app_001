class CounterController {
  int _counter = 0;
  int _step = 1;
  final List<String> _history = [];
  
  int get value => _counter;
  int get step => _step;
  List<String> get history => List.unmodifiable(_history);
  
  void increment() {
    _counter += _step;
    _addHistory('User menambahkan nilai sebesar $_step menjadi $_counter');
  }

  void decrement() {
    if(_counter - _step >= 0) {
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
}
