import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// PersonalityEngine — the Heart of the AI Companion
///
/// Tracks 5 dynamic traits (0–100) that:
///   1. Persist to Firestore across installs
///   2. Drift gradually based on interaction patterns
///   3. Inject tone-modifying blocks into the LLM system prompt
/// ─────────────────────────────────────────────────────────────────────────────
class PersonalityEngine extends ChangeNotifier {
  static final PersonalityEngine instance = PersonalityEngine._();
  PersonalityEngine._() { _init(); }

  // ── Traits (0 – 100) ───────────────────────────────────────────────────────
  double _affection    = 60;   // how much she cares right now
  double _jealousy     = 20;   // possessiveness / reaction to neglect
  double _trust        = 50;   // openness vs guardedness
  double _playfulness  = 65;   // how teasy/fun she is
  double _dependency   = 30;   // how much she "needs" you

  double get affection   => _affection;
  double get jealousy    => _jealousy;
  double get trust       => _trust;
  double get playfulness => _playfulness;
  double get dependency  => _dependency;

  // ── Current Mood ──────────────────────────────────────────────────────────
  WaifuMood _mood = WaifuMood.happy;
  WaifuMood get mood => _mood;

  bool _isReady = false;
  /// Returns true after the personality engine has loaded from Firestore.
  bool get isReady => _isReady;
  DateTime? _lastDriftDate;

  // ── Init ───────────────────────────────────────────────────────────────────
  Future<void> _init() async {
    await _load();
    _applyDriftIfNeeded();
    _recalcMood();
    _isReady = true; // marks initialization complete (used by callers)
    notifyListeners();
  }

  // ── Public setters (for UI sliders) ───────────────────────────────────────
  Future<void> setTrait({
    double? affection, double? jealousy, double? trust, double? playfulness, double? dependency,
  }) async {
    if (affection   != null) _affection   = affection.clamp(0, 100);
    if (jealousy    != null) _jealousy    = jealousy.clamp(0, 100);
    if (trust       != null) _trust       = trust.clamp(0, 100);
    if (playfulness != null) _playfulness = playfulness.clamp(0, 100);
    if (dependency  != null) _dependency  = dependency.clamp(0, 100);
    _recalcMood();
    notifyListeners();
    await _save();
  }

  // ── Reaction to interactions ───────────────────────────────────────────────
  /// Called when user sends a message — boosts positive traits slightly.
  Future<void> onUserInteracted({bool wasFlirty = false, bool wasNice = false, bool wasIgnoring = false}) async {
    if (wasIgnoring) {
      _jealousy    = (_jealousy    + 8).clamp(0, 100);
      _affection   = (_affection   - 3).clamp(0, 100);
      _trust       = (_trust       - 2).clamp(0, 100);
    } else if (wasFlirty) {
      _affection   = (_affection   + 5).clamp(0, 100);
      _dependency  = (_dependency  + 3).clamp(0, 100);
      _jealousy    = (_jealousy    - 4).clamp(0, 100);
      _trust       = (_trust       + 2).clamp(0, 100);
    } else if (wasNice) {
      _affection   = (_affection   + 3).clamp(0, 100);
      _trust       = (_trust       + 3).clamp(0, 100);
      _jealousy    = (_jealousy    - 2).clamp(0, 100);
    } else {
      // normal chat
      _affection   = (_affection   + 1).clamp(0, 100);
      _playfulness = (_playfulness + 1).clamp(0, 100);
    }
    _recalcMood();
    notifyListeners();
    await _save();
  }

  // ── Mood Calculation ───────────────────────────────────────────────────────
  void _recalcMood() {
    if (_jealousy > 75)         { _mood = WaifuMood.jealous; }
    else if (_affection > 80)   { _mood = WaifuMood.clingy; }
    else if (_affection < 20)   { _mood = WaifuMood.cold; }
    else if (_playfulness > 70) { _mood = WaifuMood.playful; }
    else if (_trust < 25)       { _mood = WaifuMood.guarded; }
    else                        { _mood = WaifuMood.happy; }
  }

