import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// RagEmbeddingService — True Vector Embedding RAG for AI Chat
///
/// Pipeline:
///   1. INGEST: User/assistant messages → OpenAI text-embedding-3-small → vector
///   2. STORE:  Vectors saved locally as JSON in SharedPreferences
///   3. SEARCH: On each query → embed query → cosine similarity → top-K results
///   4. INJECT: Format top-K chunks into a context block for the AI system prompt
///
/// OPTIMIZED for minimal API usage:
///   • Single API call per message (reuses query embedding for storage)
///   • 30-second cooldown between RAG calls (skips if too frequent)
///   • Skips messages under 15 chars
///   • Caches embeddings in memory to avoid re-embedding
///   • Only embeds every 3rd assistant message (user messages always embedded)
///
/// Uses the same API key the user configured for their AI model.
/// Falls back gracefully if API is unreachable.
/// ─────────────────────────────────────────────────────────────────────────────
class RagEmbeddingService {
  static final RagEmbeddingService instance = RagEmbeddingService._();
  RagEmbeddingService._();

  static const String _storageKey = 'rag_vector_store_v1';
  static const String _embeddingModel = 'text-embedding-3-small';
  static const int _maxStoredChunks = 200;
  static const int _topK = 5;
  static const double _minSimilarity = 0.35;
  static const int _cooldownSeconds = 30;  // Min seconds between RAG calls
  static const int _minTextLength = 15;    // Skip tiny messages

  // In-memory cache
  List<RagChunk>? _cache;
  DateTime? _lastRagCall;
  int _assistantMsgCount = 0;  // Counter to skip some assistant messages

  // ── MAIN ENTRY: Search + Ingest in ONE API call ────────────────────────────
  /// Replaces separate search() + ingestMessage() to use only 1 embedding call.
  /// Call this from _refreshPhase2Extras().
  Future<String> buildRagContextBlock(String currentMessage) async {
    // Skip if message too short
    if (currentMessage.trim().length < _minTextLength) return '';

    // Cooldown: skip if last call was too recent
    if (_lastRagCall != null) {
      final elapsed = DateTime.now().difference(_lastRagCall!).inSeconds;
      if (elapsed < _cooldownSeconds) {
        debugPrint('RAG: skipping (cooldown ${_cooldownSeconds - elapsed}s remaining)');
        return '';
      }
    }

    try {
      final apiKey = await _getApiKey();
      if (apiKey == null || apiKey.isEmpty) return '';

      // ── SINGLE API CALL: embed the current message ─────────────────────
      final queryEmbedding = await _embed(currentMessage, apiKey);
      if (queryEmbedding == null) return '';

      _lastRagCall = DateTime.now();

      // ── SEARCH: cosine similarity against stored vectors ───────────────
      final store = await _loadStore();
      final results = <RagResult>[];

      for (final chunk in store) {
        if (chunk.embedding.isEmpty) continue;
        final sim = _cosineSimilarity(queryEmbedding, chunk.embedding);
        if (sim >= _minSimilarity) {
          results.add(RagResult(chunk: chunk, similarity: sim));
        }
      }

      results.sort((a, b) => b.similarity.compareTo(a.similarity));
      final topResults = results.take(_topK).toList();

      // ── REUSE EMBEDDING FOR INGEST (no extra API call!) ────────────────
      final chunk = RagChunk(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: currentMessage.length > 300
            ? currentMessage.substring(0, 300)
            : currentMessage,
        source: 'user',
        embedding: queryEmbedding,
        timestamp: DateTime.now(),
      );

      store.add(chunk);
      if (store.length > _maxStoredChunks) {
        store.removeRange(0, store.length - _maxStoredChunks);
      }
      await _saveStore(store);
      _cache = store;

      // ── FORMAT RESULTS ─────────────────────────────────────────────────
      if (topResults.isEmpty) return '';

      final buf = StringBuffer(
        '\n// [RAG Memory Retrieval — semantically relevant past conversations]:\n');
      for (final r in topResults) {
        final age = DateTime.now().difference(r.chunk.timestamp);
        final ageStr = age.inDays == 0
            ? 'today'
            : age.inDays == 1
                ? 'yesterday'
                : '${age.inDays}d ago';
        final simPct = (r.similarity * 100).toStringAsFixed(0);
        buf.writeln(
          '  [${r.chunk.source}, $ageStr, $simPct% match]: "${r.chunk.text}"');
      }
      buf.writeln();
      return buf.toString();
    } catch (e) {
      debugPrint('RAG context build failed: $e');
      return '';
    }
  }

