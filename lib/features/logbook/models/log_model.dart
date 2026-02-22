class LogModel {
  const LogModel({
    required this.title,
    required this.description,
    required this.timestamp,
  });

  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(
      title: (map['title'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      timestamp: (map['timestamp'] ?? DateTime.now().toIso8601String())
          .toString(),
    );
  }

  final String title;
  final String description;
  final String timestamp;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'title': title,
      'description': description,
      'timestamp': timestamp,
    };
  }
}
