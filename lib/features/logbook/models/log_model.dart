import 'package:hive/hive.dart';
import 'package:mongo_dart/mongo_dart.dart';

part 'log_model.g.dart';

@HiveType(typeId: 0)
class LogModel {
  const LogModel({
    this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.category,
    this.authorId = 'unknown',
    this.teamId = 'unknown',
  });

  factory LogModel.fromMap(Map<String, dynamic> map) {
    final dynamic rawId = map['_id'];

    return LogModel(
      id: _stringifyId(rawId),
      title: (map['title'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      timestamp: (map['timestamp'] ?? DateTime.now().toIso8601String())
          .toString(),
      category: (map['category'] ?? 'Pribadi').toString(),
      authorId: (map['authorId'] ?? 'unknown').toString(),
      teamId: (map['teamId'] ?? 'unknown').toString(),
    );
  }

  static String? _stringifyId(dynamic rawId) {
    if (rawId is ObjectId) {
      return rawId.oid;
    }
    if (rawId is Map && rawId[r'$oid'] != null) {
      return rawId[r'$oid'].toString();
    }
    if (rawId == null) {
      return null;
    }
    return rawId.toString();
  }

  static dynamic _toMongoId(String? rawId) {
    if (rawId == null || rawId.trim().isEmpty) {
      return ObjectId();
    }
    final String normalized = rawId.trim();
    try {
      return ObjectId.fromHexString(normalized);
    } on FormatException {
      return normalized;
    }
  }

  @HiveField(0)
  final String? id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String description;
  @HiveField(3)
  final String timestamp;
  @HiveField(4)
  final String category;
  @HiveField(5)
  final String authorId;
  @HiveField(6)
  final String teamId;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      '_id': _toMongoId(id),
      'title': title,
      'description': description,
      'timestamp': timestamp,
      'category': category,
      'authorId': authorId,
      'teamId': teamId,
    };
  }
}
