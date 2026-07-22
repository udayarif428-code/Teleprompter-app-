class ScriptModel {
  final int? id;
  final String title;
  final String content;
  final String language; // 'bn' or 'en'
  final DateTime updatedAt;

  ScriptModel({
    this.id,
    required this.title,
    required this.content,
    required this.language,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'language': language,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ScriptModel.fromMap(Map<String, dynamic> map) {
    return ScriptModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      content: map['content'] as String,
      language: map['language'] as String,
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}
