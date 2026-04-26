import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ✈️ Travel Planner Service
/// 
/// Suggest destinations, create itineraries, remember preferences.
class TravelPlannerService {
  TravelPlannerService._();
  static final TravelPlannerService instance = TravelPlannerService._();

  final List<Trip> _trips = [];
  final List<Destination> _destinations = [];
  final List<String> _preferences = [];
  final List<TravelMemory> _memories = [];
  
  int _totalTrips = 0;
  
  static const String _storageKey = 'travel_planner_v1';
  static const int _maxTrips = 50;

  Future<void> initialize() async {
    await _loadData();
    if (kDebugMode) debugPrint('[TravelPlanner] Initialized with $_totalTrips trips');
    
    // Initialize default destinations if empty
    if (_destinations.isEmpty) {
      _initializeDefaultDestinations();
    }
  }

  void _initializeDefaultDestinations() {
    final defaultDestinations = [
      Destination(
        name: 'Tokyo, Japan',
        country: 'Japan',
        type: DestinationType.city,
        description: 'Vibrant metropolis blending ultramodern and traditional',
        bestTimeToVisit: 'Spring (March-May) or Fall (September-November)',
        budget: BudgetLevel.medium,
        activities: ['Visit temples', 'Explore neighborhoods', 'Try local cuisine', 'Shopping'],
        climate: 'Temperate with distinct seasons',
        language: 'Japanese',
        visaRequired: true,
      ),
      Destination(
        name: 'Paris, France',
        country: 'France',
        type: DestinationType.city,
        description: 'City of light with iconic landmarks and romantic atmosphere',
        bestTimeToVisit: 'Spring (April-June) or Fall (September-November)',
        budget: BudgetLevel.medium,
        activities: ['Visit Eiffel Tower', 'Louvre Museum', 'Seine River cruise', 'Café culture'],
        climate: 'Oceanic with mild summers and cool winters',
        language: 'French',
        visaRequired: false,
      ),
      Destination(
        name: 'Bali, Indonesia',
        country: 'Indonesia',
        type: DestinationType.beach,
        description: 'Tropical paradise with beaches, temples, and rice terraces',
        bestTimeToVisit: 'Dry season (April-October)',
        budget: BudgetLevel.low,
        activities: ['Beach activities', 'Temple visits', 'Yoga retreats', 'Surfing'],
        climate: 'Tropical with wet and dry seasons',
        language: 'Indonesian',
        visaRequired: true,
      ),
      Destination(
        name: 'New York City, USA',
        country: 'United States',
        type: DestinationType.city,
        description: 'Dynamic city with world-class attractions and diverse culture',
        bestTimeToVisit: 'Spring (April-June) or Fall (September-November)',
        budget: BudgetLevel.high,
        activities: ['Broadway shows', 'Museums', 'Central Park', 'Shopping'],
        climate: 'Humid subtropical with four distinct seasons',
        language: 'English',
        visaRequired: true,
      ),
    ];
    
    _destinations.addAll(defaultDestinations);
  }

  Future<Trip> createTrip({
    required String title,
    required String destination,
    required DateTime startDate,
    required DateTime endDate,
    required int travelers,
    required double budget,
    required List<String> interests,
    String? notes,
  }) async {
    final trip = Trip(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      destination: destination,
      startDate: startDate,
      endDate: endDate,
      travelers: travelers,
      budget: budget,
      interests: interests,
      notes: notes ?? '',
      status: TripStatus.planning,
      itinerary: [],
      expenses: [],
      createdAt: DateTime.now(),
    );
    
    _trips.insert(0, trip);
    _totalTrips++;
    
    await _saveData();
    
    if (kDebugMode) debugPrint('[TravelPlanner] Created trip: $title');
    return trip;
  }

  Future<void> addItineraryItem({
    required String tripId,
    required String date,
    required String time,
    required String activity,
    required String location,
    String? notes,
  }) async {
    final tripIndex = _trips.indexWhere((t) => t.id == tripId);
    if (tripIndex == -1) return;
    
    final item = ItineraryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: date,
      time: time,
      activity: activity,
      location: location,
      notes: notes,
      completed: false,
    );
    
