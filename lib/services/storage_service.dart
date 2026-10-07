import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/character.dart';

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
}