import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:anime_waifu/services/user_profile/affection_service.dart';
import 'package:anime_waifu/services/database_storage/firestore_service.dart';
import 'package:anime_waifu/services/utilities_core/presence_message_generator.dart';

/// Tracks trust and milestone progression across the relationship.
/// The state is cached locally and synced into Firestore.
class RelationshipProgressionService {
  static final RelationshipProgressionService instance =
      RelationshipProgressionService._();

  RelationshipProgressionService._() {
    // Initialize by reloading current user state
    unawaited(_enqueue(() => _reloadForUser(FirebaseAuth.instance.currentUser)));
  }

  static const _stateKey = 'rps_state_v1';
  static const _legacyOwnerKey = 'relationshipLegacyOwnerUid';

  Future<void> _operationQueue = Future<void>.value();

  RelationshipState _state = RelationshipState.initial();

  static const List<RelationshipStage> stages = [
    RelationshipStage(0, 'Stranger', 'Cautious, formal, slightly guarded'),
    RelationshipStage(
      50,
      'Acquaintance',
      'Warm but reserved, learning about you',
    ),
    RelationshipStage(
      120,
      'Friend',
      'Relaxed, teasing starts, comfortable',
    ),
    RelationshipStage(
      250,
      'Close Friend',
      'More open, shares feelings, protective',
    ),
    RelationshipStage(
      450,
      'Confidant',
      'Tells secrets, vulnerable, trusting',
    ),
    RelationshipStage(
      700,
      'Devoted',
      'Deeply attached, needs you, expressive',
    ),
    RelationshipStage(
      1000,
      'Bonded',
      'Feels incomplete without you, intense',
    ),
    RelationshipStage(
      1400,
      'Intimate',
      'Rare vulnerability, confesses deeply',
    ),
    RelationshipStage(
      1900,
      'Soulbound',
      'Feels like one mind, knows you deeply',
    ),
    RelationshipStage(
      2500,
      'Soulmate',
      'Complete trust, unconditional presence',
    ),
  ];

  RelationshipStage get currentStage {
    final pts = AffectionService.instance.points;
    return stages.lastWhere(
      (stage) => pts >= stage.threshold,
      orElse: () => stages.first,
    );
  }

  int get trustScore => _state.trustScore;
  RelationshipState get state => _state;

  Future<void> load() {
    return _enqueue(() => _reloadForUser(FirebaseAuth.instance.currentUser));
  }

  Future<void> addTrust(int delta) {
    return _enqueue(() async {
      _state.trustScore = (_state.trustScore + delta).clamp(0, 100);
      _state.updatedAtMs = DateTime.now().millisecondsSinceEpoch;
      await _saveCurrentState();
    });
  }

  Future<void> reduceTrust(int delta) => addTrust(-delta);

  bool hasMilestone(String key) => _state.milestones.containsKey(key);

  Future<bool> recordMilestone(String key, {String? note}) async {
    var recorded = false;
    await _enqueue(() async {
      if (_state.milestones.containsKey(key)) return;
      _state.milestones[key] = MilestoneEntry(
        key: key,
        note: note ?? key,
        at: DateTime.now(),
      );
      _state.updatedAtMs = DateTime.now().millisecondsSinceEpoch;
      await _saveCurrentState();
      recorded = true;
    });
    return recorded;
  }

  String getProgressionContextBlock() {
    final stage = currentStage;
    final trust = trustScore;
    final buffer = StringBuffer();
    buffer.writeln('\n// [RELATIONSHIP STAGE]:');
    buffer.writeln('Stage: ${stage.name} — ${stage.description}');
    buffer.writeln('Trust score: $trust/100');

    if (trust < 30) {
      buffer.writeln(
        'Hint: Low trust — avoid vulnerability, stay slightly guarded.',
      );
    } else if (trust >= 80) {
      buffer.writeln(
        'Hint: High trust — full emotional openness is natural here.',
      );
    }

    final recent = _state.milestones.values
        .where((milestone) => DateTime.now().difference(milestone.at).inDays < 7)
        .map((milestone) => milestone.note)
        .take(2)
        .join(', ');
    if (recent.isNotEmpty) {
      buffer.writeln('Recent milestones: $recent');
    }

    buffer.writeln();
    return buffer.toString();
  }

  Future<String?> generateStageTransitionMessage(
    RelationshipStage newStage,
    String personaName,
  ) {
    return PresenceMessageGenerator.instance.generate(
      messageType: 'signature',
      personaName: personaName,
      context: {
        'sigType': 'stage_transition',
        'newStage': newStage.name,
        'description': newStage.description,
      },
    );
  }

