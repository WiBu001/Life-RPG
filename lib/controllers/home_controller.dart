import 'package:flutter/foundation.dart';

import '../models/character.dart';
import '../models/daily_quest.dart';
import '../services/storage_service.dart';
import '../services/quest_scheduler.dart';
import '../services/quest_completion_service.dart';

class HomeController extends ChangeNotifier {
  Character character = Character(
    name: 'Aria',
    rarity: '★★★',
    role: 'DPS',
  );

  int currency = 0;
  List<DailyQuest> quests = [];

  bool isLoading = true;
  String? errorMessage;

  Future<void> initialize() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await loadCharacter();
      await loadCurrency();
      await loadQuests();
    } catch (error) {
      errorMessage = 'Failed to load home data: $error';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCharacter() async {
    final savedCharacter = await StorageService.loadCharacter();

    if (savedCharacter != null) {
      character = savedCharacter;
    }
  }

  Future<void> loadCurrency() async {
    currency = await StorageService.loadCurrency();
  }

  Future<void> loadQuests() async {
    final weeklyQuests =
        await StorageService.loadWeeklyQuests() ?? [];

    final allDailyQuests =
        await StorageService.loadDailyQuests() ?? [];

    final todaysQuests = QuestScheduler.generateDailyQuests(
      weeklyQuests: weeklyQuests,
      allDailyQuests: allDailyQuests,
      today: DateTime.now(),
    );

    // Preserve historical daily quests.
    await StorageService.addDailyQuests(todaysQuests);

    quests = todaysQuests;
  }

  Future<void> completeQuest(DailyQuest quest) async {
    if (quest.isCompleted) return;

    // Prevent repeated taps while completion is processing.
    quest.isCompleted = true;
    errorMessage = null;
    notifyListeners();

    try {
      final success = await QuestCompletionService.completeTask(
        weeklyQuestId: quest.weeklyQuestId,
        taskId: quest.taskId,
        expReward: quest.expReward,
        currencyReward: quest.currencyReward,
      );

      if (!success) {
        errorMessage =
            'This task may already be completed. '
            'Your quest data has been refreshed.';
      }

      // Reload persisted state whether completion succeeded or not.
      await loadCharacter();
      await loadCurrency();
      await loadQuests();
    } catch (error) {
      errorMessage = 'Failed to complete quest: $error';

      // Restore the quest state from storage after an error.
      try {
        await loadQuests();
        await loadCharacter();
        await loadCurrency();
      } catch (_) {
        // Keep the original error message.
      }
    } finally {
      notifyListeners();
    }
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}