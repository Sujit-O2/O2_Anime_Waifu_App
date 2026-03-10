import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_message.dart';

/// Single cloud-storage service. All per-user data lives here.
/// Collections:
///   chats/{uid}    — chat history
///   vault/{uid}    — secret notes + PIN (XOR-obfuscated)
///   profiles/{uid} — persona, custom rules, prompt override, waifu name
///   affection/{uid}— relationship points, streak, last interaction
///   memory/{uid}   — key-value AI memory facts
///   quests/{uid}   — daily quests + custom quests
///   mood/{uid}     — mood journal entries (last 90)
class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool _initialized = false;

  // ── Init ──────────────────────────────────────────────────────────────────

  /// True only when a Firebase Auth user is logged in.
  bool get isSignedIn => FirebaseAuth.instance.currentUser != null;

  Future<void> init() async {
    if (_initialized) return;
    try {
      // Enable offline persistence so the app works without internet
      _db.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      _initialized = true;
    } catch (e) {
      debugPrint('FirestoreService.init error: $e');
    }
  }

  void resetInit() => _initialized = false;

  // ── Helpers ───────────────────────────────────────────────────────────────

  DocumentReference _doc(String collection) =>
      _db.collection(collection).doc(FirebaseAuth.instance.currentUser!.uid);

  static const int _xorKey = 0x5A;
  String _xorEncode(String text) =>
      base64Encode(text.codeUnits.map((c) => c ^ _xorKey).toList());
  String _xorDecode(String enc) {
    try {
      return String.fromCharCodes(base64Decode(enc).map((b) => b ^ _xorKey));
    } catch (_) {
      return enc;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CHAT HISTORY
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> saveChatHistory(List<ChatMessage> messages) async {
    await init();
    try {
      await _doc('chats').set({
        'updatedAt': FieldValue.serverTimestamp(),
        'messages': messages.map((m) => m.toJson()).toList(),
      });
    } catch (e) {
      debugPrint('saveChatHistory: $e');
    }
  }

  Future<void> addMessage(ChatMessage message) async {
    await init();
    try {
      await _doc('chats').set({
        'updatedAt': FieldValue.serverTimestamp(),
        'messages': FieldValue.arrayUnion([message.toJson()]),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('addMessage: $e');
    }
  }

  Future<List<ChatMessage>> loadChatHistory() async {
    await init();
    try {
      final snap = await _doc('chats').get();
      if (snap.exists) {
        final data = snap.data() as Map<String, dynamic>?;
        final msgs = data?['messages'] as List<dynamic>?;
        if (msgs != null) {
          return msgs
              .cast<Map<String, dynamic>>()
              .map(ChatMessage.fromJson)
              .toList();
        }
      }
    } catch (e) {
      debugPrint('loadChatHistory: $e');
    }
    return [];
  }

  Future<void> clearChatHistory() async {
    await init();
    try {
      await _doc('chats').delete();
    } catch (e) {
      debugPrint('clearChatHistory: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SECRET VAULT (notes + PIN)
  // ─────────────────────────────────────────────────────────────────────────

  Future<bool> hasPin() async {
    await init();
    try {
      final snap = await _doc('vault').get();
      if (snap.exists) {
        final data = snap.data() as Map<String, dynamic>?;
        final pin = data?['pin'] as String?;
        return pin != null && pin.isNotEmpty;
      }
    } catch (e) {
      debugPrint('hasPin: $e');
    }
    return false;
  }

  Future<void> setPin(String pin) async {
    await init();
    await _doc('vault').set({'pin': _xorEncode(pin)}, SetOptions(merge: true));
  }

  Future<bool> verifyPin(String pin) async {
    await init();
    try {
      final snap = await _doc('vault').get();
      if (snap.exists) {
        final data = snap.data() as Map<String, dynamic>?;
        final stored = data?['pin'] as String?;
        if (stored == null || stored.isEmpty) return true;
        return _xorDecode(stored) == pin;
      }
    } catch (e) {
      debugPrint('verifyPin: $e');
    }
    return true;
  }

  Future<List<Map<String, String>>> getSecretNotes() async {
    await init();
    try {
      final snap = await _doc('vault').get();
      if (snap.exists) {
        final data = snap.data() as Map<String, dynamic>?;
        final raw = data?['notes'] as String?;
        if (raw != null && raw.isNotEmpty) {
          return List<Map<String, String>>.from(
              (jsonDecode(_xorDecode(raw)) as List)
                  .map((e) => Map<String, String>.from(e as Map)));
        }
      }
    } catch (e) {
      debugPrint('getSecretNotes: $e');
    }
    return [];
  }

  Future<void> saveSecretNote(String title, String content) async {
    await init();
    final notes = await getSecretNotes();
    notes.add({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'content': content,
      'ts': DateTime.now().toIso8601String(),
    });
    await _doc('vault')
        .set({'notes': _xorEncode(jsonEncode(notes))}, SetOptions(merge: true));
  }

  Future<void> deleteSecretNote(String id) async {
    await init();
    final notes = await getSecretNotes();
    notes.removeWhere((n) => n['id'] == id);
    await _doc('vault')
        .set({'notes': _xorEncode(jsonEncode(notes))}, SetOptions(merge: true));
  }

  Future<void> clearSecretNotes() async {
    await init();
    await _doc('vault').set({'notes': ''}, SetOptions(merge: true));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // USER PROFILE (persona, custom rules, waifu prompt)
  // ─────────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> loadProfile() async {
    await init();
    try {
      final snap = await _doc('profiles').get();
      if (snap.exists && snap.data() != null) {
        return snap.data() as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('loadProfile: $e');
    }
    return {};
  }

  Future<void> savePersona(String persona) async {
    await init();
    await _doc('profiles').set({'persona': persona}, SetOptions(merge: true));
  }

  Future<void> saveCustomRules(String rules) async {
    await init();
    await _doc('profiles').set({'customRules': rules}, SetOptions(merge: true));
  }

  Future<void> saveWaifuPromptOverride(String prompt) async {
    await init();
    await _doc('profiles')
        .set({'promptOverride': prompt}, SetOptions(merge: true));
  }

  Future<String> loadCustomRules() async =>
      (await loadProfile())['customRules'] as String? ?? '';

  Future<String> loadWaifuPromptOverride() async =>
      (await loadProfile())['promptOverride'] as String? ?? '';

  // ─────────────────────────────────────────────────────────────────────────
  // AFFECTION / RELATIONSHIP
  // ─────────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> loadAffection() async {
    await init();
    try {
      final snap = await _doc('affection').get();
      if (snap.exists && snap.data() != null) {
        return snap.data() as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('loadAffection: $e');
    }
    return {};
  }

  Future<void> saveAffection({
    required int points,
    required int streakDays,
    required int lastInteractionMs,
    required int lastStreakDateMs,
  }) async {
    await init();
    try {
      await _doc('affection').set({
        'points': points,
        'streakDays': streakDays,
        'lastInteractionMs': lastInteractionMs,
        'lastStreakDateMs': lastStreakDateMs,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('saveAffection: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MEMORY / FACTS
  // ─────────────────────────────────────────────────────────────────────────

  Future<Map<String, String>> loadMemoryFacts() async {
    await init();
    try {
      final snap = await _doc('memory').get();
      if (snap.exists) {
        final data = snap.data() as Map<String, dynamic>?;
        final raw = data?['facts'] as String?;
        if (raw != null && raw.isNotEmpty) {
          return Map<String, String>.from(jsonDecode(raw) as Map);
        }
      }
    } catch (e) {
      debugPrint('loadMemoryFacts: $e');
    }
    return {};
  }

  Future<void> saveMemoryFacts(Map<String, String> facts) async {
    await init();
    try {
      await _doc('memory').set({
        'facts': jsonEncode(facts),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('saveMemoryFacts: $e');
    }
  }

  Future<void> clearMemoryFacts() async {
    await init();
    await _doc('memory').delete();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // QUESTS
  // ─────────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> loadQuests() async {
    await init();
    try {
      final snap = await _doc('quests').get();
      if (snap.exists && snap.data() != null) {
        return snap.data() as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('loadQuests: $e');
    }
    return {};
  }

  Future<void> saveDailyQuests(
      List<Map<String, dynamic>> quests, String dateStr) async {
    await init();
    try {
      await _doc('quests').set({
        'dailyQuests': jsonEncode(quests),
        'lastQuestDate': dateStr,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('saveDailyQuests: $e');
    }
  }

  Future<void> saveCustomQuests(List<Map<String, dynamic>> quests) async {
    await init();
    try {
      await _doc('quests').set({
        'customQuests': jsonEncode(quests),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('saveCustomQuests: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MOOD JOURNAL
  // ─────────────────────────────────────────────────────────────────────────

  Future<List<Map<String, String>>> loadMoodEntries() async {
    await init();
    try {
      final snap = await _doc('mood').get();
      if (snap.exists) {
        final data = snap.data() as Map<String, dynamic>?;
        final raw = data?['entries'] as String?;
        if (raw != null && raw.isNotEmpty) {
          return List<Map<String, String>>.from((jsonDecode(raw) as List)
              .map((e) => Map<String, String>.from(e as Map)));
        }
      }
    } catch (e) {
      debugPrint('loadMoodEntries: $e');
    }
    return [];
  }

  Future<void> saveMoodEntries(List<Map<String, String>> entries) async {
    await init();
    try {
      await _doc('mood').set({
        'entries': jsonEncode(entries),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('saveMoodEntries: $e');
    }
  }

  Future<void> clearMoodEntries() async {
    await init();
    await _doc('mood').delete();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // APP SETTINGS (all SharedPreferences synced to cloud)
  // ─────────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> loadSettings() async {
    await init();
    try {
      final snap = await _doc('settings').get();
      if (snap.exists && snap.data() != null) {
        return snap.data() as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('loadSettings: $e');
    }
    return {};
  }

  Future<void> saveSettings(Map<String, dynamic> settings) async {
    await init();
    try {
      await _doc('settings').set({
        ...settings,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('saveSettings: $e');
    }
  }

  Future<void> saveSetting(String key, dynamic value) async {
    await init();
    try {
      await _doc('settings').set({
        key: value,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('saveSetting $key: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // WAIFU ALARM
  // ─────────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> loadAlarm() async {
    await init();
    try {
      final snap = await _doc('alarm').get();
      if (snap.exists && snap.data() != null) {
        return snap.data() as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('loadAlarm: $e');
    }
    return {};
  }

  Future<void> saveAlarm(Map<String, dynamic> alarmData) async {
    await init();
    try {
      await _doc('alarm').set({
        ...alarmData,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('saveAlarm: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MINI-GAME HIGH SCORES
  // ─────────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> loadScores() async {
    await init();
    try {
      final snap = await _doc('scores').get();
      if (snap.exists && snap.data() != null) {
        return snap.data() as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('loadScores: $e');
    }
    return {};
  }

  Future<void> saveScore(String game, int score) async {
    await init();
    try {
      final current = await loadScores();
      final currentBest = (current[game] as int?) ?? 0;
      if (score > currentBest) {
        await _doc('scores').set({
          game: score,
          '${game}_date': DateTime.now().toIso8601String(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('saveScore: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ACHIEVEMENTS / BADGES
  // ─────────────────────────────────────────────────────────────────────────

  Future<List<String>> loadAchievements() async {
    await init();
    try {
      final snap = await _doc('achievements').get();
      if (snap.exists) {
        final data = snap.data() as Map<String, dynamic>?;
        final list = data?['badges'] as List<dynamic>?;
        return list?.cast<String>() ?? [];
      }
    } catch (e) {
      debugPrint('loadAchievements: $e');
    }
    return [];
  }

  Future<bool> unlockAchievement(String badge) async {
    await init();
    try {
      final existing = await loadAchievements();
      if (existing.contains(badge)) return false; // already unlocked
      await _doc('achievements').set({
        'badges': FieldValue.arrayUnion([badge]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return true; // newly unlocked
    } catch (e) {
      debugPrint('unlockAchievement: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // USER PROFILE (display name, photo URL, anniversary)
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> saveUserProfile({
    String? displayName,
    String? photoUrl,
    String? anniversaryDate, // ISO date string of first launch
  }) async {
    await init();
    final map = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (displayName != null) map['displayName'] = displayName;
    if (photoUrl != null) map['photoUrl'] = photoUrl;
    if (anniversaryDate != null) map['anniversaryDate'] = anniversaryDate;
    try {
      await _doc('profiles').set(map, SetOptions(merge: true));
    } catch (e) {
      debugPrint('saveUserProfile: $e');
    }
  }
}
