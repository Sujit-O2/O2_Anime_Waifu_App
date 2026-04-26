import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🤝 Meeting Intelligence Service
///
/// Auto-summarize meetings, extract action items, and follow up on commitments.
class MeetingIntelligenceService {
  MeetingIntelligenceService._();
  static final MeetingIntelligenceService instance =
      MeetingIntelligenceService._();

  final List<Meeting> _meetings = [];
  final List<ActionItem> _actionItems = [];

  int _totalMeetings = 0;
  int _totalActionItems = 0;
  int _completedActionItems = 0;

  static const String _storageKey = 'meeting_intelligence_v1';

  Future<void> initialize() async {
    await _loadData();
    if (kDebugMode)
      debugPrint(
          '[MeetingIntelligence] Initialized with $_totalMeetings meetings');
  }

  Future<Meeting> createMeeting({
    required String title,
    required String participants,
    required DateTime startTime,
    required DateTime endTime,
    required MeetingType type,
  }) async {
    final meeting = Meeting(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      participants: participants,
      startTime: startTime,
      endTime: endTime,
      type: type,
      status: MeetingStatus.scheduled,
      summary: '',
      keyPoints: [],
      decisions: [],
      createdAt: DateTime.now(),
    );

    _meetings.insert(0, meeting);
    _totalMeetings++;

    await _saveData();

    if (kDebugMode) debugPrint('[MeetingIntelligence] Created meeting: $title');
    return meeting;
  }

  Future<void> recordMeetingTranscript({
    required String meetingId,
    required String transcript,
  }) async {
    final meetingIndex = _meetings.indexWhere((m) => m.id == meetingId);
    if (meetingIndex == -1) return;

    final meeting = _meetings[meetingIndex];
    _meetings[meetingIndex] = meeting.copyWith(
      transcript: transcript,
      status: MeetingStatus.recorded,
    );

    await _saveData();

    if (kDebugMode)
      debugPrint(
          '[MeetingIntelligence] Transcript recorded for: ${meeting.title}');
  }

  Future<MeetingSummary> generateMeetingSummary(String meetingId) async {
    final meetingIndex = _meetings.indexWhere((m) => m.id == meetingId);
    if (meetingIndex == -1) {
      return MeetingSummary(
        meetingId: meetingId,
        summary: 'Meeting not found',
        keyPoints: [],
        decisions: [],
        actionItems: [],
        sentiment: 'neutral',
        topics: [],
      );
    }

    final meeting = _meetings[meetingIndex];

    // Simulate AI summary generation
    final summary = _generateAISummary(meeting);
    final keyPoints = _extractKeyPoints(meeting);
    final decisions = _extractDecisions(meeting);
    final actionItems = _extractActionItems(meeting);
    final sentiment = _analyzeSentiment(meeting);
    final topics = _extractTopics(meeting);

    final meetingSummary = MeetingSummary(
      meetingId: meetingId,
      summary: summary,
      keyPoints: keyPoints,
      decisions: decisions,
      actionItems: actionItems,
      sentiment: sentiment,
      topics: topics,
    );

    // Update meeting with summary
    _meetings[meetingIndex] = meeting.copyWith(
      summary: summary,
      keyPoints: keyPoints,
      decisions: decisions,
      status: MeetingStatus.summarized,
    );

    // Create action items
    for (final actionText in actionItems) {
      await _createActionItem(meetingId, actionText);
    }

    await _saveData();

    if (kDebugMode)
      debugPrint(
          '[MeetingIntelligence] Summary generated for: ${meeting.title}');

    return meetingSummary;
  }

  String _generateAISummary(Meeting meeting) {
    if (meeting.transcript?.isEmpty ?? true) {
      return 'No transcript available for this meeting.';
    }

    final lines = meeting.transcript!.split('\n');
    final wordCount = meeting.transcript!.split(' ').length;

    final buffer = StringBuffer();
    buffer.writeln('Meeting Summary: ${meeting.title}');
    buffer.writeln('');
    buffer.writeln(
        'Duration: ${meeting.endTime.difference(meeting.startTime).inMinutes} minutes');
    buffer.writeln('Participants: ${meeting.participants}');
    buffer.writeln('');
    buffer.writeln('Overview:');
    buffer.writeln(
        'This meeting covered ${lines.length} main topics with approximately $wordCount words exchanged.');
    buffer
        .writeln('The discussion focused on key objectives and deliverables.');
    buffer.writeln('');
    buffer.writeln('Next Steps:');
    buffer.writeln(
        'Action items have been identified and assigned to relevant participants.');
    buffer
        .writeln('Follow-up meeting recommended in 1 week to review progress.');

    return buffer.toString();
  }

