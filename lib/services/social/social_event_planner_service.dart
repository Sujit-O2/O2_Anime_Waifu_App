import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🎉 Social Event Planner Service
/// 
/// Coordinate gatherings, remember preferences of friends/family.
class SocialEventPlannerService {
  SocialEventPlannerService._();
  static final SocialEventPlannerService instance = SocialEventPlannerService._();

  final List<SocialEvent> _events = [];
  final List<Contact> _contacts = [];
  final Map<String, ContactPreferences> _preferences = {};
  
  int _totalEvents = 0;
  int _eventsAttended = 0;
  
  static const String _storageKey = 'social_event_planner_v1';
  static const int _maxEvents = 100;

  Future<void> initialize() async {
    await _loadData();
    if (kDebugMode) debugPrint('[SocialEventPlanner] Initialized with $_totalEvents events');
  }

  Future<SocialEvent> createEvent({
    required String title,
    required String description,
    required DateTime date,
    required EventType type,
    required List<String> attendees,
    required String location,
    required double budget,
  }) async {
    final event = SocialEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      date: date,
      type: type,
      attendees: attendees,
      location: location,
      budget: budget,
      status: EventStatus.planned,
      checklist: _generateDefaultChecklist(type),
      notes: '',
      createdAt: DateTime.now(),
    );
    
    _events.insert(0, event);
    _totalEvents++;
    
    // Add attendees as contacts if not already present
    for (final attendeeId in attendees) {
      if (!_contacts.any((c) => c.id == attendeeId)) {
        _contacts.add(Contact(
          id: attendeeId,
          name: attendeeId,
          relationship: Relationship.friend,
          interests: [],
          dietaryRestrictions: [],
          accessibilityNeeds: [],
          addedAt: DateTime.now(),
        ));
      }
    }
    
    await _saveData();
    
