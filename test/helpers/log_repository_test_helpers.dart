import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:logbook_app_001/features/logbook/log_repository_dependencies.dart';
import 'package:logbook_app_001/features/logbook/models/log_model.dart';

class FakeCloudLogService implements CloudLogService {
  final List<LogModel> cloudLogs = <LogModel>[];
  final List<LogModel> insertedLogs = <LogModel>[];
  final List<LogModel> updatedLogs = <LogModel>[];
  final List<Map<String, String?>> deletedLogs = <Map<String, String?>>[];

  String? insertResult;
  Object? insertError;
  Object? updateError;
  Object? deleteError;
  Object? getLogsError;

  @override
  Future<void> deleteLog(String id, {String? teamId}) async {
    if (deleteError != null) {
      throw deleteError!;
    }
    deletedLogs.add(<String, String?>{'id': id, 'teamId': teamId});
  }

  @override
  Future<List<LogModel>> getLogs(String teamId) async {
    if (getLogsError != null) {
      throw getLogsError!;
    }
    return cloudLogs.where((log) => log.teamId == teamId).toList();
  }

  @override
  Future<String?> insertLog(LogModel log) async {
    if (insertError != null) {
      throw insertError!;
    }
    insertedLogs.add(log);
    return insertResult;
  }

  @override
  Future<void> updateLog(LogModel log) async {
    if (updateError != null) {
      throw updateError!;
    }
    updatedLogs.add(log);
  }
}

class FakeConnectivityService implements ConnectivityService {
  FakeConnectivityService({
    List<ConnectivityResult>? initialResults,
    Stream<List<ConnectivityResult>>? connectivityStream,
  }) : _results = initialResults ?? <ConnectivityResult>[ConnectivityResult.wifi],
       _connectivityStream =
           connectivityStream ?? const Stream<List<ConnectivityResult>>.empty();

  List<ConnectivityResult> _results;
  final Stream<List<ConnectivityResult>> _connectivityStream;

  void setResults(List<ConnectivityResult> results) {
    _results = results;
  }

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => _results;

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _connectivityStream;
}

class HiveTestContext {
  HiveTestContext._(this.directory, this.offlineLogsBox, this.syncQueueBox);

  final Directory directory;
  final Box<LogModel> offlineLogsBox;
  final Box<dynamic> syncQueueBox;

  static Future<HiveTestContext> create() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final Directory directory = await Directory.systemTemp.createTemp(
      'log_repository_test_',
    );

    Hive.init(directory.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(LogModelAdapter());
    }

    final Box<LogModel> offlineLogsBox = await Hive.openBox<LogModel>(
      'offline_logs',
    );
    final Box<dynamic> syncQueueBox = await Hive.openBox<dynamic>('sync_queue');

    return HiveTestContext._(directory, offlineLogsBox, syncQueueBox);
  }

  Future<void> dispose() async {
    await offlineLogsBox.close();
    await syncQueueBox.close();
    await Hive.close();
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }
}

LogModel buildLog({
  String? id = 'local-1',
  String title = 'Judul',
  String description = 'Deskripsi',
  String timestamp = '2026-04-01T08:00:00.000',
  String category = 'Software',
  String authorId = 'admin',
  String teamId = 'TIM_ARIEF',
  String visibility = 'private',
  bool needsSync = false,
}) {
  return LogModel(
    id: id,
    title: title,
    description: description,
    timestamp: timestamp,
    category: category,
    authorId: authorId,
    teamId: teamId,
    visibility: visibility,
    needsSync: needsSync,
  );
}