  List<String> _extractKeyPoints(Meeting meeting) {
    if (meeting.transcript?.isEmpty ?? true) return [];

    final points = <String>[];
    final lines = meeting.transcript!.split('\n');

    // Extract lines that seem important (contain keywords)
    final importantKeywords = [
      'important',
      'key',
      'critical',
      'must',
      'need',
      'require',
      'decide',
      'agree'
    ];

    for (final line in lines) {
      if (importantKeywords.any((kw) => line.toLowerCase().contains(kw))) {
        final cleanLine = line.trim();
        if (cleanLine.length > 20 && cleanLine.length < 200) {
          points.add(cleanLine);
        }
      }
    }

    return points.take(5).toList();
  }

  List<String> _extractDecisions(Meeting meeting) {
    if (meeting.transcript?.isEmpty ?? true) return [];

    final decisions = <String>[];
    final lines = meeting.transcript!.split('\n');

    final decisionKeywords = [
      'decided',
      'agree',
      'approved',
      'will',
      'shall',
      'resolved'
    ];

    for (final line in lines) {
      if (decisionKeywords.any((kw) => line.toLowerCase().contains(kw))) {
        final cleanLine = line.trim();
        if (cleanLine.length > 10) {
          decisions.add(cleanLine);
        }
      }
    }

    return decisions.take(5).toList();
  }

  List<String> _extractActionItems(Meeting meeting) {
    if (meeting.transcript?.isEmpty ?? true) return [];

    final items = <String>[];
    final lines = meeting.transcript!.split('\n');

    final actionKeywords = [
      'need to',
      'should',
      'must',
      'will do',
      'action item',
      'todo',
      'task'
    ];

    for (final line in lines) {
      if (actionKeywords.any((kw) => line.toLowerCase().contains(kw))) {
        final cleanLine = line.trim();
        if (cleanLine.length > 10 && cleanLine.length < 300) {
          items.add(cleanLine);
        }
      }
    }

    return items.take(10).toList();
  }

  String _analyzeSentiment(Meeting meeting) {
    if (meeting.transcript?.isEmpty ?? true) return 'neutral';

    final text = meeting.transcript!.toLowerCase();

    final positiveWords = [
      'good',
      'great',
      'excellent',
      'happy',
      'satisfied',
      'success',
      'achieve',
      'positive'
    ];
    final negativeWords = [
      'bad',
      'problem',
      'issue',
      'concern',
      'difficult',
      'challenge',
      'delay',
      'negative'
    ];

    final positiveCount = positiveWords.where((w) => text.contains(w)).length;
    final negativeCount = negativeWords.where((w) => text.contains(w)).length;

    if (positiveCount > negativeCount) return 'positive';
    if (negativeCount > positiveCount) return 'negative';
    return 'neutral';
  }

  List<String> _extractTopics(Meeting meeting) {
    if (meeting.transcript?.isEmpty ?? true) return [];

    final topics = <String>[];
    final text = meeting.transcript!.toLowerCase();

    final commonTopics = [
      'budget',
      'timeline',
      'resources',
      'planning',
      'development',
      'marketing',
      'sales',
      'customer',
      'product',
      'strategy',
      'team',
      'hiring',
      'training',
      'process',
      'quality',
    ];

    for (final topic in commonTopics) {
      if (text.contains(topic)) {
        topics.add(topic);
      }
    }

    return topics.take(5).toList();
  }

  Future<ActionItem> _createActionItem(
      String meetingId, String description) async {
    final actionItem = ActionItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      meetingId: meetingId,
      description: description,
      assignedTo: 'Unassigned',
      dueDate: DateTime.now().add(const Duration(days: 7)),
      priority: ActionPriority.medium,
      status: ActionStatus.pending,
      createdAt: DateTime.now(),
    );

    _actionItems.insert(0, actionItem);
    _totalActionItems++;

