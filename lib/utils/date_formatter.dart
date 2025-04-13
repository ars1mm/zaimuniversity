import 'package:intl/intl.dart';

class DateFormatter {
  /// Formats a DateTime object to "Month Day, Year" format (e.g., April 14, 2025)
  static String formatFullDate(DateTime date) {
    return DateFormat('MMMM d, y').format(date);
  }

  /// Formats a DateTime object to "MM/dd/yyyy" format (e.g., 04/14/2025)
  static String formatShortDate(DateTime date) {
    return DateFormat('MM/dd/yyyy').format(date);
  }

  /// Formats a DateTime object to display time in 24-hour format (e.g., 14:30)
  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  /// Formats a DateTime object to display date and time (e.g., Apr 14, 2025 - 14:30)
  static String formatDateAndTime(DateTime date) {
    return DateFormat('MMM d, y - HH:mm').format(date);
  }

  /// Returns a relative time description (e.g., "2 hours ago", "Yesterday", "3 days ago")
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return "${(difference.inDays / 365).floor()} ${(difference.inDays / 365).floor() == 1 ? 'year' : 'years'} ago";
    }
    if (difference.inDays > 30) {
      return "${(difference.inDays / 30).floor()} ${(difference.inDays / 30).floor() == 1 ? 'month' : 'months'} ago";
    }
    if (difference.inDays > 0) {
      return difference.inDays == 1
          ? "Yesterday"
          : "${difference.inDays} days ago";
    }
    if (difference.inHours > 0) {
      return "${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago";
    }
    if (difference.inMinutes > 0) {
      return "${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago";
    }

    return "Just now";
  }
}
