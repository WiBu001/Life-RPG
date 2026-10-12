import 'package:flutter/foundation.dart';

import '../models/weekly_quest.dart';
import '../services/storage_service.dart';
import '../services/quest_completion_service.dart';

class WeeklyQuestDetailController extends ChangeNotifier {
  WeeklyQuestDetailController({
    required this._weeklyQuest,
  });

  WeeklyQuest _weeklyQuest;

  WeeklyQuest get weeklyQuest => _weeklyQuest;

  bool isLoading = false;
  final Set<String> _processingTaskIds = {};

  String taskIdFor(int index) => '${_weeklyQuest.id}_task_$index';

  bool isTaskCompleted(int index) {
    return _weeklyQuest.completedTaskIds.contains(
      taskIdFor(index),
    );
  }

  bool isTaskProcessing(int index) {
    return _processingTaskIds.contains(taskIdFor(index));
  }

  int get completedCount {
    return _weeklyQuest.dailyTaskTitles
        .asMap()
        .keys
        .where(isTaskCompleted)
        .length;
  }

  double get progress {
    final total = _weeklyQuest.dailyTaskTitles.length;
    return total == 0 ? 0 : completedCount / total;
  }

  Future<void> completeTask(int index) async {
    if (index < 0 ||
        index >= _weeklyQuest.dailyTaskTitles.length) {
      return;
    }

    final taskId = taskIdFor(index);

    if (isTaskCompleted(index) ||
        _processingTaskIds.contains(taskId)) {
      return;
    }

    _processingTaskIds.add(taskId);
    notifyListeners();

    try {
      final success = await QuestCompletionService.completeTask(
        weeklyQuestId: _weeklyQuest.id,
        taskId: taskId,
        expReward: 100,
        currencyReward: 10,
      );

      if (success) {
        await _reloadWeeklyQuest();
      }
    } finally {
      _processingTaskIds.remove(taskId);
      notifyListeners();
    }
  }

  Future<void> _reloadWeeklyQuest() async {
    final quests = await StorageService.loadWeeklyQuests() ?? [];

    for (final quest in quests) {
      if (quest.id == _weeklyQuest.id) {
        _weeklyQuest = quest;
        return;
      }
    }
  }
}