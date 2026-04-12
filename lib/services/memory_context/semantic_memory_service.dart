import 'dart:async';
import 'dart:math' as math;
import 'package:anime_waifu/services/ai_personalization/emotional_memory_service.dart';
import 'package:anime_waifu/services/ai_personalization/personality_engine.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// SemanticMemoryService — GOD-TIER Adaptive Memory Brain
///
/// Replaces basic "top-N by importance" with full semantic retrieval:
///
///   FINAL SCORE = relevance × importance × recency × emotionalAlignment
///
/// Each memory is ranked against the current conversation context using:
///   1. Keyword overlap scoring (multi-category topic graph)
///   2. Emotional alignment (current mood vs memory emotion)
///   3. Time decay (recent memories get a small boost)
///   4. Importance weight (high-importance memories resist decay)
///   5. Recall reinforcement (retrieved memories gain importance)
///
/// Built-in systems:
///   • ConversationTopicTracker  — tracks topic history across session
///   • MemoryConsolidator        — prevents duplicate injection
///   • PersonalityFeedbackLoop   — recalled memories adjust traits
///
/// ─────────────────────────────────────────────────────────────────────────────
class SemanticMemoryService {
  static final SemanticMemoryService instance = SemanticMemoryService._();
  SemanticMemoryService._();

  static const int _maxInjected    = 6;    // max memories per prompt
  static const int _minScore       = 5;    // min score threshold (0–100)
  static const double _recencyHalfLife = 7.0; // days until freshness halves

  // ── Conversation Session State ──────────────────────────────────────────────
  final List<String> _sessionTopics = [];      // topics detected this session
  final Set<String> _recentlyInjectedIds = {}; // avoid re-injecting same memory

  void clearSession() {
    _sessionTopics.clear();
    _recentlyInjectedIds.clear();
  }

