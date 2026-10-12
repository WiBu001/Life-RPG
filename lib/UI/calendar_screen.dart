import 'package:flutter/material.dart';

import '../models/calendar_event.dart';
import '../controllers/calendar_controller.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final CalendarController controller;

  @override
  void initState() {
    super.initState();
    controller = CalendarController();
    controller.loadEvents();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  String formatDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April',
      'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String formatTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  // Event Form
  Future<_EventFormData?> showEventForm({
    CalendarEvent? event,
  }) async {
    final isEditing = event != null;

    final titleController = TextEditingController(
      text: event?.title ?? '',
    );
    final locationController = TextEditingController(
      text: event?.location ?? '',
    );
    final notesController = TextEditingController(
      text: event?.notes ?? '',
    );

    String category = event?.category ?? 'Personal';
    String repeatType = 'none';
    DateTime? repeatUntil;

    DateTime startTime = event?.startTime ?? DateTime(
      controller.selectedDate.year,
      controller.selectedDate.month,
      controller.selectedDate.day,
      9,
    );

    DateTime endTime = event?.endTime ??
        startTime.add(const Duration(hours: 1));

    const categories = [
      'University',
      'Organization',
      'Social',
      'Personal',
      'Work',
      'Custom',
    ];

    Future<DateTime?> pickDateTime(DateTime initial) async {
      final pickedDate = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
      );

      if (pickedDate == null || !mounted) return null;

      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initial),
      );

      if (pickedTime == null || !mounted) return null;

      return DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    }

    try {
      return await showDialog<_EventFormData>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Text(isEditing ? 'Edit Event' : 'New Event'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Event title *',
                        ),
                      ),
                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        initialValue: categories.contains(category)
                            ? category
                            : 'Custom',
                        decoration: const InputDecoration(
                          labelText: 'Category',
                        ),
                        items: categories.map((item) {
                          return DropdownMenuItem(
                            value: item,
                            child: Text(item),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              category = value;
                            });
                          }
                        },
                      ),

                      // Recurrence is configured when creating an event.
                      if (!isEditing) ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: repeatType,
                          decoration: const InputDecoration(
                            labelText: 'Repeat',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'none',
                              child: Text('Does not repeat'),
                            ),
                            DropdownMenuItem(
                              value: 'daily',
                              child: Text('Daily'),
                            ),
                            DropdownMenuItem(
                              value: 'weekly',
                              child: Text('Weekly'),
                            ),
                            DropdownMenuItem(
                              value: 'monthly',
                              child: Text('Monthly'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;

                            setDialogState(() {
                              repeatType = value;

                              if (repeatType == 'none') {
                                repeatUntil = null;
                              }
                            });
                          },
                        ),

                        if (repeatType != 'none') ...[
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('End repeat'),
                            subtitle: Text(
                              repeatUntil == null
                                  ? 'Never'
                                  : formatDate(repeatUntil!),
                            ),
                            trailing: const Icon(Icons.event),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: repeatUntil ??
                                    startTime.add(
                                      const Duration(days: 30),
                                    ),
                                firstDate: DateTime(
                                  startTime.year,
                                  startTime.month,
                                  startTime.day,
                                ),
                                lastDate: DateTime(2100),
                              );

                              if (picked != null) {
                                setDialogState(() {
                                  repeatUntil = picked;
                                });
                              }
                            },
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                setDialogState(() {
                                  repeatUntil = null;
                                });
                              },
                              child: const Text('Clear end date'),
                            ),
                          ),
                        ],
                      ],

                      const SizedBox(height: 12),

                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Start'),
                        subtitle: Text(
                          '${formatDate(startTime)} '
                          '${formatTime(startTime)}',
                        ),
                        trailing: const Icon(Icons.edit_calendar),
                        onTap: () async {
                          final picked = await pickDateTime(startTime);

                          if (picked == null) return;

                          setDialogState(() {
                            startTime = picked;

                            if (!endTime.isAfter(startTime)) {
                              endTime = startTime.add(
                                const Duration(hours: 1),
                              );
                            }
                          });
                        },
                      ),

                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('End'),
                        subtitle: Text(
                          '${formatDate(endTime)} '
                          '${formatTime(endTime)}',
                        ),
                        trailing: const Icon(Icons.edit_calendar),
                        onTap: () async {
                          final picked = await pickDateTime(endTime);

                          if (picked != null) {
                            setDialogState(() {
                              endTime = picked;
                            });
                          }
                        },
                      ),

                      TextField(
                        controller: locationController,
                        decoration: const InputDecoration(
                          labelText: 'Location (optional)',
                        ),
                      ),

                      TextField(
                        controller: notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes (optional)',
                        ),
                        maxLines: 2,
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
                        showMessage('Please enter an event title.');
                        return;
                      }

                      if (!endTime.isAfter(startTime)) {
                        showMessage(
                          'End time must be after start time.',
                        );
                        return;
                      }

                      Navigator.pop(
                        dialogContext,
                        _EventFormData(
                          title: title,
                          category: category,
                          repeatType: repeatType,
                          repeatUntil: repeatUntil,
                          startTime: startTime,
                          endTime: endTime,
                          location: locationController.text.trim(),
                          notes: notesController.text.trim(),
                        ),
                      );
                    },
                    child: const Text('Save'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      titleController.dispose();
      locationController.dispose();
      notesController.dispose();
    }
  }

  // Add Event
  Future<void> addEvent() async {
    final data = await showEventForm();

    if (data == null || !mounted) return;

    try {
      await controller.addEvent(
        title: data.title,
        category: data.category,
        repeatType: data.repeatType,
        repeatUntil: data.repeatUntil,
        startTime: data.startTime,
        endTime: data.endTime,
        location: data.location,
        notes: data.notes,
      );

      if (!mounted) return;
      showMessage('Event created.');
    } catch (error) {
      showMessage('Could not save event: $error');
    }
  }

  // Edit Event
  Future<void> editEvent(CalendarEvent event) async {
    final data = await showEventForm(event: event);

    if (data == null || !mounted) return;

    try {
      await controller.editEvent(
        event: event,
        title: data.title,
        category: data.category,
        startTime: data.startTime,
        endTime: data.endTime,
        location: data.location,
        notes: data.notes,
      );

      if (!mounted) return;
      showMessage('Event updated.');
    } catch (error) {
      showMessage('Could not update event: $error');
    }
  }

  // Delete Event
  Future<void> deleteEvent(CalendarEvent event) async {
    if (controller.isRecurringSeries(event)) {
      final choice = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Delete recurring event'),
            content: const Text(
              'Which events do you want to delete?',
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(dialogContext, 'cancel'),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.pop(dialogContext, 'single'),
                child: const Text('This event'),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.pop(dialogContext, 'following'),
                child: const Text('This and following events'),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.pop(dialogContext, 'all'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('All events'),
              ),
            ],
          );
        },
      );

      if (!mounted || choice == null || choice == 'cancel') return;

      try {
        switch (choice) {
          case 'single':
            await controller.deleteOccurrence(event);
            break;
          case 'following':
            await controller.deleteThisAndFollowing(event);
            break;
          case 'all':
            await controller.deleteAllEventsInSeries(event);
            break;
        }

        if (!mounted) return;
        showMessage('Event deleted.');
      } catch (error) {
        showMessage('Could not delete event: $error');
      }

      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete event?'),
          content: Text(
            event.parentEventId != null
                ? 'Delete only this occurrence?'
                : 'Delete this event?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      await controller.deleteOccurrence(event);

      if (!mounted) return;
      showMessage('Event deleted.');
    } catch (error) {
      showMessage('Could not delete event: $error');
    }
  }

  // ---------- Event details ----------

  void showEventDetails(CalendarEvent event) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(event.title),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Category: ${event.category}'),
                const SizedBox(height: 8),
                Text(
                  'Date: ${formatDate(event.startTime)}',
                ),
                Text(
                  'Time: ${formatTime(event.startTime)}'
                  ' - ${formatTime(event.endTime)}',
                ),
                if (event.location.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Location: ${event.location}'),
                ],
                if (event.notes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Notes: ${event.notes}'),
                ],
                if (event.repeatType != 'none') ...[
                  const SizedBox(height: 8),
                  Text('Repeats: ${event.repeatType}'),
                  Text(
                    'Repeat until: '
                    '${event.repeatUntil == null ? 'Never' : formatDate(event.repeatUntil!)}',
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                deleteEvent(event);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                editEvent(event);
              },
              child: const Text('Edit'),
            ),
          ],
        );
      },
    );
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final dayEvents = controller.selectedDateEvents;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Calendar'),
            actions: [
              IconButton(
                icon: const Icon(Icons.today),
                tooltip: 'Go to today',
                onPressed: controller.goToToday,
              ),
            ],
          ),
          body: controller.isLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : Column(
                  children: [
                    CalendarDatePicker(
                      initialDate: controller.selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                      onDateChanged: controller.selectDate,
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        16, 8, 16, 12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              formatDate(controller.selectedDate),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium,
                            ),
                          ),
                          Text('${dayEvents.length} events'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: dayEvents.isEmpty
                          ? const Center(
                              child: Text(
                                'No events scheduled for this day.',
                              ),
                            )
                          : ListView.builder(
                              itemCount: dayEvents.length,
                              itemBuilder: (context, index) {
                                final event = dayEvents[index];

                                return ListTile(
                                  leading: const Icon(
                                    Icons.event,
                                    color: Colors.blue,
                                  ),
                                  title: Text(event.title),
                                  subtitle: Text(
                                    '${formatTime(event.startTime)}'
                                    ' - ${formatTime(event.endTime)}'
                                    '${event.location.isNotEmpty ? '\n${event.location}' : ''}',
                                  ),
                                  isThreeLine:
                                      event.location.isNotEmpty,
                                  trailing: const Icon(
                                    Icons.chevron_right,
                                  ),
                                  onTap: () => showEventDetails(event),
                                );
                              },
                            ),
                    ),
                  ],
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: addEvent,
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}

class _EventFormData {
  final String title;
  final String category;
  final String repeatType;
  final DateTime? repeatUntil;
  final DateTime startTime;
  final DateTime endTime;
  final String location;
  final String notes;

  const _EventFormData({
    required this.title,
    required this.category,
    required this.repeatType,
    required this.repeatUntil,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.notes,
  });
}