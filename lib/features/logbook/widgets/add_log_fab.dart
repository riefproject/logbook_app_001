import 'package:flutter/material.dart';
import '../../../services/access_control_service.dart';
import '../models/log_model.dart';

class AddLogFAB extends StatelessWidget {
  const AddLogFAB({super.key, required this.role, required this.onOpenEditor});
  final String role;
  final Function({LogModel? log, int? index}) onOpenEditor;

  @override
  Widget build(BuildContext context) {
    if (!AccessControlService.canPerform(
      role,
      AccessControlService.actionCreate,
    )) {
      return const SizedBox.shrink();
    }
    return FloatingActionButton(
      onPressed: onOpenEditor,
      tooltip: 'Tambah Catatan',
      child: const Icon(Icons.add),
    );
  }
}
