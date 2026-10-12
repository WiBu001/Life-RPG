import 'package:flutter/material.dart';

import '../models/calendar_event.dart';
import '../utils/date_formatter.dart';

/// A read-only detail dialog for a [CalendarEvent].
///
/// [onEdit] and [onDelete] are called when the user taps the corresponding
/// action buttons; both are invoked after the dialog closes itself.
class EventDetailDialog extends StatelessWidget {
  final CalendarEvent event;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const EventDetailDialog({
    super.key,
    required this.event,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(event.title),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Category: ${event.category}'),
            const SizedBox(height: 8),
            Text('Date: ${DateFormatter.formatDate(event.startTime)}'),
            Text(
              'Time: ${DateFormatter.formatTime(event.startTime)}'
              ' - ${DateFormatter.formatTime(event.endTime)}',
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
                '${event.repeatUntil == null ? 'Never' : DateFormatter.formatDate(event.repeatUntil!)}',
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onDelete();
          },
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Delete'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onEdit();
          },
          child: const Text('Edit'),
        ),
      ],
    );
  }
}