    return actionItem;
  }

  Future<void> updateActionItemStatus(
      String actionItemId, ActionStatus status) async {
    final itemIndex = _actionItems.indexWhere((a) => a.id == actionItemId);
    if (itemIndex == -1) return;

    final item = _actionItems[itemIndex];
    _actionItems[itemIndex] = item.copyWith(status: status);

    if (status == ActionStatus.completed) {
      _completedActionItems++;
    }

    await _saveData();

    if (kDebugMode)
      debugPrint('[MeetingIntelligence] Action item updated: $actionItemId');
  }

  Future<void> assignActionItem(String actionItemId, String assignee) async {
    final itemIndex = _actionItems.indexWhere((a) => a.id == actionItemId);
    if (itemIndex == -1) return;

    final item = _actionItems[itemIndex];
    _actionItems[itemIndex] = item.copyWith(assignedTo: assignee);

    await _saveData();
  }

  Future<void> scheduleFollowUp({
    required String meetingId,
    required DateTime followUpDate,
    required String notes,
  }) async {
    final meetingIndex = _meetings.indexWhere((m) => m.id == meetingId);
    if (meetingIndex == -1) return;

    final meeting = _meetings[meetingIndex];
    _meetings[meetingIndex] = meeting.copyWith(
      followUpDate: followUpDate,
      followUpNotes: notes,
    );

    await _saveData();

    if (kDebugMode)
      debugPrint(
          '[MeetingIntelligence] Follow-up scheduled for: ${meeting.title}');
  }

  List<Meeting> getMeetingsByDateRange(DateTime start, DateTime end) {
    return _meetings
        .where((m) => m.startTime.isAfter(start) && m.startTime.isBefore(end))
        .toList();
  }

  List<ActionItem> getPendingActionItems() {
    return _actionItems.where((a) => a.status == ActionStatus.pending).toList();
  }

  List<ActionItem> getOverdueActionItems() {
    final now = DateTime.now();
    return _actionItems
        .where(
            (a) => a.status == ActionStatus.pending && a.dueDate.isBefore(now))
        .toList();
  }

  String getMeetingInsights() {
    if (_meetings.isEmpty) {
      return 'No meetings recorded yet.';
    }

    final completedMeetings =
        _meetings.where((m) => m.status == MeetingStatus.completed).length;
    final pendingActionItems = getPendingActionItems().length;
    final overdueActionItems = getOverdueActionItems().length;

    final buffer = StringBuffer();
    buffer.writeln('📅 Meeting Insights:');
    buffer.writeln('• Total Meetings: $_totalMeetings');
    buffer.writeln('• Completed: $completedMeetings');
    buffer.writeln('• Action Items: $_totalActionItems');
    buffer.writeln('• Completed Actions: $_completedActionItems');
    buffer.writeln('• Pending Actions: $pendingActionItems');

    if (overdueActionItems > 0) {
      buffer.writeln('\n⚠️ $overdueActionItems overdue action items!');
    }

    return buffer.toString();
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'meetings': _meetings.take(50).map((m) => m.toJson()).toList(),
        'actionItems': _actionItems.take(100).map((a) => a.toJson()).toList(),
        'totalMeetings': _totalMeetings,
        'totalActionItems': _totalActionItems,
        'completedActionItems': _completedActionItems,
      };
      await prefs.setString(_storageKey, jsonEncode(data));
    } catch (e) {
      if (kDebugMode) debugPrint('[MeetingIntelligence] Save error: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString != null && jsonString.isNotEmpty) {
        final data = jsonDecode(jsonString) as Map<String, dynamic>;

        _meetings.clear();
        _meetings.addAll((data['meetings'] as List<dynamic>)
            .map((m) => Meeting.fromJson(m as Map<String, dynamic>)));

        _actionItems.clear();
        _actionItems.addAll((data['actionItems'] as List<dynamic>)
            .map((a) => ActionItem.fromJson(a as Map<String, dynamic>)));

        _totalMeetings = data['totalMeetings'] as int;
        _totalActionItems = data['totalActionItems'] as int;
        _completedActionItems = data['completedActionItems'] as int;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[MeetingIntelligence] Load error: $e');
    }
  }
}

class Meeting {
  final String id;
  final String title;
  final String participants;
  final DateTime startTime;
  final DateTime endTime;
  final MeetingType type;
  MeetingStatus status;
  String summary;
  final List<String> keyPoints;
  final List<String> decisions;
  String? transcript;
  DateTime? followUpDate;
  String? followUpNotes;
  final DateTime createdAt;

