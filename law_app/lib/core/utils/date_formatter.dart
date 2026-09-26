import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');

  static String formatDate(dynamic value) {
    if (value == null) return '';
    DateTime? dt;
    if (value is DateTime) {
      dt = value;
    } else if (value is String) {
      if (value.trim().isEmpty) return '';
      dt = DateTime.tryParse(value.trim());
      if (dt == null) return value; // Return raw string if not ISO parseable
    }
    if (dt == null) return '';
    return _dateFormat.format(dt.toLocal());
  }

  static String formatDateTime(dynamic value) {
    if (value == null) return '';
    DateTime? dt;
    if (value is DateTime) {
      dt = value;
    } else if (value is String) {
      if (value.trim().isEmpty) return '';
      dt = DateTime.tryParse(value.trim());
      if (dt == null) return value;
    }
    if (dt == null) return '';
    return _dateTimeFormat.format(dt.toLocal());
  }

  static String timeAgo(dynamic value) {
    if (value == null) return '';
    DateTime? dt;
    if (value is DateTime) {
      dt = value;
    } else if (value is String) {
      if (value.trim().isEmpty) return '';
      dt = DateTime.tryParse(value.trim());
    }
    if (dt == null) return '';

    final now = DateTime.now();
    final difference = now.difference(dt);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return '$mins ${mins == 1 ? 'min' : 'mins'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hr' : 'hrs'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else {
      return _dateFormat.format(dt.toLocal());
    }
  }
}
