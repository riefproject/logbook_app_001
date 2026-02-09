import 'package:flutter/material.dart';
import 'counter_controller.dart';

class CounterView extends StatefulWidget {
  const CounterView({super.key});
  @override
  State<CounterView> createState() => _CounterViewState();
}

class _CounterViewState extends State<CounterView> {
  final CounterController _controller = CounterController();

  void _onIncrement() {
    setState(_controller.increment);
  }

  void _onDecrement() {
    setState(_controller.decrement);
  }

  void _onStepChanged(double value) {
    setState(() {
      _controller.setStep(value.round());
    });
  }

  @override
  Widget build(BuildContext context) {
    final int counter = _controller.value;
    final int step = _controller.step;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Counter SRP'),
        
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Nilai Counter',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '$counter',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 16),
              Text(
                'Step: $step',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Slider(
                value: step.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                label: '$step',
                onChanged: _onStepChanged,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _onDecrement,
                    child: const Text('Decrement'),
                  ),
                  ElevatedButton(
                    onPressed: _onIncrement,
                    child: const Text('Increment'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
