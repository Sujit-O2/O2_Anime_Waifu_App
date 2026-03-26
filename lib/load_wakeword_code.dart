import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';

/// Typedef for wake word detection callback
typedef WakeWordCallback = void Function(int keywordIndex);

/// Service for managing wake word detection using ONNX XGBoost classifier.
///
/// Replaces the previous Picovoice Porcupine implementation.
/// Uses a 128-bin Mel-Spectrogram (4 096-dim vector) at 16 kHz
/// with a multi-threshold confirmation engine.
class WakeWordService {
  // ── ONNX session ─────────────────────────────────────────────────────────
  static const String _modelAsset = 'assets/wakeword/zero_two.onnx';
  final OnnxRuntime _ort = OnnxRuntime();
  OrtSession? _session;

  // ── Audio capture via native EventChannel ────────────────────────────────
  static const EventChannel _audioChannel =
      EventChannel('com.example.anime_waifu/wake_audio');
  StreamSubscription<dynamic>? _audioSub;

  // ── State ────────────────────────────────────────────────────────────────
  bool _running = false;
  bool _initialized = false;
  bool _initializing = false;
  bool _inferenceInFlight = false;
  WakeWordCallback? _onDetected;

  // ── Audio buffer ─────────────────────────────────────────────────────────
  // librosa with 16000 samples, n_fft=2048, hop=512, center=True → (128,32) = 4096
  static const int _sampleRate = 16000;
  static const int _windowSamples = _sampleRate; // Window is exactly 1 second
  final Float64List _buffer = Float64List(_windowSamples);
  int _bufferFillCount = 0;
  int _chunksSinceLastEval = 0;

  // ── Mel-Spectrogram parameters (match librosa defaults) ──────────────────
  static const int _nFft = 2048;
  static const int _hopLength = 512; // ~31.25 frames per second
  static const int _nMels = 128;
  static const int _nMfcc = 40;
  static const int _targetFrames = 32;
  static const int _halfFft = _nFft ~/ 2 + 1;

  // Pre-computed tables (built once on init)
  List<Float64List>? _melFilters;
  late final Float64List _twiddleReal;
  late final Float64List _twiddleImag;
  late final Float64List _hannWindow;

  // ── Multi-Threshold Confirmation Engine ──────────────────────────────────
  // Based on production deployment guide §4.
  //
  // Tier 1: Fast-Pass   — confidence ≥ 0.96 → immediate trigger
  // Tier 2: Secondary   — confidence ∈ [0.70, 0.96) → 3/5 temporal check
  // Tier 3: Reject      — confidence < 0.70 → ignore
  static const double _fastPassThreshold = 0.95;
  static const double _detectFloor = 0.80;      
  static const int _confirmWindowSize = 5;
  static const int _confirmQuorum = 3;   // 3 out of 5 consecutive detections
  static const double _varianceCap = 0.04;
  final List<double> _confidenceBuffer = [];

  // ── Energy gate — skip inference on silence/fan noise ────────────────────
  static const double _energyFloor = 0.008; // Balanced to accept speaking volume in noisy rooms

  // ── Cooldown after trigger ───────────────────────────────────────────────
  DateTime? _lastTriggerTime;
  static const Duration _triggerCooldown = Duration(seconds: 3);

  // ── Wake word labels ─────────────────────────────────────────────────────
  static const List<String> _wakeLabels = ['wake_word_detected'];

  // ── Diagnostics & STT Buffer ─────────────────────────────────────────────
  static const int _bufferSize = 16000 * 2; // 2 seconds of audio
  final List<double> _audioBuffer = [];

  // ── Debug logging ────────────────────────────────────────────────────────
  static bool enableDebugLogging = true;

  /// Configure — no-op, ONNX doesn't need API keys.
  void configure({String? accessKeyOverride}) {}

  /// Returns keyword labels (Porcupine API compat).
  List<String> get loadedKeywords => List.unmodifiable(_wakeLabels);

