import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mongo_dart/mongo_dart.dart';

import '../features/logbook/models/log_model.dart';
import '../helpers/log_helper.dart';

class MongoService {
  MongoService._internal();

  static final MongoService _instance = MongoService._internal();
  static const String _source = 'mongo_service.dart';

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
      await LogHelper.writeLog(
        'connect() skipped because database is already connected',
        source: _source,
        level: 3,
      );
      return;
    }

    final String? uri = dotenv.env['MONGODB_URI'];
    if (uri == null || uri.trim().isEmpty) {
      await LogHelper.writeLog(
        'connect() failed because MONGODB_URI is missing',
        source: _source,
        level: 1,
      );
      throw Exception('MONGODB_URI is not set in .env');
    }

    final String maskedUri = uri.contains('@') 
        ? '${uri.substring(0, uri.indexOf("@") + 1)}***' 
        : uri;

    await LogHelper.writeLog(
      'Opening MongoDB connection to: $maskedUri',
      source: _source,
      level: 2,
    );

    try {
      final Db db = Db(uri);
      await db.open().timeout(const Duration(seconds: 15), onTimeout: () {
        throw TimeoutException('MongoDB connection timed out');
      });

      if (!db.isConnected) {
        throw Exception('Database opened but not connected');
      }

      _db = db;
      _collection = db.collection('logs');

      await LogHelper.writeLog(
        'MongoDB connection established and logs collection selected',
        source: _source,
        level: 2,
      );
    } catch (error) {
      await LogHelper.writeLog(
        'connect() failed: $error',
        source: _source,
        level: 1,
      );
      rethrow;
    }
  }

  Future<List<LogModel>> getLogs(String teamId) async {
    await LogHelper.writeLog(
      'Fetching logs from MongoDB for teamId "$teamId"',
      source: _source,
      level: 3,
    );

    try {
      await _ensureConnected();
      final SelectorBuilder selector = where.eq('teamId', teamId);

      final List<Map<String, dynamic>> documents =
          (await _collection!.find(selector).toList())
              .map(
                (dynamic document) =>
                    Map<String, dynamic>.from(document as Map),
              )
              .toList();

      final List<LogModel> logs = documents
          .map((Map<String, dynamic> map) => LogModel.fromMap(map))
          .toList();

      logs.sort((LogModel a, LogModel b) {
        final DateTime aTime =
            DateTime.tryParse(a.timestamp) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final DateTime bTime =
            DateTime.tryParse(b.timestamp) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

      await LogHelper.writeLog(
        'Fetched ${logs.length} logs from MongoDB for teamId "$teamId"',
        source: _source,
        level: 2,
      );

      return logs;
    } catch (error) {
      await LogHelper.writeLog(
        'getLogs() failed: $error',
        source: _source,
        level: 1,
      );
      rethrow;
    }
  }

  Future<String?> insertLog(LogModel log) async {
    await LogHelper.writeLog(
      'Inserting log with title "${log.title}"',
      source: _source,
      level: 3,
    );

    try {
      await _ensureConnected();
      final WriteResult result = await _collection!.insertOne(log.toMap());
      final dynamic insertedId = result.id;
      final String? normalizedId = insertedId is ObjectId
          ? insertedId.oid
          : insertedId?.toString();

      await LogHelper.writeLog(
        'Log inserted successfully with id "$normalizedId"',
        source: _source,
        level: 2,
      );
      return normalizedId;
    } catch (error) {
      await LogHelper.writeLog(
        'insertLog() failed: $error',
        source: _source,
        level: 1,
      );
      rethrow;
    }
  }

  Future<void> updateLog(LogModel log) async {
    await LogHelper.writeLog(
      'Updating log with id "${log.id}"',
      source: _source,
      level: 3,
    );

    if (log.id == null || log.id!.trim().isEmpty) {
      throw ArgumentError('Cannot update log without a cloud id');
    }

    try {
      await _ensureConnected();
      final ObjectId cloudId = ObjectId.fromHexString(log.id!.trim());
      final SelectorBuilder selector = where.eq('_id', cloudId);

      await _collection!.replaceOne(selector, log.toMap(), upsert: true);

      await LogHelper.writeLog(
        'Log updated successfully',
        source: _source,
        level: 2,
      );
    } catch (error) {
      await LogHelper.writeLog(
        'updateLog() failed: $error',
        source: _source,
        level: 1,
      );
      rethrow;
    }
  }

  Future<void> deleteLog(String id, {String? teamId}) async {
    await LogHelper.writeLog(
      'Deleting log with id "$id"',
      source: _source,
      level: 3,
    );

    try {
      await _ensureConnected();
      final ObjectId cloudId = ObjectId.fromHexString(id.trim());
      SelectorBuilder selector = where.eq('_id', cloudId);
      if (teamId != null && teamId.trim().isNotEmpty) {
        selector = selector.eq('teamId', teamId.trim());
      }

      await _collection!.deleteOne(selector);
      await LogHelper.writeLog(
        'Log deleted successfully',
        source: _source,
        level: 2,
      );
    } catch (error) {
      await LogHelper.writeLog(
        'deleteLog() failed: $error',
        source: _source,
        level: 1,
      );
      rethrow;
    }
  }

  Future<void> close() async {
    if (_db == null) {
      await LogHelper.writeLog(
        'close() skipped because no database instance exists',
        source: _source,
        level: 3,
      );
      return;
    }

    try {
      if (_db!.isConnected) {
        await _db!.close();
        await LogHelper.writeLog(
          'MongoDB connection closed',
          source: _source,
          level: 2,
        );
      } else {
        await LogHelper.writeLog(
          'close() skipped because database was already disconnected',
          source: _source,
          level: 3,
        );
      }
    } catch (error) {
      await LogHelper.writeLog(
        'close() failed: $error',
        source: _source,
        level: 1,
      );
      rethrow;
    } finally {
      _db = null;
      _collection = null;
    }
  }
}
