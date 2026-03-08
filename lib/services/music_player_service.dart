import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:audio_service/audio_service.dart';

/// Singleton music player service using just_audio + audio_service for background media notification.
class MusicPlayerService extends BaseAudioHandler with SeekHandler {
  static final MusicPlayerService _instance = MusicPlayerService._();

  static Future<MusicPlayerService> initHandler() async {
    return _instance;
  }

  static MusicPlayerService get instance => _instance;
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

    // Broadcast state to audio_service
    _player.playbackEventStream.listen(_broadcastState);
    _player.playerStateStream.listen((state) {
      isPlaying.value = state.playing;
      if (state.processingState == ProcessingState.completed) {
        skipToNext(); // use BaseAudioHandler method
      }
    });

    _groupSongsByFolder();
  }

  void _broadcastState(PlaybackEvent event) {
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
    ));
  }

  void _groupSongsByFolder() {
    final Map<String, List<SongModel>> groups = {};
    for (var song in _songs) {
      // Get folder path from song.data
      final pathParts = song.data.split('/');
      if (pathParts.length > 1) {
        final folderPath = pathParts.sublist(0, pathParts.length - 1).join('/');
        groups.putIfAbsent(folderPath, () => []).add(song);
      } else {
        groups.putIfAbsent('Unknown', () => []).add(song);
      }
    }
    folders.value = groups;
  }

  final ValueNotifier<Map<String, List<SongModel>>> folders = ValueNotifier({});

  Future<void> playSongAt(int index, {List<SongModel>? playlist}) async {
    final list = playlist ?? _songs;
    if (list.isEmpty) return;

    // If we're changing the active playlist, update current tracking
    _currentPlaylist = playlist ?? _currentPlaylist ?? _songs;

    _currentIndex = index.clamp(0, list.length - 1);
    final song = list[_currentIndex];
    currentSong.value = song;
    isMiniPlayerVisible.value = true;
    isMiniPlayerMinimized.value = false;

    try {
      if (song.uri != null) {
        await _player.setAudioSource(AudioSource.uri(Uri.parse(song.uri!)));
        mediaItem.add(MediaItem(
          id: song.id.toString(),
          album: song.album ?? 'Unknown Album',
          title: song.title,
          artist: song.artist ?? 'Unknown Artist',
          duration: Duration(milliseconds: song.duration ?? 0),
          artUri: Uri.parse(
              'content://media/external/audio/media/${song.id}/albumart'),
        ));
        await _player.play();
      }
    } catch (e) {
      debugPrint('MusicPlayer play error: $e');
    }
  }

  List<SongModel>? _currentPlaylist;

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
      // Use _currentPlaylist to scope to this folder — do NOT overwrite _songs
      // (that would permanently break full-library navigation).
      _currentPlaylist = folderSongs;
      songList.value = folderSongs;
      await playSongAt(0, playlist: folderSongs);
    } else {
      // Fallback
      await playSongByName(folderName);
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    currentSong.value = null;
    isPlaying.value = false;
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    final list = _currentPlaylist ?? _songs;
    if (list.isEmpty) return;
    final next = (_currentIndex + 1) % list.length;
    await playSongAt(next, playlist: list);
  }

  @override
  Future<void> skipToPrevious() async {
    final list = _currentPlaylist ?? _songs;
    if (list.isEmpty) return;
    if (position.value.inSeconds > 3) {
      await _player.seek(Duration.zero);
    } else {
      final prev = (_currentIndex - 1 + list.length) % list.length;
      await playSongAt(prev, playlist: list);
    }
  }

  Future<void> playPause() async {
    if (_player.playing) {
      await pause();
    } else if (currentSong.value != null) {
      await play();
    } else {
      await playSongAt(0);
    }
  }

  Future<void> skipNext() => skipToNext();
  Future<void> skipPrevious() => skipToPrevious();
  Future<void> seekTo(Duration pos) => seek(pos);

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
