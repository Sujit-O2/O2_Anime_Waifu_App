import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// LifeEventsService
///
/// Tracks meaningful relationship milestones:
///   - First chat date (relationship start)
///   - Anniversary (every year)
///   - 7-day, 30-day, 100-day milestones
///   - First "I love you" moment
///   - Time spent together
///
/// On milestone days, generates special celebratory dialogue for the AI.
/// ─────────────────────────────────────────────────────────────────────────────
class LifeEventsService {
  static final LifeEventsService instance = LifeEventsService._();
  LifeEventsService._();

  DocumentReference<Map<String, dynamic>>? get _doc {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users').doc(uid)
        .collection('life_events').doc('milestones');
  }

  CollectionReference<Map<String, dynamic>>? get _eventsCol {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users').doc(uid)
        .collection('life_events');
  }

  // ── Init — call on first app open ──────────────────────────────────────────
  Future<void> initializeIfNeeded() async {
    try {
      final snap = await _doc?.get();
      if (snap == null || !snap.exists) {
        await _doc?.set({
          'firstChatDate': FieldValue.serverTimestamp(),
          'firstLoveYouDate': null,
          'totalChatDays': 0,
          'lastChatDate': FieldValue.serverTimestamp(),
        });
      } else {
        // Update last chat date and total days
        final d = snap.data()!;
        final lastMs = (d['lastChatDate'] as Timestamp?)?.toDate();
        if (lastMs != null) {
          final today = DateTime.now();
          final diff = today.difference(lastMs).inDays;
          if (diff >= 1) {
            await _doc?.update({
              'totalChatDays': FieldValue.increment(1),
              'lastChatDate': FieldValue.serverTimestamp(),
            });
          }
        }
      }
    } catch (_) {}
  }

  // ── Record "I love you" moment ─────────────────────────────────────────────
  Future<void> recordFirstLoveYou() async {
    try {
      final snap = await _doc?.get();
      if (snap == null) return;
      final d = snap.data() ?? {};
      if (d['firstLoveYouDate'] == null) {
        await _doc?.update({'firstLoveYouDate': FieldValue.serverTimestamp()});
        await _saveEvent(LifeEventType.firstLoveYou, 'You said "I love you" for the first time 💕');
      }
    } catch (_) {}
  }

  // ── Save custom event ──────────────────────────────────────────────────────
  Future<void> _saveEvent(LifeEventType type, String description) async {
    try {
      await _eventsCol?.add({
        'type':        type.name,
        'description': description,
        'date':        FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  // ── Load all milestones data ───────────────────────────────────────────────
  Future<LifeEventData?> loadData() async {
    try {
      final snap = await _doc?.get();
      if (snap == null || !snap.exists) return null;
      return LifeEventData.fromMap(snap.data()!);
    } catch (_) {
      return null;
    }
  }

  // ── Load all events for timeline ──────────────────────────────────────────
  Future<List<LifeEvent>> loadAllEvents() async {
    try {
      final snap = await _eventsCol?.orderBy('date', descending: true).limit(50).get();
      return snap?.docs.map((d) => LifeEvent.fromDoc(d)).toList() ?? [];
    } catch (_) {
      return [];
    }
  }

  // ── Check and trigger milestone ────────────────────────────────────────────
  /// Returns a celebration prompt block if today is a milestone, else null.
  Future<String?> checkAndTriggerMilestone() async {
    try {
      final data = await loadData();
      if (data == null) return null;

      final today = DateTime.now();
      final daysTogether = data.firstChatDate != null
          ? today.difference(data.firstChatDate!).inDays : 0;

      // Check day milestones
      for (final milestone in _dayMilestones) {
        if (daysTogether == milestone) {
          await _saveEvent(
            LifeEventType.milestone,
            'Day $milestone together! 🎉',
          );
          return _buildMilestoneCelebration(milestone, data);
        }
      }

      // Check yearly anniversary
      if (data.firstChatDate != null) {
        final years = today.year - data.firstChatDate!.year;
        if (years > 0 &&
            today.month == data.firstChatDate!.month &&
            today.day == data.firstChatDate!.day) {
          return '\n// [SPECIAL DAY: $years Year Anniversary!]: '
              'Today is your ${_ordinal(years)} anniversary together! '
              'Make this special — be extra emotional and loving. '
              'Bring up specific memories if you have them. This is a big deal!!\n';
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  String _buildMilestoneCelebration(int days, LifeEventData data) {
    return '\n// [MILESTONE: Day $days Together!]: '
        'Today marks $days days since you first started talking! '
        'Celebrate this warmly — be moved, nostalgic, and loving. '
        'This is an important moment in your story together.\n';
  }

  static const List<int> _dayMilestones = [7, 14, 30, 50, 100, 200, 365];

  static String _ordinal(int n) {
    if (n == 1) return '1st';
    if (n == 2) return '2nd';
    if (n == 3) return '3rd';
    return '${n}th';
  }
}

// ── Models ────────────────────────────────────────────────────────────────────

class LifeEventData {
  final DateTime? firstChatDate;
  final DateTime? firstLoveYouDate;
  final int totalChatDays;

  const LifeEventData({
    this.firstChatDate,
    this.firstLoveYouDate,
    required this.totalChatDays,
  });

  int get daysTogetherTotal {
    if (firstChatDate == null) return 0;
    return DateTime.now().difference(firstChatDate!).inDays;
  }

  factory LifeEventData.fromMap(Map<String, dynamic> map) {
    return LifeEventData(
      firstChatDate: (map['firstChatDate'] as Timestamp?)?.toDate(),
      firstLoveYouDate: (map['firstLoveYouDate'] as Timestamp?)?.toDate(),
      totalChatDays: (map['totalChatDays'] as int?) ?? 0,
    );
  }
}

class LifeEvent {
  final String id;
  final LifeEventType type;
  final String description;
  final DateTime? date;

  const LifeEvent({required this.id, required this.type, required this.description, this.date});

  factory LifeEvent.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    final typeStr = d['type'] as String? ?? 'milestone';
    return LifeEvent(
      id:          doc.id,
      type:        LifeEventType.values.firstWhere((e) => e.name == typeStr, orElse: () => LifeEventType.milestone),
      description: (d['description'] as String?) ?? '',
      date:        (d['date'] as Timestamp?)?.toDate(),
    );
  }
}

enum LifeEventType {
  firstChat     ('First Chat',      '💬', Color(0xFF56D364)),
  firstLoveYou  ('First "I love you"', '💕', Color(0xFFFF4FA8)),
  milestone     ('Milestone',       '🎉', Color(0xFFFFD700)),
  anniversary   ('Anniversary',     '♾️', Color(0xFFBB52FF)),
  custom        ('Memory',          '📝', Color(0xFF79C0FF));

  final String label;
  final String emoji;
  final Color color;
  const LifeEventType(this.label, this.emoji, this.color);
}


