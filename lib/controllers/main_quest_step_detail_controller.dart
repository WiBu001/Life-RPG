import 'package:flutter/foundation.dart';

import '../models/main_quest_step.dart';
import '../models/weekly_quest.dart';
import '../services/storage_service.dart';

class MainQuestStepDetailController extends ChangeNotifier {
  MainQuestStepDetailController({
    required this.step,
  });

  final MainQuestStep step;

  List<WeeklyQuest> weeklyQuests = [];
  bool isLoading = true;
  String? errorMessage;

  Future<void> initialize() async {
    try {
      final savedQuests =
          await StorageService.loadWeeklyQuests() ?? [];

      weeklyQuests = savedQuests
          .where((quest) => quest.mainQuestStepId == step.id)
          .toList();
    } catch (error) {
      errorMessage = 'Failed to load Weekly Quests: $error';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createWeeklyQuest({
    required String title,
    required String description,
    required DateTime startDate,
    required DateTime deadline,
    required List<String> dailyTaskTitles,
  }) async {
    final trimmedTitle = title.trim();
    final tasks = dailyTaskTitles
        .map((task) => task.trim())
        .where((task) => task.isNotEmpty)
        .toList();

    if (trimmedTitle.isEmpty ||
        tasks.isEmpty ||
        deadline.isBefore(startDate)) {
      return false;
    }

    final quest = WeeklyQuest(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      mainQuestStepId: step.id,
      title: trimmedTitle,
      description: description.trim(),
      weekStartDate: startDate,
      deadline: deadline,
      expReward: 500,
      currencyReward: 50,
      dailyTaskTitles: tasks,
    );

    try {
      final allQuests =
          await StorageService.loadWeeklyQuests() ?? [];

      allQuests.add(quest);

      await StorageService.saveWeeklyQuests(allQuests);

      weeklyQuests = [
        ...weeklyQuests,
        quest,
      ];

      errorMessage = null;
      notifyListeners();

      return true;
    } catch (error) {
      errorMessage = 'Failed to save Weekly Quest: $error';
      notifyListeners();
      return false;
    }
  }
}