    final trip = _trips[tripIndex];
    _trips[tripIndex] = trip.copyWith(
      itinerary: [...trip.itinerary, item],
    );
    
    await _saveData();
    
    if (kDebugMode) debugPrint('[TravelPlanner] Added itinerary item to trip: $tripId');
  }

  Future<void> addExpense({
    required String tripId,
    required String description,
    required double amount,
    required String category,
    required DateTime date,
    String? notes,
  }) async {
    final tripIndex = _trips.indexWhere((t) => t.id == tripId);
    if (tripIndex == -1) return;
    
    final expense = Expense(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      description: description,
      amount: amount,
      category: category,
      date: date,
      notes: notes,
    );
    
    final trip = _trips[tripIndex];
    _trips[tripIndex] = trip.copyWith(
      expenses: [...trip.expenses, expense],
    );
    
    await _saveData();
    
    if (kDebugMode) debugPrint('[TravelPlanner] Added expense to trip: $tripId');
  }

  Future<void> updateTripStatus(String tripId, TripStatus status) async {
    final tripIndex = _trips.indexWhere((t) => t.id == tripId);
    if (tripIndex == -1) return;
    
    final trip = _trips[tripIndex];
    _trips[tripIndex] = trip.copyWith(status: status);
    
    await _saveData();
    
    if (kDebugMode) debugPrint('[TravelPlanner] Updated trip status: $tripId -> $status');
  }

  Future<void> addPreference(String preference) async {
    if (!_preferences.contains(preference)) {
      _preferences.add(preference);
      await _saveData();
      
      if (kDebugMode) debugPrint('[TravelPlanner] Added preference: $preference');
    }
  }

  Future<void> addTravelMemory({
    required String tripId,
    required String title,
    required String description,
    String? photoUrl,
    required int rating,
  }) async {
    final memory = TravelMemory(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      tripId: tripId,
      title: title,
      description: description,
      photoUrl: photoUrl,
      rating: rating,
      createdAt: DateTime.now(),
    );
    
    _memories.insert(0, memory);
    
    await _saveData();
    
    if (kDebugMode) debugPrint('[TravelPlanner] Added travel memory: $title');
  }

  List<Trip> getTripsByStatus(TripStatus status) {
    return _trips.where((t) => t.status == status).toList();
  }

  List<Trip> getUpcomingTrips() {
    final now = DateTime.now();
    return _trips.where((t) => t.startDate.isAfter(now)).toList();
  }

  List<Trip> getPastTrips() {
    final now = DateTime.now();
    return _trips.where((t) => t.endDate.isBefore(now)).toList();
  }

  List<Destination> getDestinationsByType(DestinationType type) {
    return _destinations.where((d) => d.type == type).toList();
  }

  List<Destination> getDestinationsByBudget(BudgetLevel budget) {
    return _destinations.where((d) => d.budget == budget).toList();
  }

  List<Destination> searchDestinations(String query) {
    final lowerQuery = query.toLowerCase();
    return _destinations.where((d) =>
      d.name.toLowerCase().contains(lowerQuery) ||
      d.country.toLowerCase().contains(lowerQuery) ||
      d.description.toLowerCase().contains(lowerQuery)
    ).toList();
  }

  String getTripSummary(String tripId) {
    final trip = _trips.firstWhere((t) => t.id == tripId);
    final days = trip.endDate.difference(trip.startDate).inDays + 1;
    final totalExpenses = trip.expenses.fold<double>(0, (sum, e) => sum + e.amount);
    
    final buffer = StringBuffer();
    buffer.writeln('✈️ Trip Summary: ${trip.title}');
    buffer.writeln('');
    buffer.writeln('Destination: ${trip.destination}');
    buffer.writeln('Duration: $days days (${trip.startDate} to ${trip.endDate})');
    buffer.writeln('Travelers: ${trip.travelers}');
    buffer.writeln('Budget: \$${trip.budget.toStringAsFixed(2)}');
    buffer.writeln('Total Expenses: \$${totalExpenses.toStringAsFixed(2)}');
    buffer.writeln('Remaining Budget: \$${(trip.budget - totalExpenses).toStringAsFixed(2)}');
    buffer.writeln('Status: ${trip.status.label}');
    buffer.writeln('');
    
    if (trip.itinerary.isNotEmpty) {
      buffer.writeln('Itinerary Items: ${trip.itinerary.length}');
      final completed = trip.itinerary.where((i) => i.completed).length;
      buffer.writeln('Completed: $completed/${trip.itinerary.length}');
    }
    
    if (trip.expenses.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('Expenses by Category:');
      final byCategory = <String, double>{};
      for (final expense in trip.expenses) {
        byCategory[expense.category] = (byCategory[expense.category] ?? 0) + expense.amount;
      }
      for (final entry in byCategory.entries) {
        buffer.writeln('• ${entry.key}: \$${entry.value.toStringAsFixed(2)}');
      }
    }
    
    return buffer.toString();
  }

  String getDestinationRecommendations() {
    final recommendations = <String>[];
    
    for (final destination in _destinations) {
      final matchScore = _calculateDestinationMatchScore(destination);
      if (matchScore > 0.5) {
        recommendations.add('${destination.name} - ${destination.description}');
      }
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('Explore our featured destinations to find your perfect trip!');
    }
    
    return '🎯 Destination Recommendations:\n${recommendations.map((r) => '• $r').join('\n')}';
  }

  double _calculateDestinationMatchScore(Destination destination) {
    double score = 0;
    
    // Check budget match
    switch (destination.budget) {
      case BudgetLevel.low:
        score += 0.3;
        break;
      case BudgetLevel.medium:
        score += 0.5;
        break;
      case BudgetLevel.high:
        score += 0.7;
        break;
    }
    
    // Check interests match
    final destinationKeywords = [
      ...destination.description.toLowerCase().split(' '),
      ...destination.activities.map((a) => a.toLowerCase()),
    ];
    
    for (final preference in _preferences) {
      if (destinationKeywords.any((k) => k.contains(preference.toLowerCase()))) {
        score += 0.2;
      }
    }
    
    return score.clamp(0, 1);
  }

  String getTravelInsights() {
    if (_trips.isEmpty) {
      return 'No trips planned yet. Start planning your next adventure!';
    }
    
    final upcoming = getUpcomingTrips().length;
    
    final totalBudget = _trips.fold<double>(0, (sum, t) => sum + t.budget);
    final totalExpenses = _trips.fold<double>(0, (sum, t) => 
      sum + t.expenses.fold<double>(0, (expSum, e) => expSum + e.amount)
    );
    
    final byDestinationType = <DestinationType, int>{};
    for (final trip in _trips) {
      final dest = _destinations.firstWhere((d) => d.name == trip.destination, orElse: () => _destinations.first);
      byDestinationType[dest.type] = (byDestinationType[dest.type] ?? 0) + 1;
    }
    
    final buffer = StringBuffer();
    buffer.writeln('🌍 Travel Insights:');
    buffer.writeln('• Total Trips: $_totalTrips');
    buffer.writeln('• Upcoming: $upcoming');
    buffer.writeln('• Total Budget: \$${totalBudget.toStringAsFixed(2)}');
    buffer.writeln('• Total Expenses: \$${totalExpenses.toStringAsFixed(2)}');
    buffer.writeln('');
    buffer.writeln('Trips by Destination Type:');
    for (final entry in byDestinationType.entries) {
      buffer.writeln('  • ${entry.key.label}: ${entry.value}');
    }
    
    if (_memories.isNotEmpty) {
      final avgRating = _memories.fold<double>(0, (sum, m) => sum + m.rating) / _memories.length;
      buffer.writeln('');
      buffer.writeln('Travel Memories: ${_memories.length}');
      buffer.writeln('Average Rating: ${avgRating.toStringAsFixed(1)}/5');
    }
    
    return buffer.toString();
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'trips': _trips.take(_maxTrips).map((t) => t.toJson()).toList(),
        'destinations': _destinations.map((d) => d.toJson()).toList(),
        'preferences': _preferences,
        'memories': _memories.take(100).map((m) => m.toJson()).toList(),
        'totalTrips': _totalTrips,
      };
      await prefs.setString(_storageKey, jsonEncode(data));
    } catch (e) {
      if (kDebugMode) debugPrint('[TravelPlanner] Save error: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      
      if (jsonString != null && jsonString.isNotEmpty) {
        final data = jsonDecode(jsonString) as Map<String, dynamic>;
        
        _trips.clear();
        _trips.addAll(
          (data['trips'] as List<dynamic>? ?? [])
              .map((t) => Trip.fromJson(t as Map<String, dynamic>))
        );
        
        _destinations.clear();
        _destinations.addAll(
          (data['destinations'] as List<dynamic>? ?? [])
              .map((d) => Destination.fromJson(d as Map<String, dynamic>))
        );
        
        _preferences.clear();
        _preferences.addAll(List<String>.from(data['preferences'] ?? []));
        
        _memories.clear();
        _memories.addAll(
          (data['memories'] as List<dynamic>? ?? [])
              .map((m) => TravelMemory.fromJson(m as Map<String, dynamic>))
        );
        
        _totalTrips = data['totalTrips'] as int? ?? 0;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[TravelPlanner] Load error: $e');
    }
  }
}

