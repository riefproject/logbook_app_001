import 'package:flutter/material.dart';

import 'log_controller.dart';
import 'models/log_model.dart';

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

  final LogController _controller = LogController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
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
    final String day = localTime.day.toString().padLeft(2, '0');
    final String month = localTime.month.toString().padLeft(2, '0');
    final String year = localTime.year.toString();
    final String hour = localTime.hour.toString().padLeft(2, '0');
    final String minute = localTime.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
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
              isSearching ? 'Tidak ada hasil pencarian' : 'Belum ada catatan',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isSearching
                  ? 'Coba kata kunci lain atau kosongkan pencarian.'
                  : 'Tambahkan catatan baru dengan tombol + di bawah.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.blueGrey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLogDialog({LogModel? selectedLog}) async {
    final bool isEdit = selectedLog != null;
    String selectedCategory = selectedLog?.category ?? _categories.first;
    if (!_categories.contains(selectedCategory)) {
      selectedCategory = _categories.first;
    }

    if (isEdit) {
      _titleController.text = selectedLog.title;
      _descriptionController.text = selectedLog.description;
    } else {
      _titleController.clear();
      _descriptionController.clear();
    }

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(isEdit ? 'Edit Catatan' : 'Tambah Catatan'),
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
              onPressed: () {
                final String title = _titleController.text.trim();
                final String description = _descriptionController.text.trim();

                if (!_controller.isValidInput(title, description)) {
                  _showMessage('Judul dan deskripsi wajib diisi');
                  return;
                }

                if (isEdit) {
                  final int index = _controller.indexOfLog(selectedLog);
                  if (index < 0) {
                    _showMessage('Data catatan tidak ditemukan');
                    return;
                  }
                  _controller.updateLog(
                    index,
                    title,
                    description,
                    selectedCategory,
                  );
                } else {
                  _controller.addLog(title, description, selectedCategory);
                }

                Navigator.pop(dialogContext);
                _showMessage(
                  isEdit
                      ? 'Catatan berhasil diperbarui'
                      : 'Catatan berhasil ditambah',
                );
              },
              child: Text(isEdit ? 'Simpan' : 'Tambah'),
            ),
          ],
        );
      },
    );
  }

  void _removeLog(LogModel log) {
    final int index = _controller.indexOfLog(log);
    if (index < 0) {
      _showMessage('Data catatan tidak ditemukan');
      return;
    }
    _controller.removeLog(index);
    _showMessage('Catatan berhasil dihapus');
  }

  Future<bool> _confirmDelete() async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Hapus catatan?'),
          content: const Text('Catatan yang dihapus tidak bisa dikembalikan.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Logbook - ${widget.username}')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: _controller.searchLog,
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
                child: ValueListenableBuilder<List<LogModel>>(
                  valueListenable: _controller.filteredLogs,
                  builder:
                      (
                        BuildContext context,
                        List<LogModel> logs,
                        Widget? child,
                      ) {
                        final bool isSearching = _searchController.text
                            .trim()
                            .isNotEmpty;
                        if (logs.isEmpty) {
                          return _buildEmptyState(isSearching: isSearching);
                        }

                        return ListView.builder(
                          itemCount: logs.length,
                          padding: const EdgeInsets.only(bottom: 12),
                          itemBuilder: (BuildContext context, int index) {
                            final LogModel log = logs[index];
                            final Color accentColor = _categoryColor(
                              log.category,
                            );

                            return Dismissible(
                              key: ValueKey<String>(
                                '${log.timestamp}_${log.title}_$index',
                              ),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade600,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(
                                      Icons.delete_outline,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Hapus',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              confirmDismiss:
                                  (DismissDirection direction) async {
                                    return _confirmDelete();
                                  },
                              onDismissed: (DismissDirection direction) {
                                _removeLog(log);
                              },
                              child: Card(
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
                                  trailing: IconButton(
                                    onPressed: () =>
                                        _showLogDialog(selectedLog: log),
                                    icon: const Icon(Icons.edit_outlined),
                                    tooltip: 'Edit',
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showLogDialog(),
        tooltip: 'Tambah Catatan',
        child: const Icon(Icons.add),
      ),
    );
  }
}
