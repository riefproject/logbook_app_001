import 'package:connectivity_plus/connectivity_plus.dart';

import 'models/log_model.dart';

abstract class CloudLogService {
  Future<List<LogModel>> getLogs(String teamId);
  Future<String?> insertLog(LogModel log);
  Future<void> updateLog(LogModel log);
  Future<void> deleteLog(String id, {String? teamId});
}

abstract class ConnectivityService {
  Stream<List<ConnectivityResult>> get onConnectivityChanged;
  Future<List<ConnectivityResult>> checkConnectivity();
}

class ConnectivityAdapter implements ConnectivityService {
  ConnectivityAdapter({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;

  @override
  Future<List<ConnectivityResult>> checkConnectivity() =>
      _connectivity.checkConnectivity();
}
