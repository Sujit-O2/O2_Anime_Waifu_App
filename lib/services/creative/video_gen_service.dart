import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Result of a video generation request.
class VideoGenResult {
  final String videoUrl; // https:// or local file path
  final String prompt;
  final String provider; // 'deapi' | 'replicate' | 'fal' | 'stability' | 'runway' | 'huggingface'
  final DateTime createdAt;

  const VideoGenResult({
    required this.videoUrl,
    required this.prompt,
    required this.provider,
    required this.createdAt,
  });
}

/// AI Video Generation Service
///
/// Full fallback chain (each with shuffled multi-key rotation):
///   1. deAPI.ai LTX-2.3 / Wan 2.2    — DEAPI_API_KEY (free $5, no card)
///   2. Replicate zeroscope-v2-xl     — REPLICATE_API_KEY
///   3. FAL.ai text-to-video          — FAL_API_KEY
///   4. Stability AI stable-video     — STABILITY_API_KEY
///   5. RunwayML gen-3                — RUNWAY_API_KEY
///   6. HuggingFace damo-vilab        — HF_API_KEY (then no-key free tier)
///
/// .env (comma-separated for multi-key rotation):
///   DEAPI_API_KEY      = "deapi_key1,deapi_key2"  (signup: https://deapi.ai/register)
///   REPLICATE_API_KEY  = "r8_key1,r8_key2"
///   FAL_API_KEY        = "fal_key1,fal_key2"
///   STABILITY_API_KEY  = "sk-key1,sk-key2"
///   RUNWAY_API_KEY     = "rw_key1,rw_key2"
///   HF_API_KEY         = "hf_key1,hf_key2"
class VideoGenService {
  VideoGenService._();
  static final VideoGenService instance = VideoGenService._();

  static const _deApiUrl =
      'https://api.deapi.ai/api/v2/videos/generations';
  static const _pollInterval = Duration(seconds: 3);
  static const _maxPolls = 120; // 6 min

  // ── Key helper ─────────────────────────────────────────────────────────────
  List<String> _keys(String envVar) => (dotenv.env[envVar] ?? '')
      .split(',')
      .map((k) => k.trim())
      .where((k) => k.isNotEmpty && !k.contains('YOUR_'))
      .toList()
    ..shuffle();

  // ── Public ─────────────────────────────────────────────────────────────────
  Future<VideoGenResult> generate({
    required String prompt,
    int numFrames = 24,
    int fps = 8,
  }) async {
    // Provider chain — each returns on success, throws _RetryException to skip
    final providers = <Future<VideoGenResult> Function()>[
      () => _tryAllKeys('DEAPI_API_KEY', 'deAPI',
          (key) => _deApi(prompt: prompt, key: key)),
      () => _tryAllKeys('REPLICATE_API_KEY', 'Replicate',
          (key) => _replicate(prompt: prompt, numFrames: numFrames, fps: fps, key: key)),
      () => _tryAllKeys('FAL_API_KEY', 'FAL',
          (key) => _fal(prompt: prompt, numFrames: numFrames, fps: fps, key: key)),
      () => _tryAllKeys('STABILITY_API_KEY', 'Stability',
          (key) => _stability(prompt: prompt, key: key)),
      () => _tryAllKeys('RUNWAY_API_KEY', 'Runway',
          (key) => _runway(prompt: prompt, numFrames: numFrames, fps: fps, key: key)),
      () => _huggingFace(prompt: prompt),
    ];

    for (final provider in providers) {
      try {
        return await provider();
      } on _SkipProvider catch (e) {
        if (kDebugMode) debugPrint('[VideoGen] Skipping provider: $e');
        continue;
      }
    }

    throw const VideoGenException(
        'All providers failed. Check API keys and internet connection.');
  }

