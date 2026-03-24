import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../features/logbook/log_repository.dart';
import '../helpers/log_helper.dart';

class OfflineSyncService {
  OfflineSyncService._internal();

  static final OfflineSyncService instance = OfflineSyncService._internal();
  static const String _source = 'offline_sync_service.dart';

  final ValueNotifier<bool> isOnline = ValueNotifier<bool>(false);
  final ValueNotifier<int> syncEpoch = ValueNotifier<int>(0);

  LogRepository? _repository;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  bool _started = false;
  bool _syncInProgress = false;

  void start() {
    if (_started) return;
    _started = true;

    _repository = LogRepository();
    unawaited(_initSafely());
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

    if (!wasOnline && online) {
      unawaited(_syncAllPending());
    }
  }

  Future<void> _syncAllPending() async {
    if (_syncInProgress) return;
    _syncInProgress = true;

    try {
      await LogHelper.writeLog(
        'Memulai sinkronisasi offline...',
        source: _source,
        level: 2,
      );

      await _repository!.syncPendingOperations();
      syncEpoch.value = syncEpoch.value + 1;
    } catch (error) {
      await LogHelper.writeLog(
        'Sync global gagal: $error',
        source: _source,
        level: 1,
      );
    } finally {
      _syncInProgress = false;
    }
  }

  Future<void> dispose() async {
    await _connectivitySub?.cancel();
    _connectivitySub = null;
    _repository = null;
    _started = false;
  }
}