  /// Returns the most recent 2 seconds of audio.
  Float32List getRecentAudio() {
    return Float32List.fromList(_audioBuffer);
  }

  /// Initialize the wake word engine
  Future<void> init(
    WakeWordCallback onDetected, {
    bool startImmediately = true,
  }) async {
    _onDetected = onDetected;
    if (_initializing || _initialized) return;
    _initializing = true;

    try {
      _session = await _ort.createSessionFromAsset(_modelAsset);

      // Pre-compute Mel filter bank, FFT twiddles, Hann window
      _melFilters = _buildMelFilters();
      _precomputeTwiddles();
      _hannWindow = Float64List(_nFft);
      for (int i = 0; i < _nFft; i++) {
        _hannWindow[i] = 0.5 * (1.0 - math.cos(2.0 * math.pi * i / (_nFft - 1)));
      }

      _initialized = true;
      _log('ONNX session loaded successfully');
      if (startImmediately) await start();
    } catch (e) {
      _initialized = false;
      _log('ONNX init FAILED: $e');
      rethrow;
    } finally {
      _initializing = false;
    }
  }

  /// Start detecting
  Future<void> start() async {
    if (_initializing || _running) return;
    if (!_initialized || _session == null) {
      if (_onDetected != null) await init(_onDetected!);
      return;
    }

    _buffer.fillRange(0, _buffer.length, 0.0);
    _bufferFillCount = 0;
    _confidenceBuffer.clear();
    _inferenceInFlight = false;

    try {
      _audioSub?.cancel();
      _audioSub = _audioChannel.receiveBroadcastStream().listen(
        _onAudioChunk,
        onError: (dynamic e) {
          _log("Wake audio error: $e");
          _running = false;
          // Auto-restart after mic error (e.g. mic conflict resolution)
          Future.delayed(const Duration(seconds: 2), () {
            if (!_running && _initialized && _onDetected != null) {
              _log('Auto-restarting after audio error...');
              start();
            }
          });
        },
        onDone: () {
          _log("Wake audio stream ended unexpectedly");
          _running = false;
          // Auto-restart if stream ended unexpectedly
          Future.delayed(const Duration(seconds: 2), () {
            if (!_running && _initialized && _onDetected != null) {
              _log('Auto-restarting after stream end...');
              start();
            }
          });
        },
      );
      _running = true;
      _log('Wake word listening STARTED');
    } catch (e) {
      _log('Failed to start audio stream: $e');
      _running = false;
    }
  }

  /// Stop detecting — releases mic for STT
  Future<void> stop() async {
    if (!_running && _audioSub == null) return;
    _running = false;
    final sub = _audioSub;
    _audioSub = null;
    await sub?.cancel();
    _confidenceBuffer.clear();
    _inferenceInFlight = false;
    // ignore: avoid_print
    print('[WakeWord] STOPPED — caller:');
    // ignore: avoid_print
    print(StackTrace.current.toString().split('\n').take(6).join('\n'));
  }

  /// Dispose all resources
  Future<void> dispose() async {
    await stop();
    try { await _session?.close(); } catch (_) {}
    _session = null;
    _initialized = false;
    _onDetected = null;
    _melFilters = null;
  }

  bool get isRunning => _running;