  /// Tries every key for a given provider. Throws [_SkipProvider] if all fail.
  Future<VideoGenResult> _tryAllKeys(
    String envVar,
    String providerName,
    Future<VideoGenResult> Function(String key) call,
  ) async {
    final keys = _keys(envVar);
    if (keys.isEmpty) throw _SkipProvider('$providerName: no keys configured');

    for (int i = 0; i < keys.length; i++) {
      if (kDebugMode) {
        debugPrint('[VideoGen] $providerName key ${i + 1}/${keys.length}');
      }
      try {
        return await call(keys[i]);
      } on _RetryException catch (e) {
        if (kDebugMode) debugPrint('[VideoGen] $providerName retry: $e');
        continue;
      } on VideoGenException {
        rethrow; // hard failure — propagate up
      } catch (e) {
        if (kDebugMode) debugPrint('[VideoGen] $providerName error: $e');
        continue;
      }
    }
    throw _SkipProvider('$providerName: all keys exhausted');
  }

  // ── 1. deAPI.ai (LTX-2.3 / Wan 2.2) ────────────────────────────────────────
  Future<VideoGenResult> _deApi({
    required String prompt,
    required String key,
  }) async {
    final submitRes = await http
        .post(
          Uri.parse(_deApiUrl),
          headers: {
            'Authorization': 'Bearer $key',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'prompt': prompt,
            'model': 'Ltxv_13B_0_9_8_Distilled_FP8',
            'width': 512,
            'height': 512,
            'frames': 30,
            'fps': 30,
            'guidance': 7.5,
            'steps': 1,
            'seed': -1,
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (submitRes.statusCode == 429 || submitRes.statusCode == 402) {
      throw _RetryException('deAPI quota/rate-limit');
    }
    if (submitRes.statusCode != 200 && submitRes.statusCode != 201) {
      if (submitRes.statusCode >= 500) throw _RetryException('deAPI server error');
      throw VideoGenException('deAPI error (${submitRes.statusCode}): ${_parseError(submitRes.body)}');
    }

    final submitData = jsonDecode(submitRes.body) as Map<String, dynamic>;
    final requestId = submitData['request_id'] as String? ??
        submitData['id'] as String?;
    if (requestId == null) throw _RetryException('deAPI: no request_id');

    // Poll status
    for (int i = 0; i < _maxPolls; i++) {
      await Future.delayed(_pollInterval);
      final statusRes = await http
          .get(Uri.parse('https://api.deapi.ai/api/v2/jobs/$requestId'),
              headers: {'Authorization': 'Bearer $key'})
          .timeout(const Duration(seconds: 15));

      if (statusRes.statusCode != 200) continue;
      final statusData = jsonDecode(statusRes.body) as Map<String, dynamic>;
      final innerData = (statusData['data'] ?? statusData) as Map<String, dynamic>;
      final status = (innerData['status'] ?? '').toString().toUpperCase();
      if (kDebugMode) debugPrint('[VideoGen] deAPI: $status');

      if (status == 'DONE' || status == 'COMPLETED' || status == 'SUCCEEDED' || status == 'SUCCESS') {
        final videoUrl = innerData['result_url'] as String? ??
            _extractVideoUrl(innerData['result']);
        if (videoUrl == null) throw _RetryException('deAPI: no video URL');
        return VideoGenResult(
          videoUrl: videoUrl,
          prompt: prompt,
          provider: 'deapi',
          createdAt: DateTime.now(),
        );
      }
      if (status == 'FAILED' || status == 'ERROR') {
        final errorMsg = innerData['error'] ?? innerData['message'] ?? 'deAPI failed';
        throw VideoGenException(errorMsg.toString());
      }
    }
    throw _RetryException('deAPI timed out');
  }

  String? _extractVideoUrl(dynamic data) {
    if (data is String) return data;
    if (data is Map) {
      for (final k in ['video_url', 'url', 'video', 'output', 'download_url']) {
        final v = data[k];
        if (v is String && v.isNotEmpty) return v;
        if (v is List && v.isNotEmpty) return v.first.toString();
      }
    }
    return null;
  }

  // ── 2. Replicate zeroscope-v2-xl ───────────────────────────────────────────
  Future<VideoGenResult> _replicate({
    required String prompt,
    required int numFrames,
    required int fps,
    required String key,
  }) async {
    const createUrl =
        'https://api.replicate.com/v1/models/anotherjesse/zeroscope-v2-xl/predictions';

    final createRes = await http
        .post(
          Uri.parse(createUrl),
          headers: {
            'Authorization': 'Bearer $key',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'input': {
              'prompt': prompt,
              'num_frames': numFrames,
              'fps': fps,
              'width': 576,
              'height': 320,
              'num_inference_steps': 40,
              'guidance_scale': 17.5,
            },
          }),
        )
        .timeout(const Duration(seconds: 30));

    _checkReplicateCreate(createRes);

    final id = (jsonDecode(createRes.body) as Map)['id'] as String?;
    if (id == null) throw const _RetryException('no prediction ID');

    final url = await _pollReplicate(id, key);
    return VideoGenResult(
        videoUrl: url, prompt: prompt, provider: 'replicate', createdAt: DateTime.now());
  }

  void _checkReplicateCreate(http.Response res) {
    if (res.statusCode == 429 || res.statusCode == 402) {
      throw const _RetryException('quota/rate-limit');
    }
    if (res.statusCode >= 500) throw const _RetryException('server error');
    if (res.statusCode != 201) {
      throw VideoGenException('Replicate error (${res.statusCode})');
    }
  }

  Future<String> _pollReplicate(String id, String key) async {
    final pollUrl = 'https://api.replicate.com/v1/predictions/$id';
    for (int i = 0; i < _maxPolls; i++) {
      await Future.delayed(_pollInterval);
      final res = await http
          .get(Uri.parse(pollUrl), headers: {'Authorization': 'Bearer $key'})
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) continue;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final status = data['status'] as String?;
      if (kDebugMode) debugPrint('[VideoGen] Replicate: $status');
      if (status == 'succeeded') {
        final output = data['output'];
        return output is List ? output.first as String : output as String;
      }
      if (status == 'failed' || status == 'canceled') {
        throw VideoGenException((data['error'] ?? 'failed').toString());
      }
    }
    throw const _RetryException('Replicate timed out');
  }

