
import 'package:flutter/material.dart';

import '../models/calendar_event.dart';
import '../services/storage_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime selectedDate = DateTime.now();
  DateTime focusedDate = DateTime.now();

  List<CalendarEvent> events = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadEvents();
  }

  Future<void> loadEvents() async {
    final savedEvents =
        await StorageService.loadCalendarEvents() ?? [];

    if (!mounted) return;

    setState(() {
      events = savedEvents;
      isLoading = false;
    });
  }


  List<CalendarEvent> get selectedDateEvents {
    final result = <CalendarEvent>[];

    for (final event in events) {
      final selectedDay = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      );

      final startDay = DateTime(
        event.startTime.year,
        event.startTime.month,
        event.startTime.day,
      );

      final endRepeatDay = event.repeatUntil == null
          ? null
          : DateTime(
              event.repeatUntil!.year,
              event.repeatUntil!.month,
              event.repeatUntil!.day,
            );

      if (event.parentEventId != null) {
        final eventDay = DateTime(
          event.startTime.year,
          event.startTime.month,
          event.startTime.day,
        );

        if (eventDay == selectedDay) {
          result.add(event);
        }

        continue;
      }

      if (selectedDay.isBefore(startDay)) continue;

      if (endRepeatDay != null &&
          selectedDay.isAfter(endRepeatDay)) {
        continue;
      }

      bool occursOnSelectedDay;

      switch (event.repeatType) {
        case 'daily':
          occursOnSelectedDay = true;
          break;
        case 'weekly':
          occursOnSelectedDay =
              selectedDay.weekday == startDay.weekday;
          break;
        case 'monthly':
          occursOnSelectedDay =
              selectedDay.day == startDay.day;
          break;
        default:
          occursOnSelectedDay = selectedDay == startDay;
      }

      if (!occursOnSelectedDay) continue;

      final occurrenceKey = _dateKey(selectedDay);

      if (event.excludedOccurrenceKeys.contains(occurrenceKey)) {
        continue;
      }

      final duration = event.endTime.difference(event.startTime);

      result.add(
        CalendarEvent(
          id: '${event.id}_$occurrenceKey',
          title: event.title,
          category: event.category,
          startTime: DateTime(
            selectedDay.year,
            selectedDay.month,
            selectedDay.day,
            event.startTime.hour,
            event.startTime.minute,
          ),
          endTime: DateTime(
            selectedDay.year,
            selectedDay.month,
            selectedDay.day,
            event.startTime.hour,
            event.startTime.minute,
          ).add(duration),
          location: event.location,
          notes: event.notes,
          repeatType: event.repeatType,
          repeatUntil: event.repeatUntil,
          excludedOccurrenceKeys: event.excludedOccurrenceKeys,
          parentEventId: event.id,
          originalOccurrenceKey: occurrenceKey,
        ),
      );
    }

    result.sort((a, b) => a.startTime.compareTo(b.startTime));
    return result;
  }

  String _dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
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

  
  Future<void> addEvent() async {
    final titleController = TextEditingController();
    final locationController = TextEditingController();
    final notesController = TextEditingController();

    String category = 'Personal';
    String repeatType = 'none';
    DateTime? repeatUntil;
    DateTime startTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      9,
    );
    DateTime endTime = startTime.add(const Duration(hours: 1));

    final categories = [
      'Univearsity',
      'Organization',
      'Personal',
      'Work',
      'Custom',
    ];

    Future<DateTime?> pickDateTime(DateTime initial) async {
      final date = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
      );

      if (date == null || !mounted) return null;

      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initial),
      );

      if (time == null) return null;

      return DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('New Event'),
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
                      initialValue: category,
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
                        if (value != null) {
                          setDialogState(() {
                            repeatType = value;
                            if (repeatType == 'none') {
                              repeatUntil = null;
                            }
                          });
                        }
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
                            initialDate: repeatUntil ?? startTime.add(
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
                        if (picked != null) {
                          setDialogState(() {
                            startTime = picked;
                            if (!endTime.isAfter(startTime)) {
                              endTime = startTime.add(
                                const Duration(hours: 1),
                              );
                            }
                          });
                        }
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
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final title = titleController.text.trim();

                    if (title.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter an event title.'),
                        ),
                      );
                      return;
                    }

                    if (!endTime.isAfter(startTime)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'End time must be after start time.',
                          ),
                        ),
                      );
                      return;
                    }

                    final event = CalendarEvent(
                      id: DateTime.now()
                          .microsecondsSinceEpoch
                          .toString(),
                      title: title,
                      category: category,
                      repeatType: repeatType,
                      repeatUntil: repeatUntil,
                      startTime: startTime,
                      endTime: endTime,
                      location: locationController.text.trim(),
                      notes: notesController.text.trim(),
                    );

                    final updatedEvents = [...events, event];

                    await StorageService.saveCalendarEvents(
                      updatedEvents,
                    );

                    if (!mounted) return;

                    setState(() {
                      events = updatedEvents;
                      selectedDate = DateTime(
                        startTime.year,
                        startTime.month,
                        startTime.day,
                      );
                      focusedDate = selectedDate;
                    });

                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    locationController.dispose();
    notesController.dispose();
  }
  
  Future<void> deleteEventOccurrence(CalendarEvent event) async {
    final updatedEvents = [...events];

    if (event.parentEventId != null) {
      // Delete an individually edited occurrence.
      updatedEvents.removeWhere(
        (item) => item.id == event.id,
      );

      final seriesIndex = updatedEvents.indexWhere(
        (item) => item.id == event.parentEventId,
      );

      if (seriesIndex != -1 &&
          event.originalOccurrenceKey != null) {
        final series = updatedEvents[seriesIndex];
        final occurrenceKey = event.originalOccurrenceKey!;

        final exclusions = [
          ...series.excludedOccurrenceKeys,
        ];

        if (!exclusions.contains(occurrenceKey)) {
          exclusions.add(occurrenceKey);
        }

        updatedEvents[seriesIndex] = CalendarEvent(
          id: series.id,
          title: series.title,
          category: series.category,
          startTime: series.startTime,
          endTime: series.endTime,
          location: series.location,
          notes: series.notes,
          repeatType: series.repeatType,
          repeatUntil: series.repeatUntil,
          excludedOccurrenceKeys: exclusions,
        );
      }
    } else if (event.repeatType != 'none') {
      // Delete only the original occurrence, not the series.
      final index = updatedEvents.indexWhere(
        (item) => item.id == event.id,
      );

      if (index != -1) {
        final series = updatedEvents[index];
        final occurrenceKey = _dateKey(series.startTime);

        final exclusions = [
          ...series.excludedOccurrenceKeys,
        ];

        if (!exclusions.contains(occurrenceKey)) {
          exclusions.add(occurrenceKey);
        }

        updatedEvents[index] = CalendarEvent(
          id: series.id,
          title: series.title,
          category: series.category,
          startTime: series.startTime,
          endTime: series.endTime,
          location: series.location,
          notes: series.notes,
          repeatType: series.repeatType,
          repeatUntil: series.repeatUntil,
          excludedOccurrenceKeys: exclusions,
        );
      }
    } else {
      // Delete a normal one-time event.
      updatedEvents.removeWhere(
        (item) => item.id == event.id,
      );
    }

    await StorageService.saveCalendarEvents(updatedEvents);

    if (!mounted) return;

    setState(() {
      events = updatedEvents;
    });
  }
  
  Future<void> deleteEvent(CalendarEvent event) async {
    final seriesId = event.parentEventId ?? event.id;

    final seriesIndex = events.indexWhere(
      (item) => item.id == seriesId,
    );

    final isRecurringSeries = seriesIndex != -1 &&
        events[seriesIndex].repeatType != 'none';

    if (isRecurringSeries) {
      final choice = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
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
        ),
      );

      if (choice == null ||
          choice == 'cancel' ||
          !mounted) {
        return;
      }

      switch (choice) {
        case 'single':
          await deleteEventOccurrence(event);
          break;

        case 'following':
          await deleteThisAndFollowing(event);
          break;

        case 'all':
          final updatedEvents = events.where((item) {
            return item.id != seriesId &&
                item.parentEventId != seriesId;
          }).toList();

          await StorageService.saveCalendarEvents(
            updatedEvents,
          );

          if (!mounted) return;

          setState(() {
            events = updatedEvents;
          });
          break;
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event deleted.'),
        ),
      );

      return;
    }

    // Normal events and orphaned edited occurrences.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete event?'),
        content: Text(
          event.parentEventId != null
              ? 'Delete only this occurrence?'
              : 'Delete this event?',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await deleteEventOccurrence(event);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Event deleted.'),
      ),
    );
  }

  Future<void> deleteThisAndFollowing(
    CalendarEvent event,
  ) async {
    final seriesId = event.parentEventId ?? event.id;

    final seriesIndex = events.indexWhere(
      (item) => item.id == seriesId,
    );

    if (seriesIndex == -1) return;

    final series = events[seriesIndex];

    if (series.repeatType == 'none') return;

    // Use the original recurrence date when an occurrence
    // has been moved or edited.
    final occurrenceKey = event.originalOccurrenceKey ??
        _dateKey(event.startTime);

    final cutoff = DateTime.parse(occurrenceKey);

    final seriesStart = DateTime(
      series.startTime.year,
      series.startTime.month,
      series.startTime.day,
    );

    final deleteEntireSeries =
        !cutoff.isAfter(seriesStart);

    final updatedEvents = <CalendarEvent>[];

    for (final item in events) {
      // Handle the recurring series itself.
      if (item.id == seriesId) {
        if (deleteEntireSeries) {
          continue;
        }

        final lastOccurrence = cutoff.subtract(
          const Duration(days: 1),
        );

        // Do not extend an existing recurrence end date.
        final existingEnd = item.repeatUntil;

        final newRepeatUntil = existingEnd != null &&
                DateTime(
                  existingEnd.year,
                  existingEnd.month,
                  existingEnd.day,
                ).isBefore(lastOccurrence)
            ? existingEnd
            : lastOccurrence;

        updatedEvents.add(
          CalendarEvent(
            id: item.id,
            title: item.title,
            category: item.category,
            startTime: item.startTime,
            endTime: item.endTime,
            location: item.location,
            notes: item.notes,
            repeatType: item.repeatType,
            repeatUntil: newRepeatUntil,
            excludedOccurrenceKeys:
                item.excludedOccurrenceKeys
                    .where(
                      (key) => key.compareTo(
                        occurrenceKey,
                      ) < 0,
                    )
                    .toList(),
          ),
        );

        continue;
      }

      // Handle separately stored edited occurrences.
      if (item.parentEventId == seriesId) {
        final originalKey = item.originalOccurrenceKey ??
            _dateKey(item.startTime);

        if (originalKey.compareTo(occurrenceKey) >= 0) {
          // Delete this edited occurrence and all following
          // edited occurrences in the series.
          continue;
        }
      }

      // Preserve unrelated events and earlier exceptions.
      updatedEvents.add(item);
    }

    await StorageService.saveCalendarEvents(updatedEvents);

    if (!mounted) return;

    setState(() {
      events = updatedEvents;
    });
  }

  Future<void> editEvent(CalendarEvent event) async {
    final titleController = TextEditingController(text: event.title);
    final locationController =
        TextEditingController(text: event.location);
    final notesController = TextEditingController(text: event.notes);

    String category = event.category;
    DateTime startTime = event.startTime;
    DateTime endTime = event.endTime;

    final categories = [
      'University',
      'Social',
      'Personal',
      'Work',
      'Custom',
    ];

    Future<DateTime?> pickDateTime(DateTime initial) async {
      final date = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
      );

      if (date == null || !mounted) return null;

      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initial),
      );

      if (time == null) return null;

      return DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    }

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Edit Event'),
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
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Start'),
                        subtitle: Text(
                          '${formatDate(startTime)} '
                          '${formatTime(startTime)}',
                        ),
                        trailing: const Icon(Icons.edit_calendar),
                        onTap: () async {
                          final picked =
                              await pickDateTime(startTime);
                          if (picked != null) {
                            setDialogState(() {
                              startTime = picked;
                              if (!endTime.isAfter(startTime)) {
                                endTime = startTime.add(
                                  const Duration(hours: 1),
                                );
                              }
                            });
                          }
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
                          final picked =
                              await pickDateTime(endTime);
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
                          labelText: 'Location',
                        ),
                      ),
                      TextField(
                        controller: notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes',
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () =>
                        Navigator.pop(dialogContext),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final title = titleController.text.trim();

                      if (title.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please enter an event title.',
                            ),
                          ),
                        );
                        return;
                      }

                      if (!endTime.isAfter(startTime)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'End time must be after start time.',
                            ),
                          ),
                        );
                        return;
                      }

                      final updatedEvents = [...events];

                      // Find the original event or recurring series.
                      final parentId = event.parentEventId;
                      final sourceIndex = updatedEvents.indexWhere(
                        (item) => item.id == parentId,
                      );

                      final existingExceptionIndex =
                          updatedEvents.indexWhere(
                        (item) => item.id == event.id,
                      );

                      final updatedEvent = CalendarEvent(
                        id: event.id,
                        title: title,
                        category: category,
                        startTime: startTime,
                        endTime: endTime,
                        location: locationController.text.trim(),
                        notes: notesController.text.trim(),
                        repeatType: event.repeatType,
                        repeatUntil: event.repeatUntil,
                        excludedOccurrenceKeys:
                            event.excludedOccurrenceKeys,
                        parentEventId: event.parentEventId,
                        originalOccurrenceKey:
                            event.originalOccurrenceKey,
                      );

                      if (existingExceptionIndex != -1) {
                        // This occurrence was already edited before.
                        updatedEvents[existingExceptionIndex] =
                            updatedEvent;
                      } else if (sourceIndex != -1) {
                        final source = updatedEvents[sourceIndex];

                        if (source.repeatType == 'none') {
                          // A one-time event: update the original.
                          updatedEvents[sourceIndex] = CalendarEvent(
                            id: source.id,
                            title: title,
                            category: category,
                            startTime: startTime,
                            endTime: endTime,
                            location: locationController.text.trim(),
                            notes: notesController.text.trim(),
                          );
                        } else {
                          // A recurring event: exclude the original
                          // occurrence and save its edited replacement.
                          final occurrenceKey =
                              event.originalOccurrenceKey ??
                              _dateKey(event.startTime);

                          if (!source.excludedOccurrenceKeys
                              .contains(occurrenceKey)) {
                            updatedEvents[sourceIndex] =
                                CalendarEvent(
                              id: source.id,
                              title: source.title,
                              category: source.category,
                              startTime: source.startTime,
                              endTime: source.endTime,
                              location: source.location,
                              notes: source.notes,
                              repeatType: source.repeatType,
                              repeatUntil: source.repeatUntil,
                              excludedOccurrenceKeys: [
                                ...source.excludedOccurrenceKeys,
                                occurrenceKey,
                              ],
                            );
                          }

                          updatedEvents.add(
                            CalendarEvent(
                              id: DateTime.now()
                                  .microsecondsSinceEpoch
                                  .toString(),
                              title: title,
                              category: category,
                              startTime: startTime,
                              endTime: endTime,
                              location: locationController.text.trim(),
                              notes: notesController.text.trim(),
                              parentEventId: source.id,
                              originalOccurrenceKey: occurrenceKey,
                            ),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Could not find the original event.',
                            ),
                          ),
                        );
                        return;
                      }

                      await StorageService.saveCalendarEvents(
                        updatedEvents,
                      );

                      if (!mounted) return;

                      setState(() {
                        events = updatedEvents;
                        selectedDate = DateTime(
                          startTime.year,
                          startTime.month,
                          startTime.day,
                        );
                        focusedDate = selectedDate;
                      });

                      Navigator.pop(dialogContext);

                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                          content: Text('Event updated.'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: 'Go to today',
            onPressed: () {
              setState(() {
                selectedDate = DateTime.now();
                focusedDate = DateTime.now();
              });
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                CalendarDatePicker(
                  initialDate: selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                  onDateChanged: (date) {
                    setState(() {
                      selectedDate = date;
                      focusedDate = date;
                    });
                  },
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          formatDate(selectedDate),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium,
                        ),
                      ),
                      Text('${selectedDateEvents.length} events'),
                    ],
                  ),
                ),
                Expanded(
                  child: selectedDateEvents.isEmpty
                      ? const Center(
                          child: Text(
                            'No events scheduled for this day.',
                          ),
                        )
                      : ListView.builder(
                          itemCount: selectedDateEvents.length,
                          itemBuilder: (context, index) {
                            final event =
                                selectedDateEvents[index];
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
                              isThreeLine: event.location.isNotEmpty,
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
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
                                          onPressed: () async {
                                            Navigator.pop(dialogContext);
                                            await deleteEvent(event);
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
                              },
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
  }
}