  // ── INGEST ASSISTANT RESPONSE (only every 3rd to save API calls) ────────────
  /// Call after receiving AI response. Only embeds every 3rd assistant message.
  Future<void> ingestAssistantMessage(String text) async {
    if (text.trim().length < _minTextLength) return;

    _assistantMsgCount++;
    if (_assistantMsgCount % 3 != 0) return; // Skip 2 out of 3

    try {
      final apiKey = await _getApiKey();
      if (apiKey == null || apiKey.isEmpty) return;

      final embedding = await _embed(text, apiKey);
      if (embedding == null) return;

      final store = await _loadStore();
      store.add(RagChunk(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text.length > 300 ? text.substring(0, 300) : text,
        source: 'assistant',
        embedding: embedding,
        timestamp: DateTime.now(),
      ));

      if (store.length > _maxStoredChunks) {
        store.removeRange(0, store.length - _maxStoredChunks);
      }
      await _saveStore(store);
      _cache = store;
    } catch (e) {
      debugPrint('RAG assistant ingest failed: $e');
    }
  }

  /// Bulk ingest (e.g., memories on first run). Rate limited internally.
  Future<void> ingestBulk(List<String> texts, String source) async {
    final apiKey = await _getApiKey();
    if (apiKey == null || apiKey.isEmpty) return;

    for (final text in texts) {
      if (text.trim().length < _minTextLength) continue;
      try {
        final store = await _loadStore();
        final textHash = text.hashCode.toString();
        if (store.any((c) => c.id == textHash)) continue;

        final embedding = await _embed(text, apiKey);
        if (embedding == null) continue;

        store.add(RagChunk(
          id: textHash,
          text: text.length > 300 ? text.substring(0, 300) : text,
          source: source,
          embedding: embedding,
          timestamp: DateTime.now(),
        ));

        if (store.length > _maxStoredChunks) {
          store.removeRange(0, store.length - _maxStoredChunks);
        }
        await _saveStore(store);
        _cache = store;

        await Future.delayed(const Duration(milliseconds: 300));
      } catch (e) {
        debugPrint('RAG bulk ingest error: $e');
      }
    }
  }

  // ── EMBEDDING API CALL ─────────────────────────────────────────────────────
  Future<List<double>?> _embed(String text, String apiKey) async {
    try {
      final resp = await http.post(
        Uri.parse('https://api.openai.com/v1/embeddings'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _embeddingModel,
          'input': text.replaceAll('\n', ' ').trim(),
        }),
      ).timeout(const Duration(seconds: 15));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final embeddingData = data['data']?[0]?['embedding'] as List?;
        if (embeddingData != null) {
          return embeddingData.map<double>((e) => (e as num).toDouble()).toList();
        }
      } else {
        debugPrint('Embedding API ${resp.statusCode}');
      }
      return null;
    } catch (e) {
      debugPrint('Embedding API failed: $e');
      return null;
    }
  }

  // ── COSINE SIMILARITY ──────────────────────────────────────────────────────
  double _cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length || a.isEmpty) return 0.0;
    double dot = 0, magA = 0, magB = 0;
    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      magA += a[i] * a[i];
      magB += b[i] * b[i];
    }
    final magnitude = math.sqrt(magA) * math.sqrt(magB);
    return magnitude > 0 ? dot / magnitude : 0.0;
  }

  // ── LOCAL STORAGE ──────────────────────────────────────────────────────────
  Future<List<RagChunk>> _loadStore() async {
    if (_cache != null) return _cache!;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw) as List;
      _cache = list.map((j) => RagChunk.fromJson(j as Map<String, dynamic>)).toList();
      return _cache!;
    } catch (e) {
      debugPrint('RAG store load failed: $e');
      return [];
    }
  }

  Future<void> _saveStore(List<RagChunk> store) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(store.map((c) => c.toJson()).toList());
      await prefs.setString(_storageKey, json);
    } catch (e) {
      debugPrint('RAG store save failed: $e');
    }
  }

  Future<String?> _getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('api_key');
  }

  // ── STATS ──────────────────────────────────────────────────────────────────
  Future<int> getStoredChunkCount() async {
    final store = await _loadStore();
    return store.length;
  }

  Future<void> clearStore() async {
    _cache = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}

// ── Data Models ──────────────────────────────────────────────────────────────

class RagChunk {
  final String id;
  final String text;
  final String source;
  final List<double> embedding;
  final DateTime timestamp;

  RagChunk({
    required this.id, required this.text, required this.source,
    required this.embedding, required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'text': text, 'source': source,
    'embedding': embedding, 'timestamp': timestamp.toIso8601String(),
  };

  factory RagChunk.fromJson(Map<String, dynamic> j) => RagChunk(
    id: j['id'] ?? '', text: j['text'] ?? '', source: j['source'] ?? 'unknown',
    embedding: (j['embedding'] as List?)
        ?.map<double>((e) => (e as num).toDouble()).toList() ?? [],
    timestamp: DateTime.tryParse(j['timestamp'] ?? '') ?? DateTime.now(),
  );
}

class RagResult {
  final RagChunk chunk;
  final double similarity;
  const RagResult({required this.chunk, required this.similarity});
}


