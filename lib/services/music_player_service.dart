import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';

/// Singleton music player service using just_audio + on_audio_query.
class MusicPlayerService {
  static final MusicPlayerService _instance = MusicPlayerService._();
  factory MusicPlayerService() => _instance;
  MusicPlayerService._();

  final AudioPlayer _player = AudioPlayer();
  final OnAudioQuery _query = OnAudioQuery();

  List<SongModel> _songs = [];
  int _currentIndex = 0;
  bool _initialized = false;

  // Notifiers for the UI to listen to
  final ValueNotifier<SongModel?> currentSong = ValueNotifier(null);
  final ValueNotifier<bool> isPlaying = ValueNotifier(false);
  final ValueNotifier<Duration> position = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> duration = ValueNotifier(Duration.zero);
  final ValueNotifier<List<SongModel>> songList = ValueNotifier([]);
  final ValueNotifier<bool> isMiniPlayerVisible = ValueNotifier(false);
  final ValueNotifier<bool> isMiniPlayerMinimized = ValueNotifier(false);

  AudioPlayer get player => _player;

  Future<bool> requestPermission() async {
    return await _query.permissionsRequest();
  }

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Fetch all songs from device
    final hasPermission = await _query.permissionsStatus();
    if (!hasPermission) await _query.permissionsRequest();

    final allSongs = await _query.querySongs(
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );

    // Filter out voice memos, whatsapp audio, and ringtones
    _songs = allSongs.where((s) {
      if (s.isMusic != true) return false;
      final path = s.data.toLowerCase();
      if (path.contains('whatsapp') ||
          path.contains('recordings') ||
          path.contains('voice') ||
          path.contains('ringtone') ||
          path.contains('notification') ||
          path.contains('alarm') ||
          path.contains('audio_records') ||
          path.contains('call') ||
          path.contains('telegram') ||
          path.contains('sound_recorder') ||
          path.contains('voice_recorder')) {
        return false;
      }
      return true;
    }).toList();

    songList.value = _songs;

    _player.positionStream.listen((pos) => position.value = pos);
    _player.durationStream
        .listen((dur) => duration.value = dur ?? Duration.zero);
    _player.playerStateStream.listen((state) {
      isPlaying.value = state.playing;
      if (state.processingState == ProcessingState.completed) {
        skipNext();
      }
    });
  }

  Future<void> playSongAt(int index) async {
    if (_songs.isEmpty) return;
    _currentIndex = index.clamp(0, _songs.length - 1);
    final song = _songs[_currentIndex];
    currentSong.value = song;
    isMiniPlayerVisible.value = true;
    isMiniPlayerMinimized.value = false;
    try {
      await _player.setAudioSource(AudioSource.uri(Uri.parse(song.uri!)));
      await _player.play();
    } catch (e) {
      debugPrint('MusicPlayer play error: $e');
    }
  }

  Future<void> playSongByName(String query) async {
    if (_songs.isEmpty) await init();
    final lq = query.toLowerCase();
    int idx = _songs.indexWhere((s) =>
        s.title.toLowerCase().contains(lq) ||
        (s.artist ?? '').toLowerCase().contains(lq) ||
        (s.album ?? '').toLowerCase().contains(lq));
    if (idx < 0) idx = 0;
    await playSongAt(idx);
  }

  Future<void> playFolder(String folderName) async {
    if (_songs.isEmpty) await init();
    final lq = folderName.toLowerCase();
    final folderSongs =
        _songs.where((s) => s.data.toLowerCase().contains(lq)).toList();
    if (folderSongs.isNotEmpty) {
      _songs = folderSongs; // Temporarily restrict playlist to this folder
      songList.value = _songs;
      await playSongAt(0);
    } else {
      // Fallback
      await playSongByName(folderName);
    }
  }

  Future<void> playPause() async {
    if (_player.playing) {
      await _player.pause();
    } else if (currentSong.value != null) {
      await _player.play();
    } else {
      await playSongAt(0);
    }
  }

  Future<void> skipNext() async {
    if (_songs.isEmpty) return;
    final next = (_currentIndex + 1) % _songs.length;
    await playSongAt(next);
  }

  Future<void> skipPrevious() async {
    if (_songs.isEmpty) return;
    if (position.value.inSeconds > 3) {
      await _player.seek(Duration.zero);
    } else {
      final prev = (_currentIndex - 1 + _songs.length) % _songs.length;
      await playSongAt(prev);
    }
  }

  Future<void> seekTo(Duration pos) async {
    await _player.seek(pos);
  }

  Future<void> stop() async {
    await _player.stop();
    currentSong.value = null;
    isPlaying.value = false;
  }

  void hideMiniPlayer() {
    isMiniPlayerVisible.value = false;
  }

  void toggleMinimize() {
    isMiniPlayerMinimized.value = !isMiniPlayerMinimized.value;
  }

  void dispose() {
    _player.dispose();
  }
}
