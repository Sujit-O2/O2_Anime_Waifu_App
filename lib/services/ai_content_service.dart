import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../api_call.dart';

/// Generates content via AI and caches it in Firestore per user per day.
/// Path: ai_content/{uid}/{collection} → { items: [...], generatedDate: "YYYY-MM-DD" }
class AiContentService {
  static final _fs = FirebaseFirestore.instance;
  static final _api = ApiService();

  static String get _today {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  static DocumentReference? _ref(String collection) {
    final uid = _uid;
    if (uid == null) return null;
    return _fs.collection('ai_content').doc(uid).collection(collection).doc(_today);
  }

  /// Try to load today's cache. If missing, generate via AI and store.
  static Future<List<dynamic>> _getOrGenerate(
      String collection, String prompt, int count) async {
    final ref = _ref(collection);
    if (ref != null) {
      try {
        final snap = await ref.get();
        if (snap.exists) {
          final data = snap.data() as Map<String, dynamic>;
          final items = data['items'] as List<dynamic>?;
          if (items != null && items.isNotEmpty) return items;
        }
      } catch (_) {}
    }

    // Generate via AI
    final raw = await _api.sendConversation([
      {'role': 'user', 'content': prompt}
    ]);

    // Strip markdown fences if any
    final cleaned = raw
        .replaceAll(RegExp(r'```json\s*'), '')
        .replaceAll(RegExp(r'```\s*'), '')
        .trim();

    List<dynamic> items = [];
    try {
      final decoded = jsonDecode(cleaned);
      if (decoded is List) {
        items = decoded;
      } else if (decoded is Map && decoded.containsKey('items')) {
        items = decoded['items'] as List<dynamic>;
      }
    } catch (_) {
      // Fallback: split by newline
      items = cleaned
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .take(count)
          .toList();
    }

    // Store to Firestore
    if (ref != null && items.isNotEmpty) {
      try {
        await ref.set({'items': items, 'generatedDate': _today,
          'createdAt': FieldValue.serverTimestamp()});
      } catch (_) {}
    }

    return items;
  }

  // ─── Fortune Cookies ────────────────────────────────────────────────────────
  static Future<List<String>> getFortunes() async {
    const prompt = 'Generate 15 unique fortune cookie messages in the style of '
        'Zero Two from DARLING in the FRANXX. Each is 1-2 sentences, poetic, '
        'romantic, and encouraging. Return ONLY a JSON array of strings, no '
        'markdown, no explanation.';
    final items = await _getOrGenerate('fortune_cookies', prompt, 15);
    return items.map((e) => e.toString()).toList();
  }

  // ─── Daily Affirmations ─────────────────────────────────────────────────────
  static Future<List<String>> getAffirmations() async {
    const prompt = 'Generate 20 daily affirmations in Zero Two\'s voice from '
        'DARLING in the FRANXX. Each is 1-2 sentences, empowering, loving, '
        'and motivating. Return ONLY a JSON array of strings.';
    final items = await _getOrGenerate('affirmations', prompt, 20);
    return items.map((e) => e.toString()).toList();
  }

  // ─── Daily Trivia (DITF lore) ───────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getTrivia() async {
    const prompt = 'Generate 10 trivia questions about DARLING in the FRANXX '
        'anime lore, characters, and plot. Return ONLY a JSON array where each '
        'item is: {"q":"...","options":["A","B","C","D"],"answer":"A","explanation":"..."}. '
        'No markdown.';
    final items = await _getOrGenerate('trivia', prompt, 10);
    return items.map((e) {
      if (e is Map) return Map<String, dynamic>.from(e);
      return <String, dynamic>{'q': e.toString(), 'options': [], 'answer': '', 'explanation': ''};
    }).toList();
  }

  // ─── Zero Two Facts ─────────────────────────────────────────────────────────
  static Future<List<String>> getZeroTwoFacts() async {
    const prompt = 'Generate 20 interesting facts about Zero Two and the '
        'DARLING in the FRANXX universe. Include lore details, character '
        'background, and series facts. Return ONLY a JSON array of strings.';
    final items = await _getOrGenerate('zt_facts', prompt, 20);
    return items.map((e) => e.toString()).toList();
  }

  // ─── Never Have I Ever ──────────────────────────────────────────────────────
  static Future<List<String>> getNeverHaveIEver() async {
    const prompt = 'Generate 25 "Never Have I Ever" prompts for couples inspired '
        'by DARLING in the FRANXX. Mix romantic, fun, and anime-themed scenarios. '
        'Each starts with "Never have I ever...". Return ONLY a JSON array of strings.';
    final items = await _getOrGenerate('nhiever', prompt, 25);
    return items.map((e) => e.toString()).toList();
  }

