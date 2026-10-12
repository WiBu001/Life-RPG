import '../models/calendar_event.dart';
import 'storage_service.dart';

class CalendarService {
  /// Converts a date to a stable YYYY-MM-DD key.
  static String dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  /// Returns the events that occur on the selected date.
  ///
  /// Recurring events are converted into individual occurrences.
  /// Stored edited occurrences are included on their actual event date.
  static List<CalendarEvent> getEventsForDate({
    required List<CalendarEvent> events,
    required DateTime selectedDate,
  }) {
    final result = <CalendarEvent>[];

    final selectedDay = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );

    for (final event in events) {
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

      // Individually edited occurrences are stored as separate events.
      if (event.parentEventId != null) {
        if (startDay == selectedDay) {
          result.add(event);
        }

        continue;
      }

      if (selectedDay.isBefore(startDay)) continue;

      if (endRepeatDay != null &&
          selectedDay.isAfter(endRepeatDay)) {
        continue;
      }

      final bool occursOnSelectedDay;

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

      final occurrenceKey = dateKey(selectedDay);

      if (event.excludedOccurrenceKeys.contains(occurrenceKey)) {
        continue;
      }

      final duration = event.endTime.difference(event.startTime);

      final occurrenceStart = DateTime(
        selectedDay.year,
        selectedDay.month,
        selectedDay.day,
        event.startTime.hour,
        event.startTime.minute,
      );

      result.add(
        CalendarEvent(
          id: '${event.id}_$occurrenceKey',
          title: event.title,
          category: event.category,
          startTime: occurrenceStart,
          endTime: occurrenceStart.add(duration),
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

    result.sort(
      (a, b) => a.startTime.compareTo(b.startTime),
    );

    return result;
  }

  static Future<List<CalendarEvent>> loadEvents() async {
    return await StorageService.loadCalendarEvents() ?? [];
  }

  static Future<void> saveEvents(List<CalendarEvent> events) async {
    await StorageService.saveCalendarEvents(events);
  }
}