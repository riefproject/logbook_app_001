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
  final LogController _controller = LogController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
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

  Future<void> _showLogDialog({int? index}) async {
    final bool isEdit = index != null;

    if (isEdit) {
      final LogModel log = _controller.logs[index];
      _titleController.text = log.title;
      _descriptionController.text = log.description;
    } else {
      _titleController.clear();
      _descriptionController.clear();
    }

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(isEdit ? 'Edit Catatan' : 'Tambah Catatan'),
          content: Column(
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
            ],
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

                if (title.isEmpty || description.isEmpty) {
                  _showMessage('Judul dan deskripsi wajib diisi');
                  return;
                }

                setState(() {
                  if (isEdit) {
                    _controller.updateLog(index, title, description);
                  } else {
                    _controller.addLog(title, description);
                  }
                });

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

  void _removeLog(int index) {
    setState(() {
      _controller.removeLog(index);
    });
    _showMessage('Catatan berhasil dihapus');
  }

  @override
  Widget build(BuildContext context) {
    final List<LogModel> logs = _controller.logs;

    return Scaffold(
      appBar: AppBar(title: Text('Logbook - ${widget.username}')),
      body: SafeArea(
        child: logs.isEmpty
            ? const Center(child: Text('Belum ada catatan.'))
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: logs.length,
                itemBuilder: (BuildContext context, int index) {
                  final LogModel log = logs[index];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text(log.title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          Text(log.description),
                          const SizedBox(height: 6),
                          Text(
                            _formatTimestamp(log.timestamp),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => _showLogDialog(index: index),
                            icon: const Icon(Icons.edit),
                            tooltip: 'Edit',
                          ),
                          IconButton(
                            onPressed: () => _removeLog(index),
                            icon: const Icon(Icons.delete),
                            tooltip: 'Hapus',
                            color: Colors.red,
                          ),
                        ],
                      ),
                    ),
                  );
                },
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
