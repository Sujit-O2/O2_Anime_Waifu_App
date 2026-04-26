import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🎁 Gift Intelligence Service
/// 
/// Suggest personalized gifts based on conversations, occasions, and budget.
class GiftIntelligenceService {
  GiftIntelligenceService._();
  static final GiftIntelligenceService instance = GiftIntelligenceService._();

  final List<GiftIdea> _giftIdeas = [];
  final Map<String, List<String>> _personPreferences = {};
  
  int _totalIdeas = 0;
  int _giftsGiven = 0;
  
  static const String _storageKey = 'gift_intelligence_v1';
  static const int _maxIdeas = 500;

  Future<void> initialize() async {
    await _loadData();
    if (kDebugMode) debugPrint('[GiftIntelligence] Initialized with $_totalIdeas gift ideas');
  }

  Future<GiftIdea> generateGiftIdea({
    required String forPerson,
    required String occasion,
    required double budget,
    required List<String> interests,
    String? relationship,
  }) async {
    final idea = GiftIdea(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      forPerson: forPerson,
      occasion: occasion,
      budget: budget,
      interests: interests,
      relationship: relationship,
      suggestedGifts: _generateSuggestions(forPerson, occasion, budget, interests),
      createdAt: DateTime.now(),
      used: false,
    );
    
    _giftIdeas.insert(0, idea);
    _totalIdeas++;
    
    // Store person preferences
    if (!_personPreferences.containsKey(forPerson)) {
      _personPreferences[forPerson] = [];
    }
    _personPreferences[forPerson]?.addAll(interests);
    
    await _saveData();
    
    if (kDebugMode) debugPrint('[GiftIntelligence] Generated gift idea for: $forPerson');
    return idea;
  }

  List<String> _generateSuggestions(String person, String occasion, double budget, List<String> interests) {
    final suggestions = <String>[];
    
    // Budget-based suggestions
    if (budget < 20) {
      suggestions.addAll(_generateBudgetSuggestions('low', interests));
    } else if (budget < 50) {
      suggestions.addAll(_generateBudgetSuggestions('medium', interests));
    } else if (budget < 100) {
      suggestions.addAll(_generateBudgetSuggestions('high', interests));
    } else {
      suggestions.addAll(_generateBudgetSuggestions('luxury', interests));
    }
    
    // Occasion-based additions
    suggestions.addAll(_generateOccasionSuggestions(occasion, budget));
    
    // Interest-based personalization
    for (final interest in interests) {
      suggestions.addAll(_generateInterestSuggestions(interest, budget));
    }
    
    return suggestions.toSet().toList(); // Remove duplicates
  }

  List<String> _generateBudgetSuggestions(String tier, List<String> interests) {
    final suggestions = <String>[];
    
    switch (tier) {
      case 'low':
        suggestions.add('Personalized handwritten letter or card');
        suggestions.add('DIY craft or art piece');
        suggestions.add('Favorite snacks or treats collection');
        suggestions.add('Playlist of meaningful songs');
        suggestions.add('Photo collage or scrapbook page');
        break;
      case 'medium':
        suggestions.add('Quality book by their favorite author');
        suggestions.add('Specialty coffee or tea set');
        suggestions.add('Custom phone case or accessory');
        suggestions.add('Board game or puzzle');
        suggestions.add('Subscription box (1-3 months)');
        break;
      case 'high':
        suggestions.add('Smart gadget or tech accessory');
        suggestions.add('Experience gift (concert, workshop)');
        suggestions.add('Premium skincare or fragrance');
        suggestions.add('Art supplies or creative kit');
        suggestions.add('Fitness or wellness equipment');
        break;
      case 'luxury':
        suggestions.add('Designer accessory or jewelry');
        suggestions.add('Weekend getaway or vacation package');
        suggestions.add('High-end electronics or gadget');
        suggestions.add('Luxury spa or wellness experience');
        suggestions.add('Exclusive event tickets or VIP experience');
        break;
    }
    
    return suggestions;
  }

  List<String> _generateOccasionSuggestions(String occasion, double budget) {
    final suggestions = <String>[];
    
    switch (occasion.toLowerCase()) {
      case 'birthday':
        suggestions.add('Birthday cake or dessert');
        suggestions.add('Personalized jewelry with birthstone');
        if (budget > 50) suggestions.add('Surprise party or gathering');
        break;
      case 'anniversary':
        suggestions.add('Romantic dinner reservation');
        suggestions.add('Custom photo album or frame');
        suggestions.add('Couple experience (cooking class, spa)');
        break;
      case 'graduation':
        suggestions.add('Professional portfolio or bag');
        suggestions.add('Inspirational book collection');
        suggestions.add('Career-related tool or software');
        break;
      case 'holiday':
      case 'christmas':
        suggestions.add('Festive decoration or ornament');
        suggestions.add('Cozy home goods or blanket');
        suggestions.add('Holiday-themed experience');
        break;
      case 'valentine':
        suggestions.add('Romantic getaway or staycation');
        suggestions.add('Love letter collection or book');
        suggestions.add('Couples activity or class');
        break;
      case 'thank you':
        suggestions.add('Gourmet gift basket');
        suggestions.add('Quality desk accessory');
        suggestions.add('Plant or flowers');
        break;
    }
    
    return suggestions;
  }

