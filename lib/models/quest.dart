class Quest {
  final String title;
  final int expReward;
  final int currencyReward;

  bool isCompleted;

  Quest({
    required this.title,
    required this.expReward,
    required this.currencyReward,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'expReward': expReward,
      'currencyReward': currencyReward,
      'isCompleted': isCompleted,
    };
  }

  factory Quest.fromJson(Map<String, dynamic> json) {
    return Quest(
      title: json['title'] as String,
      expReward: json['expReward'] as int,
      currencyReward: json['currencyReward'] as int,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}