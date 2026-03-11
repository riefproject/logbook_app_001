import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LogEmptyState extends StatelessWidget {
  const LogEmptyState({
    super.key,
    required this.isSearching,
    required this.onAddFirst,
  });

  final bool isSearching;
  final VoidCallback onAddFirst;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              'assets/animations/empty.json',
              height: 120,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.inbox_outlined,
                  size: 88,
                  color: Colors.blueGrey.shade300,
                );
              },
            ),
            const SizedBox(height: 14),
            Text(
              isSearching
                  ? 'Tidak ada hasil pencarian'
                  : 'Belum ada aktivitas hari ini?',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isSearching
                  ? 'Coba kata kunci lain atau kosongkan pencarian.'
                  : 'Mulai catat kemajuan proyek Anda sekarang!',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.blueGrey.shade600),
              textAlign: TextAlign.center,
            ),
            if (!isSearching) ...<Widget>[
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: onAddFirst,
                icon: const Icon(Icons.add),
                label: const Text('Tambah Log Pertama'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