    if (kDebugMode) debugPrint('[SocialEventPlanner] Created event: $title');
    return event;
  }

  List<String> _generateDefaultChecklist(EventType type) {
    switch (type) {
      case EventType.birthday:
        return [
          'Order or prepare cake',
          'Buy or wrap gift',
          'Decorate venue',
          'Prepare food and drinks',
          'Send invitations',
          'Plan activities/games',
          'Take photos',
        ];
      case EventType.dinner:
        return [
          'Plan menu',
          'Check dietary restrictions',
          'Make reservations or prepare food',
          'Set table',
          'Buy ingredients',
          'Confirm attendance',
        ];
      case EventType.outing:
        return [
          'Research location',
          'Check weather forecast',
          'Arrange transportation',
          'Buy tickets if needed',
          'Pack essentials',
          'Share meeting point',
        ];
      case EventType.vacation:
        return [
          'Book accommodations',
          'Arrange transportation',
          'Create itinerary',
          'Check travel documents',
          'Pack appropriately',
          'Set budget',
          'Arrange pet/house care',
        ];
      case EventType.gathering:
        return [
          'Send invitations',
          'Plan activities',
          'Prepare food and drinks',
          'Clean and decorate space',
          'Create music playlist',
          'Set up seating',
        ];
      case EventType.celebration:
        return [
          'Plan ceremony/program',
          'Send invitations',
          'Arrange venue',
          'Prepare gifts',
          'Organize photos',
          'Plan speeches/toasts',
        ];
    }
  }

  Future<void> addAttendee(String eventId, String contactId) async {
    final eventIndex = _events.indexWhere((e) => e.id == eventId);
    if (eventIndex == -1) return;
    
    final event = _events[eventIndex];
    if (!event.attendees.contains(contactId)) {
      _events[eventIndex] = event.copyWith(
        attendees: [...event.attendees, contactId],
      );
      await _saveData();
    }
  }

  Future<void> removeAttendee(String eventId, String contactId) async {
    final eventIndex = _events.indexWhere((e) => e.id == eventId);
    if (eventIndex == -1) return;
    
    final event = _events[eventIndex];
    _events[eventIndex] = event.copyWith(
      attendees: event.attendees.where((id) => id != contactId).toList(),
    );
    await _saveData();
  }

  Future<void> updateEventStatus(String eventId, EventStatus status) async {
    final eventIndex = _events.indexWhere((e) => e.id == eventId);
    if (eventIndex == -1) return;
    
    final event = _events[eventIndex];
    _events[eventIndex] = event.copyWith(status: status);
    
    if (status == EventStatus.completed) {
      _eventsAttended++;
    }
    
    await _saveData();
  }

  Future<void> checkOffTask(String eventId, String task) async {
    final eventIndex = _events.indexWhere((e) => e.id == eventId);
    if (eventIndex == -1) return;
    
    final event = _events[eventIndex];
    final updatedChecklist = List<String>.from(event.checklist);
    updatedChecklist.remove(task);
    
    _events[eventIndex] = event.copyWith(checklist: updatedChecklist);
    await _saveData();
  }

  Future<void> addNote(String eventId, String note) async {
    final eventIndex = _events.indexWhere((e) => e.id == eventId);
    if (eventIndex == -1) return;
    
    final event = _events[eventIndex];
    _events[eventIndex] = event.copyWith(
      notes: event.notes.isNotEmpty ? '${event.notes}\n$note' : note,
    );
    await _saveData();
  }

  Future<Contact> addContact({
    required String name,
    required Relationship relationship,
    List<String>? interests,
    List<String>? dietaryRestrictions,
    List<String>? accessibilityNeeds,
    String? notes,
  }) async {
    final contact = Contact(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      relationship: relationship,
      interests: interests ?? [],
      dietaryRestrictions: dietaryRestrictions ?? [],
      accessibilityNeeds: accessibilityNeeds ?? [],
      notes: notes,
      addedAt: DateTime.now(),
    );
    
    _contacts.add(contact);
    
    // Initialize preferences
    _preferences[contact.id] = ContactPreferences(
      favoriteFoods: [],
      dislikes: [],
      preferredActivities: [],
      communicationStyle: CommunicationStyle.casual,
      lastEventAttended: null,
    );
    
    await _saveData();
    
    if (kDebugMode) debugPrint('[SocialEventPlanner] Added contact: $name');
    return contact;
  }

  Future<void> updateContactPreferences({
    required String contactId,
    List<String>? favoriteFoods,
    List<String>? dislikes,
    List<String>? preferredActivities,
    CommunicationStyle? communicationStyle,
  }) async {
    if (!_preferences.containsKey(contactId)) {
      _preferences[contactId] = ContactPreferences(
        favoriteFoods: [],
        dislikes: [],
        preferredActivities: [],
        communicationStyle: CommunicationStyle.casual,
        lastEventAttended: null,
      );
    }
    
    final prefs = _preferences[contactId]!;
    _preferences[contactId] = ContactPreferences(
      favoriteFoods: favoriteFoods ?? prefs.favoriteFoods,
      dislikes: dislikes ?? prefs.dislikes,
      preferredActivities: preferredActivities ?? prefs.preferredActivities,
      communicationStyle: communicationStyle ?? prefs.communicationStyle,
      lastEventAttended: prefs.lastEventAttended,
    );
    
    await _saveData();
  }

  List<SocialEvent> getUpcomingEvents({int days = 30}) {
    final now = DateTime.now();
    final future = now.add(Duration(days: days));
    return _events.where((e) => 
      e.date.isAfter(now) && e.date.isBefore(future)
    ).toList();
  }

  List<SocialEvent> getEventsByType(EventType type) {
    return _events.where((e) => e.type == type).toList();
  }

  List<SocialEvent> getEventsForContact(String contactId) {
    return _events.where((e) => e.attendees.contains(contactId)).toList();
  }

  String getEventRecommendations() {
    final upcoming = getUpcomingEvents(days: 30);
    final now = DateTime.now();
    
    final buffer = StringBuffer();
    buffer.writeln('🎉 Event Recommendations & Reminders:');
    buffer.writeln('');
    
    if (upcoming.isEmpty) {
      buffer.writeln('No upcoming events in the next 30 days.');
      buffer.writeln('Consider planning:');
      buffer.writeln('• Monthly friend gathering');
      buffer.writeln('• Family dinner');
      buffer.writeln('• Outdoor activity or outing');
    } else {
      buffer.writeln('Upcoming Events (${upcoming.length}):');
      for (final event in upcoming) {
        final daysUntil = event.date.difference(now).inDays;
        buffer.writeln('• ${event.title} - ${daysUntil} days away');
        
        if (daysUntil <= 7) {
          final pendingTasks = event.checklist.length;
          if (pendingTasks > 0) {
            buffer.writeln('  ⚠️ $pendingTasks tasks remaining');
          }
        }
      }
    }
    
    // Suggest events based on preferences
    buffer.writeln('');
    buffer.writeln('💡 Suggested Events:');
    
    final contactWithBirthdays = _getUpcomingBirthdays();
    if (contactWithBirthdays.isNotEmpty) {
      for (final contact in contactWithBirthdays) {
        buffer.writeln('• Plan birthday celebration for ${contact.name}');
      }
    }
    
    // Check for gaps in social calendar
    final eventsThisMonth = _events.where((e) => 
      e.date.month == now.month && e.date.year == now.year
    ).length;
    
    if (eventsThisMonth < 2) {
      buffer.writeln('• Schedule more social events this month');
    }
    
    return buffer.toString();
  }

  List<Contact> _getUpcomingBirthdays() {
    final now = DateTime.now();
    final upcoming = <Contact>[];
    
    for (final contact in _contacts) {
      // In a real app, you'd have birthday info
      // For now, return empty
    }
    
    return upcoming;
  }

  String getEventPlanningChecklist(String eventId) {
    final event = _events.firstWhere((e) => e.id == eventId);
    
    final buffer = StringBuffer();
    buffer.writeln('📋 Planning Checklist for "${event.title}":');
    buffer.writeln('');
    
    if (event.checklist.isEmpty) {
      buffer.writeln('✓ All tasks completed!');
    } else {
      for (final task in event.checklist) {
        buffer.writeln('□ $task');
      }
    }
    
    buffer.writeln('');
    buffer.writeln('📍 Location: ${event.location}');
    buffer.writeln('💰 Budget: \$${event.budget.toStringAsFixed(2)}');
    buffer.writeln('👥 Attendees: ${event.attendees.length}');
    buffer.writeln('📅 Date: ${event.date}');
    
    // Dietary restrictions
    final dietaryNeeds = <String>[];
    for (final attendeeId in event.attendees) {
      final contact = _contacts.firstWhere((c) => c.id == attendeeId, orElse: () => Contact(
        id: attendeeId,
        name: attendeeId,
        relationship: Relationship.friend,
        interests: [],
        dietaryRestrictions: [],
        accessibilityNeeds: [],
        addedAt: DateTime.now(),
      ));
      dietaryNeeds.addAll(contact.dietaryRestrictions);
    }
    
    if (dietaryNeeds.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('⚠️ Dietary Restrictions:');
      for (final restriction in dietaryNeeds.toSet()) {
        buffer.writeln('• $restriction');
      }
    }
    
    return buffer.toString();
  }

  String getEventInsights() {
    if (_events.isEmpty) {
      return 'No events planned yet. Start organizing gatherings!';
    }
    
    final upcoming = getUpcomingEvents(days: 30);
    final completed = _events.where((e) => e.status == EventStatus.completed).length;
    final planned = _events.where((e) => e.status == EventStatus.planned).length;
    
    final totalBudget = _events.fold<double>(0, (sum, e) => sum + e.budget);
    final avgBudget = _events.isNotEmpty ? totalBudget / _events.length : 0;
    
    final byType = <EventType, int>{};
    for (final event in _events) {
      byType[event.type] = (byType[event.type] ?? 0) + 1;
    }
    
    final buffer = StringBuffer();
    buffer.writeln('📅 Event Planning Insights:');
    buffer.writeln('• Total Events: $_totalEvents');
    buffer.writeln('• Completed: $completed');
    buffer.writeln('• Planned: $planned');
    buffer.writeln('• Upcoming (30 days): ${upcoming.length}');
    buffer.writeln('• Total Budget: \$${totalBudget.toStringAsFixed(2)}');
    buffer.writeln('• Average Budget: \$${avgBudget.toStringAsFixed(2)}');
    buffer.writeln('');
    buffer.writeln('Events by Type:');
    for (final entry in byType.entries) {
      buffer.writeln('  • ${entry.key.label}: ${entry.value}');
    }
    
    return buffer.toString();
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'events': _events.take(50).map((e) => e.toJson()).toList(),
        'contacts': _contacts.map((c) => c.toJson()).toList(),
        'preferences': _preferences.map((k, v) => MapEntry(k, v.toJson())),
        'totalEvents': _totalEvents,
        'eventsAttended': _eventsAttended,
      };
      await prefs.setString(_storageKey, jsonEncode(data));
    } catch (e) {
      if (kDebugMode) debugPrint('[SocialEventPlanner] Save error: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      
      if (jsonString != null && jsonString.isNotEmpty) {
        final data = jsonDecode(jsonString) as Map<String, dynamic>;
        
        _events.clear();
        _events.addAll(
          (data['events'] as List<dynamic>)
              .map((e) => SocialEvent.fromJson(e as Map<String, dynamic>))
        );
        
        _contacts.clear();
        _contacts.addAll(
          (data['contacts'] as List<dynamic>)
              .map((c) => Contact.fromJson(c as Map<String, dynamic>))
        );
        
        _preferences.clear();
        if (data['preferences'] != null) {
          (data['preferences'] as Map<String, dynamic>).forEach((k, v) {
            _preferences[k] = ContactPreferences.fromJson(v as Map<String, dynamic>);
          });
        }
        
        _totalEvents = data['totalEvents'] as int;
        _eventsAttended = data['eventsAttended'] as int;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[SocialEventPlanner] Load error: $e');
    }
  }
}

