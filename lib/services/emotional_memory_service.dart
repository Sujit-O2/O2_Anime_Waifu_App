import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// EmotionalMemoryService
///
/// Stores memories as tagged documents:
///   { text, emotion, importance (0.0–1.0), waifuId, timestamp }
///
/// Top-N memories by importance are injected into every LLM context window,
/// making conversations deeply personal and continuous.
/// ─────────────────────────────────────────────────────────────────────────────
class EmotionalMemoryService {
  static final EmotionalMemoryService instance = EmotionalMemoryService._();
  EmotionalMemoryService._();

  static const int _maxMemories    = 80;
  static const int _contextLimit   = 6;   // max memories injected per prompt

  CollectionReference<Map<String, dynamic>>? get _col {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users').doc(uid)
        .collection('emotional_memories');
  }

  // ── Save a memory ──────────────────────────────────────────────────────────
  /// Call this after AI generates reply to capture emotional context.
  Future<void> saveMemory({
    required String text,
    required MemoryEmotion emotion,
    required double importance,  // 0.0 – 1.0
    String waifuId = 'zero_two',
  }) async {
    try {
      final col = _col;
      if (col == null) return;
      await col.add({
        'text':       text.length > 300 ? text.substring(0, 300) : text,
        'emotion':    emotion.name,
        'importance': importance.clamp(0.0, 1.0),
        'waifuId':    waifuId,
        'timestamp':  FieldValue.serverTimestamp(),
        'pinned':     false,
      });
      await _pruneIfNeeded();
    } catch (_) {}
  }

  // ── Update importance ──────────────────────────────────────────────────────
  Future<void> setImportance(String docId, double importance) async {
    try {
      await _col?.doc(docId).update({'importance': importance.clamp(0.0, 1.0)});
    } catch (_) {}
  }

  /// "Remember this forever" — pins to max importance
  Future<void> pinMemory(String docId) async {
    try {
      await _col?.doc(docId).update({'importance': 1.0, 'pinned': true});
    } catch (_) {}
  }

  /// "Forget this" — deletes the memory
  Future<void> forgetMemory(String docId) async {
    try {
      await _col?.doc(docId).delete();
    } catch (_) {}
  }

  // ── Load memories ──────────────────────────────────────────────────────────
  /// Returns all memories sorted by timestamp (for timeline UI).
  Future<List<EmotionalMemory>> getAllMemories() async {
    try {
      final snap = await _col
          ?.orderBy('timestamp', descending: true)
          .limit(100)
          .get();
      return snap?.docs.map((d) => EmotionalMemory.fromDoc(d)).toList() ?? [];
    } catch (_) {
      return [];
    }
  }

  /// Returns top-N most important memories for LLM context injection.
  Future<List<EmotionalMemory>> getTopMemories() async {
    try {
      final snap = await _col
          ?.orderBy('importance', descending: true)
          .limit(_contextLimit)
          .get();
      return snap?.docs.map((d) => EmotionalMemory.fromDoc(d)).toList() ?? [];
    } catch (_) {
      return [];
    }
  }

  // ── Prompt injection ───────────────────────────────────────────────────────
  /// Builds a compact block of the most important memories for system prompt.
  Future<String> buildMemoryContextBlock() async {
    try {
      final mems = await getTopMemories();
      if (mems.isEmpty) return '';
      final buf = StringBuffer('\n// [Emotional Memories — reference naturally when relevant]:\n');
      for (final m in mems) {
        buf.writeln('${m.emotion.emoji} "${m.text}" (importance: ${(m.importance * 10).round()}/10)');
      }
      buf.writeln();
      return buf.toString();
    } catch (_) {
      return '';
    }
  }

  // ── Auto-detect emotion from text ─────────────────────────────────────────
  /// Simple keyword-based emotion tagger. Returns (emotion, importance).
  static (MemoryEmotion, double) detectEmotion(String text) {
    final lower = text.toLowerCase();
    if (_containsAny(lower, ['love', 'adore', 'cherish', 'miss you', 'i love'])) {
      return (MemoryEmotion.love, 0.9);
    }
    if (_containsAny(lower, ['sorry', 'forgive', 'hurt', 'cry', 'disappointed'])) {
      return (MemoryEmotion.sad, 0.8);
    }
    if (_containsAny(lower, ['angry', 'mad', 'upset', 'hate', 'frustrated'])) {
      return (MemoryEmotion.angry, 0.75);
    }
    if (_containsAny(lower, ['scared', 'afraid', 'anxious', 'worried', 'nervous'])) {
      return (MemoryEmotion.scared, 0.65);
    }
    if (_containsAny(lower, ['happy', 'excited', 'amazing', 'great', 'wonderful', 'yay'])) {
      return (MemoryEmotion.happy, 0.6);
    }
    if (_containsAny(lower, ['haha', 'lol', 'funny', 'laugh', 'lmao'])) {
      return (MemoryEmotion.amused, 0.4);
    }
    return (MemoryEmotion.neutral, 0.2);
  }

  static bool _containsAny(String text, List<String> keywords) =>
      keywords.any((k) => text.contains(k));

  // ── Prune old low-importance memories ─────────────────────────────────────
  Future<void> _pruneIfNeeded() async {
    try {
      final snap = await _col?.orderBy('timestamp', descending: false).get();
      if (snap == null || snap.docs.length <= _maxMemories) return;
      final toDelete = snap.docs
          .where((d) => (d.data()['pinned'] as bool?) != true)
          .take(snap.docs.length - _maxMemories);
      for (final doc in toDelete) { await doc.reference.delete(); }
    } catch (_) {}
  }
}

// ── Models ────────────────────────────────────────────────────────────────────

class EmotionalMemory {
  final String id;
  final String text;
  final MemoryEmotion emotion;
  final double importance;
  final String waifuId;
  final DateTime? timestamp;
  final bool pinned;

  const EmotionalMemory({
    required this.id,
    required this.text,
    required this.emotion,
    required this.importance,
    required this.waifuId,
    this.timestamp,
    required this.pinned,
  });

  factory EmotionalMemory.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    final emotionStr = d['emotion'] as String? ?? 'neutral';
    final emotion = MemoryEmotion.values.firstWhere(
      (e) => e.name == emotionStr,
      orElse: () => MemoryEmotion.neutral,
    );
    final ts = d['timestamp'];
    return EmotionalMemory(
      id:         doc.id,
      text:       (d['text'] as String?) ?? '',
      emotion:    emotion,
      importance: ((d['importance'] as num?)?.toDouble() ?? 0.2).clamp(0.0, 1.0),
      waifuId:    (d['waifuId'] as String?) ?? 'zero_two',
      timestamp:  ts is Timestamp ? ts.toDate() : null,
      pinned:     (d['pinned'] as bool?) ?? false,
    );
  }
}

enum MemoryEmotion {
  love   ('Love',    '💕'),
  happy  ('Happy',   '😊'),
  sad    ('Sad',     '😢'),
  angry  ('Angry',   '😠'),
  scared ('Scared',  '😨'),
  amused ('Amused',  '😂'),
  neutral('Neutral', '💭');

  final String label;
  final String emoji;
  const MemoryEmotion(this.label, this.emoji);
}
