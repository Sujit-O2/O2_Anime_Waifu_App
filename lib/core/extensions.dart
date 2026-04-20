import 'package:flutter/material.dart';

import 'constants.dart';

// ============================================================================
// STRING EXTENSIONS
// ============================================================================

extension StringExtensions on String {
  /// Check if string is a valid email
  bool get isValidEmail {
    return RegExp(RegexPatterns.emailRegex).hasMatch(this);
  }

  /// Check if string is a valid password
  bool get isValidPassword {
    return RegExp(RegexPatterns.passwordRegex).hasMatch(this);
  }

  /// Check if string is a valid username
  bool get isValidUsername {
    return RegExp(RegexPatterns.usernameRegex).hasMatch(this);
  }

  /// Check if string is empty or whitespace only
  bool get isEmptyOrWhitespace {
    return isEmpty || trim().isEmpty;
  }

  /// Check if string has minimum length
  bool hasMinLength(int length) {
    return this.length >= length;
  }

  /// Check if string has maximum length
  bool hasMaxLength(int length) {
    return this.length <= length;
  }

  /// Capitalize first letter
  String get capitalize {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }

  /// Capitalize each word
  String get capitalizeWords {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize).join(' ');
  }

  /// Reverse string
  String get reversed {
    return split('').reversed.join('');
  }

  /// Remove special characters
  String get removeSpecialCharacters {
    return replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '');
  }

  /// Check if string contains only numbers
  bool get isNumeric {
    return RegExp(r'^[0-9]+$').hasMatch(this);
  }

  /// Remove whitespace
  String get removeWhitespace {
    return replaceAll(RegExp(r'\s+'), '');
  }

  /// Truncate string with ellipsis
  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}...';
  }

  /// Convert to title case
  String get toTitleCase {
    return split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}

// ============================================================================
// DATETIME EXTENSIONS
// ============================================================================

extension DateTimeExtensions on DateTime {
  /// Check if date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Check if date is yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Check if date is tomorrow
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year &&
        month == tomorrow.month &&
        day == tomorrow.day;
  }

  /// Get friendly date string
  String get friendlyDate {
    if (isToday) return 'Today';
    if (isYesterday) return 'Yesterday';
    if (isTomorrow) return 'Tomorrow';
    return 'MMM d, yyyy'.toString();
  }

  /// Format time only
  String get timeOnly {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  /// Format date only
  String get dateOnly {
    return '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
  }

  /// Get date with time
  String get dateWithTime {
    return '$dateOnly $timeOnly';
  }

  /// Check if date is in the past
  bool get isPast {
    return isBefore(DateTime.now());
  }

  /// Check if date is in the future
  bool get isFuture {
    return isAfter(DateTime.now());
  }

  /// Get days until this date
  int get daysUntil {
    final now = DateTime.now();
    return difference(now).inDays;
  }

  /// Get seconds since this date
  int get secondsSince {
    return DateTime.now().difference(this).inSeconds;
  }

  /// Get minutes since this date
  int get minutesSince {
    return DateTime.now().difference(this).inMinutes;
  }

  /// Get hours since this date
  int get hoursSince {
    return DateTime.now().difference(this).inHours;
  }

  /// Get days since this date
  int get daysSince {
    return DateTime.now().difference(this).inDays;
  }
}

// ============================================================================
// LIST EXTENSIONS
// ============================================================================

extension ListExtensions<T> on List<T> {
  /// Check if list is empty
  bool get isEmpty {
    return length == 0;
  }

  /// Check if list is not empty
  bool get isNotEmpty {
    return length > 0;
  }

  /// Get first element or null
  T? get firstOrNull {
    return isEmpty ? null : first;
  }

  /// Get last element or null
  T? get lastOrNull {
    return isEmpty ? null : last;
  }

  /// Clone list
  List<T> clone() {
    return List<T>.from(this);
  }

  /// Remove duplicates
  List<T> removeDuplicates() {
    return toSet().toList();
  }

  /// Chunk list into smaller lists
  List<List<T>> chunk(int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < length; i += size) {
      chunks.add(sublist(i, i + size > length ? length : i + size));
    }
    return chunks;
  }

  /// Shuffle list
  List<T> shuffled() {
    final shuffled = clone();
    shuffled.shuffle();
    return shuffled;
  }

  /// Reverse list
  List<T> reversed() {
    return toList().reversed.toList();
  }

  /// Filter list by condition
  List<T> whereCondition(bool Function(T) test) {
    return where(test).toList();
  }

  /// Check if any element matches condition
  bool anyMatch(bool Function(T) test) {
    return any(test);
  }

  /// Check if all elements match condition
  bool allMatch(bool Function(T) test) {
    return every(test);
  }

  /// Safe access by index
  T? safeAt(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }
}

// ============================================================================
// MAP EXTENSIONS
// ============================================================================

extension MapExtensions<K, V> on Map<K, V> {
  /// Get value or default
  V? getOrDefault(K key, V? defaultValue) {
    return containsKey(key) ? this[key] : defaultValue;
  }

