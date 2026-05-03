import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Result of a music generation request.
class MusicGenResult {
  final String audioUrl; // https:// (Replicate/deAPI) or file:// (HuggingFace)
  final String prompt;
  final String provider; // 'deapi' | 'replicate' | 'huggingface'
  final DateTime createdAt;

  const MusicGenResult({
    required this.audioUrl,
    required this.prompt,
    required this.provider,
    required this.createdAt,
  });
}

/// AI Music Generation Service
///
/// Fallback chain (each with shuffled multi-key rotation):
///   1. deAPI.ai AceStep 1.5 Turbo — DEAPI_API_KEY (free $5 on signup, no card)
///   2. Replicate MusicGen (stereo-large) — REPLICATE_API_KEY
///   3. HuggingFace Inference API (musicgen-small) — HF_API_KEY + no-key
///
/// .env keys (comma-separated, shuffled randomly each call):
///   DEAPI_API_KEY     = "deapi_key1,deapi_key2"  (signup: https://deapi.ai/register)
///   REPLICATE_API_KEY = "r8_key1,r8_key2,r8_key3"
///   HF_API_KEY        = "hf_key1,hf_key2"   (optional — free without key, slower)
class MusicGenService {
  MusicGenService._();
  static final MusicGenService instance = MusicGenService._();

  static const _replicateUrl =
      'https://api.replicate.com/v1/predictions';
  static const _replicateMusicGenVersion =
      '671ac645ce5e552cc63a54a2bbff63fcf798043055d2dac5fc9e36a837eedcfb';
  static const _hfUrl =
      'https://api-inference.huggingface.co/models/facebook/musicgen-small';
  static const _deApiUrl =
      'https://api.deapi.ai/api/v2/audio/music';
  static const _pollInterval = Duration(seconds: 3);
  static const _maxPolls = 120; // 6 min

  // ── Key helpers ────────────────────────────────────────────────────────────

  List<String> _keys(String envVar) {
    try {
      return (dotenv.env[envVar] ?? '')
          .split(',')
          .map((k) => k.trim())
          .where((k) => k.isNotEmpty && !k.contains('YOUR_'))
          .toList()
        ..shuffle();
    } catch (_) {
      return [];
    }
  }

  // ── Public ─────────────────────────────────────────────────────────────────

  Future<MusicGenResult> generate({
    required String prompt,
    int durationSeconds = 15,
  }) async {
    // 1. Try deAPI.ai with each key (free $5 credits, no card needed)
    final deApiKeys = _keys('DEAPI_API_KEY');
    for (int i = 0; i < deApiKeys.length; i++) {
      if (kDebugMode) {
        debugPrint('[MusicGen] deAPI key ${i + 1}/${deApiKeys.length}');
      }
      try {
        return await _deApi(
          prompt: prompt,
          duration: durationSeconds,
          key: deApiKeys[i],
        );
      } on _RetryException catch (e) {
        if (kDebugMode) debugPrint('[MusicGen] deAPI retry: $e');
        continue;
      } on MusicGenException {
        rethrow;
      } catch (e) {
        if (kDebugMode) debugPrint('[MusicGen] deAPI error: $e');
        continue;
      }
    }
    if (deApiKeys.isNotEmpty) {
      if (kDebugMode) debugPrint('[MusicGen] All deAPI keys exhausted → Replicate');
    }

    // 2. Try Replicate with each key
    final replicateKeys = _keys('REPLICATE_API_KEY');
    for (int i = 0; i < replicateKeys.length; i++) {
      if (kDebugMode) {
        debugPrint('[MusicGen] Replicate key ${i + 1}/${replicateKeys.length}');
      }
      try {
        return await _replicate(
          prompt: prompt,
          duration: durationSeconds,
          key: replicateKeys[i],
        );
      } on _RetryException catch (e) {
        if (kDebugMode) debugPrint('[MusicGen] Replicate retry: $e');
        continue;
      } on MusicGenException {
        rethrow;
      } catch (e) {
        if (kDebugMode) debugPrint('[MusicGen] Replicate error: $e');
        continue;
      }
    }

    if (replicateKeys.isNotEmpty) {
      if (kDebugMode) debugPrint('[MusicGen] All Replicate keys exhausted → HuggingFace');
    }

    // 3. Fallback: HuggingFace
    return _huggingFace(prompt: prompt, duration: durationSeconds);
  }

