import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logbook_app_001/features/logbook/log_repository.dart';

import 'helpers/log_repository_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await dotenv.load(fileName: '.env');
  });

  group('Module 4 - Save Data To Cloud', () {
    late HiveTestContext hiveContext;
    late FakeCloudLogService cloudService;
    late FakeConnectivityService connectivityService;
    late LogRepository repository;

    setUp(() async {
      hiveContext = await HiveTestContext.create();
      cloudService = FakeCloudLogService();
      connectivityService = FakeConnectivityService(
        initialResults: <ConnectivityResult>[ConnectivityResult.wifi],
      );
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

    test('syncSingleLog should insert a new cloud log and replace local temp id', () async {
      cloudService.insertResult = '507f1f77bcf86cd799439011';
      await hiveContext.offlineLogsBox.put(
        'local-1',
        buildLog(id: 'local-1', needsSync: true),
      );

      await repository.syncSingleLog('local-1');

      expect(hiveContext.offlineLogsBox.containsKey('local-1'), isFalse);
      expect(
        hiveContext.offlineLogsBox.get('507f1f77bcf86cd799439011')?.needsSync,
        isFalse,
      );
      expect(cloudService.insertedLogs.length, 1);
    });

    test('syncSingleLog should update existing cloud log and clear needsSync flag', () async {
      const String cloudId = '507f1f77bcf86cd799439012';
      await hiveContext.offlineLogsBox.put(
        cloudId,
        buildLog(id: cloudId, needsSync: true, title: 'Perubahan lokal'),
      );

      await repository.syncSingleLog(cloudId);

      expect(cloudService.updatedLogs.length, 1);
      expect(hiveContext.offlineLogsBox.get(cloudId)?.needsSync, isFalse);
    });

    test('deleteLog should queue cloud delete when device is offline', () async {
      const String cloudId = '507f1f77bcf86cd799439013';
      connectivityService.setResults(<ConnectivityResult>[ConnectivityResult.none]);
      final log = buildLog(id: cloudId, needsSync: false);
      await hiveContext.offlineLogsBox.put(cloudId, log);

      await repository.deleteLog(log);

      expect(cloudService.deletedLogs, isEmpty);
      expect(hiveContext.syncQueueBox.length, 1);
      expect(hiveContext.syncQueueBox.getAt(0)['id'], cloudId);
    });

    test('syncPendingOperations should send queued deletes to cloud when online', () async {
      await hiveContext.syncQueueBox.add(<String, dynamic>{
        'action': 'delete',
        'id': '507f1f77bcf86cd799439014',
        'teamId': 'TIM_ARIEF',
        'queuedAt': '2026-04-01T10:00:00.000',
      });

      await repository.syncPendingOperations();

      expect(cloudService.deletedLogs.length, 1);
      expect(hiveContext.syncQueueBox.isEmpty, isTrue);
    });

    test('pullCloudLogs should import cloud data for the requested team', () async {
      cloudService.cloudLogs.addAll([
        buildLog(
          id: '507f1f77bcf86cd799439015',
          teamId: 'TIM_ARIEF',
          needsSync: false,
        ),
        buildLog(
          id: '507f1f77bcf86cd799439016',
          teamId: 'TIM_ORANG',
          needsSync: false,
        ),
      ]);

      await repository.pullCloudLogs('TIM_ARIEF');

      expect(hiveContext.offlineLogsBox.length, 1);
      expect(
        hiveContext.offlineLogsBox.get('507f1f77bcf86cd799439015')?.teamId,
        'TIM_ARIEF',
      );
    });

    test('pullCloudLogs should not overwrite local unsynced changes', () async {
      const String cloudId = '507f1f77bcf86cd799439017';
      await hiveContext.offlineLogsBox.put(
        cloudId,
        buildLog(id: cloudId, title: 'Versi lokal', needsSync: true),
      );
      cloudService.cloudLogs.add(
        buildLog(id: cloudId, title: 'Versi cloud', needsSync: false),
      );

      await repository.pullCloudLogs('TIM_ARIEF');

      expect(hiveContext.offlineLogsBox.get(cloudId)?.title, 'Versi lokal');
      expect(hiveContext.offlineLogsBox.get(cloudId)?.needsSync, isTrue);
    });

    test('pullCloudLogs with reconcileDeletes should remove synced local logs missing in cloud', () async {
      const String removedId = '507f1f77bcf86cd799439018';
      await hiveContext.offlineLogsBox.put(
        removedId,
        buildLog(id: removedId, needsSync: false),
      );

      await repository.pullCloudLogs('TIM_ARIEF', reconcileDeletes: true);

      expect(hiveContext.offlineLogsBox.containsKey(removedId), isFalse);
    });

    test('syncSingleLog should keep needsSync true when cloud update fails', () async {
      const String cloudId = '507f1f77bcf86cd799439019';
      cloudService.updateError = Exception('update gagal');
      await hiveContext.offlineLogsBox.put(
        cloudId,
        buildLog(id: cloudId, needsSync: true, title: 'Perlu update'),
      );

      await repository.syncSingleLog(cloudId);

      expect(hiveContext.offlineLogsBox.get(cloudId)?.needsSync, isTrue);
      expect(cloudService.updatedLogs, isEmpty);
    });

    test('deleteLog should queue delete when online cloud deletion fails', () async {
      const String cloudId = '507f1f77bcf86cd799439020';
      cloudService.deleteError = Exception('delete gagal');
      final log = buildLog(id: cloudId, needsSync: false);
      await hiveContext.offlineLogsBox.put(cloudId, log);

      await repository.deleteLog(log);

      expect(hiveContext.syncQueueBox.length, 1);
      expect(hiveContext.syncQueueBox.getAt(0)['id'], cloudId);
    });

    test('pullCloudLogs should do nothing when device is offline', () async {
      connectivityService.setResults(<ConnectivityResult>[ConnectivityResult.none]);
      cloudService.cloudLogs.add(
        buildLog(id: '507f1f77bcf86cd799439021', needsSync: false),
      );

      await repository.pullCloudLogs('TIM_ARIEF');

      expect(hiveContext.offlineLogsBox.isEmpty, isTrue);
    });
  });
}
