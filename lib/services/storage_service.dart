import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/character.dart';
import '../models/quest.dart';
import '../models/main_quest.dart';
import '../models/main_quest_step.dart';
import '../models/weekly_quest.dart';
import '../models/daily_quest.dart';
import '../models/calendar_event.dart';

class StorageService {
  static const String characterKey = 'character';

  static Future<void> saveCharacter(Character character) async {
    final prefs = await SharedPreferences.getInstance();

    final jsonString = jsonEncode(character.toJson());

    await prefs.setString(characterKey, jsonString);
  }

  static Future<Character?> loadCharacter() async {
    final prefs = await SharedPreferences.getInstance();

    final jsonString = prefs.getString(characterKey);

    if (jsonString == null) {
      return null;
    }

    final jsonData = jsonDecode(jsonString);

    return Character.fromJson(jsonData);
  }

  static const String questsKey = 'quests';

  static Future<void> saveQuests(List<Quest> quests) async {
    final prefs = await SharedPreferences.getInstance();

    final jsonList = quests.map((quest) => quest.toJson()).toList();

    await prefs.setString(questsKey, jsonEncode(jsonList));
  }

  static Future<List<Quest>?> loadQuests() async {
    final prefs = await SharedPreferences.getInstance();

    final jsonString = prefs.getString(questsKey);

    if (jsonString == null) {
      return null;
    }

    final List<dynamic> jsonList = jsonDecode(jsonString);

    return jsonList
        .map((json) => Quest.fromJson(
              Map<String, dynamic>.from(json as Map),
            ))
        .toList();
  }

  static const String currencyKey = 'currency';

  static Future<void> saveCurrency(int currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(currencyKey, currency);
  }

  static Future<int> loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(currencyKey) ?? 0;
  }

  static const String mainQuestsKey = 'mainQuests';

  static Future<void> saveMainQuests(
    List<MainQuest> quests,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final jsonList = quests.map((quest) => quest.toJson()).toList();

    await prefs.setString(mainQuestsKey, jsonEncode(jsonList));
  }

  static Future<List<MainQuest>?> loadMainQuests() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(mainQuestsKey);

    if (jsonString == null) return null;

    final List<dynamic> jsonList = jsonDecode(jsonString);

    return jsonList
        .map((json) => MainQuest.fromJson(
              Map<String, dynamic>.from(json as Map),
            ))
        .toList();
  }

  static const String mainQuestStepsKey = 'mainQuestSteps';

  static Future<void> saveMainQuestSteps(
    List<MainQuestStep> steps,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final jsonList = steps.map((step) => step.toJson()).toList();

    await prefs.setString(mainQuestStepsKey, jsonEncode(jsonList));
  }

  static Future<List<MainQuestStep>?> loadMainQuestSteps() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(mainQuestStepsKey);

    if (jsonString == null) return null;

    final List<dynamic> jsonList = jsonDecode(jsonString);

    return jsonList
        .map((json) => MainQuestStep.fromJson(
              Map<String, dynamic>.from(json as Map),
            ))
        .toList();
  }

  static const String weeklyQuestsKey = 'weeklyQuests';

  static Future<void> saveWeeklyQuests(
    List<WeeklyQuest> quests,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final jsonList = quests.map((quest) => quest.toJson()).toList();

    await prefs.setString(weeklyQuestsKey, jsonEncode(jsonList));
  }

  static Future<List<WeeklyQuest>?> loadWeeklyQuests() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(weeklyQuestsKey);

    if (jsonString == null) return null;

    final List<dynamic> jsonList = jsonDecode(jsonString);

    return jsonList
        .map((json) => WeeklyQuest.fromJson(
              Map<String, dynamic>.from(json as Map),
            ))
        .toList();
  }

  static const String dailyQuestsKey = 'dailyQuests';

  static Future<void> saveDailyQuests(
    List<DailyQuest> quests,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final jsonList = quests.map((quest) => quest.toJson()).toList();

    await prefs.setString(dailyQuestsKey, jsonEncode(jsonList));
  }

  static Future<List<DailyQuest>?> loadDailyQuests() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(dailyQuestsKey);

    if (jsonString == null) return null;

    final List<dynamic> jsonList = jsonDecode(jsonString);

    return jsonList
        .map((json) => DailyQuest.fromJson(
              Map<String, dynamic>.from(json as Map),
            ))
        .toList();
  }

  static Future<void> addDailyQuests(
    List<DailyQuest> newQuests,
  ) async {
    final existingQuests = await loadDailyQuests() ?? [];

    final existingIds = existingQuests
        .map((quest) => quest.id)
        .toSet();

    for (final quest in newQuests) {
      if (!existingIds.contains(quest.id)) {
        existingQuests.add(quest);
        existingIds.add(quest.id);
      }
    }

    await saveDailyQuests(existingQuests);
  }

  static const String calendarEventsKey = 'calendarEvents';

  static Future<void> saveCalendarEvents(
    List<CalendarEvent> events,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final encodedEvents = jsonEncode(
      events.map((event) => event.toJson()).toList(),
    );

    await prefs.setString(calendarEventsKey, encodedEvents);
  }

  static Future<List<CalendarEvent>?> loadCalendarEvents() async {
    final prefs = await SharedPreferences.getInstance();

    final savedEvents = prefs.getString(calendarEventsKey);

    if (savedEvents == null) {
      return null;
    }

    final List<dynamic> decodedEvents = jsonDecode(savedEvents);

    return decodedEvents
        .map(
          (event) => CalendarEvent.fromJson(
            Map<String, dynamic>.from(event),
          ),
        )
        .toList();
  }
}