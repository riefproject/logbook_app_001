import 'package:mongo_dart/mongo_dart.dart';

class LogModel {
  const LogModel({
    this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.category,
  });

  factory LogModel.fromMap(Map<String, dynamic> map) {
    final dynamic rawId = map['_id'];

    return LogModel(
      id: rawId is ObjectId ? rawId : null,
      title: (map['title'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      timestamp: (map['timestamp'] ?? DateTime.now().toIso8601String())
          .toString(),
      category: (map['category'] ?? 'Pribadi').toString(),
    );
  }

  final ObjectId? id;
  final String title;
  final String description;
  final String timestamp;
  final String category;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      '_id': id ?? ObjectId(),
      'title': title,
      'description': description,
      'timestamp': timestamp,
      'category': category,
    };
  }
}
