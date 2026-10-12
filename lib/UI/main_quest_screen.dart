import 'package:flutter/material.dart';

import '../controllers/main_quest_controller.dart';
import '../models/main_quest.dart';
import 'main_quest_detail_screen.dart';

class MainQuestScreen extends StatefulWidget {
  const MainQuestScreen({super.key});

  @override
  State<MainQuestScreen> createState() => _MainQuestScreenState();
}

class _MainQuestScreenState extends State<MainQuestScreen> {
  late final MainQuestController controller;

  @override
  void initState() {
    super.initState();

    controller = MainQuestController();
    controller.initialize();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> showCreateQuestDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('New Main Quest'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Quest Title',
                ),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final title = titleController.text.trim();

              if (title.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a quest title.'),
                  ),
                );
                return;
              }

              Navigator.pop(
                dialogContext,
                {
                  'title': title,
                  'description': descriptionController.text.trim(),
                },
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    titleController.dispose();
    descriptionController.dispose();

    if (result == null) return;

    await controller.createQuest(
      title: result['title']!,
      description: result['description'] ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final mainQuests = controller.mainQuests;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Main Quests'),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: controller.isLoading
                ? null
                : showCreateQuestDialog,
            icon: const Icon(Icons.add),
            label: const Text('New Main Quest'),
          ),
          body: controller.isLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : Column(
                  children: [
                    if (controller.errorMessage != null)
                      MaterialBanner(
                        content: Text(controller.errorMessage!),
                        actions: [
                          TextButton(
                            onPressed: () {
                              // The message disappears when a later
                              // successful operation clears it.
                            },
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    Expanded(
                      child: mainQuests.isEmpty
                          ? const Center(
                              child: Text(
                                'No Main Quests yet. Create your first goal!',
                              ),
                            )
                          : ListView.builder(
                              itemCount: mainQuests.length,
                              itemBuilder: (context, index) {
                                final MainQuest quest =
                                    mainQuests[index];

                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  child: ListTile(
                                    leading: const Icon(
                                      Icons.flag,
                                      color: Colors.orange,
                                    ),
                                    title: Text(quest.title),
                                    subtitle:
                                        quest.description.isNotEmpty
                                            ? Text(quest.description)
                                            : null,
                                    trailing: const Icon(
                                      Icons.chevron_right,
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              MainQuestDetailScreen(
                                            mainQuest: quest,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}