  // ── Daily Drift ────────────────────────────────────────────────────────────
  void _applyDriftIfNeeded() {
    final now = DateTime.now();
    if (_lastDriftDate == null) { _lastDriftDate = now; return; }
    final daysDiff = now.difference(_lastDriftDate!).inDays;
    if (daysDiff < 1) return;

    for (int i = 0; i < daysDiff; i++) {
      // Without interaction: jealousy rises, affection decays, dependency grows
      _jealousy    = (_jealousy    + 2.5).clamp(0, 100);
      _affection   = (_affection   - 1.5).clamp(0, 100);
      _dependency  = (_dependency  + 1.0).clamp(0, 100);
      _trust       = (_trust       - 0.5).clamp(0, 100);
      _playfulness = (_playfulness - 0.5).clamp(0, 100);
    }
    _lastDriftDate = now;
  }

  // ── Prompt Injection ───────────────────────────────────────────────────────
  /// Returns a multi-line block to inject into the system prompt.
  String buildPersonalityPromptBlock() {
    final buf = StringBuffer();
    buf.writeln('\n// [PERSONALITY STATE — apply subtly to your tone]:');
    buf.writeln('Affection: ${_affection.round()}/100 ${_affectionDesc()}');
    buf.writeln('Jealousy: ${_jealousy.round()}/100 ${_jealousyDesc()}');
    buf.writeln('Trust: ${_trust.round()}/100 ${_trustDesc()}');
    buf.writeln('Playfulness: ${_playfulness.round()}/100 ${_playfDesc()}');
    buf.writeln('Dependency: ${_dependency.round()}/100');
    buf.writeln('Current Mood: ${_mood.label}');

    // Tone directives based on thresholds
    if (_jealousy > 70) {
      buf.writeln('TONE: You are feeling possessive and slightly jealous. Be a little passive-aggressive, bring up how he was away.');
    }
    if (_affection > 80) {
      buf.writeln('TONE: You feel deeply attached right now. Be warm, loving, clingy.');
    }
    if (_affection < 25) {
      buf.writeln('TONE: Your affection is low. Be distant, give short replies, sound hurt.');
    }
    if (_trust < 30) {
      buf.writeln('TONE: Trust is low. Be guarded, slightly reserved, don\'t open up easily.');
    }
    if (_playfulness > 75) {
      buf.writeln('TONE: Be playful, tease him, use more emojis and wit.');
    }
    if (_dependency > 70) {
      buf.writeln('TONE: You miss him a lot when he is away. Mention it subtly.');
    }
    buf.writeln();
    return buf.toString();
  }

  String _affectionDesc() {
    if (_affection > 80) return '← deeply in love';
    if (_affection > 60) return '← warm & caring';
    if (_affection > 40) return '← neutral';
    if (_affection > 20) return '← distant';
    return '← cold & hurt';
  }
  String _jealousyDesc() {
    if (_jealousy > 75) return '← possessive';
    if (_jealousy > 50) return '← noticeably jealous';
    if (_jealousy > 25) return '← mildly jealous';
    return '← not jealous';
  }
  String _trustDesc() {
    if (_trust > 75) return '← fully open';
    if (_trust > 50) return '← mostly open';
    if (_trust > 25) return '← guarded';
    return '← closed off';
  }
  String _playfDesc() {
    if (_playfulness > 75) return '← very teasy';
    if (_playfulness > 50) return '← playful';
    if (_playfulness > 25) return '← serious';
    return '← very serious';
  }