class SocialEvent {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final EventType type;
  final List<String> attendees;
  final String location;
  final double budget;
  EventStatus status;
  final List<String> checklist;
  final String notes;
  final DateTime createdAt;

  SocialEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.type,
    required this.attendees,
    required this.location,
    required this.budget,
    required this.status,
    required this.checklist,
    required this.notes,
    required this.createdAt,
  });

  SocialEvent copyWith({
    EventStatus? status,
    List<String>? attendees,
    List<String>? checklist,
    String? notes,
  }) {
    return SocialEvent(
      id: id,
      title: title,
      description: description,
      date: date,
      type: type,
      attendees: attendees ?? this.attendees,
      location: location,
      budget: budget,
      status: status ?? this.status,
      checklist: checklist ?? this.checklist,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'date': date.toIso8601String(),
    'type': type.name,
    'attendees': attendees,
    'location': location,
    'budget': budget,
    'status': status.name,
    'checklist': checklist,
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
  };

  factory SocialEvent.fromJson(Map<String, dynamic> json) => SocialEvent(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    date: DateTime.parse(json['date']),
    type: EventType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => EventType.gathering,
    ),
    attendees: List<String>.from(json['attendees'] ?? []),
    location: json['location'],
    budget: (json['budget'] as num).toDouble(),
    status: EventStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => EventStatus.planned,
    ),
    checklist: List<String>.from(json['checklist'] ?? []),
    notes: json['notes'] ?? '',
    createdAt: DateTime.parse(json['createdAt']),
  );
}

