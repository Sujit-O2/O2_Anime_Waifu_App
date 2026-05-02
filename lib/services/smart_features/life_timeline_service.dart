import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

enum ActivityType { chat, photo, mood, task, location, event, note }

class TimelineActivity {
  final String id;
  final ActivityType type;
  final String title;
  final String? description;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  TimelineActivity({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    required this.timestamp,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'description': description,
        'timestamp': timestamp.toIso8601String(),
        'metadata': metadata,
      };

  factory TimelineActivity.fromJson(Map<String, dynamic> json) => TimelineActivity(
        id: json['id'],
        type: ActivityType.values.firstWhere((e) => e.name == json['type']),
        title: json['title'],
        description: json['description'],
        timestamp: DateTime.parse(json['timestamp']),
        metadata: json['metadata'],
      );
}

class DailyTimeline {
  final DateTime date;
  final List<TimelineActivity> activities;
  final int totalCount;
  final Map<ActivityType, int> typeCounts;

  DailyTimeline({
    required this.date,
    required this.activities,
    required this.totalCount,
    required this.typeCounts,
  });
}

class LifeTimelineService {
  static final instance = LifeTimelineService._();
  LifeTimelineService._();

  static const _storageKey = 'timeline_activities';

  Future<List<TimelineActivity>> getActivities({int? limit, DateTime? date}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return [];

    List<dynamic> decoded = jsonDecode(raw);
    var activities = decoded.map((e) => TimelineActivity.fromJson(e)).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (date != null) {
      activities = activities
          .where((a) =>
              a.timestamp.year == date.year &&
              a.timestamp.month == date.month &&
              a.timestamp.day == date.day)
          .toList();
    }

    if (limit != null && activities.length > limit) {
      activities = activities.take(limit).toList();
    }
    return activities;
  }

  Future<void> addActivity(TimelineActivity activity) async {
    final activities = await getActivities();
    activities.insert(0, activity);
    await _saveActivities(activities);
  }

  Future<void> deleteActivity(String id) async {
    final activities = await getActivities();
    activities.removeWhere((a) => a.id == id);
    await _saveActivities(activities);
  }

  Future<void> _saveActivities(List<TimelineActivity> activities) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(activities.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  Future<DailyTimeline> getDailyTimeline(DateTime date) async {
    final activities = await getActivities(date: date);
    final typeCounts = <ActivityType, int>{};
    for (final a in activities) {
      typeCounts[a.type] = (typeCounts[a.type] ?? 0) + 1;
    }
    return DailyTimeline(
      date: date,
      activities: activities,
      totalCount: activities.length,
      typeCounts: typeCounts,
    );
  }

  Future<Map<String, int>> getActivityStreak() async {
    final activities = await getActivities();
    final days = <String>{};
    for (final a in activities) {
      days.add('${a.timestamp.year}-${a.timestamp.month}-${a.timestamp.day}');
    }
    return {'totalDays': days.length};
  }

  String getTypeEmoji(ActivityType type) {
    switch (type) {
      case ActivityType.chat:
        return '💬';
      case ActivityType.photo:
        return '📸';
      case ActivityType.mood:
        return '😊';
      case ActivityType.task:
        return '✅';
      case ActivityType.location:
        return '📍';
      case ActivityType.event:
        return '📅';
      case ActivityType.note:
        return '📝';
    }
  }

  String getTypeLabel(ActivityType type) {
    switch (type) {
      case ActivityType.chat:
        return 'Chat';
      case ActivityType.photo:
        return 'Photo';
      case ActivityType.mood:
        return 'Mood';
      case ActivityType.task:
        return 'Task';
      case ActivityType.location:
        return 'Location';
      case ActivityType.event:
        return 'Event';
      case ActivityType.note:
        return 'Note';
    }
  }
}
