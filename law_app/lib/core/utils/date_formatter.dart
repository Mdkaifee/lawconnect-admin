class AppDateFormatter {
  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  static const List<String> _fullMonths = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  /// Parses date from dynamic input (DateTime, String, num/int)
  static DateTime? _parse(dynamic input) {
    if (input == null) return null;
    if (input is DateTime) return input;
    if (input is int) {
      // Check if milliseconds vs seconds timestamp
      return input > 100000000000
          ? DateTime.fromMillisecondsSinceEpoch(input)
          : DateTime.fromMillisecondsSinceEpoch(input * 1000);
    }
    if (input is String) {
      if (input.trim().isEmpty) return null;
      return DateTime.tryParse(input.trim());
    }
    return null;
  }

  /// Formats date to '24 Aug 2026'
  static String formatDate(dynamic input, {String defaultValue = ''}) {
    final dt = _parse(input);
    if (dt == null) {
      if (input is String && input.isNotEmpty) {
        // Return cleaned string if year only (e.g. "1973")
        return input.split('T').first;
      }
      return defaultValue;
    }
    final local = dt.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = _months[local.month - 1];
    final year = local.year;
    return '$day $month $year';
  }

  /// Formats date to '24 August 2026'
  static String formatFullDate(dynamic input, {String defaultValue = ''}) {
    final dt = _parse(input);
    if (dt == null) return defaultValue;
    final local = dt.toLocal();
    final day = local.day;
    final month = _fullMonths[local.month - 1];
    final year = local.year;
    return '$day $month $year';
  }

  /// Formats date and time to '24 Aug 2026, 05:30 PM'
  static String formatDateTime(dynamic input, {String defaultValue = ''}) {
    final dt = _parse(input);
    if (dt == null) return defaultValue;
    final local = dt.toLocal();
    final dateStr = formatDate(local);
    final hour24 = local.hour;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = hour24 >= 12 ? 'PM' : 'AM';
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    return '$dateStr, ${hour12.toString().padLeft(2, '0')}:$minute $period';
  }

  /// Formats time to '05:30 PM'
  static String formatTime(dynamic input, {String defaultValue = ''}) {
    final dt = _parse(input);
    if (dt == null) return defaultValue;
    final local = dt.toLocal();
    final hour24 = local.hour;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = hour24 >= 12 ? 'PM' : 'AM';
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    return '${hour12.toString().padLeft(2, '0')}:$minute $period';
  }

  /// Formats relative time (e.g., 'Just now', '5m ago', '2h ago', '3d ago', or '24 Aug 2026')
  static String formatRelative(dynamic input, {String defaultValue = 'Recent'}) {
    final dt = _parse(input);
    if (dt == null) return defaultValue;
    final now = DateTime.now();
    final diff = now.difference(dt.toLocal());

    if (diff.isNegative) {
      return formatDate(dt);
    }
    if (diff.inSeconds < 45) {
      return 'Just now';
    }
    if (diff.inMinutes < 60) {
      final mins = diff.inMinutes;
      return '${mins}m ago';
    }
    if (diff.inHours < 24) {
      final hours = diff.inHours;
      return '${hours}h ago';
    }
    if (diff.inDays < 7) {
      final days = diff.inDays;
      return '${days}d ago';
    }
    return formatDate(dt);
  }
}
