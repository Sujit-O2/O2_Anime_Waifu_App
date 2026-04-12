import 'dart:async';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';

// ══════════════════════════════════════════════════════════════════════════════
// WakeWordService — zerotwo_v1.onnx
//
// Model spec (confirmed by ONNX runtime inspection):
//   INPUT  : 'melspectrogram'  shape=[1, 1, 80, 96]  float32
//   OUTPUT : 'logits'          shape=[1, 2]           float32
//
// Feature pipeline (MUST match training):
//   • 16 kHz mono audio, sliding 1.5-sec window (24 000 samples)
//   • n_fft=512, hop_length=160, n_mels=80, fmin=0, fmax=8000
//   • Hann window, center=True
//   • Power → dB: 10*log10(max(S, 1e-10)), ref=max
//   • Per-frame mean/std normalisation → shape [80, 96]
//   • Reshape to [1, 1, 80, 96] float32, pass as 'melspectrogram'
//   • wakeProb = softmax(logits)[1]
// ══════════════════════════════════════════════════════════════════════════════

typedef WakeWordCallback = void Function(int keywordIndex);

class WakeWordService {
  // ── Model asset ──────────────────────────────────────────────────────────
  static const String _modelAsset = 'assets/wakeword/zerotwo_v1.onnx';

  // ── ONNX session ─────────────────────────────────────────────────────────
  final OnnxRuntime _ort = OnnxRuntime();
  OrtSession? _session;

  // ── Audio channel (native Android AudioRecord @16 kHz) ───────────────────
  static const EventChannel _audioChannel =
      EventChannel('com.example.anime_waifu/wake_audio');
  StreamSubscription<dynamic>? _audioSub;

  // ── State ─────────────────────────────────────────────────────────────────
  bool _running = false;
  bool _initialized = false;
  bool _initializing = false;
  bool _inferenceInFlight = false;
  WakeWordCallback? _onDetected;

  // ── Sliding audio window ──────────────────────────────────────────────────
  // Window: 1.0 s = 16 000 samples @ 16 kHz  (matches training DURATION_SEC=1.0)
  // 16000/160 = 100 STFT frames → take first 96 for model input [1,1,80,96]
  static const int _sampleRate = 16000;
  static const int _windowSamples = 16000; // 1.0 sec — MUST match training
  final Float32List _audioWindow = Float32List(_windowSamples);
  int _chunksReceived = 0;
  int _chunksSinceLastInference = 0;

  // Mel-spectrogram params — defined locally in static _buildMelTensor().
  // Kept here for use in _log messages only:
  static const int _nMels = 80;
  static const int _targetFrames = 96; // 0.96 sec at 100 frames/sec

  // ── Multi-threshold confirmation engine ──────────────────────────────────
  // HIGHLY STRICT: Requires near-perfect confidence across multiple
  // consecutive frames with almost zero variance. Only clear, deliberate
  // "Zero Two" utterances will trigger detection.
  static const double _fastPassThreshold = 0.9999;
  static const double _detectFloor = 0.995;
  static const int _confirmWindow = 6;
  static const int _confirmQuorum = 6;
  static const double _varianceCap = 0.002;
  final List<double> _confirmBuf = [];

  // ── Energy gate ────────────────────────────────────────────────────────────
  static const double _energyFloor = 0.005; // RMS threshold for silence skip

  // ── Cooldown after a trigger ──────────────────────────────────────────────
  static const Duration _cooldown = Duration(seconds: 4);
  DateTime? _lastTrigger;

  // ── Recent audio buffer (2-sec window for STT hand-off) ──────────────────
  static const int _recentAudioCapacity = _sampleRate * 2;
  final List<double> _recentAudioBuf = [];

