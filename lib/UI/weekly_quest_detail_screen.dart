import 'package:flutter/material.dart';

import '../models/weekly_quest.dart';
import '../services/quest_completion_service.dart';

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
  late WeeklyQuest weeklyQuest;

  @override
  void initState() {
    super.initState();
    weeklyQuest = widget.weeklyQuest;
  }

Future<void> toggleTask(int index, bool isCompleted) async {
  if (!isCompleted) return;

  final taskId = '${weeklyQuest.id}_task_$index';

  if (weeklyQuest.completedTaskIds.contains(taskId)) return;

  final success = await QuestCompletionService.completeTask(
    weeklyQuestId: weeklyQuest.id,
    taskId: taskId,
    expReward: 100,
    currencyReward: 10,
  );

  if (!mounted) return;

  if (success) {
    setState(() {
      weeklyQuest.completedTaskIds.add(taskId);

      weeklyQuest.isCompleted =
          weeklyQuest.dailyTaskTitles.isNotEmpty &&
          weeklyQuest.dailyTaskTitles.asMap().entries.every(
            (entry) => weeklyQuest.completedTaskIds.contains(
              '${weeklyQuest.id}_task_${entry.key}',
            ),
          );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Task completed! +100 EXP, +10 currency'),
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    final completedCount = weeklyQuest.dailyTaskTitles
        .asMap()
        .entries
        .where(
          (entry) => weeklyQuest.completedTaskIds.contains(
            '${weeklyQuest.id}_task_${entry.key}',
          ),
        )
        .length;

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
              weeklyQuest.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (weeklyQuest.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(weeklyQuest.description),
            ],
            const SizedBox(height: 16),
            Text(
              '$completedCount / '
              '${weeklyQuest.dailyTaskTitles.length} tasks completed',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: weeklyQuest.dailyTaskTitles.isEmpty
                  ? 0
                  : completedCount /
                      weeklyQuest.dailyTaskTitles.length,
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
              child: weeklyQuest.dailyTaskTitles.isEmpty
                  ? const Center(
                      child: Text('No tasks added.'),
                    )
                  : ListView.builder(
                      itemCount:
                          weeklyQuest.dailyTaskTitles.length,
                      itemBuilder: (context, index) {
                        final taskId =
                            '${weeklyQuest.id}_task_$index';

                        final isCompleted =
                            weeklyQuest.completedTaskIds
                                .contains(taskId);

                        return Card(
                          child: CheckboxListTile(
                            value: isCompleted,
                            onChanged: isCompleted
                                ? null
                                : (value) {
                                    if (value == true) {
                                      toggleTask(index, true);
                                    }
                                  },
                            title: Text(
                              weeklyQuest.dailyTaskTitles[index],
                              style: TextStyle(
                                decoration: isCompleted
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                color: isCompleted
                                    ? Colors.grey
                                    : null,
                              ),
                            ),
                            secondary: Icon(
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
  }
}