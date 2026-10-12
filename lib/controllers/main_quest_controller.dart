import 'package:flutter/foundation.dart';

import '../models/main_quest.dart';
import '../services/storage_service.dart';

class MainQuestController extends ChangeNotifier {
  List<MainQuest> mainQuests = [];
  bool isLoading = true;
  String? errorMessage;

  Future<void> initialize() async {
    try {
      final savedQuests = await StorageService.loadMainQuests();
      mainQuests = savedQuests ?? [];
    } catch (error) {
      errorMessage = 'Failed to load Main Quests: $error';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createQuest({
    required String title,
    required String description,
  }) async {
    final trimmedTitle = title.trim();

    if (trimmedTitle.isEmpty) return false;

    final quest = MainQuest(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: trimmedTitle,
      description: description.trim(),
      createdAt: DateTime.now(),
    );

    try {
      final updatedQuests = [...mainQuests, quest];

      await StorageService.saveMainQuests(updatedQuests);

      mainQuests = updatedQuests;
      errorMessage = null;
      notifyListeners();

      return true;
    } catch (error) {
      errorMessage = 'Failed to save Main Quest: $error';
      notifyListeners();
      return false;
    }
  }
}