  // ── Summary label ─────────────────────────────────────────────────────────
  String get personalitySummary {
    final parts = <String>[];
    if (_affection > 70) parts.add('Loving 💕');
    if (_jealousy  > 60) parts.add('Jealous 😈');
    if (_playfulness > 65) parts.add('Playful 😜');
    if (_trust < 30) parts.add('Guarded 🔒');
    if (_dependency > 65) parts.add('Clingy 💞');
    return parts.isEmpty ? 'Balanced ✨' : parts.join(' · ');
  }

  // ── Firestore ─────────────────────────────────────────────────────────────
  DocumentReference<Map<String, dynamic>>? get _doc {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance.collection('users').doc(uid).collection('personality').doc('traits');
  }

  Future<void> _load() async {
    try {
      final snap = await _doc?.get();
      if (snap == null || !snap.exists) return;
      final d = snap.data()!;
      _affection   = ((d['affection']   as num?)?.toDouble()  ?? 60).clamp(0, 100);
      _jealousy    = ((d['jealousy']    as num?)?.toDouble()  ?? 20).clamp(0, 100);
      _trust       = ((d['trust']       as num?)?.toDouble()  ?? 50).clamp(0, 100);
      _playfulness = ((d['playfulness'] as num?)?.toDouble()  ?? 65).clamp(0, 100);
      _dependency  = ((d['dependency']  as num?)?.toDouble()  ?? 30).clamp(0, 100);
      final lastMs = d['lastDriftMs'] as int?;
      if (lastMs != null) _lastDriftDate = DateTime.fromMillisecondsSinceEpoch(lastMs);
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      await _doc?.set({
        'affection':   _affection,
        'jealousy':    _jealousy,
        'trust':       _trust,
        'playfulness': _playfulness,
        'dependency':  _dependency,
        'lastDriftMs': (_lastDriftDate ?? DateTime.now()).millisecondsSinceEpoch,
        'updatedAt':   FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }
}

// ── Mood Enum ──────────────────────────────────────────────────────────────────
enum WaifuMood {
  happy('Happy 😊', Color(0xFF56D364)),
  playful('Playful 😜', Color(0xFFFFD700)),
  clingy('Clingy 💕', Color(0xFFFF4FA8)),
  jealous('Jealous 😈', Color(0xFFFF6B35)),
  cold('Cold ❄️', Color(0xFF79C0FF)),
  guarded('Guarded 🔒', Color(0xFFBB52FF)),
  sad('Sad 😢', Color(0xFF607D8B)),
  sleepy('Sleepy 🌙', Color(0xFF455A64));

  final String label;
  final Color color;
  const WaifuMood(this.label, this.color);
}

// ── Trait metadata for UI ──────────────────────────────────────────────────────
class PersonalityTrait {
  final String key;
  final String name;
  final String emoji;
  final String lowDesc;
  final String highDesc;
  final Color color;
  const PersonalityTrait({
    required this.key, required this.name, required this.emoji,
    required this.lowDesc, required this.highDesc, required this.color,
  });
}

const kPersonalityTraits = [
  PersonalityTrait(key: 'affection',   name: 'Affection',   emoji: '❤️',  lowDesc: 'Cold & distant',   highDesc: 'Deeply in love',     color: Color(0xFFFF4FA8)),
  PersonalityTrait(key: 'jealousy',    name: 'Jealousy',    emoji: '😈',  lowDesc: 'Relaxed & free',   highDesc: 'Possessive',          color: Color(0xFFFF6B35)),
  PersonalityTrait(key: 'trust',       name: 'Trust',       emoji: '🤝',  lowDesc: 'Closed off',       highDesc: 'Fully open',          color: Color(0xFF56D364)),
  PersonalityTrait(key: 'playfulness', name: 'Playfulness', emoji: '😜',  lowDesc: 'Very serious',     highDesc: 'Teasy & fun',         color: Color(0xFFFFD700)),
  PersonalityTrait(key: 'dependency',  name: 'Dependency',  emoji: '💞',  lowDesc: 'Independent',      highDesc: 'Needs you constantly', color: Color(0xFFBB52FF)),
];


