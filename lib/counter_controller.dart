class CounterController {
  int _counter = 0;
  int _step = 1;
  
  int get value => _counter;
  int get step => _step;
  
  void increment() {
    _counter += _step;
  }

  void decrement() {
    if(_counter - _step >= 0) _counter -= _step;
  }

  void reset() {
    _counter = 0;
  }

  void setStep(int value) {
    final int safeValue = value < 1 ? 1 : value;
    if (safeValue == _step) {
      return;
    }
    _step = safeValue;
  }
}
