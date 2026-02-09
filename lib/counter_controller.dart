class CounterController {
  int _counter = 0;
  
  int get value => _counter;
  
  void increment() {
    _counter++;
  }

  void decrement() {
    if(_counter > 0) _counter--;
  }

  void reset() {
    _counter = 0;
  }

}
