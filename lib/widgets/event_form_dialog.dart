import 'package:flutter/material.dart';

import '../models/calendar_event.dart';
import '../utils/date_formatter.dart';

/// The data returned when the user submits the event form.
class EventFormData {
  final String title;
  final String category;
  final String repeatType;
  final DateTime? repeatUntil;
  final DateTime startTime;
  final DateTime endTime;
  final String location;
  final String notes;

  const EventFormData({
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

/// A dialog for creating or editing a [CalendarEvent].
///
/// Pass [event] to pre-populate fields for editing; omit it for a new event.
/// Pass [initialDate] to pre-select the start date when creating.
///
/// Returns an [EventFormData] on save, or `null` if cancelled.
class EventFormDialog extends StatefulWidget {
  final CalendarEvent? event;
  final DateTime initialDate;

  const EventFormDialog({
    super.key,
    this.event,
    required this.initialDate,
  });

  @override
  State<EventFormDialog> createState() => _EventFormDialogState();
}

class _EventFormDialogState extends State<EventFormDialog> {
  static const List<String> _categories = [
    'University',
    'Organization',
    'Social',
    'Personal',
    'Work',
    'Custom',
  ];

  late final TextEditingController _titleController;
  late final TextEditingController _locationController;
  late final TextEditingController _notesController;

  late String _category;
  late String _repeatType;
  DateTime? _repeatUntil;
  late DateTime _startTime;
  late DateTime _endTime;

  bool get _isEditing => widget.event != null;

  @override
  void initState() {
    super.initState();

    final event = widget.event;

    _titleController = TextEditingController(text: event?.title ?? '');
    _locationController = TextEditingController(text: event?.location ?? '');
    _notesController = TextEditingController(text: event?.notes ?? '');

    _category = event?.category ?? 'Personal';
    _repeatType = 'none';

    _startTime = event?.startTime ?? DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
      9,
    );

    _endTime = event?.endTime ?? _startTime.add(const Duration(hours: 1));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDateTime(DateTime initial) async {
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

  void _submit() {
    final title = _titleController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Please enter an event title.')),
        );
      return;
    }

    if (!_endTime.isAfter(_startTime)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('End time must be after start time.')),
        );
      return;
    }

    Navigator.pop(
      context,
      EventFormData(
        title: title,
        category: _category,
        repeatType: _repeatType,
        repeatUntil: _repeatUntil,
        startTime: _startTime,
        endTime: _endTime,
        location: _locationController.text.trim(),
        notes: _notesController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit Event' : 'New Event'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Event title *'),
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              initialValue: _categories.contains(_category) ? _category : 'Custom',
              decoration: const InputDecoration(labelText: 'Category'),
              items: _categories.map((item) {
                return DropdownMenuItem(value: item, child: Text(item));
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
            ),

            // Recurrence is only configurable when creating an event.
            if (!_isEditing) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _repeatType,
                decoration: const InputDecoration(labelText: 'Repeat'),
                items: const [
                  DropdownMenuItem(
                    value: 'none',
                    child: Text('Does not repeat'),
                  ),
                  DropdownMenuItem(value: 'daily', child: Text('Daily')),
                  DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                  DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _repeatType = value;
                    if (_repeatType == 'none') _repeatUntil = null;
                  });
                },
              ),

              if (_repeatType != 'none') ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('End repeat'),
                  subtitle: Text(
                    _repeatUntil == null
                        ? 'Never'
                        : DateFormatter.formatDate(_repeatUntil!),
                  ),
                  trailing: const Icon(Icons.event),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate:
                          _repeatUntil ?? _startTime.add(const Duration(days: 30)),
                      firstDate: DateTime(
                        _startTime.year,
                        _startTime.month,
                        _startTime.day,
                      ),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => _repeatUntil = picked);
                  },
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => setState(() => _repeatUntil = null),
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
                '${DateFormatter.formatDate(_startTime)} '
                '${DateFormatter.formatTime(_startTime)}',
              ),
              trailing: const Icon(Icons.edit_calendar),
              onTap: () async {
                final picked = await _pickDateTime(_startTime);
                if (picked == null) return;
                setState(() {
                  _startTime = picked;
                  if (!_endTime.isAfter(_startTime)) {
                    _endTime = _startTime.add(const Duration(hours: 1));
                  }
                });
              },
            ),

            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('End'),
              subtitle: Text(
                '${DateFormatter.formatDate(_endTime)} '
                '${DateFormatter.formatTime(_endTime)}',
              ),
              trailing: const Icon(Icons.edit_calendar),
              onTap: () async {
                final picked = await _pickDateTime(_endTime);
                if (picked != null) setState(() => _endTime = picked);
              },
            ),

            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location (optional)',
              ),
            ),

            TextField(
              controller: _notesController,
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
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
