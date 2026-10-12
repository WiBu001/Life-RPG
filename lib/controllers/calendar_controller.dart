import 'package:flutter/material.dart';

import '../models/calendar_event.dart';
import '../services/calendar_service.dart';

class CalendarController extends ChangeNotifier {
  DateTime selectedDate = DateTime.now();
  DateTime focusedDate = DateTime.now();

  List<CalendarEvent> events = [];
  bool isLoading = true;

  List<CalendarEvent> get selectedDateEvents {
    return CalendarService.getEventsForDate(
      events: events,
      selectedDate: selectedDate,
    );
  }

  // ---------- Loading and state ----------

  Future<void> loadEvents() async {
    isLoading = true;
    notifyListeners();

    try {
      events = await CalendarService.loadEvents();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void selectDate(DateTime date) {
    selectedDate = date;
    focusedDate = date;
    notifyListeners();
  }

  void goToToday() {
    selectDate(DateTime.now());
  }

  String dateKey(DateTime date) {
    return CalendarService.dateKey(date);
  }

  Future<void> updateEvents(
    List<CalendarEvent> updatedEvents,
  ) async {
    await CalendarService.saveEvents(updatedEvents);
    events = updatedEvents;
    notifyListeners();
  }

  // ---------- Create event ----------

  Future<void> addEvent({
    required String title,
    required String category,
    required String repeatType,
    required DateTime? repeatUntil,
    required DateTime startTime,
    required DateTime endTime,
    required String location,
    required String notes,
  }) async {
    final event = CalendarEvent(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title.trim(),
      category: category,
      repeatType: repeatType,
      repeatUntil: repeatUntil,
      startTime: startTime,
      endTime: endTime,
      location: location.trim(),
      notes: notes.trim(),
    );

    final updatedEvents = [...events, event];

    await updateEvents(updatedEvents);
    selectDate(startTime);
  }

  // ---------- Edit event ----------

  Future<void> editEvent({
    required CalendarEvent event,
    required String title,
    required String category,
    required DateTime startTime,
    required DateTime endTime,
    required String location,
    required String notes,
  }) async {
    final updatedEvents = [...events];

    // If this is an already-saved edited occurrence,
    // update that occurrence directly.
    final existingExceptionIndex = updatedEvents.indexWhere(
      (item) => item.id == event.id,
    );

    final parentId = event.parentEventId;

    final sourceIndex = parentId == null
        ? -1
        : updatedEvents.indexWhere(
            (item) => item.id == parentId,
          );

    if (existingExceptionIndex != -1) {
      final existing = updatedEvents[existingExceptionIndex];

      updatedEvents[existingExceptionIndex] = CalendarEvent(
        id: existing.id,
        title: title.trim(),
        category: category,
        startTime: startTime,
        endTime: endTime,
        location: location.trim(),
        notes: notes.trim(),
        repeatType: existing.repeatType,
        repeatUntil: existing.repeatUntil,
        excludedOccurrenceKeys: existing.excludedOccurrenceKeys,
        parentEventId: existing.parentEventId,
        originalOccurrenceKey: existing.originalOccurrenceKey,
      );
    } else if (sourceIndex != -1) {
      // The event is an occurrence of a recurring series.
      final source = updatedEvents[sourceIndex];

      if (source.repeatType == 'none') {
        updatedEvents[sourceIndex] = CalendarEvent(
          id: source.id,
          title: title.trim(),
          category: category,
          startTime: startTime,
          endTime: endTime,
          location: location.trim(),
          notes: notes.trim(),
        );
      } else {
        // Hide the original occurrence and save its replacement.
        final occurrenceKey =
            event.originalOccurrenceKey ?? dateKey(event.startTime);

        final exclusions = [
          ...source.excludedOccurrenceKeys,
        ];

        if (!exclusions.contains(occurrenceKey)) {
          exclusions.add(occurrenceKey);
        }

        updatedEvents[sourceIndex] = CalendarEvent(
          id: source.id,
          title: source.title,
          category: source.category,
          startTime: source.startTime,
          endTime: source.endTime,
          location: source.location,
          notes: source.notes,
          repeatType: source.repeatType,
          repeatUntil: source.repeatUntil,
          excludedOccurrenceKeys: exclusions,
        );

        updatedEvents.add(
          CalendarEvent(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            title: title.trim(),
            category: category,
            startTime: startTime,
            endTime: endTime,
            location: location.trim(),
            notes: notes.trim(),
            parentEventId: source.id,
            originalOccurrenceKey: occurrenceKey,
          ),
        );
      }
    } else if (event.parentEventId == null) {
      // A normal one-time event.
      final index = updatedEvents.indexWhere(
        (item) => item.id == event.id,
      );

      if (index == -1) {
        throw StateError('Could not find the original event.');
      }

      final source = updatedEvents[index];

      updatedEvents[index] = CalendarEvent(
        id: source.id,
        title: title.trim(),
        category: category,
        startTime: startTime,
        endTime: endTime,
        location: location.trim(),
        notes: notes.trim(),
        repeatType: source.repeatType,
        repeatUntil: source.repeatUntil,
        excludedOccurrenceKeys: source.excludedOccurrenceKeys,
      );
    } else {
      throw StateError('Could not find the original event.');
    }

    await updateEvents(updatedEvents);
    selectDate(startTime);
  }

  // ---------- Delete one occurrence ----------

  Future<void> deleteOccurrence(CalendarEvent event) async {
    final updatedEvents = [...events];

    if (event.parentEventId != null) {
      // Remove a separately saved edited occurrence.
      updatedEvents.removeWhere(
        (item) => item.id == event.id,
      );

      // Exclude the original occurrence so it does not reappear.
      final seriesIndex = updatedEvents.indexWhere(
        (item) => item.id == event.parentEventId,
      );

      if (seriesIndex != -1 &&
          event.originalOccurrenceKey != null) {
        final series = updatedEvents[seriesIndex];
        final exclusions = [...series.excludedOccurrenceKeys];
        final occurrenceKey = event.originalOccurrenceKey!;

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
      // Fallback for a recurring source event.
      final index = updatedEvents.indexWhere(
        (item) => item.id == event.id,
      );

      if (index != -1) {
        final series = updatedEvents[index];
        final occurrenceKey = dateKey(series.startTime);
        final exclusions = [...series.excludedOccurrenceKeys];

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

    await updateEvents(updatedEvents);
  }

  // ---------- Delete this and following ----------

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

    final occurrenceKey =
        event.originalOccurrenceKey ?? dateKey(event.startTime);

    final cutoff = DateTime.parse(occurrenceKey);

    final seriesStart = DateTime(
      series.startTime.year,
      series.startTime.month,
      series.startTime.day,
    );

    final deleteEntireSeries = !cutoff.isAfter(seriesStart);
    final updatedEvents = <CalendarEvent>[];

    for (final item in events) {
      if (item.id == seriesId) {
        if (deleteEntireSeries) continue;

        final lastOccurrence = cutoff.subtract(
          const Duration(days: 1),
        );

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
                    .where((key) => key.compareTo(occurrenceKey) < 0)
                    .toList(),
          ),
        );

        continue;
      }

      if (item.parentEventId == seriesId) {
        final originalKey =
            item.originalOccurrenceKey ?? dateKey(item.startTime);

        if (originalKey.compareTo(occurrenceKey) >= 0) {
          continue;
        }
      }

      updatedEvents.add(item);
    }

    await updateEvents(updatedEvents);
  }

  // ---------- Delete entire series ----------

  bool isRecurringSeries(CalendarEvent event) {
    final seriesId = event.parentEventId ?? event.id;

    final index = events.indexWhere(
      (item) => item.id == seriesId,
    );

    return index != -1 && events[index].repeatType != 'none';
  }

  Future<void> deleteAllEventsInSeries(
    CalendarEvent event,
  ) async {
    final seriesId = event.parentEventId ?? event.id;

    final updatedEvents = events.where((item) {
      return item.id != seriesId &&
          item.parentEventId != seriesId;
    }).toList();

    await updateEvents(updatedEvents);
  }
}