  // ── Compat API ────────────────────────────────────────────────────────────
  static const List<String> _labels = ['zerotwo'];
  List<String> get loadedKeywords => List.unmodifiable(_labels);
  bool get isRunning => _running;
  void configure({String? accessKeyOverride}) {}
  void testTriggerByIndex(int i) => _onDetected?.call(i);
  Float32List getRecentAudio() => Float32List.fromList(_recentAudioBuf);
  static bool enableDebugLogging = true;

  // ── Public API ────────────────────────────────────────────────────────────

  Future<void> init(
    WakeWordCallback onDetected, {
    bool startImmediately = true,
  }) async {
    _onDetected = onDetected;
    if (_initializing || _initialized) return;
    _initializing = true;
    try {
      _session = await _ort.createSessionFromAsset(_modelAsset);
      _initialized = true;
      _log('zerotwo_v1.onnx loaded ✅  [in=$_nMels×$_targetFrames → out=2]');
      if (startImmediately) await start();
    } catch (e) {
      _initialized = false;
      _log('init FAILED: $e');
      rethrow;
    } finally {
      _initializing = false;
    }
  }

  Future<void> start() async {
    if (_initializing || _running) return;
    if (!_initialized || _session == null) {
      if (_onDetected != null) await init(_onDetected!);
      return;
    }
    _audioWindow.fillRange(0, _audioWindow.length, 0.0);
    _chunksReceived = 0;
    _chunksSinceLastInference = 0;
    _confirmBuf.clear();
    _inferenceInFlight = false;

    _audioSub?.cancel();
    _audioSub = _audioChannel.receiveBroadcastStream().listen(
      _onAudioChunk,
      onError: (dynamic e) {
        _log('Audio error: $e');
        _running = false;
        _scheduleRestart();
      },
      onDone: () {
        _log('Audio stream ended unexpectedly');
        _running = false;
        _scheduleRestart();
      },
    );
    _running = true;
    _log('STARTED — listening for "Zerotwo"');
  }

  Future<void> stop() async {
    if (!_running && _audioSub == null) return;
    _running = false;
    final sub = _audioSub;
    _audioSub = null;
    await sub?.cancel();
    _confirmBuf.clear();
    _inferenceInFlight = false;
    _log('STOPPED');
  }

  Future<void> dispose() async {
    await stop();
    try {
      await _session?.close();
    } catch (_) {}
    _session = null;
    _initialized = false;
    _onDetected = null;
  }

  // ── Private: audio pipeline ───────────────────────────────────────────────

  void _scheduleRestart() {
    Future.delayed(const Duration(seconds: 2), () {
      if (!_running && _initialized && _onDetected != null) {
        _log('Auto-restarting...');
        start();
      }
    });
  }

  void _onAudioChunk(dynamic data) {
    if (!_running || _session == null) return;
    try {
      final List<double> samples;
      if (data is Uint8List) {
        final byteData = data.buffer.asByteData(data.offsetInBytes, data.lengthInBytes);
        final int numSamples = data.lengthInBytes ~/ 2;
        samples = List<double>.generate(numSamples, (i) {
          return byteData.getInt16(i * 2, Endian.little).toDouble() / 32768.0;
        }, growable: false);
      } else if (data is List) {
        // Fallback for older buffered data if any
        samples = List<double>.from(data);
      } else {
        return;
      }
      if (samples.isEmpty) return;

      // Maintain recent audio ring buffer for STT hand-off
      _recentAudioBuf.addAll(samples);
      if (_recentAudioBuf.length > _recentAudioCapacity) {
        _recentAudioBuf.removeRange(
            0, _recentAudioBuf.length - _recentAudioCapacity);
      }

      // Slide window
      final incoming = samples.length;
      if (incoming < _windowSamples) {
        // shift left, append new
        final shift = _windowSamples - incoming;
        for (int i = 0; i < shift; i++) {
          _audioWindow[i] = _audioWindow[i + incoming];
        }
        for (int i = 0; i < incoming; i++) {
          _audioWindow[shift + i] = samples[i].toDouble().clamp(-1.0, 1.0);
        }
      } else {
        for (int i = 0; i < _windowSamples; i++) {
          _audioWindow[i] = samples[incoming - _windowSamples + i]
              .toDouble()
              .clamp(-1.0, 1.0);
        }
      }

      _chunksReceived++;
      // Wait until buffer is ~full (10 chunks ≈ first second)
      if (_chunksReceived < 10) return;

      // Energy gate — skip silence
      final rms = _computeRms(_audioWindow);
      if (_chunksReceived % 20 == 0) {
        _logV('RMS=${rms.toStringAsFixed(5)} (floor=$_energyFloor)');
      }
      if (rms < _energyFloor) {
        _confirmBuf.clear();
        return;
      }

      // Rate-limit inference to ~5 Hz
      _chunksSinceLastInference++;
      if (_chunksSinceLastInference < 1) {
        return; // run every chunk for responsiveness
      }
      _chunksSinceLastInference = 0;

      if (_inferenceInFlight) return;
      _inferenceInFlight = true;

      final copy = Float32List.fromList(_audioWindow);
      unawaited(_processAsync(copy, rms));
    } catch (e) {
      _log('onAudioChunk error: $e');
    }
  }

