import 'package:flutter/material.dart';
import '../models/log_model.dart';
import '../presenters/log_ui_presenter.dart';

class LogCardItem extends StatelessWidget {
  const LogCardItem({
    super.key,
    required this.log,
    required this.canUpdate,
    required this.canDelete,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final LogModel log;
  final bool canUpdate;
  final bool canDelete;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: log.accentColor.withValues(alpha: 0.26),
        ),
      ),
      color: log.accentColor.withValues(alpha: 0.08),
      child: ListTile(
        onTap: onTap,
        title: Text(
          log.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text(
              log.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildVisibilityBadge(),
                _buildCategoryBadge(),
              ],
            ),
            const SizedBox(height: 6),
            _buildFooter(context),
          ],
        ),
        trailing: (canUpdate || canDelete)
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (canUpdate)
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Edit',
                      onPressed: onEdit,
                    ),
                  if (canDelete)
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Hapus',
                      onPressed: onDelete,
                    ),
                ],
              )
            : null,
      ),
    );
  }

  Widget _buildVisibilityBadge() {
    final bool isPublic = log.visibility == 'public';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        color: isPublic
            ? Colors.green.withValues(alpha: 0.16)
            : Colors.blueGrey.withValues(alpha: 0.16),
      ),
      child: Icon(
        isPublic ? Icons.public : Icons.lock,
        size: 12,
        color: isPublic ? Colors.green : Colors.blueGrey,
      ),
    );
  }

  Widget _buildCategoryBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        color: log.accentColor.withValues(alpha: 0.16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            log.categoryIcon,
            size: 12,
            color: log.accentColor,
          ),
          const SizedBox(width: 4),
          Text(
            log.category,
            style: TextStyle(
              color: log.accentColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Row(
      children: [
        Icon(
          log.isSynced ? Icons.cloud_outlined : Icons.cloud_off,
          size: 12,
          color: log.isSynced ? Colors.green.shade700 : Colors.orange.shade700,
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
            log.formattedTimestamp,
            textAlign: TextAlign.left,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.blueGrey.shade600,
                  fontSize: 11,
                ),
          ),
        ),
      ],
    );
  }
}