  Meeting({
    required this.id,
    required this.title,
    required this.participants,
    required this.startTime,
    required this.endTime,
    required this.type,
    required this.status,
    required this.summary,
    required this.keyPoints,
    required this.decisions,
    this.transcript,
    this.followUpDate,
    this.followUpNotes,
    required this.createdAt,
  });

  Meeting copyWith({
    MeetingStatus? status,
    String? summary,
    List<String>? keyPoints,
    List<String>? decisions,
    String? transcript,
    DateTime? followUpDate,
    String? followUpNotes,
  }) {
    return Meeting(
      id: id,
      title: title,
      participants: participants,
      startTime: startTime,
      endTime: endTime,
      type: type,
      status: status ?? this.status,
      summary: summary ?? this.summary,
      keyPoints: keyPoints ?? this.keyPoints,
      decisions: decisions ?? this.decisions,
      transcript: transcript ?? this.transcript,
      followUpDate: followUpDate ?? this.followUpDate,
      followUpNotes: followUpNotes ?? this.followUpNotes,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'participants': participants,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'type': type.name,
        'status': status.name,
        'summary': summary,
        'keyPoints': keyPoints,
        'decisions': decisions,
        'transcript': transcript,
        'followUpDate': followUpDate?.toIso8601String(),
        'followUpNotes': followUpNotes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Meeting.fromJson(Map<String, dynamic> json) => Meeting(
        id: json['id'],
        title: json['title'],
        participants: json['participants'],
        startTime: DateTime.parse(json['startTime']),
        endTime: DateTime.parse(json['endTime']),
        type: MeetingType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => MeetingType.other,
        ),
        status: MeetingStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => MeetingStatus.scheduled,
        ),
        summary: json['summary'] ?? '',
        keyPoints: List<String>.from(json['keyPoints'] ?? []),
        decisions: List<String>.from(json['decisions'] ?? []),
        transcript: json['transcript'],
        followUpDate: json['followUpDate'] != null
            ? DateTime.parse(json['followUpDate'])
            : null,
        followUpNotes: json['followUpNotes'],
        createdAt: DateTime.parse(json['createdAt']),
      );
}

class MeetingSummary {
  final String meetingId;
  final String summary;
  final List<String> keyPoints;
  final List<String> decisions;
  final List<String> actionItems;
  final String sentiment;
  final List<String> topics;

  MeetingSummary({
    required this.meetingId,
    required this.summary,
    required this.keyPoints,
    required this.decisions,
    required this.actionItems,
    required this.sentiment,
    required this.topics,
  });
}

class ActionItem {
  final String id;
  final String meetingId;
  final String description;
  String assignedTo;
  final DateTime dueDate;
  final ActionPriority priority;
  ActionStatus status;
  final DateTime createdAt;

  ActionItem({
    required this.id,
    required this.meetingId,
    required this.description,
    required this.assignedTo,
    required this.dueDate,
    required this.priority,
    required this.status,
    required this.createdAt,
  });

  ActionItem copyWith({
    String? assignedTo,
    ActionStatus? status,
  }) {
    return ActionItem(
      id: id,
      meetingId: meetingId,
      description: description,
      assignedTo: assignedTo ?? this.assignedTo,
      dueDate: dueDate,
      priority: priority,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'meetingId': meetingId,
        'description': description,
        'assignedTo': assignedTo,
        'dueDate': dueDate.toIso8601String(),
        'priority': priority.name,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ActionItem.fromJson(Map<String, dynamic> json) => ActionItem(
        id: json['id'],
        meetingId: json['meetingId'],
        description: json['description'],
        assignedTo: json['assignedTo'],
        dueDate: DateTime.parse(json['dueDate']),
        priority: ActionPriority.values.firstWhere(
          (e) => e.name == json['priority'],
          orElse: () => ActionPriority.medium,
        ),
        status: ActionStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => ActionStatus.pending,
        ),
        createdAt: DateTime.parse(json['createdAt']),
      );
}

enum MeetingType {
  teamSync,
  projectReview,
  planning,
  clientMeeting,
  oneOnOne,
  other
}

enum MeetingStatus { scheduled, recorded, summarized, completed, cancelled }

enum ActionPriority { low, medium, high, urgent }

enum ActionStatus { pending, inProgress, completed, blocked }
