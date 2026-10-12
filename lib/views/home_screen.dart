import 'package:flutter/material.dart';

import '../controllers/home_controller.dart';
import '../models/daily_quest.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeController controller;

  @override
  void initState() {
    super.initState();
    controller = HomeController();
    controller.initialize();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Life RPG'),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: Text(
                    '💎 ${controller.currency}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: controller.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (controller.errorMessage != null)
                        MaterialBanner(
                          content: Text(controller.errorMessage!),
                          actions: [
                            TextButton(
                              onPressed: controller.clearError,
                              child: const Text('DISMISS'),
                            ),
                          ],
                        ),
                      _CharacterCard(controller: controller),
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
                        child: _QuestList(controller: controller),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _CharacterCard extends StatelessWidget {
  final HomeController controller;

  const _CharacterCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final character = controller.character;

    return Card(
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
            Text('EXP ${character.exp} / ${character.expToNextLevel}'),
            Text('❤️ HP   ${character.hp}'),
            Text('⚔️ ATK   ${character.atk}'),
            Text('🛡️ DEF   ${character.def}'),
          ],
        ),
      ),
    );
  }
}

class _QuestList extends StatelessWidget {
  final HomeController controller;

  const _QuestList({required this.controller});

  @override
  Widget build(BuildContext context) {
    final quests = controller.quests;

    if (quests.isEmpty) {
      return const Center(
        child: Text(
          'No daily quests yet.\n'
          'Create a Weekly Quest to get started.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      itemCount: quests.length,
      itemBuilder: (context, index) =>
          _QuestCard(quest: quests[index], controller: controller),
    );
  }
}

class _QuestCard extends StatelessWidget {
  final DailyQuest quest;
  final HomeController controller;

  const _QuestCard({required this.quest, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(quest.title),
        subtitle: Text(
          '+${quest.expReward} EXP    +${quest.currencyReward} 💎',
        ),
        trailing: ElevatedButton(
          onPressed:
              quest.isCompleted ? null : () => controller.completeQuest(quest),
          child: Text(quest.isCompleted ? 'COMPLETED' : 'COMPLETE'),
        ),
      ),
    );
  }
}
