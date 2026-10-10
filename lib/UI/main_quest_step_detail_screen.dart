
import 'package:flutter/material.dart';

import '../models/main_quest_step.dart';
import '../models/weekly_quest.dart';
import '../services/storage_service.dart';
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
  List<WeeklyQuest> weeklyQuests = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadWeeklyQuests();
  }

  Future<void> loadWeeklyQuests() async {
    final savedQuests =
        await StorageService.loadWeeklyQuests() ?? [];

    if (!mounted) return;

    setState(() {
      weeklyQuests = savedQuests
          .where(
            (quest) => quest.mainQuestStepId == widget.step.id,
          )
          .toList();
      isLoading = false;
    });
  }

  Future<void> showCreateWeeklyQuestDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final tasksController = TextEditingController();

    DateTime startDate = DateTime.now();
    DateTime deadline = DateTime.now().add(
      const Duration(days: 6),
    );

    final result = await showDialog<WeeklyQuest>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Create Weekly Quest'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Assignment / Quest Title',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description (optional)',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: tasksController,
                      decoration: const InputDecoration(
                        labelText: 'Daily Tasks',
                        hintText:
                            'Research topic\nWrite report\nReview work',
                        helperText:
                            'Enter one task per line.',
                      ),
                      maxLines: 5,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Start date'),
                      subtitle: Text(
                        '${startDate.day}/${startDate.month}/${startDate.year}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: startDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );

                        if (picked != null) {
                          setDialogState(() {
                            startDate = picked;
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
                      trailing: const Icon(Icons.event),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: deadline,
                          firstDate: startDate,
                          lastDate: DateTime(2100),
                        );

                        if (picked != null) {
                          setDialogState(() {
                            deadline = picked;
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
                      return;
                    }

                    Navigator.pop(
                      dialogContext,
                      WeeklyQuest(
                        id: DateTime.now()
                            .microsecondsSinceEpoch
                            .toString(),
                        mainQuestStepId: widget.step.id,
                        title: title,
                        description:
                            descriptionController.text.trim(),
                        weekStartDate: startDate,
                        deadline: deadline,
                        expReward: 500,
                        currencyReward: 50,
                        dailyTaskTitles: tasks,
                      ),
                    );
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    descriptionController.dispose();
    tasksController.dispose();

    if (result == null) return;

    final allQuests =
        await StorageService.loadWeeklyQuests() ?? [];

    allQuests.add(result);
    await StorageService.saveWeeklyQuests(allQuests);

    if (!mounted) return;

    setState(() {
      weeklyQuests.add(result);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Quests'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: showCreateWeeklyQuestDialog,
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
            const SizedBox(height: 20),
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : weeklyQuests.isEmpty
                      ? const Center(
                          child: Text(
                            'No Weekly Quests yet.\n'
                            'Add an assignment or short-term goal.',
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.builder(
                          itemCount: weeklyQuests.length,
                          itemBuilder: (context, index) {
                            final quest = weeklyQuests[index];

                            return Card(
                              child: ListTile(
                                leading: const Icon(
                                  Icons.assignment_outlined,
                                ),
                                title: Text(quest.title),
                                subtitle: Text(
                                  'Deadline: '
                                  '${quest.deadline.day}/'
                                  '${quest.deadline.month}/'
                                  '${quest.deadline.year}\n'
                                  '${quest.dailyTaskTitles.length} tasks',
                                ),
                                isThreeLine: true,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => WeeklyQuestDetailScreen(
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
  }
}
