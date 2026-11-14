class ContentItem {
  const ContentItem({
    required this.id,
    required this.title,
    required this.task,
    required this.content,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String task;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ContentItem copyWith({String? title, String? content, DateTime? updatedAt}) =>
      ContentItem(
        id: id,
        title: title ?? this.title,
        task: task,
        content: content ?? this.content,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'task': task,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  factory ContentItem.fromJson(Map<String, dynamic> json) => ContentItem(
    id: json['id'] as String,
    title: json['title'] as String,
    task: json['task'] as String,
    content: json['content'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: json['updatedAt'] == null
        ? null
        : DateTime.parse(json['updatedAt'] as String),
  );
}