  // ── deAPI.ai (AceStep 1.5 Turbo) ───────────────────────────────────────────

  Future<MusicGenResult> _deApi({
    required String prompt,
    required int duration,
    required String key,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse(_deApiUrl))
      ..headers['Authorization'] = 'Bearer $key'
      ..headers['Accept'] = 'application/json'
      ..fields['caption'] = prompt
      ..fields['model'] = 'AceStep_1_5_Turbo'
      ..fields['lyrics'] = '[Instrumental]'
      ..fields['duration'] = duration.clamp(10, 600).toString()
      ..fields['inference_steps'] = '8'
      ..fields['guidance_scale'] = '1'
      ..fields['seed'] = '-1'
      ..fields['format'] = 'mp3';

    final streamedRes = await request.send().timeout(const Duration(seconds: 30));
    final submitRes = await http.Response.fromStream(streamedRes);

    if (submitRes.statusCode == 429 || submitRes.statusCode == 402) {
      throw _RetryException('deAPI quota/rate-limit');
    }
    if (submitRes.statusCode != 200 && submitRes.statusCode != 201) {
      if (submitRes.statusCode >= 500) throw _RetryException('deAPI server error');
      throw MusicGenException('deAPI error (${submitRes.statusCode}): ${_parseHfError(submitRes.body)}');
    }

    final raw = jsonDecode(submitRes.body) as Map<String, dynamic>;
    final dataWrapper = (raw['data'] ?? raw) as Map<String, dynamic>;
    final requestId = dataWrapper['request_id'] as String?;
    if (requestId == null) throw _RetryException('deAPI: no request_id');

    // Poll status via v2 jobs endpoint
    for (int i = 0; i < _maxPolls; i++) {
      await Future.delayed(_pollInterval);
      final statusRes = await http
          .get(Uri.parse('https://api.deapi.ai/api/v2/jobs/$requestId'),
              headers: {'Authorization': 'Bearer $key'})
          .timeout(const Duration(seconds: 15));

      if (statusRes.statusCode != 200) continue;
      final rawStatus = jsonDecode(statusRes.body) as Map<String, dynamic>;
      final statusData = (rawStatus['data'] ?? rawStatus) as Map<String, dynamic>;
      final status = (statusData['status'] ?? '').toString().toLowerCase();
      if (kDebugMode) debugPrint('[MusicGen] deAPI: $status');

      if (status == 'done') {
        final audioUrl = statusData['result_url'] as String?;
        if (audioUrl == null) throw _RetryException('deAPI: no audio URL');
        return MusicGenResult(
          audioUrl: audioUrl,
          prompt: prompt,
          provider: 'deapi',
          createdAt: DateTime.now(),
        );
      }
      if (status == 'error') {
        final errorMsg = statusData['error'] ?? 'deAPI failed';
        throw MusicGenException(errorMsg.toString());
      }
    }
    throw _RetryException('deAPI timed out');
  }

  // ── Replicate ──────────────────────────────────────────────────────────────

