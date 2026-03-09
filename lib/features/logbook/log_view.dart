import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'models/log_model.dart';
import '../../services/mongo_service.dart';

class LogView extends StatefulWidget {
  const LogView({super.key, required this.username});

  final String username;

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  static const List<String> _categories = <String>[
    'Akademik',
    'Proyek',
    'Pribadi',
  ];
  static const List<String> _indonesianMonthNames = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  final MongoService _mongoService = MongoService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  Future<List<LogModel>>? _logsFuture;

  @override
  void initState() {
    super.initState();
    _logsFuture = _mongoService.getLogs();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatTimestamp(String timestamp) {
    final DateTime? parsedTime = DateTime.tryParse(timestamp);
    if (parsedTime == null) {
      return timestamp;
    }

    final DateTime localTime = parsedTime.toLocal();
    final Duration difference = DateTime.now().difference(localTime);

    if (!difference.isNegative) {
      if (difference.inMinutes < 1) {
        return 'Baru saja';
      }

      if (difference.inHours < 1) {
        return '${difference.inMinutes} menit yang lalu';
      }
    }

    try {
      return DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(localTime);
    } catch (_) {
      final String hour = localTime.hour.toString().padLeft(2, '0');
      final String minute = localTime.minute.toString().padLeft(2, '0');
      final String month = _indonesianMonthNames[localTime.month - 1];

      return '${localTime.day} $month ${localTime.year}, $hour:$minute';
    }
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'Akademik':
        return Colors.indigo;
      case 'Proyek':
        return Colors.teal;
      case 'Pribadi':
        return Colors.deepOrange;
      default:
        return Colors.blueGrey;
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Akademik':
        return Icons.school;
      case 'Proyek':
        return Icons.build_circle_outlined;
      case 'Pribadi':
        return Icons.favorite_border;
      default:
        return Icons.label_outline;
    }
  }

  Future<void> _refreshLogs() async {
    setState(() {
      _logsFuture = _mongoService.getLogs();
    });

    try {
      await _logsFuture;
    } catch (_) {
      // Error state is rendered by FutureBuilder via snapshot.hasError.
    }
  }

  Widget _buildConnectionErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 72, color: Colors.blueGrey),
            const SizedBox(height: 12),
            Text(
              'Tidak dapat terhubung ke server',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Periksa koneksi internet Anda',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.blueGrey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                _refreshLogs();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({required bool isSearching}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 88,
              color: Colors.blueGrey.shade300,
            ),
            const SizedBox(height: 14),
            Text(
              isSearching ? 'Tidak ada hasil pencarian' : 'Data Kosong',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isSearching
                  ? 'Coba kata kunci lain atau kosongkan pencarian.'
                  : 'Tambahkan log pertamamu untuk mulai menyimpan data cloud.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.blueGrey.shade600),
              textAlign: TextAlign.center,
            ),
            if (!isSearching) ...<Widget>[
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: _showLogDialog,
                icon: const Icon(Icons.add),
                label: const Text('Tambah Log Pertama'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showLogDialog() async {
    String selectedCategory = _categories.first;
    if (!_categories.contains(selectedCategory)) {
      selectedCategory = _categories.first;
    }

    _titleController.clear();
    _descriptionController.clear();

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Tambah Catatan'),
          content: StatefulBuilder(
            builder:
                (
                  BuildContext context,
                  void Function(void Function()) setDialogState,
                ) {
                  return SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Judul',
                            border: OutlineInputBorder(),
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Deskripsi',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Kategori',
                            border: OutlineInputBorder(),
                          ),
                          items: _categories.map((String category) {
                            return DropdownMenuItem<String>(
                              value: category,
                              child: Text(category),
                            );
                          }).toList(),
                          onChanged: (String? value) {
                            if (value == null) {
                              return;
                            }
                            setDialogState(() {
                              selectedCategory = value;
                            });
                          },
                        ),
                      ],
                    ),
                  );
                },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final String title = _titleController.text.trim();
                final String description = _descriptionController.text.trim();

                if (title.isEmpty || description.isEmpty) {
                  _showMessage('Judul dan deskripsi wajib diisi');
                  return;
                }

                try {
                  await _mongoService.insertLog(
                    LogModel(
                      title: title,
                      description: description,
                      timestamp: DateTime.now().toIso8601String(),
                      category: selectedCategory,
                    ),
                  );
                } catch (error) {
                  if (!mounted || !dialogContext.mounted) {
                    return;
                  }
                  Navigator.of(dialogContext).pop();
                  _showMessage('Gagal menambah catatan: $error');
                  return;
                }

                if (!mounted || !dialogContext.mounted) {
                  return;
                }
                Navigator.of(dialogContext).pop();
                _refreshLogs();
                _showMessage('Catatan berhasil ditambah');
              },
              child: const Text('Tambah'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Logbook - ${widget.username}'),
        actions: [
          IconButton(
            onPressed: () {
              _refreshLogs();
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Cari catatan',
                  hintText: 'Cari judul, deskripsi, atau kategori',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.blueGrey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.blueGrey.shade50,
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: FutureBuilder<List<LogModel>>(
                  future: _logsFuture,
                  builder:
                      (
                        BuildContext context,
                        AsyncSnapshot<List<LogModel>> snapshot,
                      ) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return _buildConnectionErrorState();
                        }

                        final List<LogModel> allLogs =
                            snapshot.data ?? <LogModel>[];
                        final String query = _searchController.text
                            .trim()
                            .toLowerCase();
                        final List<LogModel> logs = query.isEmpty
                            ? allLogs
                            : allLogs.where((LogModel log) {
                                return log.title.toLowerCase().contains(
                                      query,
                                    ) ||
                                    log.description.toLowerCase().contains(
                                      query,
                                    ) ||
                                    log.category.toLowerCase().contains(query);
                              }).toList();

                        if (logs.isEmpty) {
                          return _buildEmptyState(
                            isSearching: query.isNotEmpty,
                          );
                        }

                        return RefreshIndicator(
                          onRefresh: _refreshLogs,
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: logs.length,
                            padding: const EdgeInsets.only(bottom: 12),
                            itemBuilder: (BuildContext context, int index) {
                              final LogModel log = logs[index];
                              final Color accentColor = _categoryColor(
                                log.category,
                              );

                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: accentColor.withValues(alpha: 0.26),
                                  ),
                                ),
                                color: accentColor.withValues(alpha: 0.08),
                                child: ListTile(
                                  title: Text(
                                    log.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 6),
                                      Text(log.description),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(99),
                                              color: accentColor.withValues(
                                                alpha: 0.16,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  _categoryIcon(log.category),
                                                  size: 12,
                                                  color: accentColor,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  log.category,
                                                  style: TextStyle(
                                                    color: accentColor,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 12,
                                                    height: 1.1,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Icon(
                                            Icons.schedule_outlined,
                                            size: 12,
                                            color: Colors.blueGrey.shade500,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              _formatTimestamp(log.timestamp),
                                              textAlign: TextAlign.left,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: Colors
                                                        .blueGrey
                                                        .shade600,
                                                    fontSize: 11,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showLogDialog,
        tooltip: 'Tambah Catatan',
        child: const Icon(Icons.add),
      ),
    );
  }
}
