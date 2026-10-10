
import 'package:flutter/material.dart';

import '../models/main_quest.dart';
import '../services/storage_service.dart';
import 'main_quest_detail_screen.dart';

class MainQuestScreen extends StatefulWidget {
  const MainQuestScreen({super.key});

  @override
  State<MainQuestScreen> createState() => _MainQuestScreenState();
}

class _MainQuestScreenState extends State<MainQuestScreen> {
  List<MainQuest> mainQuests = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadMainQuests();
  }

  Future<void> loadMainQuests() async {
    final savedQuests = await StorageService.loadMainQuests();

    if (!mounted) return;

    setState(() {
      mainQuests = savedQuests ?? [];
      isLoading = false;
    });
  }

  Future<void> saveMainQuests() async {
    await StorageService.saveMainQuests(mainQuests);
  }

  Future<void> showCreateQuestDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    final result = await showDialog<MainQuest>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create Main Quest'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Quest Title',
                    hintText: 'e.g. Graduate from University',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final title = titleController.text.trim();

                if (title.isEmpty) return;

                Navigator.pop(
                  context,
                  MainQuest(
                    id: DateTime.now().microsecondsSinceEpoch.toString(),
                    title: title,
                    description:
                        descriptionController.text.trim(),
                    createdAt: DateTime.now(),
                  ),
                );
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    titleController.dispose();
    descriptionController.dispose();

    if (result == null) return;

    setState(() {
      mainQuests.add(result);
    });

    await saveMainQuests();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Main Quests'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: showCreateQuestDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Main Quest'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : mainQuests.isEmpty
              ? const Center(
                  child: Text(
                    'No Main Quests yet.\nCreate your first long-term goal!',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: mainQuests.length,
                  itemBuilder: (context, index) {
                    final quest = mainQuests[index];

                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.flag),
                        title: Text(quest.title),
                        subtitle: quest.description.isEmpty
                            ? null
                            : Text(quest.description),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MainQuestDetailScreen(
                                    mainQuest: quest,
                                  ),
                                ),
                              );
                            },
                      ),
                    );
                  },
                ),
    );
  }
}
