import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 💕 Long-Distance Relationship Tools Service
/// 
/// Shared activities, virtual date ideas, time zone coordination.
class LongDistanceRelationshipService {
  LongDistanceRelationshipService._();
  static final LongDistanceRelationshipService instance = LongDistanceRelationshipService._();

  final List<VirtualDate> _virtualDates = [];
  final List<SharedActivity> _sharedActivities = [];
  final List<TimezoneCoordination> _timezoneCoords = [];
  
  int _totalDates = 0;
  int _completedDates = 0;
  
  static const String _storageKey = 'ldr_tools_v1';
  static const int _maxDates = 200;

  Future<void> initialize() async {
    await _loadData();
    if (kDebugMode) debugPrint('[LDRTools] Initialized with $_totalDates virtual dates');
  }

  Future<VirtualDate> scheduleVirtualDate({
    required String title,
    required String partnerName,
    required DateTime scheduledTime,
    required String timezone1,
    required String timezone2,
    required VirtualDateType type,
    required List<String> activities,
    required String platform,
  }) async {
    final date = VirtualDate(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      partnerName: partnerName,
      scheduledTime: scheduledTime,
      timezone1: timezone1,
      timezone2: timezone2,
      type: type,
      activities: activities,
      platform: platform,
      status: VirtualDateStatus.scheduled,
      notes: '',
      rating: 0,
      createdAt: DateTime.now(),
    );
    
    _virtualDates.insert(0, date);
    _totalDates++;
    
    // Create timezone coordination
    await _createTimezoneCoordination(date);
    
    await _saveData();
    
    if (kDebugMode) debugPrint('[LDRTools] Scheduled virtual date: $title');
    return date;
  }

  Future<void> _createTimezoneCoordination(VirtualDate date) async {
    final coord = TimezoneCoordination(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      dateId: date.id,
      partner1Timezone: date.timezone1,
      partner2Timezone: date.timezone2,
      scheduledTime: date.scheduledTime,
      partner1LocalTime: date.scheduledTime, // Simplified - would convert in real app
      partner2LocalTime: date.scheduledTime, // Simplified - would convert in real app
      reminderSet: false,
      createdAt: DateTime.now(),
    );
    
    _timezoneCoords.insert(0, coord);
  }

  Future<void> completeVirtualDate(String dateId, int rating, String notes) async {
    final dateIndex = _virtualDates.indexWhere((d) => d.id == dateId);
    if (dateIndex == -1) return;
    
    final date = _virtualDates[dateIndex];
    _virtualDates[dateIndex] = date.copyWith(
      status: VirtualDateStatus.completed,
      rating: rating,
      notes: notes,
      completedAt: DateTime.now(),
    );
    
    _completedDates++;
    
    await _saveData();
    
    if (kDebugMode) debugPrint('[LDRTools] Completed virtual date: $dateId');
  }

  Future<SharedActivity> createSharedActivity({
    required String title,
    required String description,
    required ActivityType type,
    required List<String> participants,
    required String schedule,
    required String platform,
  }) async {
    final activity = SharedActivity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      type: type,
      participants: participants,
      schedule: schedule,
      platform: platform,
      status: ActivityStatus.active,
      progress: 0,
      notes: '',
      createdAt: DateTime.now(),
    );
    
    _sharedActivities.insert(0, activity);
    
    await _saveData();
    