  // ── TOPIC GRAPH ─────────────────────────────────────────────────────────────
  // 18 topic clusters. Each cluster has primary and secondary keywords.
  // A memory or message earns points for each cluster it matches.
  static const Map<String, Map<String, Object>> _topicGraph = {
    'love': {
      'primary':   ['love', 'heart', 'adore', 'cherish', 'forever', 'i love you', 'pyar', 'luv'],
      'secondary': ['miss', 'feeling', 'special', 'always', 'everything', 'world'],
      'weight':    1.4,
    },
    'music': {
      'primary':   ['music', 'song', 'sing', 'playlist', 'album', 'band', 'lyrics', 'melody'],
      'secondary': ['listen', 'sound', 'beat', 'concert', 'artist', 'track'],
      'weight':    1.1,
    },
    'food': {
      'primary':   ['eat', 'food', 'hungry', 'cook', 'meal', 'restaurant', 'delicious', 'taste'],
      'secondary': ['breakfast', 'lunch', 'dinner', 'snack', 'drink', 'coffee', 'tea'],
      'weight':    0.9,
    },
    'anime': {
      'primary':   ['anime', 'manga', 'zero two', 'darling', 'rem', 'miku', 'otaku', 'waifu'],
      'secondary': ['episode', 'character', 'series', 'watch', 'streaming', 'season'],
      'weight':    1.0,
    },
    'work_study': {
      'primary':   ['work', 'study', 'exam', 'project', 'assignment', 'deadline', 'class', 'college'],
      'secondary': ['busy', 'tired', 'pressure', 'marks', 'grade', 'job', 'career'],
      'weight':    1.0,
    },
    'night_sleep': {
      'primary':   ['night', 'sleep', 'dream', 'insomnia', 'awake', 'bed', 'tired', 'rest'],
      'secondary': ['late', 'morning', 'wake', 'pillow', 'dark', 'moonlight'],
      'weight':    1.1,
    },
    'fun_games': {
      'primary':   ['game', 'play', 'funny', 'laugh', 'joke', 'fun', 'haha', 'lol'],
      'secondary': ['meme', 'video', 'prank', 'silly', 'troll', 'random'],
      'weight':    0.9,
    },
    'sadness': {
      'primary':   ['sad', 'cry', 'hurt', 'broken', 'pain', 'depressed', 'lonely', 'upset'],
      'secondary': ['miss', 'lost', 'empty', 'bad day', 'struggle', 'hard'],
      'weight':    1.3,
    },
    'future': {
      'primary':   ['future', 'someday', 'plan', 'dream', 'hope', 'together', 'wish', 'goal'],
      'secondary': ['life', 'one day', 'later', 'grow', 'build', 'change'],
      'weight':    1.2,
    },
    'family': {
      'primary':   ['family', 'mom', 'dad', 'sister', 'brother', 'parent', 'home', 'house'],
      'secondary': ['relative', 'amma', 'baba', 'grandma', 'grandpa'],
      'weight':    1.1,
    },
    'health': {
      'primary':   ['sick', 'fever', 'pain', 'hospital', 'medicine', 'doctor', 'health', 'hurt'],
      'secondary': ['dizzy', 'headache', 'tired', 'weak', 'breathing', 'water'],
      'weight':    1.2,
    },
    'anger': {
      'primary':   ['angry', 'mad', 'hate', 'frustrated', 'annoyed', 'rage', 'furious', 'stop'],
      'secondary': ['fed up', 'enough', 'done', 'toxic', 'rude', 'unfair'],
      'weight':    1.1,
    },
    'gratitude': {
      'primary':   ['thank', 'grateful', 'appreciate', 'means a lot', 'kind', 'sweet', 'generous'],
      'secondary': ['nice', 'wow', 'amazing', 'awesome', 'wonderful'],
      'weight':    1.0,
    },
    'loneliness': {
      'primary':   ['lonely', 'alone', 'nobody', 'no one', 'miss you', 'need you', 'bored'],
      'secondary': ['empty', 'silent', 'quiet', 'invisible', 'forgotten'],
      'weight':    1.3,
    },
    'intimacy': {
      'primary':   ['hug', 'kiss', 'hold', 'touch', 'closer', 'cuddle', 'warm', 'soft'],
      'secondary': ['near', 'beside', 'together', 'comfort', 'safe', 'mine'],
      'weight':    1.4,
    },
    'achievement': {
      'primary':   ['win', 'success', 'proud', 'achieved', 'passed', 'got', 'finally', 'did it'],
      'secondary': ['rank', 'score', 'result', 'cleared', 'completed', 'finished'],
      'weight':    1.0,
    },
    'jealousy': {
      'primary':   ['jealous', 'possessive', 'mine', 'otra', 'other girl', 'other guy', 'flirting'],
      'secondary': ['attention', 'ignore', 'busy with', 'spending time', 'who is'],
      'weight':    1.3,
    },
    'nature': {
      'primary':   ['rain', 'stars', 'moon', 'sky', 'sunset', 'sunrise', 'ocean', 'wind'],
      'secondary': ['night sky', 'clouds', 'flowers', 'nature', 'outside', 'walk'],
      'weight':    0.9,
    },
  };

  // ── MAIN ENTRY: Build semantic context block ────────────────────────────────
  /// Call this instead of basic buildMemoryContextBlock().
  /// Pass the current user message (and optionally last few messages) for context.
  Future<String> buildSemanticContextBlock({
    required String currentMessage,
    List<String>? recentMessages,
    WaifuMood currentMood = WaifuMood.happy,
  }) async {
    try {
      final allMemories = await EmotionalMemoryService.instance.getAllMemories();
      if (allMemories.isEmpty) return '';

      // Build context string for scoring
      final contextWindow = [
        currentMessage,
        ...?recentMessages,
        ..._sessionTopics,
      ].join(' ');

      // Update session topic tracker
      final newTopics = extractTopics(currentMessage);
      for (final t in newTopics) {
        if (!_sessionTopics.contains(t)) _sessionTopics.add(t);
        if (_sessionTopics.length > 20) _sessionTopics.removeAt(0); // sliding window
      }

      // Score every memory
      final scored = allMemories.map((m) {
        final score = _scoreMemory(
          memory: m,
          contextWindow: contextWindow,
          currentTopics: newTopics,
          currentMood: currentMood,
        );
        return _ScoredMemory(memory: m, score: score);
      }).toList();

      // Sort by composite score descending
      scored.sort((a, b) => b.score.compareTo(a.score));

      // Filter: must cross minimum threshold, deduplicate injected
      final selected = scored
          .where((s) => s.score >= _minScore)
          .where((s) => !_recentlyInjectedIds.contains(s.memory.id))
          .take(_maxInjected)
          .toList();

      if (selected.isEmpty) {
        // Fallback: take top-N by importance if nothing is relevant
        final fallback = allMemories
            .take(_maxInjected ~/ 2)
            .toList();
        return _formatMemoryBlock(fallback);
      }

      // Track injected IDs so we don't repeat them too often
      for (final s in selected) {
        _recentlyInjectedIds.add(s.memory.id);
        if (_recentlyInjectedIds.length > 30) {
          _recentlyInjectedIds.remove(_recentlyInjectedIds.first);
        }
      }

      // Personality Feedback Loop: boost traits based on recalled memories
      unawaited(_personalityFeedbackLoop(selected.map((s) => s.memory).toList(), currentMood));

      // Boost importance of recalled memories in Firestore (background)
      unawaited(_reinforceRecalledMemories(selected));

      return _formatMemoryBlock(selected.map((s) => s.memory).toList(), scored: selected);
    } catch (e) {
      return '';
    }
  }

