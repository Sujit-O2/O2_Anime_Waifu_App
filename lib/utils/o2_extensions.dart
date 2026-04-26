/// String utilities for O2-WAIFU — clean text formatting helpers.
extension O2StringExtensions on String {
  /// Capitalize the first letter: "hello world" → "Hello world"
  String get capitalized =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  /// Title case: "hello world" → "Hello World"
  String get titleCase => split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
      .join(' ');

  /// Truncate with ellipsis: "very long text" → "very lo..."
  String truncate(int maxLen, {String suffix = '...'}) {
    if (length <= maxLen) return this;
    return '${substring(0, maxLen - suffix.length)}$suffix';
  }

  /// Remove HTML tags: "<b>hello</b>" → "hello"
  String get stripHtml => replaceAll(RegExp(r'<[^>]*>'), '');

  /// Check if string is a valid email address
  bool get isValidEmail =>
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
          .hasMatch(this);

  /// Convert to URL-safe slug: "Hello World!" → "hello-world"
  String get toSlug => toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
      .replaceAll(RegExp(r'[\s]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');

  /// Smart time-ago: converts duration to human-readable "2h ago"
  static String timeAgo(DateTime from) {
    final diff = DateTime.now().difference(from);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${diff.inDays ~/ 7}w ago';
    if (diff.inDays < 365) return '${diff.inDays ~/ 30}mo ago';
    return '${diff.inDays ~/ 365}y ago';
  }

  /// Mask sensitive data: "user@email.com" → "us***@email.com"
  String get masked {
    if (length <= 4) return '****';
    return '${substring(0, 2)}${'*' * (length - 4)}${substring(length - 2)}';
  }

  /// Word count
  int get wordCount =>
      trim().isEmpty ? 0 : trim().split(RegExp(r'\s+')).length;

  /// Reading time estimate in minutes (avg 200 WPM)
  int get readingTimeMinutes => (wordCount / 200).ceil().clamp(1, 999);
}

/// DateTime extension utilities
extension O2DateTimeExtensions on DateTime {
  /// "Today", "Yesterday", or "Mon, Jan 5"
  String get friendlyDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(year, month, day);
    
    if (date == today) return 'Today';
    if (date == today.subtract(const Duration(days: 1))) return 'Yesterday';
    if (date == today.add(const Duration(days: 1))) return 'Tomorrow';
    
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return '${days[weekday - 1]}, ${months[month - 1]} $day';
  }

  /// "2:30 PM"
  String get friendlyTime {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final m = minute.toString().padLeft(2, '0');
    final ampm = hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }

  /// "Today at 2:30 PM" or "Mon, Jan 5 at 2:30 PM"
  String get friendlyFull => '$friendlyDate at $friendlyTime';
  
  /// Check if this date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }
}

/// Number formatting extensions
extension O2NumExtensions on num {
  /// Format large numbers: 1234 → "1.2K", 1234567 → "1.2M"
  String get compact {
    if (this >= 1000000) return '${(this / 1000000).toStringAsFixed(1)}M';
    if (this >= 1000) return '${(this / 1000).toStringAsFixed(1)}K';
    return toStringAsFixed(0);
  }

  /// Format as currency: 1234.5 → "₹1,234.50"
  String get asCurrency {
    final parts = toStringAsFixed(2).split('.');
    final integer = parts[0];
    final decimal = parts[1];
    // Add commas (Indian style: 1,23,456)
    final chars = integer.replaceAll('-', '').split('').reversed.toList();
    final formatted = <String>[];
    for (int i = 0; i < chars.length; i++) {
      if (i == 3 || (i > 3 && (i - 3) % 2 == 0)) {
        formatted.add(',');
      }
      formatted.add(chars[i]);
    }
    final sign = this < 0 ? '-' : '';
    return '$sign₹${formatted.reversed.join()}.$decimal';
  }

  /// Duration formatting: 125 → "2h 5m"
  String get asDuration {
    final totalMin = toInt();
    if (totalMin < 60) return '${totalMin}m';
    final h = totalMin ~/ 60;
    final m = totalMin % 60;
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }
}