  Future<MusicGenResult> _replicate({
    required String prompt,
    required int duration,
    required String key,
  }) async {
    final createRes = await http
        .post(
          Uri.parse(_replicateUrl),
          headers: {
            'Authorization': 'Bearer $key',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'version': _replicateMusicGenVersion,
            'input': {
              'prompt': prompt,
              'duration': duration,
              'model_version': 'stereo-large',
              'output_format': 'mp3',
              'normalization_strategy': 'peak',
            },
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (createRes.statusCode == 429 || createRes.statusCode == 402) {
      throw _RetryException('quota/rate-limit (${createRes.statusCode})');
    }
    if (createRes.statusCode != 201) {
      if (kDebugMode) debugPrint('[MusicGen] Replicate: ${createRes.body}');
      if (createRes.statusCode >= 500) {
        throw _RetryException('server error (${createRes.statusCode})');
      }
      throw MusicGenException(
          'Replicate error (${createRes.statusCode})');
    }

    final prediction = jsonDecode(createRes.body) as Map<String, dynamic>;
    final pollUrl = prediction['urls']?['get'] as String?;
    if (pollUrl == null) throw const MusicGenException('No poll URL');

    // Poll for result
    for (int i = 0; i < _maxPolls; i++) {
      await Future.delayed(_pollInterval);
      final pollRes = await http
          .get(Uri.parse(pollUrl), headers: {'Authorization': 'Bearer $key'})
          .timeout(const Duration(seconds: 15));

      if (pollRes.statusCode != 200) continue;

      final data = jsonDecode(pollRes.body) as Map<String, dynamic>;
      final status = data['status'] as String?;
      if (kDebugMode) debugPrint('[MusicGen] Replicate status: $status');

      if (status == 'succeeded') {
        final output = data['output'];
        final url =
            output is List ? output.first as String : output as String;
        return MusicGenResult(
          audioUrl: url,
          prompt: prompt,
          provider: 'replicate',
          createdAt: DateTime.now(),
        );
      }
      if (status == 'failed' || status == 'canceled') {
        throw MusicGenException(
            (data['error'] ?? 'Generation failed').toString());
      }
    }
    throw const _RetryException('Replicate timed out');
  }

  // ── HuggingFace fallback ───────────────────────────────────────────────────

  Future<MusicGenResult> _huggingFace({
    required String prompt,
    required int duration,
  }) async {
    final hfKeys = _keys('HF_API_KEY');
    // Try each HF key, then once without any key (free anonymous tier)
    final attempts = [...hfKeys, null];
    int _hf503Retries = 0;

    for (int i = 0; i < attempts.length; i++) {
      final key = attempts[i];
      if (kDebugMode) {
        debugPrint(
            '[MusicGen] HuggingFace attempt ${i + 1}/${attempts.length} '
            '(${key != null ? 'key' : 'no-key'})');
      }

      try {
        final res = await http
            .post(
              Uri.parse(_hfUrl),
              headers: {
                'Content-Type': 'application/json',
                if (key != null) 'Authorization': 'Bearer $key',
              },
              body: jsonEncode({'inputs': prompt}),
            )
            .timeout(const Duration(minutes: 3));

        if (res.statusCode == 503) {
          // Model cold-starting — wait and retry, max 3 times total
          if (kDebugMode) debugPrint('[MusicGen] HF model loading, waiting 20s...');
          await Future.delayed(const Duration(seconds: 20));
          if (_hf503Retries < 3) { _hf503Retries++; i--; }
          continue;
        }

        if (res.statusCode == 429 && i < attempts.length - 1) {
          continue; // try next key
        }

        if (res.statusCode != 200) {
          if (kDebugMode) debugPrint('[MusicGen] HF error: ${res.body}');
          if (i < attempts.length - 1) continue;
          throw MusicGenException(
              'HuggingFace error (${res.statusCode}): ${_parseHfError(res.body)}');
        }

        // HF returns raw audio bytes — write to cache file
        final dir = await getTemporaryDirectory();
        final file = File(
            '${dir.path}/musicgen_${DateTime.now().millisecondsSinceEpoch}.mp3');
        await file.writeAsBytes(res.bodyBytes);

        return MusicGenResult(
          audioUrl: file.path, // audioplayers DeviceFileSource
          prompt: prompt,
          provider: 'huggingface',
          createdAt: DateTime.now(),
        );
      } on TimeoutException {
        if (kDebugMode) debugPrint('[MusicGen] HF timeout attempt ${i + 1}');
        if (i < attempts.length - 1) continue;
        throw const MusicGenException('All providers timed out');
      }
    }

    throw const MusicGenException(
        'All providers failed. Check API keys and internet.');
  }

  String _parseHfError(String body) {
    try {
      return (jsonDecode(body) as Map<String, dynamic>)['error']?.toString() ??
          body;
    } catch (_) {
      return body.length > 80 ? '${body.substring(0, 80)}...' : body;
    }
  }
}

/// Internal — signals that the current key should be skipped, try next.
class _RetryException implements Exception {
  final String reason;
  const _RetryException(this.reason);
  @override
  String toString() => reason;
}

class MusicGenException implements Exception {
  final String message;
  const MusicGenException(this.message);
  @override
  String toString() => message;
}
