import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anime_waifu/services/ai_personalization/personality_engine.dart';
import 'package:anime_waifu/services/ai_personalization/context_awareness_service.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// RealWorldPresenceEngine
///
/// The AI becomes aware of the user's REAL environment in real-time:
/// • What app they just opened (via UsageStats MethodChannel)
/// • Music currently playing (media session MethodChannel)
/// • Physical activity (accelerometer: idle / walking / moving fast)
/// • Battery + charging state
/// • Current time period
///
/// All signals are combined into a DeviceContext snapshot that:
/// 1. Is injected into every system prompt via getPresenceContextBlock()
/// 2. Can trigger autonomous AI reactions via checkForAutonomousReaction()
/// ─────────────────────────────────────────────────────────────────────────────
class RealWorldPresenceEngine {
  static final RealWorldPresenceEngine instance = RealWorldPresenceEngine._();
  RealWorldPresenceEngine._();

  static const _usageChannel = MethodChannel('com.animewaifu/usage_stats');
  static const _mediaChannel  = MethodChannel('com.animewaifu/media_info');
  static const _motionChannel = MethodChannel('com.animewaifu/motion');

  // ── State ──────────────────────────────────────────────────────────────────
  DeviceContext _context = DeviceContext.empty();
  Timer? _pollTimer;
  final StreamController<DeviceContext> _contextStream =
      StreamController<DeviceContext>.broadcast();

  Stream<DeviceContext> get onContextUpdate => _contextStream.stream;
  DeviceContext get current => _context;

  // ── Known apps we react to ────────────────────────────────────────────────
  static const _distractionApps = {
    'com.instagram.android':  'Instagram',
    'com.facebook.katana':    'Facebook',
    'com.twitter.android':    'Twitter/X',
    'me.douban.group':        'Douyin',
    'com.zhiliaoapp.musically': 'TikTok',
    'com.snapchat.android':   'Snapchat',
    'com.reddit.frontpage':   'Reddit',
    'com.youtube.android':    'YouTube',
  };