  List<String> _generateInterestSuggestions(String interest, double budget) {
    final suggestions = <String>[];
    final lowerInterest = interest.toLowerCase();
    
    if (lowerInterest.contains('music')) {
      suggestions.add('Vinyl records or music collection');
      suggestions.add('Concert tickets or music lessons');
      suggestions.add('Quality headphones or speaker');
      suggestions.add('Musical instrument accessory');
    } else if (lowerInterest.contains('book') || lowerInterest.contains('reading')) {
      suggestions.add('Signed book or first edition');
      suggestions.add('E-reader or reading light');
      suggestions.add('Book subscription service');
      suggestions.add('Personalized bookmark or bookplate');
    } else if (lowerInterest.contains('art') || lowerInterest.contains('paint')) {
      suggestions.add('Premium art supplies');
      suggestions.add('Art class or workshop');
      suggestions.add('Museum membership or gallery visit');
      suggestions.add('Custom portrait or artwork');
    } else if (lowerInterest.contains('game') || lowerInterest.contains('gaming')) {
      suggestions.add('New game release or pre-order');
      suggestions.add('Gaming accessory or peripheral');
      suggestions.add('Gaming subscription or gift card');
      suggestions.add('Retro game or collector item');
    } else if (lowerInterest.contains('fitness') || lowerInterest.contains('sport')) {
      suggestions.add('Fitness tracker or smartwatch');
      suggestions.add('Gym membership or class package');
      suggestions.add('Quality athletic wear');
      suggestions.add('Personal training session');
    } else if (lowerInterest.contains('cook') || lowerInterest.contains('food')) {
      suggestions.add('Cooking class or workshop');
      suggestions.add('Quality kitchen gadget or tool');
      suggestions.add('Gourmet ingredient collection');
      suggestions.add('Restaurant gift certificate');
    } else if (lowerInterest.contains('travel')) {
      suggestions.add('Travel accessory set');
      suggestions.add('Experience gift certificate');
      suggestions.add('Travel guide or photography book');
      suggestions.add('Luggage or travel gear upgrade');
    } else if (lowerInterest.contains('tech') || lowerInterest.contains('gadget')) {
      suggestions.add('Latest tech accessory');
      suggestions.add('Smart home device');
      suggestions.add('Tech subscription or service');
      suggestions.add('Portable charger or power bank');
    }
    
    return suggestions;
  }

  Future<void> markGiftAsGiven(String giftId, String recipientReaction) async {
    final giftIndex = _giftIdeas.indexWhere((g) => g.id == giftId);
    if (giftIndex == -1) return;
    
    final gift = _giftIdeas[giftIndex];
    _giftIdeas[giftIndex] = gift.copyWith(
      used: true,
      recipientReaction: recipientReaction,
      givenAt: DateTime.now(),
    );
    
    _giftsGiven++;
    
    await _saveData();
    
    if (kDebugMode) debugPrint('[GiftIntelligence] Gift marked as given: $giftId');
  }

  List<GiftIdea> getGiftIdeasForPerson(String person) {
    return _giftIdeas.where((g) => g.forPerson == person).toList();
  }

  List<GiftIdea> getGiftIdeasForOccasion(String occasion) {
    return _giftIdeas.where((g) => g.occasion.toLowerCase() == occasion.toLowerCase()).toList();
  }

  String getGiftInsights() {
    if (_giftIdeas.isEmpty) {
      return 'No gift ideas generated yet. Start creating personalized gift suggestions!';
    }
    
    final givenGifts = _giftIdeas.where((g) => g.used).length;
    final avgBudget = _giftIdeas.fold<double>(0, (sum, g) => sum + g.budget) / _giftIdeas.length;
    
    final positiveReactions = _giftIdeas.where((g) => 
      g.recipientReaction?.toLowerCase().contains('love') == true ||
      g.recipientReaction?.toLowerCase().contains('like') == true ||
      g.recipientReaction?.toLowerCase().contains('happy') == true
    ).length;
    
    final buffer = StringBuffer();
    buffer.writeln('🎁 Gift Intelligence Insights:');
    buffer.writeln('• Total Ideas Generated: $_totalIdeas');
    buffer.writeln('• Gifts Given: $givenGifts');
    buffer.writeln('• Average Budget: \$${avgBudget.toStringAsFixed(2)}');
    
    if (givenGifts > 0) {
      final satisfactionRate = (positiveReactions / givenGifts * 100).toStringAsFixed(0);
      buffer.writeln('• Recipient Satisfaction: $satisfactionRate%');
    }
    
    // Most popular interests
    final allInterests = <String>[];
    for (final interests in _personPreferences.values) {
      allInterests.addAll(interests);
    }
    
    if (allInterests.isNotEmpty) {
      final interestCounts = <String, int>{};
      for (final interest in allInterests) {
        interestCounts[interest] = (interestCounts[interest] ?? 0) + 1;
      }
      
      final topInterests = interestCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      buffer.writeln('\n📊 Top Interests:');
      for (final entry in topInterests.take(3)) {
        buffer.writeln('  • ${entry.key}: ${entry.value} mentions');
      }
    }
    
    return buffer.toString();
  }

