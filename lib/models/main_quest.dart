
class MainQuest {
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;

  bool isCompleted;

  MainQuest({
    required this.id,
    required this.title,
    this.description = '',
    required this.createdAt,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  factory MainQuest.fromJson(Map<String, dynamic> json) {
    return MainQuest(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}