  Future<void> _reloadForUser(User? user) async {
    final prefs = await SharedPreferences.getInstance();
    final local = _readLocalState(prefs, user?.uid);

    var resolved = local;
    var shouldPushCloud = false;

    if (user != null) {
      final cloudData = await FirestoreService().loadRelationshipProgression();
      final cloud = RelationshipState.fromJson(cloudData);
      resolved = _resolveState(local, cloud);
      shouldPushCloud = cloudData.isEmpty || !resolved.sameAs(cloud);
    }

    _state = resolved;
    await _writeLocalState(prefs, user?.uid, resolved);

    if (user != null && shouldPushCloud) {
      await _pushState(resolved);
    }
  }

  Future<void> _saveCurrentState() async {
    final prefs = await SharedPreferences.getInstance();
    await _writeLocalState(prefs, FirebaseAuth.instance.currentUser?.uid, _state);

    if (FirestoreService().isSignedIn) {
      await _pushState(_state);
    }
  }

  Future<void> _pushState(RelationshipState value) {
    return FirestoreService().saveRelationshipProgression(
      trustScore: value.trustScore,
      milestones: value.milestones.map(
        (key, entry) => MapEntry(key, entry.toJson()),
      ),
      updatedAtMs: value.updatedAtMs,
      relationshipStage: currentStage.name,
    );
  }

  RelationshipState _resolveState(
    RelationshipState local,
    RelationshipState cloud,
  ) {
    if (!local.hasData && !cloud.hasData) {
      return RelationshipState.initial();
    }
    if (!cloud.hasData) return local;
    if (!local.hasData) return cloud;
    return cloud.updatedAtMs >= local.updatedAtMs ? cloud : local;
  }

  RelationshipState _readLocalState(SharedPreferences prefs, String? uid) {
    final raw = uid == null
        ? prefs.getString(_guestKey())
        : prefs.getString(_scopedKey(uid)) ??
            ((prefs.getString(_legacyOwnerKey) == null ||
                    prefs.getString(_legacyOwnerKey) == uid)
                ? prefs.getString(_stateKey)
                : null);

    if (raw == null || raw.isEmpty) {
      return RelationshipState.initial();
    }

    try {
      return RelationshipState.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return RelationshipState.initial();
    }
  }

  Future<void> _writeLocalState(
    SharedPreferences prefs,
    String? uid,
    RelationshipState value,
  ) async {
    final encoded = jsonEncode(value.toJson());
    await prefs.setString(uid == null ? _guestKey() : _scopedKey(uid), encoded);
    await prefs.setString(_stateKey, encoded);
    if (uid != null) {
      await prefs.setString(_legacyOwnerKey, uid);
    }
  }

  String _scopedKey(String uid) => 'relationship.$uid.$_stateKey';
  String _guestKey() => 'relationship.guest.$_stateKey';

  Future<void> _enqueue(Future<void> Function() operation) {
    final future = _operationQueue.then((_) => operation());
    _operationQueue = future.catchError((Object error, StackTrace stackTrace) {
      // Keep the queue alive if one save/load fails.
    });
    return future;
  }
}

class RelationshipStage {
  final int threshold;
  final String name;
  final String description;

  const RelationshipStage(this.threshold, this.name, this.description);
}

class RelationshipState {
  int trustScore;
  int updatedAtMs;
  Map<String, MilestoneEntry> milestones;

  RelationshipState({
    required this.trustScore,
    required this.updatedAtMs,
    required this.milestones,
  });

  factory RelationshipState.initial() => RelationshipState(
        trustScore: 30,
        updatedAtMs: 0,
        milestones: {},
      );

  factory RelationshipState.fromJson(Map<String, dynamic> json) {
    return RelationshipState(
      trustScore:
          json['trustScore'] as int? ?? json['trust'] as int? ?? 30,
      updatedAtMs: json['updatedAtMs'] as int? ?? 0,
      milestones: (json['milestones'] as Map? ?? {}).map(
        (key, value) => MapEntry(
          key.toString(),
          MilestoneEntry.fromJson(Map<String, dynamic>.from(value as Map)),
        ),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'trustScore': trustScore,
        'updatedAtMs': updatedAtMs,
        'milestones': milestones.map(
          (key, value) => MapEntry(key, value.toJson()),
        ),
      };

  bool get hasData =>
      updatedAtMs > 0 || milestones.isNotEmpty || trustScore != 30;

  bool sameAs(RelationshipState other) {
    return trustScore == other.trustScore &&
        updatedAtMs == other.updatedAtMs &&
        jsonEncode(toJson()) == jsonEncode(other.toJson());
  }
}

class MilestoneEntry {
  final String key;
  final String note;
  final DateTime at;

  const MilestoneEntry({
    required this.key,
    required this.note,
    required this.at,
  });

  factory MilestoneEntry.fromJson(Map<String, dynamic> json) => MilestoneEntry(
        key: json['key'] as String,
        note: json['note'] as String,
        at: DateTime.parse(json['at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'key': key,
        'note': note,
        'at': at.toIso8601String(),
      };
}


