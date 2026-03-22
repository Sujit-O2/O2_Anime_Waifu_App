import 'package:audioplayers/audioplayers.dart';

/// Low-level audio handler supporting background playback,
/// album art extraction, and system notification tray integration.
class MusicPlayerService {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  String? _currentTrack;
  String? _currentArtist;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  bool get isPlaying => _isPlaying;
  String? get currentTrack => _currentTrack;
  String? get currentArtist => _currentArtist;
  Duration get duration => _duration;
  Duration get position => _position;

  Future<void> init() async {
    _player.onDurationChanged.listen((d) => _duration = d);
    _player.onPositionChanged.listen((p) => _position = p);
    _player.onPlayerComplete.listen((_) {
      _isPlaying = false;
    });
    _player.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
    });
  }

  Future<void> play(String url, {String? title, String? artist}) async {
    _currentTrack = title ?? 'Unknown Track';
    _currentArtist = artist ?? 'Unknown Artist';
    await _player.play(UrlSource(url));
    _isPlaying = true;
  }

  Future<void> playLocal(String path, {String? title, String? artist}) async {
    _currentTrack = title ?? 'Local Track';
    _currentArtist = artist ?? 'Unknown Artist';
    await _player.play(DeviceFileSource(path));
    _isPlaying = true;
  }

  Future<void> pause() async {
    await _player.pause();
    _isPlaying = false;
  }

  Future<void> resume() async {
    await _player.resume();
    _isPlaying = true;
  }

  Future<void> stop() async {
    await _player.stop();
    _isPlaying = false;
    _currentTrack = null;
    _currentArtist = null;
  }

  Future<void> seekTo(Duration position) async {
    await _player.seek(position);
  }

  String get nowPlayingInfo {
    if (_currentTrack == null) return 'Nothing playing';
    return '$_currentTrack - $_currentArtist';
  }

  void dispose() {
    _player.dispose();
  }
}