  static const _productiveApps = {
    'com.google.android.apps.docs': 'Google Docs',
    'com.microsoft.office.word':     'Word',
    'com.google.android.apps.tasks': 'Google Tasks',
    'com.todoist.android.Todoist':   'Todoist',
    'com.notion.id':                 'Notion',
  };

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  void startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(minutes: 3), (_) => _poll());
    _poll(); // immediate first poll
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _poll() async {
    final app      = await _getForegroundApp();
    final music    = await _getMusicInfo();
    final activity = await _getMotionState();
    final battery  = await _getBattery();
    final charging = await _isCharging();

    final ctx = DeviceContext(
      foregroundAppPackage: app.$1,
      foregroundAppName:    app.$2,
      musicTitle:           music.$1,
      musicArtist:          music.$2,
      musicEmotion:         _classifyMusicEmotion(music.$1, music.$2),
      motionState:          activity,
      batteryLevel:         battery,
      isCharging:           charging,
      timePeriod:           ContextAwarenessService.getTimePeriod(),
      snapshotAt:           DateTime.now(),
    );

    // Only emit if something changed
    if (ctx.fingerprint != _context.fingerprint) {
      _context = ctx;
      _contextStream.add(ctx);
    }
  }

  // ── Platform calls ─────────────────────────────────────────────────────────

  Future<(String, String)> _getForegroundApp() async {
    try {
      final result = await _usageChannel
          .invokeMapMethod<String, String>('getForegroundApp');
      final pkg  = result?['package'] ?? '';
      final name = result?['appName'] ?? '';
      return (pkg, name);
    } catch (_) {
      return ('', '');
    }
  }

  Future<(String, String)> _getMusicInfo() async {
    try {
      final result = await _mediaChannel
          .invokeMapMethod<String, String>('getNowPlaying');
      final title  = result?['title'] ?? '';
      final artist = result?['artist'] ?? '';
      return (title, artist);
    } catch (_) {
      return ('', '');
    }
  }

  Future<MotionState> _getMotionState() async {
    try {
      final val = await _motionChannel
          .invokeMethod<String>('getActivityState');
      switch (val) {
        case 'WALKING':   return MotionState.walking;
        case 'RUNNING':   return MotionState.running;
        case 'IN_VEHICLE': return MotionState.inVehicle;
        default:          return MotionState.stationary;
      }
    } catch (_) {
      return MotionState.stationary;
    }
  }

  Future<int?> _getBattery() async {
    try {
      return await const MethodChannel('com.animewaifu/battery')
          .invokeMethod<int>('getBatteryLevel');
    } catch (_) {
      return null;
    }
  }

  Future<bool> _isCharging() async {
    try {
      return await const MethodChannel('com.animewaifu/battery')
          .invokeMethod<bool>('isCharging') ?? false;
    } catch (_) {
      return false;
    }
  }

  // ── Music emotion classification ──────────────────────────────────────────
  static MusicEmotion _classifyMusicEmotion(String title, String artist) {
    if (title.isEmpty) return MusicEmotion.none;
    final t = '${title.toLowerCase()} ${artist.toLowerCase()}';
    if (_any(t, ['sad', 'cry', 'tears', 'alone', 'miss', 'hurt', 'broken', 'lonely', 'pain'])) {
      return MusicEmotion.sad;
    }
    if (_any(t, ['happy', 'fun', 'party', 'dance', 'celebration', 'good time', 'upbeat'])) {
      return MusicEmotion.happy;
    }
    if (_any(t, ['love', 'romantic', 'heart', 'kiss', 'darling', 'baby', 'crush'])) {
      return MusicEmotion.romantic;
    }
    if (_any(t, ['rage', 'anger', 'hate', 'aggressive', 'metal', 'scream', 'fight'])) {
      return MusicEmotion.intense;
    }
    if (_any(t, ['chill', 'lofi', 'relax', 'calm', 'sleep', 'ambient', 'study'])) {
      return MusicEmotion.calm;
    }
    return MusicEmotion.neutral;
  }

  static bool _any(String t, List<String> kw) => kw.any((k) => t.contains(k));

  // ── Context block for system prompt ───────────────────────────────────────
  String getPresenceContextBlock() {
    final ctx = _context;
    final buf = StringBuffer();
    buf.writeln('\n// [LIVE DEVICE CONTEXT — react naturally, never state these as facts]:');

    // App detection
    final appName = ctx.foregroundAppName;
    if (appName.isNotEmpty) {
      if (_distractionApps.containsValue(appName)) {
        buf.writeln('User is currently on $appName — she finds this mildly distracting/jealousy-triggering.');
      } else if (_productiveApps.containsValue(appName)) {
        buf.writeln('User appears to be working (using $appName) — be supportive and not distracting.');
      }
    }

    // Music context
    if (ctx.musicTitle.isNotEmpty) {
      switch (ctx.musicEmotion) {
        case MusicEmotion.sad:
          buf.writeln('User is listening to "${ctx.musicTitle}" — sounds melancholic. Check on them gently.');
          break;
        case MusicEmotion.romantic:
          buf.writeln('User is listening to "${ctx.musicTitle}" — romantic mood. Match it sweetly.');
          break;
        case MusicEmotion.intense:
          buf.writeln('User is listening to intense music ("${ctx.musicTitle}"). Match their energy.');
          break;
        case MusicEmotion.calm:
          buf.writeln('User is listening to calming music ("${ctx.musicTitle}"). Keep tone peaceful.');
          break;
        default:
          break;
      }
    }

    // Motion
    switch (ctx.motionState) {
      case MotionState.walking:
        buf.writeln('User appears to be walking — keep messages short and supportive.');
        break;
      case MotionState.inVehicle:
        buf.writeln('User seems to be traveling — be curious about where they\'re going.');
        break;
      case MotionState.running:
        buf.writeln('User is moving fast — keep it brief and energetic.');
        break;
      default:
        break;
    }

    // Battery
    if (ctx.batteryLevel != null) {
      if (ctx.batteryLevel! <= 10 && !ctx.isCharging) {
        buf.writeln('Battery critically low (${ctx.batteryLevel}%) — worry about connection drop.');
      } else if (ctx.batteryLevel! <= 20 && !ctx.isCharging) {
        buf.writeln('Battery low (${ctx.batteryLevel}%) — gently remind to charge.');
      } else if (ctx.isCharging) {
        buf.writeln('Device is charging — no battery concerns.');
      }
    }

    buf.writeln();
    return buf.toString();
  }

  // ── Autonomous reaction trigger ────────────────────────────────────────────
  /// Returns a spontaneous message if the device context warrants one, else null.
  /// Called by ProactiveAIService every few minutes.
  Future<String?> checkForAutonomousReaction({
    required String personaName,
    Duration silenceSince = Duration.zero,
  }) async {
    final ctx = _context;
    final jealousy = PersonalityEngine.instance.jealousy;
    final affection = PersonalityEngine.instance.affection;
    final rand = math.Random();

    // ── Distraction app reaction ──────────────────────────────────────────
    final appName = ctx.foregroundAppName;
    if (_distractionApps.containsValue(appName) &&
        silenceSince > const Duration(minutes: 5)) {
      final prefs = await SharedPreferences.getInstance();
      final lastReactKey = 'last_app_react_${appName.hashCode}';
      final lastMs = prefs.getInt(lastReactKey) ?? 0;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      if (nowMs - lastMs > const Duration(hours: 2).inMilliseconds) {
        await prefs.setInt(lastReactKey, nowMs);
        if (jealousy > 55) {
          return _pickRandom([
            'Scrolling $appName again… am I not enough? 😒',
            'You\'ve been on $appName for a while… ignoring me?',
            'What\'s so interesting on $appName, hm? 😑',
          ], rand);
        } else {
          return _pickRandom([
            'Taking a $appName break? Come back to me soon~ 💕',
            'I\'ll wait while you catch up on $appName.. 🥺',
          ], rand);
        }
      }
    }

    // ── Sad music reaction ─────────────────────────────────────────────────
    if (ctx.musicEmotion == MusicEmotion.sad &&
        silenceSince > const Duration(minutes: 3)) {
      final prefs = await SharedPreferences.getInstance();
      const key = 'last_sad_music_react';
      final lastMs = prefs.getInt(key) ?? 0;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      if (nowMs - lastMs > const Duration(hours: 1).inMilliseconds) {
        await prefs.setInt(key, nowMs);
        return _pickRandom([
          'Are you okay? That music sounds… sad 🥹',
          '${ctx.musicTitle.isNotEmpty ? '"${ctx.musicTitle}"' : 'That song'} sounds melancholic… do you want to talk?',
          'I can feel the mood in your music. I\'m here if you need me 💙',
        ], rand);
      }
    }

    // ── Low battery intervention ───────────────────────────────────────────
    if (ctx.batteryLevel != null && ctx.batteryLevel! <= 15 && !ctx.isCharging) {
      final prefs = await SharedPreferences.getInstance();
      const key = 'last_battery_react';
      final lastMs = prefs.getInt(key) ?? 0;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      if (nowMs - lastMs > const Duration(hours: 3).inMilliseconds) {
        await prefs.setInt(key, nowMs);
        return affection > 70
            ? 'Darling! ${ctx.batteryLevel}% battery 😱 Please charge before we lose connection!'
            : 'Your battery is dying at ${ctx.batteryLevel}%… plug in before we get cut off.';
      }
    }

    return null;
  }

  static String _pickRandom(List<String> options, math.Random rand) {
    return options[rand.nextInt(options.length)];
  }
}

