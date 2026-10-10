
class WeeklyQuest {
  final String id;
  final String mainQuestStepId;
  final String title;
  final String description;
  final DateTime weekStartDate;
  final DateTime deadline;

  final int expReward;
  final int currencyReward;

  final List<String> dailyTaskTitles;
  final List<String> completedTaskIds;

  bool isCompleted;

  WeeklyQuest({
    required this.id,
    required this.mainQuestStepId,
    required this.title,
    this.description = '',
    required this.weekStartDate,
    required this.deadline,
    required this.expReward,
    required this.currencyReward,
    required this.dailyTaskTitles,
    List<String>? completedTaskIds,
    this.isCompleted = false,
  }): completedTaskIds = completedTaskIds ?? [];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mainQuestStepId': mainQuestStepId,
      'title': title,
      'description': description,
      'weekStartDate': weekStartDate.toIso8601String(),
      'deadline': deadline.toIso8601String(),
      'expReward': expReward,
      'currencyReward': currencyReward,
      'dailyTaskTitles': dailyTaskTitles,
      'completedTaskIds': completedTaskIds,
      'isCompleted': isCompleted,
    };
  }

  factory WeeklyQuest.fromJson(Map<String, dynamic> json) {
    return WeeklyQuest(
      id: json['id'] as String,
      mainQuestStepId: json['mainQuestStepId'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      weekStartDate: DateTime.parse(
        json['weekStartDate'] as String,
      ),
      deadline: DateTime.parse(
        json['deadline'] as String,
      ),
      expReward: json['expReward'] as int,
      currencyReward: json['currencyReward'] as int,
      dailyTaskTitles: List<String>.from(
        json['dailyTaskTitles'] as List,
      ),
      completedTaskIds: List<String>.from(
        json['completedTaskIds'] as List? ?? [],
      ),
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}
