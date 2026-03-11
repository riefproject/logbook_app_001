import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/log_model.dart';

extension LogModelUI on LogModel {
  static final RegExp _objectIdPattern = RegExp(r'^[a-fA-F0-9]{24}$');

  bool get isSynced {
    final String? rawId = id?.trim();
    final bool hasCloudId = rawId != null && _objectIdPattern.hasMatch(rawId);
    return hasCloudId && !needsSync;
  }

  Color get accentColor {
    switch (category) {
      case 'Mechanical':
        return Colors.green;
      case 'Electronic':
        return Colors.blue;
      case 'Software':
        return Colors.purple;
      default:
        return Colors.blueGrey;
    }
  }

  IconData get categoryIcon {
    switch (category) {
      case 'Mechanical':
        return Icons.settings;
      case 'Electronic':
        return Icons.memory;
      case 'Software':
        return Icons.code;
      default:
        return Icons.label_outline;
    }
  }

  String get formattedTimestamp {
    final DateTime? parsedTime = DateTime.tryParse(timestamp);
    if (parsedTime == null) return timestamp;

    final DateTime localTime = parsedTime.toLocal();
    final Duration difference = DateTime.now().difference(localTime);

    if (!difference.isNegative) {
      if (difference.inMinutes < 1) return 'Baru saja';
      if (difference.inHours < 1) return '${difference.inMinutes} menit yang lalu';
    }

    try {
      return DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(localTime);
    } catch (_) {
      const List<String> monthNames = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      final String hour = localTime.hour.toString().padLeft(2, '0');
      final String minute = localTime.minute.toString().padLeft(2, '0');
      final String month = monthNames[localTime.month - 1];
      return '${localTime.day} $month ${localTime.year}, $hour:$minute';
    }
  }
}
