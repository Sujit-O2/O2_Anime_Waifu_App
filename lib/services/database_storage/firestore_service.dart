import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;

import 'package:anime_waifu/models/chat_message.dart';
import 'package:anime_waifu/services/security_privacy/secure_encryption_service.dart';

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
      if (kDebugMode) debugPrint('FirestoreService.init error: $e');
    }
  }

  void resetInit() => _initialized = false;

  // ── Helpers ───────────────────────────────────────────────────────────────

  DocumentReference _doc(String collection) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError('User not authenticated');
    }
    return _db.collection(collection).doc(uid);
  }

  // Uses SecureEncryption for strong encryption instead of weak XOR
  static const String _encryptionPassword = 'anime-waifu-vault-key-2026';

  // ─────────────────────────────────────────────────────────────────────────
  // CHAT HISTORY
  // ─────────────────────────────────────────────────────────────────────────

  DateTime _lastSaveAt = DateTime(2000);
  
  Future<void> saveChatHistory(List<ChatMessage> messages) async {
    // Rate-limit writes: max once per 3 seconds to reduce Firestore costs
    final now = DateTime.now();
    if (now.difference(_lastSaveAt).inSeconds < 3) return;
    _lastSaveAt = now;
    await init();
    try {
      await _doc('chats').set({
        'updatedAt': FieldValue.serverTimestamp(),
        'messages': messages.map((m) => m.toJson()).toList(),
      });
    } catch (e) {
      if (kDebugMode) debugPrint('saveChatHistory: $e');
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
      if (kDebugMode) debugPrint('addMessage: $e');
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
              .map((e) => Map<String, dynamic>.from(e as Map))
              .map(ChatMessage.fromJson)
              .toList();
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('loadChatHistory: $e');
    }
    return [];
  }

  Future<void> clearChatHistory() async {
    await init();
    try {
      await _doc('chats').delete();
    } catch (e) {
      if (kDebugMode) debugPrint('clearChatHistory: $e');
    }
  }

  /// Delete specific messages by their IDs, then re-save remaining to cloud.
  Future<void> deleteMessages(
      List<ChatMessage> allMessages, Set<String> idsToDelete) async {
    await init();
    try {
      final remaining =
          allMessages.where((m) => !idsToDelete.contains(m.id)).toList();
      await saveChatHistory(remaining);
    } catch (e) {
      if (kDebugMode) debugPrint('deleteMessages: $e');
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
      if (kDebugMode) debugPrint('hasPin: $e');
    }
    return false;
  }

  Future<void> setPin(String pin) async {
    await init();
    final encrypted = SecureEncryption.encrypt(pin, _encryptionPassword);
    await _doc('vault').set({
      'pin': encrypted,
      'pin_updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _logAuditEvent(
        'pin_set', {'uid': FirebaseAuth.instance.currentUser?.uid});
  }

  Future<bool> verifyPin(String pin) async {
    await init();
    try {
      final snap = await _doc('vault').get();
      if (snap.exists) {
        final data = snap.data() as Map<String, dynamic>?;
        final stored = data?['pin'] as String?;
        if (stored == null || stored.isEmpty) return true;
        final decrypted = SecureEncryption.decrypt(stored, _encryptionPassword);
        final verified = (decrypted ?? '') == pin;
        if (!verified) {
          await _logAuditEvent('pin_verification_failed',
              {'uid': FirebaseAuth.instance.currentUser?.uid});
        }
        return verified;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('verifyPin: $e');
      await _logAuditEvent('pin_verification_error', {'error': e.toString()});
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
          final decrypted =
              SecureEncryption.decrypt(raw, _encryptionPassword) ?? '';
          if (decrypted.isEmpty) return [];
          try {
            return List<Map<String, String>>.from(
                (jsonDecode(decrypted) as List)
                    .map((e) => Map<String, String>.from(e as Map)));
          } catch (_) {
            if (kDebugMode) debugPrint('getSecretNotes: corrupt JSON data');
            return [];
          }
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('getSecretNotes: $e');
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
    final encrypted =
        SecureEncryption.encrypt(jsonEncode(notes), _encryptionPassword);
    await _doc('vault').set({
      'notes': encrypted,
      'notes_updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _logAuditEvent(
        'secret_note_created', {'uid': FirebaseAuth.instance.currentUser?.uid});
  }

  Future<void> deleteSecretNote(String id) async {
    await init();
    final notes = await getSecretNotes();
    notes.removeWhere((n) => n['id'] == id);
    final encrypted =
        SecureEncryption.encrypt(jsonEncode(notes), _encryptionPassword);
    await _doc('vault').set({
      'notes': encrypted,
      'notes_updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _logAuditEvent('secret_note_deleted',
        {'uid': FirebaseAuth.instance.currentUser?.uid, 'note_id': id});
  }

  Future<void> clearSecretNotes() async {
    await init();
    await _doc('vault').set({
      'notes': '',
      'notes_updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _logAuditEvent('secret_notes_cleared',
        {'uid': FirebaseAuth.instance.currentUser?.uid});
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
      if (kDebugMode) debugPrint('loadProfile: $e');
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
      if (kDebugMode) debugPrint('loadAffection: $e');
    }
    return {};
  }

  Future<void> saveAffection({
    required int points,
    required int streakDays,
    required int lastInteractionMs,
    required int lastStreakDateMs,
    String? levelName,
    double? levelProgress,
  }) async {
    await init();
    try {
      final payload = <String, dynamic>{
        'points': points,
        'streakDays': streakDays,
        'lastInteractionMs': lastInteractionMs,
        'lastStreakDateMs': lastStreakDateMs,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (levelName != null) payload['levelName'] = levelName;
      if (levelProgress != null) payload['levelProgress'] = levelProgress;
      await _doc('affection').set(payload, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) debugPrint('saveAffection: $e');
    }
  }

  Future<Map<String, dynamic>> loadRelationshipProgression() async {
    await init();
    try {
      final snap = await _doc('affection').get();
      if (snap.exists && snap.data() != null) {
        final data = snap.data() as Map<String, dynamic>;
        return <String, dynamic>{
          if (data.containsKey('trustScore')) 'trustScore': data['trustScore'],
          if (data.containsKey('milestones')) 'milestones': data['milestones'],
          if (data.containsKey('relationshipStateUpdatedAtMs'))
            'updatedAtMs': data['relationshipStateUpdatedAtMs'],
        };
      }
    } catch (e) {
      if (kDebugMode) debugPrint('loadRelationshipProgression: $e');
    }
    return {};
  }

  Future<void> saveRelationshipProgression({
    required int trustScore,
    required Map<String, dynamic> milestones,
    required int updatedAtMs,
    String? relationshipStage,
  }) async {
    await init();
    try {
      final payload = <String, dynamic>{
        'trustScore': trustScore,
        'milestones': milestones,
        'relationshipStateUpdatedAtMs': updatedAtMs,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (relationshipStage != null) {
        payload['relationshipStage'] = relationshipStage;
      }
      await _doc('affection').set(payload, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) debugPrint('saveRelationshipProgression: $e');
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
      if (kDebugMode) debugPrint('loadMemoryFacts: $e');
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
      if (kDebugMode) debugPrint('saveMemoryFacts: $e');
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
      if (kDebugMode) debugPrint('loadQuests: $e');
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
      if (kDebugMode) debugPrint('saveDailyQuests: $e');
    }
  }

  Future<void> saveCustomQuests(List<Map<String, dynamic>> quests) async {
    await init();
    try {
      await _doc('quests').set({
        'customQuests': jsonEncode(quests),
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) debugPrint('saveCustomQuests: $e');
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
      if (kDebugMode) debugPrint('loadMoodEntries: $e');
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
      if (kDebugMode) debugPrint('saveMoodEntries: $e');
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
      if (kDebugMode) debugPrint('loadSettings: $e');
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
      if (kDebugMode) debugPrint('saveSettings: $e');
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
      if (kDebugMode) debugPrint('saveSetting $key: $e');
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
      if (kDebugMode) debugPrint('loadAlarm: $e');
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
      if (kDebugMode) debugPrint('saveAlarm: $e');
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
      if (kDebugMode) debugPrint('loadScores: $e');
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
      if (kDebugMode) debugPrint('saveScore: $e');
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
      if (kDebugMode) debugPrint('loadAchievements: $e');
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
      if (kDebugMode) debugPrint('unlockAchievement: $e');
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
      if (kDebugMode) debugPrint('saveUserProfile: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // AUDIT LOGGING (Security & Compliance)
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _logAuditEvent(
      String event, Map<String, dynamic> details) async {
    await init();
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      await _db.collection('audit_logs').add({
        'uid': uid,
        'event': event,
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
        'ip': 'mobile_app',
      });
    } catch (e) {
      if (kDebugMode) debugPrint('_logAuditEvent: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DATA DELETION & RETENTION (GDPR Compliance)
  // ─────────────────────────────────────────────────────────────────────────

  /// Cascade delete all user data. Called when account is deleted.
  Future<void> deleteAllUserData() async {
    await init();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      // List of all user-scoped collections to delete
      final collections = [
        'chats',
        'vault',
        'profiles',
        'affection',
        'memory',
        'quests',
        'mood',
        'settings',
        'alarm',
        'scores',
        'achievements',
        'dreams',
        'gratitude',
        'habits',
        'bucket',
        'zt_diary',
        'pinned_messages',
        'scheduled_messages',
        'user_data_sync',
        'checked',
      ];

      // Batch delete top-level user collections in parallel
      await Future.wait(
        collections.map((collection) async {
          try {
            await _db.collection(collection).doc(uid).delete();
          } catch (e) {
            if (kDebugMode) debugPrint('Error deleting $collection: $e');
          }
        }),
      );

      // Delete nested documents under /users/{uid}
      try {
        final userRef = _db.collection('users').doc(uid);
        final nestedCollections = [
          'feature_data',
          'moodEntries',
          'conversationSummaries',
          'personality',
          'dreamInterpretations',
          'coupleChallenge',
          'emotional_memories',
          'memory_facts',
          'life_events',
          'ai_content',
        ];

        // Delete nested sub-collection docs using WriteBatch for speed
        for (final nestedCol in nestedCollections) {
          try {
            final docs = await userRef.collection(nestedCol).get();
            if (docs.docs.isNotEmpty) {
              final batch = _db.batch();
              for (final doc in docs.docs) {
                batch.delete(doc.reference);
              }
              await batch.commit();
            }
          } catch (e) {
            if (kDebugMode) debugPrint('Error deleting nested $nestedCol: $e');
          }
        }

        // Delete user profile (but keep basic public info for friend lists, etc)
        await userRef.update({
          'email': FieldValue.delete(),
          'emailVerified': FieldValue.delete(),
          'phone': FieldValue.delete(),
          'lastLogin': FieldValue.delete(),
          'deletedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        if (kDebugMode) debugPrint('Error deleting user document: $e');
      }

      await _logAuditEvent('account_deleted', {'uid': uid});
    } catch (e) {
      if (kDebugMode) debugPrint('deleteAllUserData error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DATA EXPORT (User Data Portability)
  // ─────────────────────────────────────────────────────────────────────────

  /// Export all user data as JSON. Used for GDPR data portability.
  Future<String> exportUserData() async {
    await init();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return '{}';

    try {
      final export = <String, dynamic>{};

      final collections = [
        'chats',
        'profiles',
        'affection',
        'memory',
        'quests',
        'mood',
        'settings',
        'alarm',
        'scores',
        'achievements',
      ];

      for (final collection in collections) {
        try {
          final snap = await _db.collection(collection).doc(uid).get();
          if (snap.exists) {
            export[collection] = snap.data();
          }
        } catch (e) {
          if (kDebugMode) debugPrint('Error exporting $collection: $e');
        }
      }

      export['exported_at'] = DateTime.now().toIso8601String();
      export['exported_by'] = uid;

      return jsonEncode(export);
    } catch (e) {
      if (kDebugMode) debugPrint('exportUserData error: $e');
      return '{"error": "$e"}';
    }
  }
}
