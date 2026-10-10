
import '../models/character.dart';
import '../services/storage_service.dart';

class QuestCompletionService {
  static Future<bool> completeTask({
    required String weeklyQuestId,
    required String taskId,
    required int expReward,
    required int currencyReward,
  }) async {
    final weeklyQuests =
        await StorageService.loadWeeklyQuests() ?? [];

    final weeklyIndex = weeklyQuests.indexWhere(
      (quest) => quest.id == weeklyQuestId,
    );

    if (weeklyIndex == -1) return false;

    final weeklyQuest = weeklyQuests[weeklyIndex];

    // Never reward the same task twice.
    if (weeklyQuest.completedTaskIds.contains(taskId)) {
      return false;
    }

    // Mark the task as permanently completed.
    weeklyQuest.completedTaskIds.add(taskId);

    weeklyQuest.isCompleted =
        weeklyQuest.dailyTaskTitles.isNotEmpty &&
        weeklyQuest.dailyTaskTitles.asMap().entries.every(
          (entry) => weeklyQuest.completedTaskIds.contains(
            '${weeklyQuest.id}_task_${entry.key}',
          ),
        );

    await StorageService.saveWeeklyQuests(weeklyQuests);

    // Update any saved Daily Quest entries for this task.
    final dailyQuests =
        await StorageService.loadDailyQuests() ?? [];

    var dailyQuestsChanged = false;

    for (final quest in dailyQuests) {
      if (quest.taskId == taskId && !quest.isCompleted) {
        quest.isCompleted = true;
        dailyQuestsChanged = true;
      }
    }

    if (dailyQuestsChanged) {
      await StorageService.saveDailyQuests(dailyQuests);
    }

    // Award rewards and apply level-ups.
    final character = await StorageService.loadCharacter() ??
        Character(
          name: 'Aria',
          rarity: '★★★',
          role: 'DPS',
        );

    var currency = await StorageService.loadCurrency();

    character.exp += expReward;
    currency += currencyReward;

    while (character.exp >= 100) {
      character.exp -= 100;
      character.level++;
      character.hp += 50;
      character.atk += 5;
      character.def += 3;
    }

    await StorageService.saveCharacter(character);
    await StorageService.saveCurrency(currency);

    return true;
  }
}
