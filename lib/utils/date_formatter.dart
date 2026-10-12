/// Shared date/time formatting utilities used across the app.
class DateFormatter {
  DateFormatter._();

  static const List<String> _months = [
    'January', 'February', 'March', 'April',
    'May', 'June', 'July', 'August',
    'September', 'October', 'November', 'December',
  ];

  /// Returns a human-readable date string, e.g. "January 5, 2026".
  static String formatDate(DateTime date) {
    return '${_months[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Returns a short date string, e.g. "5/1/2026".
  static String formatShortDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Returns a 12-hour time string, e.g. "9:05 AM".
  static String formatTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
