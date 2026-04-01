import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logbook_app_001/features/logbook/log_repository.dart';
import 'package:logbook_app_001/features/logbook/models/log_model.dart';

import 'helpers/log_repository_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await dotenv.load(fileName: '.env');
  });

  group('Module 3 - Save Data To Disk', () {
    late HiveTestContext hiveContext;
    late FakeCloudLogService cloudService;
    late FakeConnectivityService connectivityService;
    late LogRepository repository;

    setUp(() async {
      hiveContext = await HiveTestContext.create();
      cloudService = FakeCloudLogService();
      connectivityService = FakeConnectivityService();
      repository = LogRepository(
        offlineLogsBox: hiveContext.offlineLogsBox,
        syncQueueBox: hiveContext.syncQueueBox,
        mongoService: cloudService,
        connectivityService: connectivityService,
      );
    });

    tearDown(() async {
      await hiveContext.dispose();
    });

    test('saveLog should store a log in the local Hive box', () async {
      final LogModel log = buildLog(id: 'local-1');

      await repository.saveLog(log);

      expect(hiveContext.offlineLogsBox.get('local-1')?.title, 'Judul');
    });

    test('getLocalLogs should only return logs for the requested team', () async {
      await repository.saveLog(buildLog(id: 'team-a', teamId: 'TIM_ARIEF'));
      await repository.saveLog(buildLog(id: 'team-b', teamId: 'TIM_ORANG'));

      final List<LogModel> actual = repository.getLocalLogs('TIM_ARIEF');

      expect(actual.length, 1);
      expect(actual.first.id, 'team-a');
    });

    test('getLocalLogs should sort the newest timestamp first', () async {
      await repository.saveLog(
        buildLog(id: 'older', timestamp: '2026-04-01T08:00:00.000'),
      );
      await repository.saveLog(
        buildLog(id: 'newer', timestamp: '2026-04-01T09:00:00.000'),
      );

      final List<LogModel> actual = repository.getLocalLogs('TIM_ARIEF');

      expect(actual.map((log) => log.id).toList(), <String?>['newer', 'older']);
    });

    test('deleteLog should remove a local-only log from disk immediately', () async {
      final LogModel log = buildLog(id: 'draft-1');
      await repository.saveLog(log);

      await repository.deleteLog(log);

      expect(hiveContext.offlineLogsBox.containsKey('draft-1'), isFalse);
      expect(hiveContext.syncQueueBox.isEmpty, isTrue);
    });

    test('saveLog should not call cloud sync when needsSync is false', () async {
      await repository.saveLog(buildLog(id: 'stable-1', needsSync: false));

      expect(cloudService.insertedLogs, isEmpty);
      expect(cloudService.updatedLogs, isEmpty);
    });

    test('saveLog should keep local data when sync insert fails', () async {
      cloudService.insertError = Exception('insert gagal');
      final LogModel log = buildLog(id: 'draft-sync', needsSync: true);

      await repository.saveLog(log);

      expect(hiveContext.offlineLogsBox.containsKey('draft-sync'), isTrue);
      expect(hiveContext.offlineLogsBox.get('draft-sync')?.needsSync, isTrue);
    });
  });
}
