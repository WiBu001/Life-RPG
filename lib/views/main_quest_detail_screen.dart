import 'package:flutter/material.dart';

import '../controllers/main_quest_detail_controller.dart';
import '../models/main_quest.dart';
import '../models/main_quest_step.dart';
import 'main_quest_step_detail_screen.dart';

class MainQuestDetailScreen extends StatefulWidget {
  final MainQuest mainQuest;

  const MainQuestDetailScreen({
    super.key,
    required this.mainQuest,
  });

  @override
  State<MainQuestDetailScreen> createState() =>
      _MainQuestDetailScreenState();
}

class _MainQuestDetailScreenState extends State<MainQuestDetailScreen> {
  late final MainQuestDetailController controller;

  @override
  void initState() {
    super.initState();
    controller = MainQuestDetailController(mainQuest: widget.mainQuest);
    controller.initialize();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _showCreateStepDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Main Quest Step'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Step Title'),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
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
                    content: Text('Please enter a step title.'),
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

    await controller.createStep(
      title: result['title']!,
      description: result['description'] ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final steps = controller.steps;

        return Scaffold(
          appBar: AppBar(title: const Text('Main Quest Details')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed:
                controller.isLoading ? null : _showCreateStepDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Step'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.mainQuest.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (widget.mainQuest.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(widget.mainQuest.description),
                ],
                const SizedBox(height: 24),
                const Text(
                  'MILESTONES',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (controller.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      controller.errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                Expanded(
                  child: controller.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : steps.isEmpty
                          ? const Center(
                              child: Text(
                                'No steps yet. Add your first milestone!',
                              ),
                            )
                          : ListView.builder(
                              itemCount: steps.length,
                              itemBuilder: (context, index) {
                                final MainQuestStep step = steps[index];

                                return Card(
                                  child: ListTile(
                                    leading: const Icon(
                                      Icons.flag_outlined,
                                    ),
                                    title: Text(step.title),
                                    subtitle: step.description.isNotEmpty
                                        ? Text(step.description)
                                        : null,
                                    trailing:
                                        const Icon(Icons.chevron_right),
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            MainQuestStepDetailScreen(
                                          step: step,
                                        ),
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
      },
    );
  }
}
