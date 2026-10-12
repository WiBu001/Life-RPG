import 'package:flutter/material.dart';

import '../controllers/main_quest_step_detail_controller.dart';
import '../models/main_quest_step.dart';
import '../models/weekly_quest.dart';
import 'weekly_quest_detail_screen.dart';

class MainQuestStepDetailScreen extends StatefulWidget {
  final MainQuestStep step;

  const MainQuestStepDetailScreen({
    super.key,
    required this.step,
  });

  @override
  State<MainQuestStepDetailScreen> createState() =>
      _MainQuestStepDetailScreenState();
}

class _MainQuestStepDetailScreenState
    extends State<MainQuestStepDetailScreen> {
  late final MainQuestStepDetailController controller;

  @override
  void initState() {
    super.initState();

    controller = MainQuestStepDetailController(
      step: widget.step,
    );

    controller.initialize();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> showCreateWeeklyQuestDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final tasksController = TextEditingController();

    DateTime startDate = DateTime.now();
    DateTime deadline = DateTime.now().add(
      const Duration(days: 6),
    );

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Weekly Quest'),
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
                  maxLines: 2,
                ),
                TextField(
                  controller: tasksController,
                  decoration: const InputDecoration(
                    labelText: 'Daily Tasks (one per line)',
                    hintText: 'Read chapter 1\nComplete assignment',
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Start Date'),
                  subtitle: Text(
                    '${startDate.day}/${startDate.month}/${startDate.year}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final selected = await showDatePicker(
                      context: context,
                      initialDate: startDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );

                    if (selected != null) {
                      setDialogState(() {
                        startDate = selected;

                        if (deadline.isBefore(startDate)) {
                          deadline = startDate;
                        }
                      });
                    }
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Deadline'),
                  subtitle: Text(
                    '${deadline.day}/${deadline.month}/${deadline.year}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final selected = await showDatePicker(
                      context: context,
                      initialDate: deadline,
                      firstDate: startDate,
                      lastDate: DateTime(2100),
                    );

                    if (selected != null) {
                      setDialogState(() {
                        deadline = selected;
                      });
                    }
                  },
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

                final tasks = tasksController.text
                    .split('\n')
                    .map((task) => task.trim())
                    .where((task) => task.isNotEmpty)
                    .toList();

                if (title.isEmpty || tasks.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Enter a title and at least one task.',
                      ),
                    ),
                  );
                  return;
                }

                if (deadline.isBefore(startDate)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Deadline cannot be before the start date.',
                      ),
                    ),
                  );
                  return;
                }

                Navigator.pop(
                  dialogContext,
                  {
                    'title': title,
                    'description': descriptionController.text.trim(),
                    'startDate': startDate,
                    'deadline': deadline,
                    'tasks': tasks,
                  },
                );
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );

    titleController.dispose();
    descriptionController.dispose();
    tasksController.dispose();

    if (result == null) return;

    await controller.createWeeklyQuest(
      title: result['title'] as String,
      description: result['description'] as String,
      startDate: result['startDate'] as DateTime,
      deadline: result['deadline'] as DateTime,
      dailyTaskTitles: result['tasks'] as List<String>,
    );
  }

  String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final quests = controller.weeklyQuests;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Weekly Quests'),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: controller.isLoading
                ? null
                : showCreateWeeklyQuestDialog,
            icon: const Icon(Icons.add),
            label: const Text('New Weekly Quest'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.step.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (widget.step.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(widget.step.description),
                ],
                const SizedBox(height: 24),
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
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : quests.isEmpty
                          ? const Center(
                              child: Text(
                                'No Weekly Quests yet. Create one!',
                              ),
                            )
                          : ListView.builder(
                              itemCount: quests.length,
                              itemBuilder: (context, index) {
                                final WeeklyQuest quest =
                                    quests[index];

                                return Card(
                                  child: ListTile(
                                    title: Text(quest.title),
                                    subtitle: Text(
                                      'Deadline: ${formatDate(quest.deadline)}\n'
                                      '${quest.dailyTaskTitles.length} daily tasks',
                                    ),
                                    isThreeLine: true,
                                    trailing: const Icon(
                                      Icons.chevron_right,
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              WeeklyQuestDetailScreen(
                                            weeklyQuest: quest,
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
          ),
        );
      },
    );
  }
}