  double _computeRms(Float32List audio) {
    double sum = 0;
    for (int i = 0; i < audio.length; i++) {
      sum += audio[i] * audio[i];
    }
    return math.sqrt(sum / audio.length);
  }

  Future<void> _processAsync(Float32List audio, double rms) async {
    try {
      if (!_running || _session == null) return;
      // Isolate.run works with static methods in Dart 3+
      final tensor = await Isolate.run(() => _buildMelTensor(audio));
      await _runInference(tensor, rms);
    } catch (e, st) {
      _log('Process error: $e\n$st');
    } finally {
      _inferenceInFlight = false;
    }
  }

  Future<void> _runInference(Float32List melTensor, double rms) async {
    if (!_running || _session == null) return;
    OrtValue? input;
    try {
      // Pass Float32List directly (supported typed data — no .toList() needed)
      // Shape: [batch=1, channels=1, mel_bins=80, time_frames=96]
      input = await OrtValue.fromList(melTensor, [1, 1, _nMels, _targetFrames]);

      final outputs = await _session!.run({'melspectrogram': input});

      // Parse logits [1, 2] -> softmax -> P(wake)
      // asList() on shape [1,2] returns [[l0, l1]]
      final logitsOut = outputs['logits'] ?? outputs.values.first;
      final raw = await logitsOut.asList();

      double l0 = 0.0, l1 = 0.0;
      if (raw.isNotEmpty) {
        final inner = raw[0] is List ? raw[0] as List : raw;
        if (inner.length >= 2) {
          l0 = (inner[0] as num).toDouble();
          l1 = (inner[1] as num).toDouble();
        } else if (inner.length == 1) {
          l1 = (inner[0] as num).toDouble();
        }
      }

      // Release output OrtValues (native memory)
      for (final v in outputs.values) {
        try {
          await v.dispose();
        } catch (_) {}
      }

      // Softmax
      final exp0 = math.exp(l0);
      final exp1 = math.exp(l1);
      final wakeProb = exp1 / (exp0 + exp1);

      _logV(
          'Prob=${wakeProb.toStringAsFixed(4)}  RMS=${rms.toStringAsFixed(4)}');

      _processConfirmation(wakeProb);
    } catch (e) {
      _log('Inference error: $e');
    } finally {
      // Always release input tensor memory
      try {
        await input?.dispose();
      } catch (_) {}
    }
  }