  /// Test trigger (debug)
  void testTriggerByIndex(int keywordIndex) {
    _onDetected?.call(keywordIndex);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DEBUG LOGGING
  // ═══════════════════════════════════════════════════════════════════════════

  void _log(String msg) {
    // CRITICAL: Use print() not debugPrint() — debugPrint is disabled globally
    // ignore: avoid_print
    print('[WakeWord] $msg');
  }

  void _logVerbose(String msg) {
    if (enableDebugLogging) {
      // ignore: avoid_print
      print('[WakeWord] $msg');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AUDIO PIPELINE
  // ═══════════════════════════════════════════════════════════════════════════

  void _onAudioChunk(dynamic data) {
    if (!_running || _session == null) return;
    try {
      final List<double> samples;
      if (data is List) {
        samples = List<double>.from(data);
      } else {
        print('[WakeWord Diagnostics] Received non-List data: $data');
        return;
      }
      if (samples.isEmpty) return;

      _audioBuffer.addAll(samples);
      if (_audioBuffer.length > _bufferSize) {
        _audioBuffer.removeRange(0, _audioBuffer.length - _bufferSize);
      }

      final incoming = samples.length;
      // Slide buffer left, append new samples at end
      if (incoming < _windowSamples) {
        for (int i = 0; i < _windowSamples - incoming; i++) {
          _buffer[i] = _buffer[i + incoming];
        }
        for (int i = 0; i < incoming; i++) {
          _buffer[_windowSamples - incoming + i] = samples[i];
        }
      } else {
        for (int i = 0; i < _windowSamples; i++) {
          _buffer[i] = samples[incoming - _windowSamples + i];
        }
      }

      _bufferFillCount++;
      // Need ~10 chunks (1 second) to fill buffer
      if (_bufferFillCount < 10) return;

      // ── Energy gate: skip classification on silence ──────────────────
      final rms = _computeRms(_buffer);
      // Diagnostic print to verify audio channel stream is alive
      if (_bufferFillCount % 10 == 0) {
        print('[WakeWord Diagnostics] 1 sec passed. RMS: ${rms.toStringAsFixed(5)}');
      }
      
      if (rms < _energyFloor) {
        _logVerbose('Skip: silence (RMS=${rms.toStringAsFixed(5)})');
        // Decay confidence buffer on silence
        _confidenceBuffer.clear();
        return;
      }

      _chunksSinceLastEval++;
      if (_chunksSinceLastEval < 3) return; // Evaluate max 3 times a second to prevent UI thread lockup!
      _chunksSinceLastEval = 0;

      // Skip if inference is already in progress (prevent backpressure)
      if (_inferenceInFlight) return;
      _inferenceInFlight = true;

      // Copy buffer and process async to not block audio stream
      final copy = Float64List.fromList(_buffer);
      unawaited(_processAsync(copy, rms));
    } catch (e) {
      _log("Audio chunk error: $e");
    }
  }


  double _computeRms(Float64List audio) {
    double sum = 0;
    for (int i = 0; i < audio.length; i++) {
      sum += audio[i] * audio[i];
    }
    return math.sqrt(sum / audio.length);
  }

  Future<void> _processAsync(Float64List audio, double rms) async {
    try {
      if (!_running || _session == null) return;
      final features = _extractMelFeatures(audio);
      await _runInference(features, rms);
    } catch (e) {
      _log("Process error: $e");
    } finally {
      _inferenceInFlight = false;
    }
  }

  Future<void> _runInference(Float32List features, double rms) async {
    if (!_running || _session == null) return;
    try {
      final input = await OrtValue.fromList(
        features.toList(),
        [1, _nMfcc, _targetFrames, 1], // CNN input shape [Batch, 40, 32, 1]
      );
      final outputs = await _session!.run({'input': input});

      double wakeProb = 0.0;

      // Parse Keras/TeachableMachine Softmax output
      final identityOut = outputs['Identity:0'] ?? outputs['dense_7'] ?? outputs.values.first;
      final list = await identityOut.asList();
      if (list.isNotEmpty && list[0] is List) {
          final probs = list[0] as List; // e.g. [0.1, 0.05, 0.85]
          if (probs.length == 1) { // Assuming single output for wake word probability
             wakeProb = (probs[0] as num).toDouble();
             _logVerbose('TM Prob: ${wakeProb.toStringAsFixed(3)}');
          } else if (probs.length == 2) { // Standard binary classification [bg, wake]
             double p0 = (probs[0] as num).toDouble();
             double p1 = (probs[1] as num).toDouble();
             wakeProb = p1; // Second class is wake word
             _logVerbose('TM Probs (2-class): Bg=${p0.toStringAsFixed(3)}, Wake=${p1.toStringAsFixed(3)}');
          } else if (probs.length == 3) { // Fallback for 3-class softmax
             double p0 = (probs[0] as num).toDouble();
             double p1 = (probs[1] as num).toDouble();
             double p2 = (probs[2] as num).toDouble();
             wakeProb = math.max(p1, p2); 
             _logVerbose('TM Probs (3-class): Bg=${p0.toStringAsFixed(3)}, C1=${p1.toStringAsFixed(3)}, C2=${p2.toStringAsFixed(3)}');
        }
      }

      _logVerbose(
        'Inference: prob=${wakeProb.toStringAsFixed(4)} '
        'RMS=${rms.toStringAsFixed(4)}',
      );

      // ── Multi-Threshold Confirmation Engine ────────────────────────
      _processConfirmation(wakeProb);
    } catch (e) {
      _log("Inference error: $e");
    }
  }

  /// Multi-threshold tiered confirmation engine.
  ///
  /// Tier 1: Fast-Pass   — score ≥ 0.96 → immediate trigger
  /// Tier 2: Secondary   — score ∈ [0.70, 0.96) → 3/5 temporal check
  /// Tier 3: Reject      — score < 0.70 → clear buffer
  void _processConfirmation(double wakeProb) {
    // Cooldown after a recent trigger
    if (_lastTriggerTime != null) {
      final elapsed = DateTime.now().difference(_lastTriggerTime!);
      if (elapsed < _triggerCooldown) return;
    }

    // Tier 1: Fast-Pass
    if (wakeProb >= _fastPassThreshold) {
      _log('FAST-PASS trigger (prob=${wakeProb.toStringAsFixed(4)})');
      _confidenceBuffer.clear();
      _triggerDetected();
      return;
    }

    // Tier 2: Secondary Check (overlap zone)
    if (wakeProb >= _detectFloor) {
      _confidenceBuffer.add(wakeProb);
      if (_confidenceBuffer.length > _confirmWindowSize) {
        _confidenceBuffer.removeAt(0);
      }

      if (_confidenceBuffer.length >= _confirmQuorum) {
        // Count how many in the window are above the floor
        final aboveCount = _confidenceBuffer
            .where((s) => s >= _detectFloor)
            .length;

        // Check variance — genuine wake words have low variance
        final mean = _confidenceBuffer.reduce((a, b) => a + b) /
            _confidenceBuffer.length;
        double variance = 0;
        for (final s in _confidenceBuffer) {
          variance += (s - mean) * (s - mean);
        }
        final stdDev = math.sqrt(variance / _confidenceBuffer.length);

        _logVerbose(
          'Confirm: above=$aboveCount/${_confidenceBuffer.length} '
          'stdDev=${stdDev.toStringAsFixed(4)} '
          'mean=${mean.toStringAsFixed(4)}',
        );

        if (aboveCount >= _confirmQuorum && stdDev <= _varianceCap) {
          _log('CONFIRMED trigger ($aboveCount/$_confirmWindowSize windows, '
              'stdDev=${stdDev.toStringAsFixed(4)})');
          _confidenceBuffer.clear();
          _triggerDetected();
        }
      }
    } else {
      // Tier 3: Below floor — reset temporal buffer
      _confidenceBuffer.clear();
    }
  }

  void _triggerDetected() {
    if (!_running || _onDetected == null) return;
    _lastTriggerTime = DateTime.now();
    _log("✅ ONNX wake word DETECTED");
    try { _onDetected!(0); } catch (_) {}
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MEL-SPECTROGRAM (librosa-compatible)
  //
  // librosa.feature.melspectrogram(y, sr=16000, n_fft=2048, hop=512, n_mels=128)
  //   → center=True (pads n_fft//2 on each side)
  //   → numFrames = 1 + len(y) // hop_length = 1 + 16000//512 = 32
  //   → shape (128, 32) → flatten = 4096
  // Then librosa.power_to_db(S, ref=np.max)
  // ═══════════════════════════════════════════════════════════════════════════

  Float32List _extractMelFeatures(Float64List audio) {
    // 1. Center-pad (librosa default: center=True)
    final padLen = _nFft ~/ 2; // 1024
    final padded = Float64List(audio.length + 2 * padLen);
    // Reflect-pad left edge
    for (int i = 0; i < padLen; i++) {
      padded[i] = audio[padLen - i]; // reflect
    }
    // Copy original audio
    for (int i = 0; i < audio.length; i++) {
      padded[padLen + i] = audio[i];
    }
    // Reflect-pad right edge
    for (int i = 0; i < padLen; i++) {
      final srcIdx = audio.length - 2 - i;
      padded[padLen + audio.length + i] = srcIdx >= 0 ? audio[srcIdx] : 0.0;
    }

    // 2. STFT with centered frames
    // numFrames = 1 + len(y) // hop_length = 1 + 16000 // 512 = 32
    final nFrames = 1 + audio.length ~/ _hopLength;
    final powerSpec = List<Float64List>.generate(
        _halfFft, (_) => Float64List(nFrames));

    final frameReal = Float64List(_nFft);
    final frameImag = Float64List(_nFft);

    for (int frame = 0; frame < nFrames; frame++) {
      final start = frame * _hopLength;

      // Apply window and load frame
      for (int i = 0; i < _nFft; i++) {
        final idx = start + i;
        final sample = idx < padded.length ? padded[idx] : 0.0;
        frameReal[i] = sample * _hannWindow[i];
        frameImag[i] = 0.0;
      }

      // Radix-2 FFT
      _fftInPlace(frameReal, frameImag, _nFft);

      // Power spectrum (no division by N — matches librosa)
      for (int k = 0; k < _halfFft; k++) {
        powerSpec[k][frame] =
            frameReal[k] * frameReal[k] + frameImag[k] * frameImag[k];
      }
    }

    // 3. Mel filter bank
    final melFilters = _melFilters!;
    final melSpec = List<Float64List>.generate(
        _nMels, (_) => Float64List(nFrames));
    for (int m = 0; m < _nMels; m++) {
      for (int f = 0; f < nFrames; f++) {
        double sum = 0;
        for (int k = 0; k < _halfFft; k++) {
          final w = melFilters[m][k];
          if (w > 0) sum += w * powerSpec[k][f];
        }
        melSpec[m][f] = sum;
      }
    }

    // 4. power_to_db (ref=np.max, amin=1e-10, top_db=80)
    double refMax = 1e-10;
    for (int m = 0; m < _nMels; m++) {
      for (int f = 0; f < nFrames; f++) {
        if (melSpec[m][f] > refMax) refMax = melSpec[m][f];
      }
    }
    for (int m = 0; m < _nMels; m++) {
      for (int f = 0; f < nFrames; f++) {
        final val = math.max(melSpec[m][f], 1e-10);
        double db = 10.0 * math.log(val / math.max(refMax, 1e-10)) / math.ln10;
        melSpec[m][f] = math.max(db, -80.0);
      }
    }

    // 5. Build packed features exactly to [40, 44]
    final features = Float32List(_targetFrames * _nMels);
    for (int i = 0; i < _targetFrames; i++) {
      if (i < nFrames) {
        for (int j = 0; j < _nMels; j++) {
          features[j * _targetFrames + i] = melSpec[j][i];
        }
      } else {
        // Pad with -80.0 dB for missing frames
        for (int j = 0; j < _nMels; j++) {
          features[j * _targetFrames + i] = -80.0;
        }
      }
    }

    return _computeMfccFromMel(features);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RADIX-2 FFT
  // ═══════════════════════════════════════════════════════════════════════════

  void _precomputeTwiddles() {
    _twiddleReal = Float64List(_nFft ~/ 2);
    _twiddleImag = Float64List(_nFft ~/ 2);
    for (int i = 0; i < _nFft ~/ 2; i++) {
      final angle = -2.0 * math.pi * i / _nFft;
      _twiddleReal[i] = math.cos(angle);
      _twiddleImag[i] = math.sin(angle);
    }
  }

  void _fftInPlace(Float64List real, Float64List imag, int n) {
    // Bit-reversal permutation
    int j = 0;
    for (int i = 0; i < n - 1; i++) {
      if (i < j) {
        final tR = real[i]; real[i] = real[j]; real[j] = tR;
        final tI = imag[i]; imag[i] = imag[j]; imag[j] = tI;
      }
      int k = n >> 1;
      while (k <= j) { j -= k; k >>= 1; }
      j += k;
    }
    // Butterfly operations
    int step = 1;
    while (step < n) {
      final half = step;
      step <<= 1;
      final stride = n ~/ step;
      for (int g = 0; g < n; g += step) {
        for (int p = 0; p < half; p++) {
          final wR = _twiddleReal[p * stride];
          final wI = _twiddleImag[p * stride];
          final e = g + p;
          final o = e + half;
          final tR = wR * real[o] - wI * imag[o];
          final tI = wR * imag[o] + wI * real[o];
          real[o] = real[e] - tR;
          imag[o] = imag[e] - tI;
          real[e] += tR;
          imag[e] += tI;
        }
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MEL FILTER BANK
  // ═══════════════════════════════════════════════════════════════════════════

  List<Float64List> _buildMelFilters() {
    const double fMin = 0;
    final double fMax = _sampleRate / 2.0;
    final melMin = _hzToMel(fMin);
    final melMax = _hzToMel(fMax);
    final melPoints = Float64List(_nMels + 2);
    for (int i = 0; i < _nMels + 2; i++) {
      melPoints[i] = melMin + i * (melMax - melMin) / (_nMels + 1);
    }
    final binIndices = List<int>.generate(_nMels + 2, (i) {
      final hz = _melToHz(melPoints[i]);
      return ((hz / fMax) * (_halfFft - 1)).round().clamp(0, _halfFft - 1);
    });
    final filters = List<Float64List>.generate(
        _nMels, (_) => Float64List(_halfFft));
    for (int m = 0; m < _nMels; m++) {
      final l = binIndices[m], c = binIndices[m + 1], r = binIndices[m + 2];
      for (int k = l; k < c && k < _halfFft; k++) {
        if (c != l) filters[m][k] = (k - l) / (c - l);
      }
      for (int k = c; k <= r && k < _halfFft; k++) {
        if (r != c) filters[m][k] = (r - k) / (r - c);
      }
    }
    return filters;
  }

  /// Applies Discrete Cosine Transform (DCT-II) to convert Log-Mel Spectrogram into MFCCs.
  /// Expects `melsDb` of shape [nMels, targetFrames] flattened.
  Float32List _computeMfccFromMel(Float32List melsDb) {
    final mfcc = Float32List(_targetFrames * _nMfcc);
    final factor = math.pi / _nMels;
    
    // Orthogonal normalization (matches librosa norm='ortho')
    final scale0 = math.sqrt(1.0 / _nMels);
    final scaleK = math.sqrt(2.0 / _nMels);

    for (int frame = 0; frame < _targetFrames; frame++) {
      for (int k = 0; k < _nMfcc; k++) {
        double sum = 0.0;
        for (int m = 0; m < _nMels; m++) {
          final melVal = melsDb[m * _targetFrames + frame];
          sum += melVal * math.cos(factor * (m + 0.5) * k);
        }
        final scale = (k == 0) ? scale0 : scaleK;
        mfcc[k * _targetFrames + frame] = sum * scale;
      }
    }
    return mfcc;
  }

  double _hzToMel(double hz) => 2595.0 * math.log(1.0 + hz / 700.0) / math.ln10;
  double _melToHz(double mel) => 700.0 * (math.pow(10.0, mel / 2595.0) - 1.0);
}
