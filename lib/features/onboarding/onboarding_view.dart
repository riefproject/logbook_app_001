import 'package:flutter/material.dart';

import '../auth/login_view.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  int step = 1;

  final List<IconData> _icons = [Icons.edit_note, Icons.history, Icons.lock];

  final List<String> _titles = [
    'Catat Aktivitas Harian',
    'Lihat Riwayat Counter',
    'Login Aman dan Cepat',
  ];

  final List<String> _descriptions = [
    'Gunakan counter untuk mencatat progres logbook dengan rapi.',
    'Semua perubahan tersimpan di history agar mudah ditelusuri.',
    'Masuk dengan akun yang tersedia sebelum mulai mencatat.',
  ];

  void _onNext() {
    final int nextStep = step + 1;
    if (nextStep > 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (BuildContext context) => const LoginView()),
      );
      return;
    }

    setState(() {
      step = nextStep;
    });
  }

  @override
  Widget build(BuildContext context) {
    final int index = step - 1;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Onboarding $step/3',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _icons[index],
                  size: 72,
                  color: Colors.blue.shade700,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _titles[index],
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                _descriptions[index],
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _onNext,
                  child: Text(step == 3 ? 'Mulai Login' : 'Next'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