    if (kDebugMode) debugPrint('[LDRTools] Created shared activity: $title');
    return activity;
  }

  Future<void> updateActivityProgress(String activityId, int progress) async {
    final activityIndex = _sharedActivities.indexWhere((a) => a.id == activityId);
    if (activityIndex == -1) return;
    
    final activity = _sharedActivities[activityIndex];
    _sharedActivities[activityIndex] = activity.copyWith(
      progress: progress.clamp(0, 100),
      status: progress >= 100 ? ActivityStatus.completed : ActivityStatus.active,
    );
    
    await _saveData();
  }

  Future<void> addActivityNote(String activityId, String note) async {
    final activityIndex = _sharedActivities.indexWhere((a) => a.id == activityId);
    if (activityIndex == -1) return;
    
    final activity = _sharedActivities[activityIndex];
    _sharedActivities[activityIndex] = activity.copyWith(
      notes: activity.notes.isNotEmpty ? '${activity.notes}\n$note' : note,
    );
    
    await _saveData();
  }

  List<VirtualDate> getUpcomingDates({int days = 30}) {
    final now = DateTime.now();
    final future = now.add(Duration(days: days));
    return _virtualDates.where((d) => 
      d.scheduledTime.isAfter(now) && 
      d.scheduledTime.isBefore(future) &&
      d.status == VirtualDateStatus.scheduled
    ).toList();
  }

  List<VirtualDate> getPastDates({int limit = 10}) {
    return _virtualDates
        .where((d) => d.status == VirtualDateStatus.completed)
        .take(limit)
        .toList();
  }

  List<VirtualDate> getDatesByType(VirtualDateType type) {
    return _virtualDates.where((d) => d.type == type).toList();
  }

  List<SharedActivity> getActiveActivities() {
    return _sharedActivities.where((a) => a.status == ActivityStatus.active).toList();
  }

  List<SharedActivity> getCompletedActivities() {
    return _sharedActivities.where((a) => a.status == ActivityStatus.completed).toList();
  }

  String getVirtualDateIdeas() {
    final ideas = [
      '🎬 Movie Night: Watch the same movie simultaneously and discuss',
      '🎮 Gaming Session: Play online games together',
      '🍳 Virtual Cooking: Cook the same recipe while video chatting',
      '📚 Book Club: Read the same book and discuss chapters',
      '🎵 Music Date: Create a shared playlist and listen together',
      '🎨 Art Session: Draw or paint together on a shared canvas',
      '🧘 Meditation: Practice guided meditation together',
      '🎲 Game Night: Play board games or card games online',
      '🌍 Virtual Travel: Explore cities together using Google Earth',
      '📝 Writing Session: Write letters or stories together',
      '🎤 Karaoke Night: Sing your favorite songs together',
      '📸 Photo Sharing: Share and discuss recent photos',
      '💪 Workout Together: Exercise simultaneously while video chatting',
      '🧩 Puzzle Time: Work on digital puzzles together',
      '🌟 Stargazing: Look at the night sky "together"',
    ];
    
    return '💕 Virtual Date Ideas:\n' + ideas.join('\n');
  }

  String getLongDistanceTips() {
    final tips = [
      '💬 Communicate regularly but don\'t force it',
      '🎯 Set shared goals and plan visits',
      '📅 Schedule regular virtual dates',
      '🎁 Send surprise gifts or letters',
      '📱 Share your daily life through photos',
      '🕊️ Trust is the foundation of LDR',
      '🎵 Create shared playlists',
      '📚 Read the same books',
      '🎬 Watch shows together',
      '🌍 Plan your next visit',
      '💕 Keep the romance alive',
      '🙏 Be patient and understanding',
      '🎨 Share your creative projects',
      '🏆 Celebrate milestones together',
      '🤗 Send virtual hugs often',
    ];
    
    return '💡 Long-Distance Relationship Tips:\n' + tips.join('\n');
  }

  String getTimezoneHelp(String timezone1, String timezone2) {
    return '''
🌍 Time Zone Coordination Help

Partner 1: $timezone1
Partner 2: $timezone2

💡 Tips:
• Use world clock apps to track each other's time
• Find overlapping "golden hours" for calls
• Be mindful of sleep schedules
• Plan dates during both partners' daytime when possible
• Set reminders for important times
• Consider rotating meeting times to share the inconvenience

📱 Tools:
• World Clock widgets
• Time zone converter websites
• Calendar apps with time zone support
• Scheduling tools like Calendly
'''.trim();
  }

  String getLDRInsights() {
    if (_virtualDates.isEmpty) {
      return 'No virtual dates scheduled yet. Start planning special moments!';
    }
    
    final upcoming = getUpcomingDates().length;
    final completed = getPastDates().length;
    final avgRating = completed > 0 
        ? getPastDates(limit: completed).fold<double>(0, (sum, d) => sum + d.rating) / completed
        : 0;
    
    final byType = <VirtualDateType, int>{};
    for (final date in _virtualDates) {
      byType[date.type] = (byType[date.type] ?? 0) + 1;
    }
    
    final activeActivities = getActiveActivities().length;
    const completedActivities = 0; // Would calculate from completed activities
    
    final buffer = StringBuffer();
    buffer.writeln('💕 Long-Distance Relationship Insights:');
    buffer.writeln('• Virtual Dates Scheduled: $_totalDates');
    buffer.writeln('• Completed Dates: $completed');
    buffer.writeln('• Upcoming Dates: $upcoming');
    if (completed > 0) {
      buffer.writeln('• Average Date Rating: ${avgRating.toStringAsFixed(1)}/5');
    }
    buffer.writeln('• Active Shared Activities: $activeActivities');
    buffer.writeln('• Completed Activities: $completedActivities');
    buffer.writeln('');
    buffer.writeln('Dates by Type:');
    for (final entry in byType.entries) {
      buffer.writeln('  • ${entry.key.label}: ${entry.value}');
    }
    
    if (upcoming == 0) {
      buffer.writeln('');
      buffer.writeln('💡 Schedule a virtual date to keep the connection strong!');
    }
    
    return buffer.toString();
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'virtualDates': _virtualDates.take(50).map((d) => d.toJson()).toList(),
        'sharedActivities': _sharedActivities.take(50).map((a) => a.toJson()).toList(),
        'timezoneCoords': _timezoneCoords.take(50).map((c) => c.toJson()).toList(),
        'totalDates': _totalDates,
        'completedDates': _completedDates,
      };
      await prefs.setString(_storageKey, jsonEncode(data));
    } catch (e) {
      if (kDebugMode) debugPrint('[LDRTools] Save error: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      
      if (jsonString != null && jsonString.isNotEmpty) {
        final data = jsonDecode(jsonString) as Map<String, dynamic>;
        
        _virtualDates.clear();
        _virtualDates.addAll(
          (data['virtualDates'] as List<dynamic>)
              .map((d) => VirtualDate.fromJson(d as Map<String, dynamic>))
        );
        
        _sharedActivities.clear();
        _sharedActivities.addAll(
          (data['sharedActivities'] as List<dynamic>)
              .map((a) => SharedActivity.fromJson(a as Map<String, dynamic>))
        );
        
        _timezoneCoords.clear();
        if (data['timezoneCoords'] != null) {
          _timezoneCoords.addAll(
            (data['timezoneCoords'] as List<dynamic>)
                .map((c) => TimezoneCoordination.fromJson(c as Map<String, dynamic>))
          );
        }
        
        _totalDates = data['totalDates'] as int;
        _completedDates = data['completedDates'] as int;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[LDRTools] Load error: $e');
    }
  }
}