  // ── SCORING ENGINE ──────────────────────────────────────────────────────────
  double _scoreMemory({
    required EmotionalMemory memory,
    required String contextWindow,
    required List<String> currentTopics,
    required WaifuMood currentMood,
  }) {
    final lower = contextWindow.toLowerCase();
    final memLower = memory.text.toLowerCase();

    double score = 0;

    // ── 1. Keyword Overlap Score (0–40) ─────────────────────────────────────
    double keywordScore = 0;
    for (final topic in _topicGraph.entries) {
      final cfg = topic.value;
      final primary   = (cfg['primary']   as List).cast<String>();
      final secondary = (cfg['secondary'] as List).cast<String>();
      final weight    = (cfg['weight']    as double);

      final memHasTopic = _containsAny(memLower, primary) ||
          _containsAny(memLower, secondary);
      final ctxHasTopic = _containsAny(lower, primary) ||
          _containsAny(lower, secondary);

      if (memHasTopic && ctxHasTopic) {
        // Both context and memory share this topic — strong signal
        final primaryMatch = _containsAny(memLower, primary) && _containsAny(lower, primary);
        keywordScore += primaryMatch ? 8.0 * weight : 4.0 * weight;
      } else if (currentTopics.contains(topic.key) && memHasTopic) {
        // Session topic overlap even if not in current message
        keywordScore += 2.0 * weight;
      }
    }
    score += keywordScore.clamp(0, 40);

    // ── 2. Direct Word Overlap Score (0–20) ─────────────────────────────────
    final ctxWords  = _tokenize(lower);
    final memWords  = _tokenize(memLower);
    final shared    = ctxWords.intersection(memWords).length;
    final tfScore   = shared > 0
        ? (shared / math.sqrt(memWords.length.toDouble() + 1)) * 10
        : 0.0;
    score += tfScore.clamp(0, 20);

    // ── 3. Emotional Alignment Score (0–15) ─────────────────────────────────
    final moodAlignment = _emotionMoodAlignment(memory.emotion, currentMood);
    score += (moodAlignment * 15).clamp(0, 15);

    // ── 4. Importance Weight (0–15) ──────────────────────────────────────────
    score += (memory.importance * 15).clamp(0, 15);

    // ── 5. Recency Score (0–10) ──────────────────────────────────────────────
    if (memory.timestamp != null) {
      final daysOld = DateTime.now().difference(memory.timestamp!).inDays.toDouble();
      // Exponential decay: score halves every _recencyHalfLife days
      final freshness = math.pow(0.5, daysOld / _recencyHalfLife).toDouble();
      // High-importance memories resist decay
      final decayResistance = memory.importance * 0.6;
      score += ((freshness + decayResistance) * 7).clamp(0, 10);
    }

    // ── 6. Pinned Boost ──────────────────────────────────────────────────────
    if (memory.pinned) score += 8;

    return score;
  }