  // ─── Truth or Dare ──────────────────────────────────────────────────────────
  static Future<Map<String, List<String>>> getTruthOrDare() async {
    const prompt = 'Generate 20 romantic truth questions and 20 fun dare challenges '
        'for couples inspired by Zero Two and DARLING in the FRANXX. '
        'Return ONLY JSON: {"truths":["..."],"dares":["..."]}. No markdown.';
    final ref = _ref('truth_dare');
    if (ref != null) {
      try {
        final snap = await ref.get();
        if (snap.exists) {
          final data = snap.data() as Map<String, dynamic>;
          final truths = (data['truths'] as List?)?.map((e) => e.toString()).toList() ?? [];
          final dares = (data['dares'] as List?)?.map((e) => e.toString()).toList() ?? [];
          if (truths.isNotEmpty && dares.isNotEmpty) return {'truths': truths, 'dares': dares};
        }
      } catch (_) {}
    }

    final raw = await _api.sendConversation([{'role': 'user', 'content': prompt}]);
    final cleaned = raw.replaceAll(RegExp(r'```json\s*'), '').replaceAll(RegExp(r'```\s*'), '').trim();

    List<String> truths = [], dares = [];
    try {
      final decoded = jsonDecode(cleaned) as Map<String, dynamic>;
      truths = (decoded['truths'] as List).map((e) => e.toString()).toList();
      dares = (decoded['dares'] as List).map((e) => e.toString()).toList();
    } catch (_) {
      truths = ['Tell me your most embarrassing childhood memory~'];
      dares = ['Do your best Zero Two impression! 💕'];
    }

    if (ref != null) {
      try {
        await ref.set({'truths': truths, 'dares': dares, 'generatedDate': _today,
          'createdAt': FieldValue.serverTimestamp()});
      } catch (_) {}
    }
    return {'truths': truths, 'dares': dares};
  }

  // ─── Would You Rather ───────────────────────────────────────────────────────
  static Future<List<Map<String, String>>> getWouldYouRather() async {
    const prompt = 'Generate 15 "Would You Rather" dilemmas for couples inspired '
        'by DARLING in the FRANXX. Mix sweet, romantic, and fun scenarios. '
        'Return ONLY a JSON array: [{"optionA":"...","optionB":"..."}]. No markdown.';
    final items = await _getOrGenerate('wyr', prompt, 15);
    return items.map((e) {
      if (e is Map) {
        return {
          'optionA': (e['optionA'] ?? e['option_a'] ?? 'Option A').toString(),
          'optionB': (e['optionB'] ?? e['option_b'] ?? 'Option B').toString(),
        };
      }
      return {'optionA': 'Option A', 'optionB': 'Option B'};
    }).toList();
  }

  // ─── Love Quiz ──────────────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getLoveQuiz() async {
    const prompt = 'Generate 10 fun love & relationship quiz questions. '
        'Each has 4 options with one correct answer and a short sweet explanation. '
        'Return ONLY JSON array: [{"q":"...","options":["A","B","C","D"],'
        '"answer":"A","explanation":"..."}]. No markdown.';
    final items = await _getOrGenerate('love_quiz', prompt, 10);
    return items.map((e) {
      if (e is Map) return Map<String, dynamic>.from(e);
      return <String, dynamic>{'q': e.toString(), 'options': [], 'answer': '', 'explanation': ''};
    }).toList();
  }

  // ─── Workouts ───────────────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getWorkouts() async {
    const prompt = 'Generate 12 diverse workout exercises (mix cardio, strength, '
        'flexibility). Each has name, sets, reps, and a short description. '
        'Return ONLY JSON array: [{"name":"...","sets":"3","reps":"12",'
        '"desc":"...","muscle":"..."}]. No markdown.';
    final items = await _getOrGenerate('workouts', prompt, 12);
    return items.map((e) {
      if (e is Map) return Map<String, dynamic>.from(e);
      return <String, dynamic>{'name': e.toString(), 'sets': '3', 'reps': '10', 'desc': '', 'muscle': ''};
    }).toList();
  }

  // ─── Gratitude Prompts ──────────────────────────────────────────────────────
  static Future<List<String>> getGratitudePrompts() async {
    const prompt = 'Generate 30 daily gratitude journal prompts in Zero Two\'s '
        'loving voice. Mix deep reflection, love, growth, and happiness themes. '
        'Each is a short question or sentence starter. Return ONLY a JSON array of strings.';
    final items = await _getOrGenerate('gratitude_prompts', prompt, 30);
    return items.map((e) => e.toString()).toList();
  }

  // ─── Wordle Words ───────────────────────────────────────────────────────────
  static Future<List<String>> getWordleWords() async {
    const prompt = 'Generate 60 5-letter English words related to anime, '
        'romance, DARLING in the FRANXX, and Japanese culture. ALL must be '
        'exactly 5 letters and real words. Return ONLY a JSON array of '
        'uppercase strings. No markdown.';
    final items = await _getOrGenerate('wordle_words', prompt, 60);
    return items.map((e) => e.toString().toUpperCase().trim())
        .where((w) => w.length == 5)
        .toList();
  }

  // ─── Anime Quiz ─────────────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getAnimeQuiz() async {
    const prompt = 'Generate 25 anime general knowledge questions (not just DITF). '
        'Each has 4 options. Return ONLY JSON array: '
        '[{"q":"...","options":["A. ...","B. ...","C. ...","D. ..."],"answer":"A"}]. '
        'No markdown.';
    final items = await _getOrGenerate('anime_quiz', prompt, 25);
    return items.map((e) {
      if (e is Map) return Map<String, dynamic>.from(e);
      return <String, dynamic>{'q': e.toString(), 'options': [], 'answer': 'A'};
    }).toList();
  }

  // ─── Refresh (force regenerate today's batch) ───────────────────────────────
  static Future<void> forceRefresh(String collection) async {
    final ref = _ref(collection);
    if (ref != null) {
      try { await ref.delete(); } catch (_) {}
    }
  }
}