class VirtualDate {
  final String id;
  final String title;
  final String partnerName;
  final DateTime scheduledTime;
  final String timezone1;
  final String timezone2;
  final VirtualDateType type;
  final List<String> activities;
  final String platform;
  VirtualDateStatus status;
  final String notes;
  final int rating;
  DateTime? completedAt;
  final DateTime createdAt;

  VirtualDate({
    required this.id,
    required this.title,
    required this.partnerName,
    required this.scheduledTime,
    required this.timezone1,
    required this.timezone2,
    required this.type,
    required this.activities,
    required this.platform,
    required this.status,
    required this.notes,
    required this.rating,
    this.completedAt,
    required this.createdAt,
  });

  VirtualDate copyWith({
    VirtualDateStatus? status,
    int? rating,
    String? notes,
    DateTime? completedAt,
  }) {
    return VirtualDate(
      id: id,
      title: title,
      partnerName: partnerName,
      scheduledTime: scheduledTime,
      timezone1: timezone1,
      timezone2: timezone2,
      type: type,
      activities: activities,
      platform: platform,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      rating: rating ?? this.rating,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'partnerName': partnerName,
    'scheduledTime': scheduledTime.toIso8601String(),
    'timezone1': timezone1,
    'timezone2': timezone2,
    'type': type.name,
    'activities': activities,
    'platform': platform,
    'status': status.name,
    'notes': notes,
    'rating': rating,
    'completedAt': completedAt?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory VirtualDate.fromJson(Map<String, dynamic> json) => VirtualDate(
    id: json['id'],
    title: json['title'],
    partnerName: json['partnerName'],
    scheduledTime: DateTime.parse(json['scheduledTime']),
    timezone1: json['timezone1'],
    timezone2: json['timezone2'],
    type: VirtualDateType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => VirtualDateType.videoChat,
    ),
    activities: List<String>.from(json['activities'] ?? []),
    platform: json['platform'],
    status: VirtualDateStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => VirtualDateStatus.scheduled,
    ),
    notes: json['notes'] ?? '',
    rating: json['rating'] ?? 0,
    completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
    createdAt: DateTime.parse(json['createdAt']),
  );
}