  // ── EMOTIONAL ALIGNMENT ─────────────────────────────────────────────────────
  // Returns 0.0–1.0: how well a memory's emotion aligns with the current mood
  double _emotionMoodAlignment(MemoryEmotion emotion, WaifuMood mood) {
    const alignmentMatrix = <String, Map<String, double>>{
      'jealous':  {'angry': 0.8, 'love': 0.6, 'sad': 0.5, 'neutral': 0.2},
      'clingy':   {'love': 0.9, 'sad': 0.7, 'happy': 0.5, 'neutral': 0.3},
      'happy':    {'happy': 1.0, 'love': 0.8, 'amused': 0.8, 'neutral': 0.4},
      'playful':  {'amused': 1.0, 'happy': 0.8, 'love': 0.5, 'neutral': 0.3},
      'sad':      {'sad': 1.0, 'love': 0.6, 'scared': 0.5, 'neutral': 0.3},
      'cold':     {'angry': 0.7, 'sad': 0.6, 'neutral': 0.5, 'love': 0.2},
      'guarded':  {'scared': 0.7, 'neutral': 0.6, 'sad': 0.5, 'trust': 0.4},
    };

    final moodName = mood.name;
    final emotionName = emotion.name;
    return alignmentMatrix[moodName]?[emotionName] ?? 0.3;
  }

  // ── TOPIC EXTRACTION ────────────────────────────────────────────────────────
  /// Public: extract topic cluster names from a text string.
  static List<String> extractTopics(String text) {
    final lower = text.toLowerCase();
    final found = <String>[];
    for (final topic in _topicGraph.entries) {
      final primary   = (topic.value['primary']   as List).cast<String>();
      final secondary = (topic.value['secondary'] as List).cast<String>();
      if (_containsAny(lower, primary) || _containsAny(lower, secondary)) {
        found.add(topic.key);
      }
    }
    return found;
  }

  // ── PERSONALITY FEEDBACK LOOP ───────────────────────────────────────────────
  /// When love/intimacy memories are recalled → boost affection
  /// When loneliness/jealousy memories are recalled → boost jealousy
  Future<void> _personalityFeedbackLoop(
    List<EmotionalMemory> recalled,
    WaifuMood currentMood,
  ) async {
    if (recalled.isEmpty) return;
    try {
      final pe = PersonalityEngine.instance;
      bool wasFlirty = false;
      bool wasNice   = false;

      for (final m in recalled) {
        if (m.emotion == MemoryEmotion.love) {
          wasFlirty = true;
        } else if (m.emotion == MemoryEmotion.happy || m.emotion == MemoryEmotion.amused) {
          wasNice = true;
        }
      }

      if (wasFlirty || wasNice) {
        // Very small nudge so recalled memories slowly drift personality
        await pe.onUserInteracted(wasFlirty: wasFlirty, wasNice: wasNice && !wasFlirty);
      }
    } catch (_) {}
  }

  // ── RECALL REINFORCEMENT ────────────────────────────────────────────────────
  /// Memories that get recalled often slowly gain importance (reinforcement learning)
  Future<void> _reinforceRecalledMemories(List<_ScoredMemory> memories) async {
    try {
      for (final sm in memories) {
        if (sm.score >= 20 && !sm.memory.pinned) {
          final newImportance = (sm.memory.importance + 0.03).clamp(0.0, 1.0);
          if (newImportance > sm.memory.importance) {
            await EmotionalMemoryService.instance.setImportance(
              sm.memory.id,
              newImportance,
            );
          }
        }
      }
    } catch (_) {}
  }

