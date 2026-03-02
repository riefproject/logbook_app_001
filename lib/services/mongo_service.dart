import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mongo_dart/mongo_dart.dart';

import '../features/logbook/models/log_model.dart';

class MongoService {
  MongoService._internal();

  static final MongoService _instance = MongoService._internal();

  factory MongoService() => _instance;

  Db? _db;
  DbCollection? _collection;

  Future<void> _ensureConnected() async {
    if (_db != null && _db!.isConnected && _collection != null) {
      return;
    }

    await connect();
  }

  Future<void> connect() async {
    if (_db != null && _db!.isConnected) {
      return;
    }

    final String? uri = dotenv.env['MONGODB_URI'];
    if (uri == null || uri.trim().isEmpty) {
      throw Exception('MONGODB_URI is not set in .env');
    }

    final Db db = Db(uri);
    await db.open();

    _db = db;
    _collection = db.collection('logs');
  }

  Future<List<LogModel>> getLogs() async {
    await _ensureConnected();

    final List<Map<String, dynamic>> documents = (await _collection!
            .find()
            .toList())
        .map((dynamic document) => Map<String, dynamic>.from(document as Map))
        .toList();

    final List<LogModel> logs = documents
        .map((Map<String, dynamic> map) => LogModel.fromMap(map))
        .toList();

    logs.sort((LogModel a, LogModel b) {
      final DateTime aTime =
          DateTime.tryParse(a.timestamp) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final DateTime bTime =
          DateTime.tryParse(b.timestamp) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });

    return logs;
  }

  Future<void> insertLog(LogModel log) async {
    await _ensureConnected();
    await _collection!.insertOne(log.toMap());
  }

  Future<void> close() async {
    if (_db == null) {
      return;
    }

    if (_db!.isConnected) {
      await _db!.close();
    }

    _db = null;
    _collection = null;
  }
}
