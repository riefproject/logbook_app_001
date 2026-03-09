import 'package:flutter/material.dart';

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

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  late String _selectedCategory;

  bool get _isEditMode => widget.log != null && widget.index != null;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.log?.title ?? '';
    _descriptionController.text = widget.log?.description ?? '';
    _selectedCategory = widget.log?.category ?? _categories.first;
    if (!_categories.contains(_selectedCategory)) {
      _selectedCategory = _categories.first;
    }
  }

  @override
  void dispose() {
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
      _callUpdateLog(
        index: widget.index!,
        title: title,
        description: description,
        category: _selectedCategory,
        authorId: authorId,
        teamId: teamId,
      );
    } else {
      _callAddLog(
        title: title,
        description: description,
        category: _selectedCategory,
        authorId: authorId,
        teamId: teamId,
      );
    }

    Navigator.pop(context);
  }

  void _callAddLog({
    required String title,
    required String description,
    required String category,
    required String authorId,
    required String teamId,
  }) {
    try {
      Function.apply(
        widget.controller.addLog as Function,
        <dynamic>[title, description, category],
        <Symbol, dynamic>{#authorId: authorId, #teamId: teamId},
      );
      return;
    } on NoSuchMethodError {
      widget.controller.addLog(title, description, category);
    }
  }

  void _callUpdateLog({
    required int index,
    required String title,
    required String description,
    required String category,
    required String authorId,
    required String teamId,
  }) {
    try {
      Function.apply(
        widget.controller.updateLog as Function,
        <dynamic>[index, title, description, category],
        <Symbol, dynamic>{#authorId: authorId, #teamId: teamId},
      );
      return;
    } on NoSuchMethodError {
      widget.controller.updateLog(index, title, description, category);
    }
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
                ],
              ),
            ),
            const Center(
              child: Text('Pratinjau akan hadir di iterasi berikutnya.'),
            ),
          ],
        ),
      ),
    );
  }
}