  /// Check if map is empty
  bool get isEmpty {
    return length == 0;
  }

  /// Check if map is not empty
  bool get isNotEmpty {
    return length > 0;
  }

  /// Convert to JSON string
  String toJsonString() {
    return toString();
  }

  /// Merge with another map
  Map<K, V> merge(Map<K, V> other) {
    return {...this, ...other};
  }

  /// Filter map by keys
  Map<K, V> filterKeys(bool Function(K) test) {
    final result = <K, V>{};
    forEach((key, value) {
      if (test(key)) result[key] = value;
    });
    return result;
  }

  /// Filter map by values
  Map<K, V> filterValues(bool Function(V) test) {
    final result = <K, V>{};
    forEach((key, value) {
      if (test(value)) result[key] = value;
    });
    return result;
  }
}

// ============================================================================
// BUILDCONTEXT EXTENSIONS
// ============================================================================

extension BuildContextExtensions on BuildContext {
  /// Get screen width
  double get width {
    return MediaQuery.of(this).size.width;
  }

  /// Get screen height
  double get height {
    return MediaQuery.of(this).size.height;
  }

  /// Get screen size
  Size get screenSize {
    return MediaQuery.of(this).size;
  }

  /// Check if screen is portrait
  bool get isPortrait {
    return MediaQuery.of(this).orientation == Orientation.portrait;
  }

  /// Check if screen is landscape
  bool get isLandscape {
    return MediaQuery.of(this).orientation == Orientation.landscape;
  }

  /// Check if device is in dark mode
  bool get isDarkMode {
    return Theme.of(this).brightness == Brightness.dark;
  }

  /// Get device padding (safe area)
  EdgeInsets get devicePadding {
    return MediaQuery.of(this).padding;
  }

  /// Get device view insets (keyboard)
  EdgeInsets get viewInsets {
    return MediaQuery.of(this).viewInsets;
  }

  /// Check if keyboard is visible
  bool get isKeyboardVisible {
    return MediaQuery.of(this).viewInsets.bottom > 0;
  }

  /// Get keyboard height
  double get keyboardHeight {
    return MediaQuery.of(this).viewInsets.bottom;
  }

  /// Get device pixel ratio
  double get devicePixelRatio {
    return MediaQuery.of(this).devicePixelRatio;
  }

  /// Get app bar height
  double get appBarHeight {
    return kToolbarHeight;
  }

  /// Pop navigation
  void pop<T>([T? result]) {
    Navigator.of(this).pop(result);
  }

  /// Push to route
  Future<T?> pushNamed<T>(String routeName, {Object? arguments}) {
    return Navigator.of(this).pushNamed<T>(routeName, arguments: arguments);
  }

  /// Show snackbar
  void showSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Show error snackbar
  void showErrorSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Show success snackbar
  void showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Show dialog
  Future<T?> showAppDialog<T>(WidgetBuilder builder) {
    return showDialog<T>(
      context: this,
      builder: builder,
    );
  }
}

// ============================================================================
// DURATION EXTENSIONS
// ============================================================================

extension DurationExtensions on Duration {
  /// Format duration as mm:ss
  String get formatted {
    final minutes = inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Format duration as hh:mm:ss
  String get formattedLong {
    final hours = inHours.toString().padLeft(2, '0');
    final minutes = inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  /// Get human readable string
  String get humanReadable {
    if (inDays > 0) return '${inDays}d';
    if (inHours > 0) return '${inHours}h';
    if (inMinutes > 0) return '${inMinutes}m';
    return '${inSeconds}s';
  }
}

// ============================================================================
// DOUBLE EXTENSIONS
// ============================================================================

extension DoubleExtensions on double {
  /// Round to decimal places
  double roundToDecimals(int decimals) {
    final mod = 10.0 * decimals;
    return (this * mod).round() / mod;
  }

  /// Check if value is between two numbers
  bool isBetween(double min, double max) {
    return this >= min && this <= max;
  }
}

// ============================================================================
// INT EXTENSIONS
// ============================================================================

extension IntExtensions on int {
  /// Format as currency
  String toCurrency() {
    return '${AppearanceConstants.paddingSmall.toStringAsFixed(0)}$this';
  }

  /// Check if number is even
  bool get isEven {
    return this % 2 == 0;
  }

  /// Check if number is odd
  bool get isOdd {
    return this % 2 != 0;
  }

  /// Check if number is positive
  bool get isPositive {
    return this > 0;
  }

  /// Check if number is negative
  bool get isNegative {
    return this < 0;
  }

  /// Convert to duration
  Duration get milliseconds {
    return Duration(milliseconds: this);
  }

  /// Convert to duration (seconds)
  Duration get seconds {
    return Duration(seconds: this);
  }

  /// Convert to duration (minutes)
  Duration get minutes {
    return Duration(minutes: this);
  }

  /// Convert to duration (hours)
  Duration get hours {
    return Duration(hours: this);
  }

  /// Convert to duration (days)
  Duration get days {
    return Duration(days: this);
  }
}


