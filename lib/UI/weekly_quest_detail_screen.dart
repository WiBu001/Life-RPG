import 'package:flutter/material.dart';

import '../models/weekly_quest.dart';
import '../controllers/weekly_quest_detail_controller.dart';

class WeeklyQuestDetailScreen extends StatefulWidget {
  final WeeklyQuest weeklyQuest;

  const WeeklyQuestDetailScreen({
    super.key,
    required this.weeklyQuest,
  });

  @override
  State<WeeklyQuestDetailScreen> createState() =>
      _WeeklyQuestDetailScreenState();
}

class _WeeklyQuestDetailScreenState
    extends State<WeeklyQuestDetailScreen> {
  late final WeeklyQuestDetailController controller;

  @override
  void initState() {
    super.initState();

    controller = WeeklyQuestDetailController(
      weeklyQuest: widget.weeklyQuest,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> completeTask(int index) async {
    final wasCompleted = controller.isTaskCompleted(index);

    await controller.completeTask(index);

    if (!mounted) return;

    if (!wasCompleted && controller.isTaskCompleted(index)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Task completed! +100 EXP, +10 currency',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final quest = controller.weeklyQuest;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Weekly Quest Details'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quest.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (quest.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(quest.description),
                ],
                const SizedBox(height: 16),
                Text(
                  '${controller.completedCount} / '
                  '${quest.dailyTaskTitles.length} tasks completed',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: controller.progress,
                ),
                const SizedBox(height: 16),
                const Text(
                  'TASK CHECKLIST',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: quest.dailyTaskTitles.isEmpty
                      ? const Center(
                          child: Text('No tasks added.'),
                        )
                      : ListView.builder(
                          itemCount: quest.dailyTaskTitles.length,
                          itemBuilder: (context, index) {
                            final isCompleted =
                                controller.isTaskCompleted(index);
                            final isProcessing =
                                controller.isTaskProcessing(index);

                            return Card(
                              child: CheckboxListTile(
                                value: isCompleted,
                                onChanged:
                                    isCompleted || isProcessing
                                        ? null
                                        : (value) {
                                            if (value == true) {
                                              completeTask(index);
                                            }
                                          },
                                title: Text(
                                  quest.dailyTaskTitles[index],
                                  style: TextStyle(
                                    decoration: isCompleted
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                    color: isCompleted
                                        ? Colors.grey
                                        : null,
                                  ),
                                ),
                                secondary: isProcessing
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Icon(
                                        isCompleted
                                            ? Icons.check_circle
                                            : Icons.circle_outlined,
                                        color: isCompleted
                                            ? Colors.green
                                            : Colors.grey,
                                      ),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
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