class Trip {
  final String id;
  final String title;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final int travelers;
  final double budget;
  final List<String> interests;
  final String notes;
  TripStatus status;
  final List<ItineraryItem> itinerary;
  final List<Expense> expenses;
  final DateTime createdAt;

  Trip({
    required this.id,
    required this.title,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.travelers,
    required this.budget,
    required this.interests,
    required this.notes,
    required this.status,
    required this.itinerary,
    required this.expenses,
    required this.createdAt,
  });

  Trip copyWith({
    TripStatus? status,
    List<ItineraryItem>? itinerary,
    List<Expense>? expenses,
  }) {
    return Trip(
      id: id,
      title: title,
      destination: destination,
      startDate: startDate,
      endDate: endDate,
      travelers: travelers,
      budget: budget,
      interests: interests,
      notes: notes,
      status: status ?? this.status,
      itinerary: itinerary ?? this.itinerary,
      expenses: expenses ?? this.expenses,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'destination': destination,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'travelers': travelers,
    'budget': budget,
    'interests': interests,
    'notes': notes,
    'status': status.name,
    'itinerary': itinerary.map((i) => i.toJson()).toList(),
    'expenses': expenses.map((e) => e.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory Trip.fromJson(Map<String, dynamic> json) => Trip(
    id: json['id'],
    title: json['title'],
    destination: json['destination'],
    startDate: DateTime.parse(json['startDate']),
    endDate: DateTime.parse(json['endDate']),
    travelers: json['travelers'],
    budget: (json['budget'] as num).toDouble(),
    interests: List<String>.from(json['interests'] ?? []),
    notes: json['notes'] ?? '',
    status: TripStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => TripStatus.planning,
    ),
    itinerary: (json['itinerary'] as List<dynamic>? ?? [])
        .map((i) => ItineraryItem.fromJson(i as Map<String, dynamic>))
        .toList(),
    expenses: (json['expenses'] as List<dynamic>? ?? [])
        .map((e) => Expense.fromJson(e as Map<String, dynamic>))
        .toList(),
    createdAt: DateTime.parse(json['createdAt']),
  );
}

class ItineraryItem {
  final String id;
  final String date;
  final String time;
  final String activity;
  final String location;
  final String? notes;
  bool completed;

  ItineraryItem({
    required this.id,
    required this.date,
    required this.time,
    required this.activity,
    required this.location,
    this.notes,
    this.completed = false,
  });

  ItineraryItem copyWith({
    bool? completed,
  }) {
    return ItineraryItem(
      id: id,
      date: date,
      time: time,
      activity: activity,
      location: location,
      notes: notes,
      completed: completed ?? this.completed,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'time': time,
    'activity': activity,
    'location': location,
    'notes': notes,
    'completed': completed,
  };

  factory ItineraryItem.fromJson(Map<String, dynamic> json) => ItineraryItem(
    id: json['id'],
    date: json['date'],
    time: json['time'],
    activity: json['activity'],
    location: json['location'],
    notes: json['notes'],
    completed: json['completed'] ?? false,
  );
}

class Expense {
  final String id;
  final String description;
  final double amount;
  final String category;
  final DateTime date;
  final String? notes;

  Expense({
    required this.id,
    required this.description,
    required this.amount,
    required this.category,
    required this.date,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'description': description,
    'amount': amount,
    'category': category,
    'date': date.toIso8601String(),
    'notes': notes,
  };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
    id: json['id'],
    description: json['description'],
    amount: (json['amount'] as num).toDouble(),
    category: json['category'],
    date: DateTime.parse(json['date']),
    notes: json['notes'],
  );
}

class Destination {
  final String name;
  final String country;
  final DestinationType type;
  final String description;
  final String bestTimeToVisit;
  final BudgetLevel budget;
  final List<String> activities;
  final String climate;
  final String language;
  final bool visaRequired;

  Destination({
    required this.name,
    required this.country,
    required this.type,
    required this.description,
    required this.bestTimeToVisit,
    required this.budget,
    required this.activities,
    required this.climate,
    required this.language,
    required this.visaRequired,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'country': country,
    'type': type.name,
    'description': description,
    'bestTimeToVisit': bestTimeToVisit,
    'budget': budget.name,
    'activities': activities,
    'climate': climate,
    'language': language,
    'visaRequired': visaRequired,
  };

  factory Destination.fromJson(Map<String, dynamic> json) => Destination(
    name: json['name'],
    country: json['country'],
    type: DestinationType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => DestinationType.city,
    ),
    description: json['description'],
    bestTimeToVisit: json['bestTimeToVisit'],
    budget: BudgetLevel.values.firstWhere(
      (e) => e.name == json['budget'],
      orElse: () => BudgetLevel.medium,
    ),
    activities: List<String>.from(json['activities'] ?? []),
    climate: json['climate'],
    language: json['language'],
    visaRequired: json['visaRequired'] ?? false,
  );
}

class TravelMemory {
  final String id;
  final String tripId;
  final String title;
  final String description;
  final String? photoUrl;
  final int rating;
  final DateTime createdAt;

  TravelMemory({
    required this.id,
    required this.tripId,
    required this.title,
    required this.description,
    this.photoUrl,
    required this.rating,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'tripId': tripId,
    'title': title,
    'description': description,
    'photoUrl': photoUrl,
    'rating': rating,
    'createdAt': createdAt.toIso8601String(),
  };

  factory TravelMemory.fromJson(Map<String, dynamic> json) => TravelMemory(
    id: json['id'],
    tripId: json['tripId'],
    title: json['title'],
    description: json['description'],
    photoUrl: json['photoUrl'],
    rating: json['rating'],
    createdAt: DateTime.parse(json['createdAt']),
  );
}

enum TripStatus {
  planning('Planning'),
  inProgress('In Progress'),
  completed('Completed'),
  cancelled('Cancelled');

  final String label;
  const TripStatus(this.label);
}

enum DestinationType {
  city('City'),
  beach('Beach'),
  mountain('Mountain'),
  countryside('Countryside'),
  historical('Historical');

  final String label;
  const DestinationType(this.label);
}

enum BudgetLevel {
  low('Low'),
  medium('Medium'),
  high('High');

  final String label;
  const BudgetLevel(this.label);
}