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
}