  void _processConfirmation(double wakeProb) {
    // Cooldown check
    if (_lastTrigger != null &&
        DateTime.now().difference(_lastTrigger!) < _cooldown) {
      return;
    }

    // Tier 1: Fast-pass
    if (wakeProb >= _fastPassThreshold) {
      _log(
          '🚀 FAST-PASS (prob=${wakeProb.toStringAsFixed(4)} ≥ $_fastPassThreshold)');
      _confirmBuf.clear();
      _fire();
      return;
    }

    // Tier 2: Accumulate for temporal confirmation
    if (wakeProb >= _detectFloor) {
      _confirmBuf.add(wakeProb);
      if (_confirmBuf.length > _confirmWindow) _confirmBuf.removeAt(0);

      if (_confirmBuf.length >= _confirmQuorum) {
        final aboveFloor = _confirmBuf.where((p) => p >= _detectFloor).length;
        final mean = _confirmBuf.reduce((a, b) => a + b) / _confirmBuf.length;
        double varSum = 0;
        for (final p in _confirmBuf) {
          varSum += (p - mean) * (p - mean);
        }
        final stdDev = math.sqrt(varSum / _confirmBuf.length);

        _logV('Confirming: $aboveFloor/$_confirmWindow above floor '
            'stdDev=${stdDev.toStringAsFixed(4)} cap=$_varianceCap');

        if (aboveFloor >= _confirmQuorum && stdDev <= _varianceCap) {
          _log('✅ CONFIRMED ($aboveFloor/$_confirmWindow, '
              'stdDev=${stdDev.toStringAsFixed(4)})');
          _confirmBuf.clear();
          _fire();
        }
      }
    } else {
      // Tier 3: Below floor — decay buffer
      _confirmBuf.clear();
    }
  }

