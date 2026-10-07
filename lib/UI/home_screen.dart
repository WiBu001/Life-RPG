import 'package:flutter/material.dart';
import '../models/quest.dart';
import '../data/quest_data.dart';
import '../models/character.dart';
import '../services/storage_service.dart';

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

  @override
  void initState() {
    super.initState();

    loadCharacter();
  }

  int currency = 0;
  final List<Quest> quests = dailyQuests;

  Future<void> completeQuest(Quest quest) async {
    if (quest.isCompleted) {
      return;
    }

    setState(() {
      quest.isCompleted = true;

      character.exp += quest.expReward;
      currency += quest.currencyReward;

      if (character.exp >= 100) {
        character.exp -= 100;
        character.level++;

        character.hp += 50;
        character.atk += 5;
        character.def += 3;
      }
    });
    await StorageService.saveCharacter(character);
  }

  void showAddQuestDialog() {
    final titleController = TextEditingController();
    final expController = TextEditingController(text: '100');
    final currencyController = TextEditingController(text: '10');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create Quest'),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Quest Title',
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: expController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'EXP Reward',
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: currencyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Currency Reward',
                ),
              ),
            ],
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('CANCEL'),
            ),

            ElevatedButton(
              onPressed: () {
                final title = titleController.text.trim();
                final expReward = int.tryParse(expController.text) ?? 0;
                final currencyReward =
                    int.tryParse(currencyController.text) ?? 0;

                if (title.isEmpty) {
                  return;
                }

                setState(() {
                  quests.add(
                    Quest(
                      title: title,
                      expReward: expReward,
                      currencyReward: currencyReward,
                    ),
                  );
                });

                Navigator.pop(context);
              },
              child: const Text('CREATE'),
            ),
          ],
        );
      },
    );
  }

  Future<void> loadCharacter() async {
    final savedCharacter = await StorageService.loadCharacter();

    if (savedCharacter != null) {
      setState(() {
        character = savedCharacter;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Life RPG'),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // Currency
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '💎 $currency',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Character
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

                    Text(
                      '${character.rarity} ${character.role}',
                    ),

                    const SizedBox(height: 10),

                    Text(
                      'Lv. ${character.level}',
                      style: const TextStyle(
                        fontSize: 20,
                      ),
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

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'DAILY QUESTS',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                ElevatedButton.icon(
                  onPressed: showAddQuestDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('ADD'),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Column(
              children: quests.map((quest) {
                return Card(
                  child: ListTile(
                    title: Text(quest.title),
                    subtitle: Text(
                      '+${quest.expReward} EXP    +${quest.currencyReward} 💎',
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
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}