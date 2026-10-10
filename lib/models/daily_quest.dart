class DailyQuest {
  final String id;
  final String taskId;
  final String weeklyQuestId;
  final String title;
  final DateTime displayDate;

  final int expReward;
  final int currencyReward;

  bool isCompleted;

  DailyQuest({
    required this.id,
    required this.taskId,
    required this.weeklyQuestId,
    required this.title,
    required this.displayDate,
    required this.expReward,
    required this.currencyReward,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskId': taskId,
      'weeklyQuestId': weeklyQuestId,
      'title': title,
      'displayDate': displayDate.toIso8601String(),
      'expReward': expReward,
      'currencyReward': currencyReward,
      'isCompleted': isCompleted,
    };
  }

  factory DailyQuest.fromJson(Map<String, dynamic> json) {
    return DailyQuest(
      id: json['id'] as String,
      taskId: json['taskId'] as String,
      weeklyQuestId: json['weeklyQuestId'] as String,
      title: json['title'] as String,
      displayDate: DateTime.parse(
        json['displayDate'] as String,
      ),
      expReward: json['expReward'] as int,
      currencyReward: json['currencyReward'] as int,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}