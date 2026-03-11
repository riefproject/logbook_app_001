import 'dart:developer' as dev;
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';

class LogHelper {
  static Future<void> writeLog(
    String message, {
    String source = 'Unknown',
    int level = 2,
  }) async {
    final int configLevel = int.tryParse(dotenv.env['LOG_LEVEL'] ?? '2') ?? 2;
    final List<String> muteList = (dotenv.env['LOG_MUTE'] ?? '')
        .split(',')
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .toList();

    if (level > configLevel) {
      return;
    }

    if (muteList.contains(source)) {
      return;
    }

    try {
      final DateTime now = DateTime.now();
      final String label = _getLabel(level);
      final String timestamp = _formatTime(now);
      final String fileName = _formatFileName(now);
      final String line = '[$timestamp][$label][$source] $message';

      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final Directory logsDirectory = Directory('${appDocDir.path}/logs');

      if (!await logsDirectory.exists()) {
        await logsDirectory.create(recursive: true);
      }

      dev.log(message, name: source, time: now, level: _developerLevel(level));
      // ignore: avoid_print
      print(line);

      final File logFile = File('${logsDirectory.path}/$fileName');
      await logFile.writeAsString(
        '$line\n',
        mode: FileMode.append,
        flush: true,
      );
    } catch (error) {
      dev.log('Logging failed: $error', name: 'SYSTEM', level: 1000);
    }
  }

  static String _getLabel(int level) {
    switch (level) {
      case 1:
        return 'ERROR';
      case 2:
        return 'INFO';
      case 3:
        return 'VERBOSE';
      default:
        return 'LOG';
    }
  }

  static String _formatTime(DateTime dateTime) {
    final String hour = dateTime.hour.toString().padLeft(2, '0');
    final String minute = dateTime.minute.toString().padLeft(2, '0');
    final String second = dateTime.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

  static String _formatFileName(DateTime dateTime) {
    final String day = dateTime.day.toString().padLeft(2, '0');
    final String month = dateTime.month.toString().padLeft(2, '0');
    final String year = dateTime.year.toString();
    return '$day-$month-$year.log';
  }

  static int _developerLevel(int level) {
    switch (level) {
      case 1:
        return 1000;
      case 2:
        return 800;
      case 3:
        return 500;
      default:
        return 0;
    }
  }
}