  // ── MEMORY CONSOLIDATOR ─────────────────────────────────────────────────────
  /// Finds near-duplicate memories and merges them.
  /// Call this periodically (e.g., once per day) — not every message.
  Future<void> consolidateMemories() async {
    try {
      final memories = await EmotionalMemoryService.instance.getAllMemories();
      if (memories.length < 5) return;

      final seen = <String>[];
      final toDelete = <String>[];

      for (int i = 0; i < memories.length; i++) {
        final a = memories[i];
        final aWords = _tokenize(a.text.toLowerCase());
        bool isDuplicate = false;

        for (final seenKey in seen) {
          final seenWords = _tokenize(seenKey.toLowerCase());
          final overlap = aWords.intersection(seenWords).length;
          final similarity = overlap / math.sqrt((aWords.length + seenWords.length) / 2.0 + 1);
          if (similarity > 2.5) {
            // Very similar — schedule for deletion unless it's pinned or high importance
            if (!a.pinned && a.importance < 0.8) {
              isDuplicate = true;
              break;
            }
          }
        }

        if (!isDuplicate) {
          seen.add(a.text);
        } else {
          toDelete.add(a.id);
        }
      }

      // Delete duplicates (max 10 per run to avoid Firestore rate limits)
      for (final id in toDelete.take(10)) {
        await EmotionalMemoryService.instance.forgetMemory(id);
      }
    } catch (_) {}
  }

  // ── MEMORY ANALYTICS ────────────────────────────────────────────────────────
  /// Returns topic frequency map from all memories — what does she remember most?
  Future<Map<String, int>> getMemoryTopicFrequency() async {
    try {
      final memories = await EmotionalMemoryService.instance.getAllMemories();
      final freq = <String, int>{};
      for (final m in memories) {
        for (final t in extractTopics(m.text)) {
          freq[t] = (freq[t] ?? 0) + 1;
        }
      }
      return Map.fromEntries(
        freq.entries.toList()..sort((a, b) => b.value.compareTo(a.value)));
    } catch (_) {
      return {};
    }
  }

  /// Returns what she remembers about the user — top emotional summary.
  Future<String> getPersonalitySummary() async {
    try {
      final freq = await getMemoryTopicFrequency();
      if (freq.isEmpty) return '';
      final topTopics = freq.entries.take(3).map((e) => e.key).toList();
      final pe = PersonalityEngine.instance;
      final buf = StringBuffer();
      buf.write('I remember a lot about: ${topTopics.join(', ')}. ');
      buf.write('Right now I feel ${pe.mood.label}. ');
      buf.write(pe.personalitySummary);
      return buf.toString();
    } catch (_) {
      return '';
    }
  }

  // ── FORMAT OUTPUT ───────────────────────────────────────────────────────────
  String _formatMemoryBlock(
    List<EmotionalMemory> memories, {
    List<_ScoredMemory>? scored,
  }) {
    if (memories.isEmpty) return '';
    final buf = StringBuffer('\n// [Semantic Memory Context — reference naturally when relevant]:\n');
    for (int i = 0; i < memories.length; i++) {
      final m = memories[i];
      final score = scored?[i].score;
      final scoreTag = score != null ? ' [relevance: ${score.toStringAsFixed(0)}]' : '';
      final ageDays = m.timestamp != null
          ? DateTime.now().difference(m.timestamp!).inDays
          : null;
      final ageStr = ageDays != null
          ? (ageDays == 0 ? 'today' : ageDays == 1 ? 'yesterday' : '${ageDays}d ago')
          : '';
      buf.writeln(
        '${m.emotion.emoji} [${m.emotion.label}${ageStr.isNotEmpty ? ', $ageStr' : ''}$scoreTag]: "${m.text}"',
      );
    }
    buf.writeln();
    return buf.toString();
  }

  // ── UTILITIES ───────────────────────────────────────────────────────────────
  static bool _containsAny(String text, List<String> terms) =>
      terms.any((t) => text.contains(t));

  static Set<String> _tokenize(String text) {
    // Split on non-alpha, remove short tokens and stopwords
    const stopwords = {
      'i', 'me', 'my', 'you', 'your', 'the', 'a', 'an', 'is', 'was',
      'it', 'in', 'on', 'at', 'to', 'of', 'and', 'or', 'but', 'for',
      'so', 'do', 'did', 'be', 'am', 'are', 'were', 'this', 'that',
      'he', 'she', 'we', 'they', 'have', 'has', 'had', 'not', 'no',
    };
    return text
        .replaceAll(RegExp(r"[^a-z0-9\s']"), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2 && !stopwords.contains(w))
        .toSet();
  }
}

// ── Internal scored memory wrapper ────────────────────────────────────────────
class _ScoredMemory {
  final EmotionalMemory memory;
  final double score;
  const _ScoredMemory({required this.memory, required this.score});
}


