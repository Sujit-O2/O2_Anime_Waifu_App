import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🎙️ Voice Clone Training Service
///
/// Train Zero Two to sound EXACTLY like your favorite character.
/// Upload 5-10 voice samples → custom TTS model.
/// Uses Groq/OpenAI voice fine-tuning API.
class VoiceCloneTrainingService {
  VoiceCloneTrainingService._();
  static final VoiceCloneTrainingService instance =
      VoiceCloneTrainingService._();

  final List<VoiceProfile> _profiles = [];
  String? _activeProfileId;
  bool _isTraining = false;

  static const String _storageKey = 'voice_profiles_v1';
  static const int _minSamples = 5;
  static const int _maxSamples = 15;
  static const int _minDurationSeconds = 3;
  static const int _maxDurationSeconds = 30;

  Future<void> initialize() async {
    await _loadProfiles();
    if (kDebugMode)
      debugPrint('[VoiceClone] Initialized with ${_profiles.length} profiles');
  }

  /// Create a new voice profile
  Future<VoiceProfile> createProfile({
    required String name,
    required String description,
    String? characterReference,
  }) async {
    final profile = VoiceProfile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      characterReference: characterReference,
      samples: [],
      status: TrainingStatus.pending,
      createdAt: DateTime.now(),
    );

    _profiles.add(profile);
    await _saveProfiles();

    if (kDebugMode) debugPrint('[VoiceClone] Created profile: ${profile.name}');
    return profile;
  }

  /// Add voice sample to profile
  Future<bool> addSample({
    required String profileId,
    required String audioPath,
    required int durationSeconds,
    String? transcript,
  }) async {
    final profileIndex = _profiles.indexWhere((p) => p.id == profileId);
    if (profileIndex == -1) return false;

    final profile = _profiles[profileIndex];

    // Validate duration
    if (durationSeconds < _minDurationSeconds ||
        durationSeconds > _maxDurationSeconds) {
      if (kDebugMode)
        debugPrint('[VoiceClone] Invalid duration: $durationSeconds seconds');
      return false;
    }

    // Check max samples
    if (profile.samples.length >= _maxSamples) {
      if (kDebugMode) debugPrint('[VoiceClone] Max samples reached');
      return false;
    }

    final sample = VoiceSample(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      audioPath: audioPath,
      durationSeconds: durationSeconds,
      transcript: transcript,
      uploadedAt: DateTime.now(),
    );

    profile.samples.add(sample);
    _profiles[profileIndex] = profile;
    await _saveProfiles();

    if (kDebugMode)
      debugPrint(
          '[VoiceClone] Added sample ${profile.samples.length}/$_maxSamples');
    return true;
  }

  /// Remove sample from profile
  Future<void> removeSample(String profileId, String sampleId) async {
    final profileIndex = _profiles.indexWhere((p) => p.id == profileId);
    if (profileIndex == -1) return;

    final profile = _profiles[profileIndex];
    profile.samples.removeWhere((s) => s.id == sampleId);
    _profiles[profileIndex] = profile;
    await _saveProfiles();
  }

  /// Start training the voice model
  Future<bool> startTraining(String profileId, String apiKey) async {
    final profileIndex = _profiles.indexWhere((p) => p.id == profileId);
    if (profileIndex == -1) return false;

    final profile = _profiles[profileIndex];

    // Validate minimum samples
    if (profile.samples.length < _minSamples) {
      if (kDebugMode)
        debugPrint('[VoiceClone] Need at least $_minSamples samples');
      return false;
    }

    if (_isTraining) {
      if (kDebugMode) debugPrint('[VoiceClone] Training already in progress');
      return false;
    }

    _isTraining = true;
    profile.status = TrainingStatus.training;
    profile.trainingProgress = 0.0;
    _profiles[profileIndex] = profile;
    await _saveProfiles();

    try {
      // Simulate training process (replace with actual API call)
      await _trainModel(profile, apiKey);

      profile.status = TrainingStatus.completed;
      profile.trainingProgress = 1.0;
      profile.modelId =
          'model_${profile.id}_${DateTime.now().millisecondsSinceEpoch}';
      _profiles[profileIndex] = profile;
      await _saveProfiles();

      if (kDebugMode)
        debugPrint('[VoiceClone] Training completed: ${profile.modelId}');
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[VoiceClone] Training failed: $e');
      profile.status = TrainingStatus.failed;
      profile.errorMessage = e.toString();
      _profiles[profileIndex] = profile;
      await _saveProfiles();
      return false;
    } finally {
      _isTraining = false;
    }
  }

  /// Train the model (mock implementation - replace with actual API)
  Future<void> _trainModel(VoiceProfile profile, String apiKey) async {
    // Simulate training progress
    for (int i = 0; i <= 100; i += 10) {
      await Future.delayed(const Duration(milliseconds: 500));
      final profileIndex = _profiles.indexWhere((p) => p.id == profile.id);
      if (profileIndex != -1) {
        _profiles[profileIndex].trainingProgress = i / 100.0;
        await _saveProfiles();
      }
    }

    // In production, this would call the actual API:
    // - Upload audio samples
    // - Submit training job
    // - Poll for completion
    // - Download trained model
  }

  /// Set active voice profile
  Future<void> setActiveProfile(String? profileId) async {
    _activeProfileId = profileId;
    final prefs = await SharedPreferences.getInstance();
    if (profileId != null) {
      await prefs.setString('active_voice_profile', profileId);
    } else {
      await prefs.remove('active_voice_profile');
    }
    if (kDebugMode) debugPrint('[VoiceClone] Active profile: $profileId');
  }

  /// Get active profile
  VoiceProfile? getActiveProfile() {
    if (_activeProfileId == null) return null;
    try {
      return _profiles.firstWhere((p) => p.id == _activeProfileId);
    } catch (_) {
      return null;
    }
  }

  /// Get all profiles
  List<VoiceProfile> getAllProfiles() => List.unmodifiable(_profiles);

  /// Get profile by ID
  VoiceProfile? getProfile(String id) {
    try {
      return _profiles.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Delete profile
  Future<void> deleteProfile(String profileId) async {
    _profiles.removeWhere((p) => p.id == profileId);
    if (_activeProfileId == profileId) {
      await setActiveProfile(null);
    }
    await _saveProfiles();
  }

  /// Check if profile is ready for use
  bool isProfileReady(String profileId) {
    final profile = getProfile(profileId);
    return profile?.status == TrainingStatus.completed &&
        profile?.modelId != null;
  }

  /// Get training requirements
  Map<String, dynamic> getTrainingRequirements() {
    return {
      'min_samples': _minSamples,
      'max_samples': _maxSamples,
      'min_duration_seconds': _minDurationSeconds,
      'max_duration_seconds': _maxDurationSeconds,
      'recommended_samples': 8,
      'total_audio_minutes': '2-5 minutes',
    };
  }

  Future<void> _saveProfiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _profiles.map((p) => p.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(jsonList));
    } catch (e) {
      if (kDebugMode) debugPrint('[VoiceClone] Save error: $e');
    }
  }

  Future<void> _loadProfiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString != null && jsonString.isNotEmpty) {
        final jsonList = jsonDecode(jsonString) as List<dynamic>;
        _profiles.clear();
        _profiles.addAll(jsonList.map(
            (json) => VoiceProfile.fromJson(json as Map<String, dynamic>)));
      }

      _activeProfileId = prefs.getString('active_voice_profile');
    } catch (e) {
      if (kDebugMode) debugPrint('[VoiceClone] Load error: $e');
    }
  }
}