class SharedActivity {
  final String id;
  final String title;
  final String description;
  final ActivityType type;
  final List<String> participants;
  final String schedule;
  final String platform;
  ActivityStatus status;
  final int progress;
  final String notes;
  final DateTime createdAt;

  SharedActivity({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.participants,
    required this.schedule,
    required this.platform,
    required this.status,
    required this.progress,
    required this.notes,
    required this.createdAt,
  });

  SharedActivity copyWith({
    ActivityStatus? status,
    int? progress,
    String? notes,
  }) {
    return SharedActivity(
      id: id,
      title: title,
      description: description,
      type: type,
      participants: participants,
      schedule: schedule,
      platform: platform,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'type': type.name,
    'participants': participants,
    'schedule': schedule,
    'platform': platform,
    'status': status.name,
    'progress': progress,
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
  };

  factory SharedActivity.fromJson(Map<String, dynamic> json) => SharedActivity(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    type: ActivityType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => ActivityType.other,
    ),
    participants: List<String>.from(json['participants'] ?? []),
    schedule: json['schedule'],
    platform: json['platform'],
    status: ActivityStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => ActivityStatus.active,
    ),
    progress: json['progress'] ?? 0,
    notes: json['notes'] ?? '',
    createdAt: DateTime.parse(json['createdAt']),
  );
}

class TimezoneCoordination {
  final String id;
  final String dateId;
  final String partner1Timezone;
  final String partner2Timezone;
  final DateTime scheduledTime;
  final DateTime partner1LocalTime;
  final DateTime partner2LocalTime;
  bool reminderSet;
  final DateTime createdAt;

  TimezoneCoordination({
    required this.id,
    required this.dateId,
    required this.partner1Timezone,
    required this.partner2Timezone,
    required this.scheduledTime,
    required this.partner1LocalTime,
    required this.partner2LocalTime,
    required this.reminderSet,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'dateId': dateId,
    'partner1Timezone': partner1Timezone,
    'partner2Timezone': partner2Timezone,
    'scheduledTime': scheduledTime.toIso8601String(),
    'partner1LocalTime': partner1LocalTime.toIso8601String(),
    'partner2LocalTime': partner2LocalTime.toIso8601String(),
    'reminderSet': reminderSet,
    'createdAt': createdAt.toIso8601String(),
  };

  factory TimezoneCoordination.fromJson(Map<String, dynamic> json) => TimezoneCoordination(
    id: json['id'],
    dateId: json['dateId'],
    partner1Timezone: json['partner1Timezone'],
    partner2Timezone: json['partner2Timezone'],
    scheduledTime: DateTime.parse(json['scheduledTime']),
    partner1LocalTime: DateTime.parse(json['partner1LocalTime']),
    partner2LocalTime: DateTime.parse(json['partner2LocalTime']),
    reminderSet: json['reminderSet'] ?? false,
    createdAt: DateTime.parse(json['createdAt']),
  );
}

enum VirtualDateType {
  videoChat('Video Chat'),
  movieNight('Movie Night'),
  gaming('Gaming Session'),
  cooking('Virtual Cooking'),
  reading('Book Club'),
  music('Music Date'),
  art('Art Session'),
  meditation('Meditation'),
  games('Game Night'),
  travel('Virtual Travel'),
  writing('Writing Session'),
  karaoke('Karaoke'),
  photoSharing('Photo Sharing'),
  workout('Workout Together'),
  puzzle('Puzzle Time'),
  stargazing('Stargazing');
  
  final String label;
  const VirtualDateType(this.label);
}

enum VirtualDateStatus { scheduled, completed, cancelled }

enum ActivityType {
  reading('Reading'),
  gaming('Gaming'),
  fitness('Fitness'),
  learning('Learning'),
  creative('Creative'),
  music('Music'),
  cooking('Cooking'),
  meditation('Meditation'),
  other('Other');
  
  final String label;
  const ActivityType(this.label);
}

enum ActivityStatus { active, completed, paused, cancelled }