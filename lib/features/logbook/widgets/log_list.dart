import 'package:flutter/material.dart';

import '../../../services/access_control_service.dart';
import '../log_controller.dart';
import '../models/log_model.dart';
import 'log_card_item.dart';
import 'log_empty_state.dart';

class LogList extends StatelessWidget {
  const LogList({
    super.key,
    required this.controller,
    required this.role,
    required this.userId,
    required this.teamId,
    required this.onOpenEditor,
    required this.onShowDetails,
  });

  final LogController controller;
  final String role;
  final String userId;
  final String teamId;
  final Function({LogModel? log, int? index}) onOpenEditor;
  final Function(LogModel log) onShowDetails;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<LogModel>>(
      valueListenable: controller.filteredLogs,
      builder: (context, logs, _) {
        if (logs.isEmpty) {
          return LogEmptyState(
            isSearching: controller.searchQuery.isNotEmpty,
            onAddFirst: onOpenEditor,
          );
        }

        return RefreshIndicator(
          onRefresh: () async => controller.loadLogs(teamId),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: logs.length,
            padding: const EdgeInsets.only(bottom: 12),
            itemBuilder: (context, index) {
              final log = logs[index];
              final originalIndex = controller.indexOfLog(log);
              if (originalIndex < 0) return const SizedBox.shrink();

              final bool isOwner = log.authorId == userId;
              return LogCardItem(
                log: log,
                canUpdate: AccessControlService.canPerform(
                  role,
                  AccessControlService.actionUpdate,
                  isOwner: isOwner,
                ),
                canDelete: AccessControlService.canPerform(
                  role,
                  AccessControlService.actionDelete,
                  isOwner: isOwner,
                ),
                onTap: () => onShowDetails(log),
                onEdit: () => onOpenEditor(log: log, index: index),
                onDelete: () async {
                  final bool? confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Konfirmasi Hapus'),
                      content: const Text(
                        'Yakin ingin menghapus catatan ini? Tindakan ini tidak dapat dibatalkan.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Batal'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade50,
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Hapus'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    controller.removeLog(index);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Catatan berhasil dihapus'),
                        ),
                      );
                    }
                  }
                },
              );
            },
          ),
        );
      },
    );
  }
}
