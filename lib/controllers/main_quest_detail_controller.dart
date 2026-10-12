import 'package:flutter/foundation.dart';

import '../models/main_quest.dart';
import '../models/main_quest_step.dart';
import '../services/storage_service.dart';

class MainQuestDetailController extends ChangeNotifier {
  MainQuestDetailController({
    required this.mainQuest,
  });

  final MainQuest mainQuest;

  List<MainQuestStep> steps = [];
  bool isLoading = true;
  String? errorMessage;

  Future<void> initialize() async {
    try {
      final savedSteps =
          await StorageService.loadMainQuestSteps() ?? [];

      steps = savedSteps
          .where((step) => step.mainQuestId == mainQuest.id)
          .toList();
    } catch (error) {
      errorMessage = 'Failed to load milestones: $error';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createStep({
    required String title,
    required String description,
  }) async {
    final trimmedTitle = title.trim();

    if (trimmedTitle.isEmpty) return false;

    final step = MainQuestStep(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      mainQuestId: mainQuest.id,
      title: trimmedTitle,
      description: description.trim(),
    );

    try {
      final allSteps =
          await StorageService.loadMainQuestSteps() ?? [];

      allSteps.add(step);

      await StorageService.saveMainQuestSteps(allSteps);

      steps = [
        ...steps,
        step,
      ];

      errorMessage = null;
      notifyListeners();

      return true;
    } catch (error) {
      errorMessage = 'Failed to save milestone: $error';
      notifyListeners();
      return false;
    }
  }
}