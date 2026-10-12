import 'package:flutter/material.dart';

import '../controllers/calendar_controller.dart';
import '../models/calendar_event.dart';
import '../utils/date_formatter.dart';
import '../widgets/delete_event_dialog.dart';
import '../widgets/event_detail_dialog.dart';
import '../widgets/event_form_dialog.dart';

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

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ---------- Add ----------

  Future<void> _addEvent() async {
    final data = await showDialog<EventFormData>(
      context: context,
      builder: (_) => EventFormDialog(
        initialDate: controller.selectedDate,
      ),
    );

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
      _showMessage('Event created.');
    } catch (error) {
      _showMessage('Could not save event: $error');
    }
  }

  // ---------- Edit ----------

  Future<void> _editEvent(CalendarEvent event) async {
    final data = await showDialog<EventFormData>(
      context: context,
      builder: (_) => EventFormDialog(
        event: event,
        initialDate: controller.selectedDate,
      ),
    );

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
      _showMessage('Event updated.');
    } catch (error) {
      _showMessage('Could not update event: $error');
    }
  }

  // ---------- Delete ----------

  Future<void> _deleteEvent(CalendarEvent event) async {
    final choice = await showDeleteEventDialog(
      context: context,
      event: event,
      isRecurring: controller.isRecurringSeries(event),
    );

    if (choice == null || !mounted) return;

    try {
      switch (choice) {
        case DeleteEventChoice.single:
          await controller.deleteOccurrence(event);
        case DeleteEventChoice.following:
          await controller.deleteThisAndFollowing(event);
        case DeleteEventChoice.all:
          await controller.deleteAllEventsInSeries(event);
      }
      if (!mounted) return;
      _showMessage('Event deleted.');
    } catch (error) {
      _showMessage('Could not delete event: $error');
    }
  }

  // ---------- Details ----------

  void _showEventDetails(CalendarEvent event) {
    showDialog<void>(
      context: context,
      builder: (_) => EventDetailDialog(
        event: event,
        onEdit: () => _editEvent(event),
        onDelete: () => _deleteEvent(event),
      ),
    );
  }

  // ---------- Build ----------

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
              ? const Center(child: CircularProgressIndicator())
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
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              DateFormatter.formatDate(
                                controller.selectedDate,
                              ),
                              style: Theme.of(context).textTheme.titleMedium,
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
                                    '${DateFormatter.formatTime(event.startTime)}'
                                    ' - ${DateFormatter.formatTime(event.endTime)}'
                                    '${event.location.isNotEmpty ? '\n${event.location}' : ''}',
                                  ),
                                  isThreeLine: event.location.isNotEmpty,
                                  trailing:
                                      const Icon(Icons.chevron_right),
                                  onTap: () => _showEventDetails(event),
                                );
                              },
                            ),
                    ),
                  ],
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: _addEvent,
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
