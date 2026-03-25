import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';

import '../features/logbook/log_repository.dart';
import '../helpers/log_helper.dart';

class OfflineSyncService with WidgetsBindingObserver {
  OfflineSyncService._internal();

  static final OfflineSyncService instance = OfflineSyncService._internal();
  static const String _source = 'offline_sync_service.dart';
  static const Duration _pullInterval = Duration(seconds: 30);

  final ValueNotifier<bool> isOnline = ValueNotifier<bool>(false);
  final ValueNotifier<int> syncEpoch = ValueNotifier<int>(0);

  LogRepository? _repository;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _pullTimer;

  bool _started = false;
  bool _maintenanceInProgress = false;
  bool _appInForeground = true;

  void start() {
    if (_started) return;
    _started = true;

    WidgetsBinding.instance.addObserver(this);
    _repository = LogRepository();
    unawaited(_initSafely());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appInForeground = state == AppLifecycleState.resumed;
    if (_appInForeground && isOnline.value) {
      _ensurePullTimer();
      unawaited(_runMaintenance(pushPending: false, pullReconcile: true));
    } else {
      _stopPullTimer();
    }
  }

  Future<void> _initSafely() async {
    try {
      await LogHelper.writeLog(
        'OfflineSyncService started',
        source: _source,
        level: 2,
      );

      final List<ConnectivityResult> results = await _repository!
          .checkConnectivity();
      _handleConnectivity(results);

      _connectivitySub = _repository!.onConnectivityChanged.listen((results) {
        _handleConnectivity(results);
      });
    } catch (error) {
      await LogHelper.writeLog(
        'OfflineSyncService init failed: $error',
        source: _source,
        level: 1,
      );
    }
  }

  void _handleConnectivity(List<ConnectivityResult> results) {
    final bool online = !results.contains(ConnectivityResult.none);
    final bool wasOnline = isOnline.value;

    if (wasOnline != online) {
      isOnline.value = online;
    }

    if (online && _appInForeground) {
      _ensurePullTimer();
    } else {
      _stopPullTimer();
    }

    // Saat offline -> online: push pending dulu, lalu reconcile pull (biar delete di cloud ikut tercermin).
    if (!wasOnline && online) {
      unawaited(_runMaintenance(pushPending: true, pullReconcile: true));
    }
  }

  void _ensurePullTimer() {
    _pullTimer ??= Timer.periodic(_pullInterval, (_) {
      unawaited(_runMaintenance(pushPending: false, pullReconcile: true));
    });
  }

  void _stopPullTimer() {
    _pullTimer?.cancel();
    _pullTimer = null;
  }

  Future<void> _runMaintenance({
    required bool pushPending,
    required bool pullReconcile,
  }) async {
    if (_maintenanceInProgress) return;
    _maintenanceInProgress = true;

    try {
      if (pushPending) {
        await LogHelper.writeLog(
          'Memulai sinkronisasi offline...',
          source: _source,
          level: 2,
        );
        await _repository!.syncPendingOperations();
      }

      if (pullReconcile) {
        await _repository!.reconcileCloudForAllLocalTeams();
      }

      if (pushPending || pullReconcile) {
        syncEpoch.value = syncEpoch.value + 1;
      }
    } catch (error) {
      await LogHelper.writeLog(
        'Maintenance global gagal: $error',
        source: _source,
        level: 1,
      );
    } finally {
      _maintenanceInProgress = false;
    }
  }

  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    await _connectivitySub?.cancel();
    _connectivitySub = null;
    _stopPullTimer();
    _repository = null;
    _started = false;
  }
}