  // ── 3. FAL.ai ──────────────────────────────────────────────────────────────
  Future<VideoGenResult> _fal({
    required String prompt,
    required int numFrames,
    required int fps,
    required String key,
  }) async {
    // FAL uses queue-based API
    const submitUrl = 'https://queue.fal.run/fal-ai/fast-svd-lcm';

    final submitRes = await http
        .post(
          Uri.parse(submitUrl),
          headers: {
            'Authorization': 'Key $key',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'prompt': prompt,
            'num_frames': numFrames,
            'fps': fps,
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (submitRes.statusCode == 429 || submitRes.statusCode == 402) {
      throw const _RetryException('FAL quota/rate-limit');
    }
    if (submitRes.statusCode != 200 && submitRes.statusCode != 202) {
      if (submitRes.statusCode >= 500) throw const _RetryException('FAL server error');
      throw VideoGenException('FAL error (${submitRes.statusCode})');
    }

    final submitData = jsonDecode(submitRes.body) as Map<String, dynamic>;
    final requestId = submitData['request_id'] as String?;
    if (requestId == null) throw const _RetryException('FAL: no request_id');

    // Poll FAL status
    final statusUrl = 'https://queue.fal.run/fal-ai/fast-svd-lcm/requests/$requestId/status';
    final resultUrl = 'https://queue.fal.run/fal-ai/fast-svd-lcm/requests/$requestId';

    for (int i = 0; i < _maxPolls; i++) {
      await Future.delayed(_pollInterval);
      final statusRes = await http
          .get(Uri.parse(statusUrl),
              headers: {'Authorization': 'Key $key'})
          .timeout(const Duration(seconds: 15));

      if (statusRes.statusCode != 200) continue;
      final statusData = jsonDecode(statusRes.body) as Map<String, dynamic>;
      final status = statusData['status'] as String?;
      if (kDebugMode) debugPrint('[VideoGen] FAL: $status');

      if (status == 'COMPLETED') {
        final resultRes = await http
            .get(Uri.parse(resultUrl),
                headers: {'Authorization': 'Key $key'})
            .timeout(const Duration(seconds: 15));
        final resultData = jsonDecode(resultRes.body) as Map<String, dynamic>;
        final videoUrl = (resultData['video'] as Map?)?['url'] as String? ??
            (resultData['output'] as Map?)?['video_url'] as String?;
        if (videoUrl == null) throw const _RetryException('FAL: no video URL');
        return VideoGenResult(
            videoUrl: videoUrl, prompt: prompt, provider: 'fal', createdAt: DateTime.now());
      }
      if (status == 'FAILED') {
        throw VideoGenException(
            (statusData['error'] ?? 'FAL generation failed').toString());
      }
    }
    throw const _RetryException('FAL timed out');
  }

  // ── 4. Stability AI ────────────────────────────────────────────────────────
  Future<VideoGenResult> _stability({
    required String prompt,
    required String key,
  }) async {
    // Stability AI video generation (stable-video-diffusion)

    // Stability video requires an image — use text-to-image first, then animate
    // For simplicity, use their text-to-video endpoint if available
    const txt2vidUrl = 'https://api.stability.ai/v2beta/stable-video-diffusion';

    final res = await http
        .post(
          Uri.parse(txt2vidUrl),
          headers: {
            'Authorization': 'Bearer $key',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'text_prompts': [
              {'text': prompt, 'weight': 1}
            ],
            'cfg_scale': 1.8,
            'motion_bucket_id': 127,
            'seed': 0,
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (res.statusCode == 429 || res.statusCode == 402) {
      throw const _RetryException('Stability quota/rate-limit');
    }
    if (res.statusCode == 404) {
      // Endpoint not available on this plan — try generation ID polling
      throw const _RetryException('Stability endpoint unavailable');
    }
    if (res.statusCode != 200 && res.statusCode != 202) {
      if (res.statusCode >= 500) throw const _RetryException('Stability server error');
      throw VideoGenException('Stability error (${res.statusCode}): ${_parseError(res.body)}');
    }

    // Stability returns generation ID for async jobs
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final generationId = data['id'] as String?;

    if (generationId != null) {
      // Poll for result
      for (int i = 0; i < _maxPolls; i++) {
        await Future.delayed(_pollInterval);
        final pollRes = await http
            .get(
              Uri.parse('https://api.stability.ai/v2beta/stable-video-diffusion/result/$generationId'),
              headers: {'Authorization': 'Bearer $key', 'Accept': 'video/*'},
            )
            .timeout(const Duration(seconds: 15));

        if (pollRes.statusCode == 202) continue; // still processing
        if (pollRes.statusCode == 200) {
          // Save video bytes
          final dir = await getTemporaryDirectory();
          final file = File('${dir.path}/stability_${DateTime.now().millisecondsSinceEpoch}.mp4');
          await file.writeAsBytes(pollRes.bodyBytes);
          return VideoGenResult(
              videoUrl: file.path, prompt: prompt, provider: 'stability', createdAt: DateTime.now());
        }
        throw VideoGenException('Stability poll error (${pollRes.statusCode})');
      }
      throw const _RetryException('Stability timed out');
    }

    // Direct video URL in response
    final videoUrl = data['video_url'] as String? ?? data['url'] as String?;
    if (videoUrl != null) {
      return VideoGenResult(
          videoUrl: videoUrl, prompt: prompt, provider: 'stability', createdAt: DateTime.now());
    }

    throw const _RetryException('Stability: unexpected response format');
  }

  // ── 5. RunwayML ────────────────────────────────────────────────────────────
  Future<VideoGenResult> _runway({
    required String prompt,
    required int numFrames,
    required int fps,
    required String key,
  }) async {
    // RunwayML Gen-3 Alpha API
    const createUrl = 'https://api.dev.runwayml.com/v1/image_to_video';

    final createRes = await http
        .post(
          Uri.parse(createUrl),
          headers: {
            'Authorization': 'Bearer $key',
            'Content-Type': 'application/json',
            'X-Runway-Version': '2024-11-06',
          },
          body: jsonEncode({
            'promptText': prompt,
            'model': 'gen3a_turbo',
            'duration': (numFrames / fps).round().clamp(4, 10),
            'ratio': '1280:768',
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (createRes.statusCode == 429 || createRes.statusCode == 402) {
      throw const _RetryException('Runway quota/rate-limit');
    }
    if (createRes.statusCode != 200 && createRes.statusCode != 201) {
      if (createRes.statusCode >= 500) throw const _RetryException('Runway server error');
      throw VideoGenException('Runway error (${createRes.statusCode}): ${_parseError(createRes.body)}');
    }

    final taskId = (jsonDecode(createRes.body) as Map)['id'] as String?;
    if (taskId == null) throw const _RetryException('Runway: no task ID');

    // Poll task
    for (int i = 0; i < _maxPolls; i++) {
      await Future.delayed(_pollInterval);
      final pollRes = await http
          .get(
            Uri.parse('https://api.dev.runwayml.com/v1/tasks/$taskId'),
            headers: {
              'Authorization': 'Bearer $key',
              'X-Runway-Version': '2024-11-06',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (pollRes.statusCode != 200) continue;
      final data = jsonDecode(pollRes.body) as Map<String, dynamic>;
      final status = data['status'] as String?;
      if (kDebugMode) debugPrint('[VideoGen] Runway: $status');

      if (status == 'SUCCEEDED') {
        final output = data['output'] as List?;
        final videoUrl = output?.first as String?;
        if (videoUrl == null) throw const _RetryException('Runway: no output URL');
        return VideoGenResult(
            videoUrl: videoUrl, prompt: prompt, provider: 'runway', createdAt: DateTime.now());
      }
      if (status == 'FAILED') {
        throw VideoGenException((data['failure'] ?? 'Runway failed').toString());
      }
    }
    throw const _RetryException('Runway timed out');
  }

  // ── 6. HuggingFace (free, no key required) ────────────────────────────────
  Future<VideoGenResult> _huggingFace({required String prompt}) async {
    const hfUrl =
        'https://api-inference.huggingface.co/models/damo-vilab/text-to-video-ms-1.7b';

    final hfKeys = _keys('HF_API_KEY');
    final attempts = [...hfKeys, null]; // null = anonymous free tier

    for (int i = 0; i < attempts.length; i++) {
      final key = attempts[i];
      if (kDebugMode) {
        debugPrint('[VideoGen] HuggingFace ${i + 1}/${attempts.length} '
            '(${key != null ? 'key' : 'no-key'})');
      }
      try {
        final res = await http
            .post(
              Uri.parse(hfUrl),
              headers: {
                'Content-Type': 'application/json',
                if (key != null) 'Authorization': 'Bearer $key',
              },
              body: jsonEncode({'inputs': prompt}),
            )
            .timeout(const Duration(minutes: 5));

        if (res.statusCode == 503) {
          if (kDebugMode) debugPrint('[VideoGen] HF loading, waiting 30s...');
          await Future.delayed(const Duration(seconds: 30));
          i--;
          continue;
        }
        if (res.statusCode == 429 && i < attempts.length - 1) continue;
        if (res.statusCode != 200) {
          if (kDebugMode) debugPrint('[VideoGen] HF error: ${res.body}');
          if (i < attempts.length - 1) continue;
          throw VideoGenException(
              'HuggingFace error (${res.statusCode}): ${_parseError(res.body)}');
        }

        final dir = await getTemporaryDirectory();
        final file = File(
            '${dir.path}/videogen_${DateTime.now().millisecondsSinceEpoch}.mp4');
        await file.writeAsBytes(res.bodyBytes);
        return VideoGenResult(
            videoUrl: file.path, prompt: prompt, provider: 'huggingface', createdAt: DateTime.now());
      } on TimeoutException {
        if (i < attempts.length - 1) continue;
        throw const VideoGenException('All providers timed out');
      }
    }
    throw const VideoGenException('All providers failed.');
  }

  String _parseError(String body) {
    try {
      return (jsonDecode(body) as Map<String, dynamic>)['error']?.toString() ??
          body;
    } catch (_) {
      return body.length > 80 ? '${body.substring(0, 80)}...' : body;
    }
  }
}

class _RetryException implements Exception {
  final String reason;
  const _RetryException(this.reason);
  @override
  String toString() => reason;
}

class _SkipProvider implements Exception {
  final String reason;
  const _SkipProvider(this.reason);
  @override
  String toString() => reason;
}

class VideoGenException implements Exception {
  final String message;
  const VideoGenException(this.message);
  @override
  String toString() => message;
}