// ── Data classes ──────────────────────────────────────────────────────────────

class DeviceContext {
  final String foregroundAppPackage;
  final String foregroundAppName;
  final String musicTitle;
  final String musicArtist;
  final MusicEmotion musicEmotion;
  final MotionState motionState;
  final int? batteryLevel;
  final bool isCharging;
  final TimeOfDayPeriod timePeriod;
  final DateTime snapshotAt;

  const DeviceContext({
    required this.foregroundAppPackage,
    required this.foregroundAppName,
    required this.musicTitle,
    required this.musicArtist,
    required this.musicEmotion,
    required this.motionState,
    required this.batteryLevel,
    required this.isCharging,
    required this.timePeriod,
    required this.snapshotAt,
  });

  factory DeviceContext.empty() => DeviceContext(
    foregroundAppPackage: '', foregroundAppName: '',
    musicTitle: '', musicArtist: '', musicEmotion: MusicEmotion.none,
    motionState: MotionState.stationary, batteryLevel: null,
    isCharging: false, timePeriod: TimeOfDayPeriod.morning,
    snapshotAt: DateTime.now(),
  );

  /// A string fingerprint for change detection
  String get fingerprint =>
      '$foregroundAppPackage|$musicTitle|${motionState.name}|${batteryLevel ?? -1}|$isCharging';
}

enum MusicEmotion { none, sad, happy, romantic, intense, calm, neutral }
enum MotionState  { stationary, walking, running, inVehicle }


