import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mongo_dart/mongo_dart.dart';

class MongoService {
  MongoService._internal();

  static final MongoService _instance = MongoService._internal();

  factory MongoService() => _instance;

  Db? _db;
  DbCollection? _collection;

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
