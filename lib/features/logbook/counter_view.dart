import 'package:flutter/material.dart';

import '../onboarding/onboarding_view.dart';
import 'counter_controller.dart';

class CounterView extends StatefulWidget {
  final String username;

  const CounterView({super.key, required this.username});

  @override
  State<CounterView> createState() => _CounterViewState();
}

class _CounterViewState extends State<CounterView> {
  late final CounterController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = CounterController(storageKeyPrefix: widget.username);
    _loadCounterData();
  }

  Future<void> _loadCounterData() async {
    await _controller.loadData();
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _onIncrement() async {
    setState(_controller.increment);
    await _controller.saveData();
  }

  Future<void> _onDecrement() async {
    setState(_controller.decrement);
    await _controller.saveData();
  }

  Future<void> _onReset() async {
    if (_controller.value == 0) {
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
    await _controller.saveData();
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Counter sudah di-reset')));
  }

  void _onStepChanged(double value) {
    setState(() {
      _controller.setStep(value.round());
    });
    _controller.saveData();
  }

  Future<void> _onLogout() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Logout'),
          content: const Text('Yakin ingin logout sekarang?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => const OnboardingView(),
      ),
      (Route<dynamic> route) => false,
    );
  }

  Color _getHistoryColor(String historyEntry) {
    if (historyEntry.toLowerCase().contains('menambahkan')) {
      return Colors.green;
    } else if (historyEntry.toLowerCase().contains('mengurangi')) {
      return Colors.red;
    }
    return Colors.grey;
  }

  String _getGreetingWib() {
    final DateTime wibTime = DateTime.now().toUtc().add(
      const Duration(hours: 7),
    );
    final int hour = wibTime.hour;

    if (hour >= 5 && hour < 11) {
      return 'Selamat Pagi';
    }
    if (hour >= 11 && hour < 15) {
      return 'Selamat Siang';
    }
    if (hour >= 15 && hour < 18) {
      return 'Selamat Sore';
    }
    return 'Selamat Malam';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('LogbookApp - ${widget.username}')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final int counter = _controller.value;
    final int step = _controller.step;
    final List<String> history = _controller.history;
    final String greeting = _getGreetingWib();

    return Scaffold(
      appBar: AppBar(
        title: Text('LogbookApp - ${widget.username}'),
        actions: [
          IconButton(
            onPressed: _onLogout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '$greeting, ${widget.username}',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
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
              Text('History', style: Theme.of(context).textTheme.titleMedium),
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
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w500,
                              ),
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
