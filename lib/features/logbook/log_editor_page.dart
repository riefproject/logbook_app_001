import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import 'log_controller.dart';
import 'models/log_model.dart';

class LogEditorPage extends StatefulWidget {
  const LogEditorPage({
    super.key,
    this.log,
    this.index,
    required this.controller,
    required this.currentUser,
  });

  final LogModel? log;
  final int? index;
  final LogController controller;
  final Map<String, dynamic> currentUser;

  @override
  State<LogEditorPage> createState() => _LogEditorPageState();
}

class _LogEditorPageState extends State<LogEditorPage> {
  static const List<String> _categories = <String>[
    'Akademik',
    'Proyek',
    'Pribadi',
  ];
  static const List<String> _visibilityOptions = <String>['private', 'public'];

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  late String _selectedCategory;
  late String _selectedVisibility;

  bool get _isEditMode => widget.log != null && widget.index != null;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.log?.title ?? '';
    _descriptionController.text = widget.log?.description ?? '';
    _descriptionController.addListener(_onDescriptionChanged);
    _selectedCategory = widget.log?.category ?? _categories.first;
    if (!_categories.contains(_selectedCategory)) {
      _selectedCategory = _categories.first;
    }
    _selectedVisibility = widget.log?.visibility ?? _visibilityOptions.first;
    if (!_visibilityOptions.contains(_selectedVisibility)) {
      _selectedVisibility = _visibilityOptions.first;
    }
  }

  void _onDescriptionChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _descriptionController.removeListener(_onDescriptionChanged);
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveLog() {
    final String title = _titleController.text.trim();
    final String description = _descriptionController.text.trim();
    final String authorId = (widget.currentUser['uid'] ?? 'unknown').toString();
    final String teamId = (widget.currentUser['teamId'] ?? 'unknown')
        .toString();

    if (!widget.controller.isValidInput(title, description)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul dan deskripsi wajib diisi')),
      );
      return;
    }

    if (_isEditMode) {
      widget.controller.updateLog(
        widget.index!,
        title,
        description,
        _selectedCategory,
        authorId: authorId,
        teamId: teamId,
        visibility: _selectedVisibility,
      );
    } else {
      widget.controller.addLog(
        title,
        description,
        _selectedCategory,
        authorId: authorId,
        teamId: teamId,
        visibility: _selectedVisibility,
      );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditMode ? 'Edit Catatan' : 'Tambah Catatan'),
          actions: [
            IconButton(
              onPressed: _saveLog,
              icon: const Icon(Icons.save_outlined),
              tooltip: 'Simpan',
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Editor'),
              Tab(text: 'Pratinjau'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
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
                    minLines: 6,
                    maxLines: null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
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
                      setState(() {
                        _selectedCategory = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedVisibility,
                    decoration: const InputDecoration(
                      labelText: 'Visibilitas',
                      border: OutlineInputBorder(),
                    ),
                    items: _visibilityOptions.map((String visibility) {
                      final String label = visibility == 'public'
                          ? 'Public (tim dapat melihat)'
                          : 'Private (hanya Anda)';
                      return DropdownMenuItem<String>(
                        value: visibility,
                        child: Text(label),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _selectedVisibility = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: MarkdownBody(data: _descriptionController.text),
            ),
          ],
        ),
      ),
    );
  }
}