  void _fire() {
    if (!_running || _onDetected == null) return;
    _lastTrigger = DateTime.now();
    _log('🔊 "Zerotwo" DETECTED');
    try {
      _onDetected!(0);
    } catch (_) {}
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FEATURE EXTRACTION — Pure Dart mel-spectrogram [1, 1, 80, 96]
  //
  // MUST MATCH training script 06_train.py EXACTLY:
  //   sr=16000, n_fft=512, hop_length=160, win_length=400, n_mels=80
  //   mel = librosa.feature.melspectrogram(y, sr, n_mels, n_fft, hop, win)
  //   mel_db = librosa.power_to_db(mel + 1e-9, ref=np.max)
  //   mel_db = (mel_db - mel_db.mean()) / (mel_db.std() + 1e-9)  ← GLOBAL
  //   mel_db = mel_db[:, :96]  ← FIRST 96 frames
  // ══════════════════════════════════════════════════════════════════════════

  static Float32List _buildMelTensor(Float32List audio) {
    const int nFft = 512;
    const int hopLength = 160;
    const int winLength = 400; // 25ms window — MUST match training
    const int nMels = 80;
    const int targetFrames = 96;
    const int halfFft = nFft ~/ 2 + 1; // 257
    const int sampleRate = 16000;

    // 1. Hann window of length winLength, zero-padded to nFft
    //    librosa uses win_length=400 centered inside n_fft=512
    final hann = Float64List(nFft); // zero-initialized
    final padLeft = (nFft - winLength) ~/ 2; // 56
    for (int i = 0; i < winLength; i++) {
      hann[padLeft + i] = 0.5 * (1.0 - math.cos(2.0 * math.pi * i / winLength));
    }

    // 2. Centre-pad (librosa center=True, mode='reflect')
    final padLen = nFft ~/ 2; // 256
    final paddedLen = audio.length + 2 * padLen;
    final padded = Float64List(paddedLen);
    // Reflect left
    for (int i = 0; i < padLen; i++) {
      final srcIdx = padLen - i;
      padded[i] = srcIdx < audio.length ? audio[srcIdx] : 0.0;
    }
    // Centre copy
    for (int i = 0; i < audio.length; i++) {
      padded[padLen + i] = audio[i];
    }
    // Reflect right
    for (int i = 0; i < padLen; i++) {
      final srcIdx = audio.length - 2 - i;
      padded[padLen + audio.length + i] = srcIdx >= 0 ? audio[srcIdx] : 0.0;
    }

    // 3. STFT → power spectrum
    final nFrames = 1 + audio.length ~/ hopLength;
    // powerSpec[freq_bin][frame]
    final powerSpec =
        List<Float64List>.generate(halfFft, (_) => Float64List(nFrames));
    final frameR = Float64List(nFft);
    final frameI = Float64List(nFft);

    // Twiddle factors for FFT
    final twR = Float64List(nFft ~/ 2);
    final twI = Float64List(nFft ~/ 2);
    for (int i = 0; i < nFft ~/ 2; i++) {
      final a = -2.0 * math.pi * i / nFft;
      twR[i] = math.cos(a);
      twI[i] = math.sin(a);
    }

    for (int frame = 0; frame < nFrames; frame++) {
      final start = frame * hopLength;
      for (int i = 0; i < nFft; i++) {
        final idx = start + i;
        final s = idx < paddedLen ? padded[idx] : 0.0;
        frameR[i] = s * hann[i];
        frameI[i] = 0.0;
      }

      _fft(frameR, frameI, nFft, twR, twI);

      for (int k = 0; k < halfFft; k++) {
        powerSpec[k][frame] = frameR[k] * frameR[k] + frameI[k] * frameI[k];
      }
    }

    // 4. Mel filter bank — librosa default = SLANEY (NOT HTK)
    final melFilters = _computeMelFiltersSlaney(
        nMels, nFft, sampleRate, 0.0, sampleRate / 2.0);

    // 5. Apply mel filters → power_to_db(mel + 1e-9, ref=np.max)
    final melSpec =
        List<Float64List>.generate(nMels, (_) => Float64List(nFrames));
    double globalMax = 1e-10;
    for (int m = 0; m < nMels; m++) {
      for (int f = 0; f < nFrames; f++) {
        double sum = 0;
        for (int k = 0; k < halfFft; k++) {
          sum += melFilters[m][k] * powerSpec[k][f];
        }
        sum += 1e-9; // Match: power_to_db(mel + 1e-9, ...)
        melSpec[m][f] = sum;
        if (sum > globalMax) globalMax = sum;
      }
    }

    // Convert to dB: 10 * log10(S / ref) where ref = globalMax
    for (int m = 0; m < nMels; m++) {
      for (int f = 0; f < nFrames; f++) {
        double db = 10.0 * math.log(melSpec[m][f] / globalMax) / math.ln10;
        if (db < -80.0) db = -80.0; // top_db=80 (librosa default)
        melSpec[m][f] = db;
      }
    }

    // 6. GLOBAL normalization: (mel_db - mean) / (std + 1e-9)
    //    This is THE critical difference — training uses GLOBAL, not per-channel
    final int totalElements = nMels * nFrames;
    double globalMean = 0;
    for (int m = 0; m < nMels; m++) {
      for (int f = 0; f < nFrames; f++) {
        globalMean += melSpec[m][f];
      }
    }
    globalMean /= totalElements;

    double globalVar = 0;
    for (int m = 0; m < nMels; m++) {
      for (int f = 0; f < nFrames; f++) {
        final d = melSpec[m][f] - globalMean;
        globalVar += d * d;
      }
    }
    final globalStd = math.sqrt(globalVar / totalElements);
    final stdSafe = globalStd < 1e-9 ? 1e-9 : globalStd;

    for (int m = 0; m < nMels; m++) {
      for (int f = 0; f < nFrames; f++) {
        melSpec[m][f] = (melSpec[m][f] - globalMean) / stdSafe;
      }
    }

    // 7. Pack into [1, 1, nMels, targetFrames] = 7680 floats
    //    Take FIRST 96 frames (training: mel_db[:, :target_frames])
    final result = Float32List(nMels * targetFrames);
    for (int m = 0; m < nMels; m++) {
      for (int f = 0; f < targetFrames; f++) {
        result[m * targetFrames + f] =
            f < nFrames ? melSpec[m][f].toDouble() : 0.0;
      }
    }

    return result;
  }

  static void _fft(
      Float64List r, Float64List im, int n, Float64List twR, Float64List twI) {
    // Bit-reversal
    int j = 0;
    for (int i = 0; i < n - 1; i++) {
      if (i < j) {
        double t = r[i];
        r[i] = r[j];
        r[j] = t;
        t = im[i];
        im[i] = im[j];
        im[j] = t;
      }
      int k = n >> 1;
      while (k <= j) {
        j -= k;
        k >>= 1;
      }
      j += k;
    }
    // Butterfly
    int step = 1;
    while (step < n) {
      final half = step;
      step <<= 1;
      final stride = n ~/ step;
      for (int g = 0; g < n; g += step) {
        for (int p = 0; p < half; p++) {
          final wR = twR[p * stride];
          final wI = twI[p * stride];
          final e = g + p, o = e + half;
          final tR = wR * r[o] - wI * im[o];
          final tI = wR * im[o] + wI * r[o];
          r[o] = r[e] - tR;
          im[o] = im[e] - tI;
          r[e] += tR;
          im[e] += tI;
        }
      }
    }
  }

  /// Slaney-scale mel filter bank — matches librosa.filters.mel default
  /// (NOT HTK scale — librosa uses Slaney by default unless htk=True)
  static List<List<double>> _computeMelFiltersSlaney(
      int nMels, int nFft, int sr, double fMin, double fMax) {
    // Slaney mel scale: linear below 1kHz, log above
    double hzToMel(double hz) {
      const double minLogHz = 1000.0;
      const double minLogMel = 15.0; // 1000/200*3
      const double logStep = 27.0 / math.ln2; // ~38.96
      if (hz < minLogHz) return 3.0 * hz / 200.0;
      return minLogMel + math.log(hz / minLogHz) * logStep;
    }

    double melToHz(double mel) {
      const double minLogHz = 1000.0;
      const double minLogMel = 15.0;
      const double logStep = 27.0 / math.ln2;
      if (mel < minLogMel) return 200.0 * mel / 3.0;
      return minLogHz * math.exp((mel - minLogMel) / logStep);
    }

    final melMin = hzToMel(fMin);
    final melMax = hzToMel(fMax);
    final nPoints = nMels + 2;

    // Evenly spaced in mel, then convert back to Hz
    final melPts = List<double>.generate(
        nPoints, (i) => melMin + i * (melMax - melMin) / (nPoints - 1));
    final hzPts = melPts.map(melToHz).toList();

    // Convert Hz to FFT bin indices
    final halfFft = nFft ~/ 2 + 1;
    final bins = hzPts
        .map((hz) => ((hz * nFft) / sr).floor().clamp(0, halfFft - 1))
        .toList();

    // Build triangular filters with Slaney normalization (area = 1)
    final filters = List<List<double>>.generate(
        nMels, (_) => List<double>.filled(halfFft, 0.0));

    for (int m = 0; m < nMels; m++) {
      final fL = bins[m];
      final fC = bins[m + 1];
      final fR = bins[m + 2];

      // Slaney normalization: 2 / (hzPts[m+2] - hzPts[m])
      final norm = 2.0 / (hzPts[m + 2] - hzPts[m]);

      // Rising slope
      if (fC > fL) {
        for (int k = fL; k < fC && k < halfFft; k++) {
          filters[m][k] = (k - fL) / (fC - fL) * norm;
        }
      }
      // Falling slope
      if (fR > fC) {
        for (int k = fC; k <= fR && k < halfFft; k++) {
          filters[m][k] = (fR - k) / (fR - fC) * norm;
        }
      }
    }
    return filters;
  }

  // ── Logging ───────────────────────────────────────────────────────────────
  void _log(String msg) {
    // ignore: avoid_print
    debugPrint('[WakeWord] $msg');
  }

  void _logV(String msg) {
    if (enableDebugLogging) {
      // ignore: avoid_print
      debugPrint('[WakeWord] $msg');
    }
  }
}
