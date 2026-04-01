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

    test('saveLog should overwrite existing local data when id is the same', () async {
      await repository.saveLog(
        buildLog(id: 'same-id', title: 'Versi Lama', description: 'Lama'),
      );

      await repository.saveLog(
        buildLog(id: 'same-id', title: 'Versi Baru', description: 'Baru'),
      );

      final LogModel? actual = hiveContext.offlineLogsBox.get('same-id');

      expect(actual?.title, 'Versi Baru');
      expect(actual?.description, 'Baru');
    });

    test('getLocalLogs should return an empty list when no local data exists', () {
      final List<LogModel> actual = repository.getLocalLogs('TIM_ARIEF');

      expect(actual, isEmpty);
    });

    test('saveLog should preserve all important fields after reading from disk', () async {
      final LogModel log = buildLog(
        id: 'full-data',
        title: 'Catatan Lengkap',
        description: 'Deskripsi Lengkap',
        category: 'Jaringan',
        authorId: 'arief',
        teamId: 'TIM_ARIEF',
        visibility: 'team',
      );

      await repository.saveLog(log);

      final LogModel? actual = hiveContext.offlineLogsBox.get('full-data');

      expect(actual?.title, 'Catatan Lengkap');
      expect(actual?.description, 'Deskripsi Lengkap');
      expect(actual?.category, 'Jaringan');
      expect(actual?.authorId, 'arief');
      expect(actual?.teamId, 'TIM_ARIEF');
      expect(actual?.visibility, 'team');
    });

    test('getLocalLogs should ignore data from other teams even when local box has many entries', () async {
      await repository.saveLog(buildLog(id: 'a1', teamId: 'TIM_ARIEF'));
      await repository.saveLog(buildLog(id: 'a2', teamId: 'TIM_ARIEF'));
      await repository.saveLog(buildLog(id: 'b1', teamId: 'TIM_ORANG'));
      await repository.saveLog(buildLog(id: 'b2', teamId: 'TIM_ORANG'));

      final List<LogModel> actual = repository.getLocalLogs('TIM_ARIEF');

      expect(actual.length, 2);
      expect(actual.every((log) => log.teamId == 'TIM_ARIEF'), isTrue);
    });

    test('deleteLog should not fail when local key is already missing', () async {
      final LogModel log = buildLog(id: 'missing-local');

      await repository.deleteLog(log);

      expect(hiveContext.offlineLogsBox.containsKey('missing-local'), isFalse);
      expect(hiveContext.syncQueueBox.isEmpty, isTrue);
    });

    test('saveLog should keep invalid timestamp data unchanged in local storage', () async {
      final LogModel log = buildLog(
        id: 'invalid-time',
        timestamp: 'bukan-format-tanggal',
      );

      await repository.saveLog(log);

      final LogModel? actual = hiveContext.offlineLogsBox.get('invalid-time');

      expect(actual?.timestamp, 'bukan-format-tanggal');
    });
  });
}
