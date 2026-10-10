
import 'package:flutter/material.dart';

import '../models/character.dart';
import '../models/daily_quest.dart';
import '../services/storage_service.dart';
import '../services/quest_scheduler.dart';
import '../services/quest_completion_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Character character = Character(
    name: 'Aria',
    rarity: '★★★',
    role: 'DPS',
  );

  int currency = 0;
  List<DailyQuest> quests = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    initializeHome();
  }

  Future<void> initializeHome() async {
    await loadCharacter();
    await loadCurrency();
    await loadQuests();
  }

  Future<void> loadCharacter() async {
    final savedCharacter = await StorageService.loadCharacter();

    if (!mounted || savedCharacter == null) return;

    setState(() {
      character = savedCharacter;
    });
  }

  Future<void> loadCurrency() async {
    final savedCurrency = await StorageService.loadCurrency();

    if (!mounted) return;

    setState(() {
      currency = savedCurrency;
    });
  }

  Future<void> loadQuests() async {
    try {
      final weeklyQuests =
          await StorageService.loadWeeklyQuests() ?? [];

      final allDailyQuests =
          await StorageService.loadDailyQuests() ?? [];

      final todaysQuests = QuestScheduler.generateDailyQuests(
        weeklyQuests: weeklyQuests,
        allDailyQuests: allDailyQuests,
        today: DateTime.now(),
      );

      // Save today's selection without replacing quest history.
      await StorageService.addDailyQuests(todaysQuests);

      if (!mounted) return;

      setState(() {
        quests = todaysQuests;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load quests: $error'),
        ),
      );
    }
  }

Future<void> completeQuest(DailyQuest quest) async {
  if (quest.isCompleted) return;

  // Disable the button immediately to prevent double taps.
  setState(() {
    quest.isCompleted = true;
  });

  final success = await QuestCompletionService.completeTask(
    weeklyQuestId: quest.weeklyQuestId,
    taskId: quest.taskId,
    expReward: quest.expReward,
    currencyReward: quest.currencyReward,
  );

  if (!mounted) return;

  if (!success) {
    // Restore the UI if the task was already completed elsewhere.
    setState(() {
      quest.isCompleted = true;
    });
  }

  await loadCharacter();
  await loadCurrency();
  await loadQuests();
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Life RPG'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                '💎 $currency',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      character.name.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('${character.rarity} ${character.role}'),
                    const SizedBox(height: 10),
                    Text(
                      'Lv. ${character.level}',
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 15),
                    Text('EXP ${character.exp} / 100'),
                    Text('❤️ HP   ${character.hp}'),
                    Text('⚔️ ATK   ${character.atk}'),
                    Text('🛡️ DEF   ${character.def}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'DAILY QUESTS',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: quests.isEmpty
                  ? const Center(
                      child: Text(
                        'No daily quests yet.\nCreate a Weekly Quest to get started.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      itemCount: quests.length,
                      itemBuilder: (context, index) {
                        final quest = quests[index];

                        return Card(
                          child: ListTile(
                            title: Text(quest.title),
                            subtitle: Text(
                              '+${quest.expReward} EXP'
                              '    +${quest.currencyReward} 💎',
                            ),
                            trailing: ElevatedButton(
                              onPressed: quest.isCompleted
                                  ? null
                                  : () => completeQuest(quest),
                              child: Text(
                                quest.isCompleted
                                    ? 'COMPLETED'
                                    : 'COMPLETE',
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
