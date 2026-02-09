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

  Future<void> _onReset() async {
    if(_controller.value == 0) {
      return;
    }
    
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Reset'),
          content: const Text('Yakin ingin reset counter ke 0?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(_controller.reset);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Counter sudah di-reset')),
    );
  }

  void _onStepChanged(double value) {
    setState(() {
      _controller.setStep(value.round());
    });
  }

  Color _getHistoryColor(String historyEntry) {
    if (historyEntry.toLowerCase().contains('menambahkan')) {
      return Colors.green;
    } else if (historyEntry.toLowerCase().contains('mengurangi')) {
      return Colors.red;
    }
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final int counter = _controller.value;
    final int step = _controller.step;
    final List<String> history = _controller.history;

    return Scaffold(
      appBar: AppBar(
        title: const Text('LogbookApp'),
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
                max: 100,
                divisions: 99,
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
                  OutlinedButton(
                    onPressed: _onReset,
                    child: const Text('Reset'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'History',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: history.isEmpty
                    ? const Center(child: Text('Belum ada history'))
                    : ListView.separated(
                        itemCount: history.length,
                        separatorBuilder: (BuildContext context, int index) {
                          return const Divider(height: 1);
                        },
                        itemBuilder: (BuildContext context, int index) {
                          final color = _getHistoryColor(history[index]);
                          return ListTile(
                            dense: true,
                            title: Text(
                              history[index],
                              style: TextStyle(color: color, fontWeight: FontWeight.w500),
                            ),
                            // leading: Container(
                            //   width: 4,
                            //   color: color,
                            // ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