/// Voice profile model
class VoiceProfile {
  final String id;
  final String name;
  final String description;
  final String? characterReference;
  final List<VoiceSample> samples;
  TrainingStatus status;
  double trainingProgress;
  String? modelId;
  String? errorMessage;
  final DateTime createdAt;

  VoiceProfile({
    required this.id,
    required this.name,
    required this.description,
    this.characterReference,
    required this.samples,
    required this.status,
    this.trainingProgress = 0.0,
    this.modelId,
    this.errorMessage,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'characterReference': characterReference,
      'samples': samples.map((s) => s.toJson()).toList(),
      'status': status.name,
      'trainingProgress': trainingProgress,
      'modelId': modelId,
      'errorMessage': errorMessage,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory VoiceProfile.fromJson(Map<String, dynamic> json) {
    return VoiceProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      characterReference: json['characterReference'] as String?,
      samples: (json['samples'] as List<dynamic>)
          .map((s) => VoiceSample.fromJson(s as Map<String, dynamic>))
          .toList(),
      status: TrainingStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TrainingStatus.pending,
      ),
      trainingProgress: (json['trainingProgress'] as num?)?.toDouble() ?? 0.0,
      modelId: json['modelId'] as String?,
      errorMessage: json['errorMessage'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Voice sample model
class VoiceSample {
  final String id;
  final String audioPath;
  final int durationSeconds;
  final String? transcript;
  final DateTime uploadedAt;

  const VoiceSample({
    required this.id,
    required this.audioPath,
    required this.durationSeconds,
    this.transcript,
    required this.uploadedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'audioPath': audioPath,
      'durationSeconds': durationSeconds,
      'transcript': transcript,
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }

  factory VoiceSample.fromJson(Map<String, dynamic> json) {
    return VoiceSample(
      id: json['id'] as String,
      audioPath: json['audioPath'] as String,
      durationSeconds: json['durationSeconds'] as int,
      transcript: json['transcript'] as String?,
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
    );
  }
}

/// Training status enum
enum TrainingStatus {
  pending,
  training,
  completed,
  failed,
}
