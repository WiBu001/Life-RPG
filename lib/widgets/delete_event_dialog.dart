import 'package:flutter/material.dart';

import '../models/calendar_event.dart';

/// The user's choice from the delete dialog.
enum DeleteEventChoice { single, following, all }

/// Shows a delete confirmation dialog.
///
/// For recurring events, presents three options (this event, this and
/// following, all events). For one-time events, shows a simple confirm dialog.
///
/// Returns the user's [DeleteEventChoice], or `null` if cancelled.
Future<DeleteEventChoice?> showDeleteEventDialog({
  required BuildContext context,
  required CalendarEvent event,
  required bool isRecurring,
}) {
  if (isRecurring) {
    return showDialog<DeleteEventChoice>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete recurring event'),
        content: const Text('Which events do you want to delete?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, DeleteEventChoice.single),
            child: const Text('This event'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, DeleteEventChoice.following),
            child: const Text('This and following events'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, DeleteEventChoice.all),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('All events'),
          ),
        ],
      ),
    );
  }

  return showDialog<DeleteEventChoice>(
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
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () =>
              Navigator.pop(dialogContext, DeleteEventChoice.single),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}
