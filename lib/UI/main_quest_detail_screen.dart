
import 'package:flutter/material.dart';

import '../models/main_quest.dart';
import '../models/main_quest_step.dart';
import '../services/storage_service.dart';
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

class _MainQuestDetailScreenState
    extends State<MainQuestDetailScreen> {
  List<MainQuestStep> steps = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadSteps();
  }

  Future<void> loadSteps() async {
    final savedSteps =
        await StorageService.loadMainQuestSteps() ?? [];

    if (!mounted) return;

    setState(() {
      steps = savedSteps
          .where((step) => step.mainQuestId == widget.mainQuest.id)
          .toList();
      isLoading = false;
    });
  }

  Future<void> showCreateStepDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    final result = await showDialog<MainQuestStep>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Main Quest Step'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Step Title',
                    hintText: 'e.g. Complete coursework',
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
                  MainQuestStep(
                    id: DateTime.now()
                        .microsecondsSinceEpoch
                        .toString(),
                    mainQuestId: widget.mainQuest.id,
                    title: title,
                    description:
                        descriptionController.text.trim(),
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

    final allSteps =
        await StorageService.loadMainQuestSteps() ?? [];

    allSteps.add(result);
    await StorageService.saveMainQuestSteps(allSteps);

    if (!mounted) return;

    setState(() {
      steps.add(result);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Main Quest Details'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: showCreateStepDialog,
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
            Text(
              'MILESTONES',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : steps.isEmpty
                      ? const Center(
                          child: Text(
                            'No milestones yet.\nAdd your first step!',
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.builder(
                          itemCount: steps.length,
                          itemBuilder: (context, index) {
                            final step = steps[index];

                            return Card(
                              child: ListTile(
                                leading: const Icon(
                                  Icons.flag_outlined,
                                ),
                                title: Text(step.title),
                                subtitle: step.description.isEmpty
                                    ? null
                                    : Text(step.description),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MainQuestStepDetailScreen(
                                        step: step,
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
