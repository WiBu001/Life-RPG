import 'dart:math';

import '../models/daily_quest.dart';
import '../models/weekly_quest.dart';

class QuestScheduler {
  static const int maxQuestsPerDay = 5;

  static List<DailyQuest> generateDailyQuests({
    required List<WeeklyQuest> weeklyQuests,
    required List<DailyQuest> allDailyQuests,
    required DateTime today,
  }) {
    final random = Random();

    final date = DateTime(today.year, today.month, today.day);

    // Do not regenerate today's selection.
    final todaysQuests = allDailyQuests.where((quest) {
      final d = quest.displayDate;
      return d.year == date.year &&
          d.month == date.month &&
          d.day == date.day;
    }).toList();

    if (todaysQuests.isNotEmpty) {
      return todaysQuests;
    }

    // Find tasks that have not been completed and are within their
    // Weekly Quest's scheduling dates.
    final availableTasks = <Map<String, dynamic>>[];

    for (final weeklyQuest in weeklyQuests) {
      if (weeklyQuest.isCompleted) continue;

      final start = DateTime(
        weeklyQuest.weekStartDate.year,
        weeklyQuest.weekStartDate.month,
        weeklyQuest.weekStartDate.day,
      );

      final deadline = DateTime(
        weeklyQuest.deadline.year,
        weeklyQuest.deadline.month,
        weeklyQuest.deadline.day,
      );

      if (date.isBefore(start) || date.isAfter(deadline)) {
        continue;
      }

      for (var i = 0; i < weeklyQuest.dailyTaskTitles.length; i++) {
        final taskId = '${weeklyQuest.id}_task_$i';

        final alreadyCompleted =
            weeklyQuest.completedTaskIds.contains(taskId) ||
            allDailyQuests.any(
              (quest) =>
                  quest.taskId == taskId && quest.isCompleted,
            );

        if (alreadyCompleted) continue;

        availableTasks.add({
          'taskId': taskId,
          'weeklyQuestId': weeklyQuest.id,
          'title': weeklyQuest.dailyTaskTitles[i],
        });
      }
    }

    availableTasks.shuffle(random);

    final selectedTasks = availableTasks
        .take(maxQuestsPerDay)
        .toList();

    return selectedTasks.asMap().entries.map((entry) {
      final task = entry.value;

      return DailyQuest(
        id: '${task['taskId']}_${date.toIso8601String()}',
        taskId: task['taskId'] as String,
        weeklyQuestId: task['weeklyQuestId'] as String,
        title: task['title'] as String,
        displayDate: date,
        expReward: 100,
        currencyReward: 10,
      );
    }).toList();
  }
}