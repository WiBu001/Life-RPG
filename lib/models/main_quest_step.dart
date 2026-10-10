
class MainQuestStep {
  final String id;
  final String mainQuestId;
  final String title;
  final String description;

  bool isCompleted;

  MainQuestStep({
    required this.id,
    required this.mainQuestId,
    required this.title,
    this.description = '',
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mainQuestId': mainQuestId,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
    };
  }

  factory MainQuestStep.fromJson(Map<String, dynamic> json) {
    return MainQuestStep(
      id: json['id'] as String,
      mainQuestId: json['mainQuestId'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}