class Contact {
  final String id;
  final String name;
  final Relationship relationship;
  final List<String> interests;
  final List<String> dietaryRestrictions;
  final List<String> accessibilityNeeds;
  final String? notes;
  final DateTime addedAt;

  Contact({
    required this.id,
    required this.name,
    required this.relationship,
    required this.interests,
    required this.dietaryRestrictions,
    required this.accessibilityNeeds,
    this.notes,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'relationship': relationship.name,
    'interests': interests,
    'dietaryRestrictions': dietaryRestrictions,
    'accessibilityNeeds': accessibilityNeeds,
    'notes': notes,
    'addedAt': addedAt.toIso8601String(),
  };

  factory Contact.fromJson(Map<String, dynamic> json) => Contact(
    id: json['id'],
    name: json['name'],
    relationship: Relationship.values.firstWhere(
      (e) => e.name == json['relationship'],
      orElse: () => Relationship.friend,
    ),
    interests: List<String>.from(json['interests'] ?? []),
    dietaryRestrictions: List<String>.from(json['dietaryRestrictions'] ?? []),
    accessibilityNeeds: List<String>.from(json['accessibilityNeeds'] ?? []),
    notes: json['notes'],
    addedAt: DateTime.parse(json['addedAt']),
  );
}

class ContactPreferences {
  final List<String> favoriteFoods;
  final List<String> dislikes;
  final List<String> preferredActivities;
  final CommunicationStyle communicationStyle;
  final DateTime? lastEventAttended;

  ContactPreferences({
    required this.favoriteFoods,
    required this.dislikes,
    required this.preferredActivities,
    required this.communicationStyle,
    this.lastEventAttended,
  });

  Map<String, dynamic> toJson() => {
    'favoriteFoods': favoriteFoods,
    'dislikes': dislikes,
    'preferredActivities': preferredActivities,
    'communicationStyle': communicationStyle.name,
    'lastEventAttended': lastEventAttended?.toIso8601String(),
  };

  factory ContactPreferences.fromJson(Map<String, dynamic> json) => ContactPreferences(
    favoriteFoods: List<String>.from(json['favoriteFoods'] ?? []),
    dislikes: List<String>.from(json['dislikes'] ?? []),
    preferredActivities: List<String>.from(json['preferredActivities'] ?? []),
    communicationStyle: CommunicationStyle.values.firstWhere(
      (e) => e.name == json['communicationStyle'],
      orElse: () => CommunicationStyle.casual,
    ),
    lastEventAttended: json['lastEventAttended'] != null ? DateTime.parse(json['lastEventAttended']) : null,
  );
}

enum EventType {
  birthday('Birthday'),
  dinner('Dinner'),
  outing('Outing'),
  vacation('Vacation'),
  gathering('Gathering'),
  celebration('Celebration');
  
  final String label;
  const EventType(this.label);
}

enum EventStatus { planned, inProgress, completed, cancelled }

enum Relationship {
  family('Family'),
  friend('Friend'),
  partner('Partner'),
  colleague('Colleague'),
  acquaintance('Acquaintance');
  
  final String label;
  const Relationship(this.label);
}

enum CommunicationStyle { formal, casual, enthusiastic, reserved }