  String getPersonalizedRecommendation(String person, double budget) {
    final personInterests = _personPreferences[person] ?? [];
    
    if (personInterests.isEmpty) {
      return 'Add some interests for $person to get personalized recommendations!';
    }
    
    final suggestions = _generateSuggestions(person, 'general', budget, personInterests);
    
    if (suggestions.isEmpty) {
      return 'No specific recommendations available. Try adding more interests.';
    }
    
    final buffer = StringBuffer();
    buffer.writeln('🎯 Personalized Recommendations for $person (\$${budget.toStringAsFixed(2)} budget):');
    buffer.writeln('');
    buffer.writeln('Based on interests: ${personInterests.join(", ")}');
    buffer.writeln('');
    buffer.writeln('Top Suggestions:');
    for (final suggestion in suggestions.take(5)) {
      buffer.writeln('• $suggestion');
    }
    
    return buffer.toString();
  }

  Future<void> addPersonPreference(String person, List<String> interests) async {
    if (!_personPreferences.containsKey(person)) {
      _personPreferences[person] = [];
    }
    
    _personPreferences[person]?.addAll(interests);
    await _saveData();
    
    if (kDebugMode) debugPrint('[GiftIntelligence] Added preferences for: $person');
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'giftIdeas': _giftIdeas.take(50).map((g) => g.toJson()).toList(),
        'totalIdeas': _totalIdeas,
        'giftsGiven': _giftsGiven,
        'personPreferences': _personPreferences,
      };
      await prefs.setString(_storageKey, jsonEncode(data));
    } catch (e) {
      if (kDebugMode) debugPrint('[GiftIntelligence] Save error: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      
      if (jsonString != null && jsonString.isNotEmpty) {
        final data = jsonDecode(jsonString) as Map<String, dynamic>;
        
        _giftIdeas.clear();
        _giftIdeas.addAll(
          (data['giftIdeas'] as List<dynamic>)
              .map((g) => GiftIdea.fromJson(g as Map<String, dynamic>))
        );
        
        _totalIdeas = data['totalIdeas'] as int;
        _giftsGiven = data['giftsGiven'] as int;
        _personPreferences.clear();
        _personPreferences.addAll(
          Map<String, List<String>>.from(
            (data['personPreferences'] as Map<String, dynamic>).map(
              (k, v) => MapEntry(k, List<String>.from(v as List)),
            ),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[GiftIntelligence] Load error: $e');
    }
  }
}

class GiftIdea {
  final String id;
  final String forPerson;
  final String occasion;
  final double budget;
  final List<String> interests;
  final String? relationship;
  final List<String> suggestedGifts;
  final DateTime createdAt;
  bool used;
  String? recipientReaction;
  DateTime? givenAt;

  GiftIdea({
    required this.id,
    required this.forPerson,
    required this.occasion,
    required this.budget,
    required this.interests,
    this.relationship,
    required this.suggestedGifts,
    required this.createdAt,
    this.used = false,
    this.recipientReaction,
    this.givenAt,
  });

  GiftIdea copyWith({
    bool? used,
    String? recipientReaction,
    DateTime? givenAt,
  }) {
    return GiftIdea(
      id: id,
      forPerson: forPerson,
      occasion: occasion,
      budget: budget,
      interests: interests,
      relationship: relationship,
      suggestedGifts: suggestedGifts,
      createdAt: createdAt,
      used: used ?? this.used,
      recipientReaction: recipientReaction ?? this.recipientReaction,
      givenAt: givenAt ?? this.givenAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'forPerson': forPerson,
    'occasion': occasion,
    'budget': budget,
    'interests': interests,
    'relationship': relationship,
    'suggestedGifts': suggestedGifts,
    'createdAt': createdAt.toIso8601String(),
    'used': used,
    'recipientReaction': recipientReaction,
    'givenAt': givenAt?.toIso8601String(),
  };

  factory GiftIdea.fromJson(Map<String, dynamic> json) => GiftIdea(
    id: json['id'],
    forPerson: json['forPerson'],
    occasion: json['occasion'],
    budget: (json['budget'] as num).toDouble(),
    interests: List<String>.from(json['interests'] ?? []),
    relationship: json['relationship'],
    suggestedGifts: List<String>.from(json['suggestedGifts'] ?? []),
    createdAt: DateTime.parse(json['createdAt']),
    used: json['used'] ?? false,
    recipientReaction: json['recipientReaction'],
    givenAt: json['givenAt'] != null ? DateTime.parse(json['givenAt']) : null,
  );
}