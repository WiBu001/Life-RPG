
class CalendarEvent {
  final String id;
  final String title;
  final String category;
  final DateTime startTime;
  final DateTime endTime;
  final String location;
  final String notes;

  // Recurrence settings
  final String repeatType;
  final DateTime? repeatUntil;

  // Occurrences excluded from the recurring series
  final List<String> excludedOccurrenceKeys;

  // Used when an individual occurrence is edited
  final String? parentEventId;
  final String? originalOccurrenceKey;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.category,
    required this.startTime,
    required this.endTime,
    this.location = '',
    this.notes = '',
    this.repeatType = 'none',
    this.repeatUntil,
    List<String>? excludedOccurrenceKeys,
    this.parentEventId,
    this.originalOccurrenceKey,
  }) : excludedOccurrenceKeys = excludedOccurrenceKeys ?? [];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'location': location,
      'notes': notes,
      'repeatType': repeatType,
      'repeatUntil': repeatUntil?.toIso8601String(),
      'excludedOccurrenceKeys': excludedOccurrenceKeys,
      'parentEventId': parentEventId,
      'originalOccurrenceKey': originalOccurrenceKey,
    };
  }

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String? ?? 'Personal',
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      location: json['location'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      repeatType: json['repeatType'] as String? ?? 'none',
      repeatUntil: json['repeatUntil'] == null
          ? null
          : DateTime.parse(json['repeatUntil'] as String),
      excludedOccurrenceKeys:
          List<String>.from(json['excludedOccurrenceKeys'] as List? ?? []),
      parentEventId: json['parentEventId'] as String?,
      originalOccurrenceKey: json['originalOccurrenceKey'] as String?,
    );
  }
}
