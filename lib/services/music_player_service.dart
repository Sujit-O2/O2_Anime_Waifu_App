import 'dart:math';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'home_widget_service.dart';

/// System-level music player using just_audio + audio_service.
/// Shows a persistent notification with album art, play/pause/skip controls
/// — visible in notification shade, lock screen, and Android media session.
class MusicPlayerService extends BaseAudioHandler with SeekHandler {
  static final MusicPlayerService _instance = MusicPlayerService._();
  
  // This holds the wrapped AudioHandler returned by AudioService.init()
  static AudioHandler? _audioHandlerProxy;

  // Called in main.dart to setup the service
  static Future<AudioHandler> initHandler() async {
    _audioHandlerProxy = await AudioService.init(
      builder: () => _instance,
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.example.anime_waifu.channel.audio',
        androidNotificationChannelName: 'Zero Two Music',
        androidNotificationChannelDescription: 'Music player controls',
        androidNotificationIcon: 'mipmap/ic_launcher',
        androidNotificationOngoing: false,
        androidStopForegroundOnPause: false,
        notificationColor: Color(0xFF9B59B6),
      ),
    );
    return _audioHandlerProxy!;
  }

  static MusicPlayerService get instance => _instance;
  // Expose the proxy so UI components can call `.play()` on it to trigger the OS notification
  static AudioHandler? get handler => _audioHandlerProxy;

  factory MusicPlayerService() => _instance;
  MusicPlayerService._();

  final AudioPlayer _player = AudioPlayer();
  OnAudioQuery? _queryInstance;
  OnAudioQuery get _query => _queryInstance ??= OnAudioQuery();


  List<SongModel> _songs = [];
  int _currentIndex = 0;
  bool _initialized = false;

  // ── Notifiers for the UI ──────────────────────────────────────────────────
  final ValueNotifier<SongModel?> currentSong = ValueNotifier(null);
  final ValueNotifier<bool> isPlaying = ValueNotifier(false);
  final ValueNotifier<Duration> position = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> duration = ValueNotifier(Duration.zero);
  final ValueNotifier<List<SongModel>> songList = ValueNotifier([]);
  final ValueNotifier<bool> isMiniPlayerVisible = ValueNotifier(false);
  final ValueNotifier<bool> isMiniPlayerMinimized = ValueNotifier(false);
  final ValueNotifier<bool> isShuffle = ValueNotifier(false);
  final ValueNotifier<bool> isRepeat = ValueNotifier(false);
  final ValueNotifier<Map<String, List<SongModel>>> folders = ValueNotifier({});

  AudioPlayer get player => _player;

  Future<bool> requestPermission() async {
    return await _query.permissionsRequest();
  }

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Small delay to ensure native plugin is fully bound
    await Future.delayed(const Duration(seconds: 1));

    final hasPermission = await _query.permissionsStatus();

    if (!hasPermission) await _query.permissionsRequest();

    final allSongs = await _query.querySongs(
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );

    // Filter out voice recordings, notifications, etc.
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
    _groupSongsByFolder();

    _player.positionStream.listen((pos) => position.value = pos);
    _player.durationStream.listen((dur) => duration.value = dur ?? Duration.zero);
    _player.playbackEventStream.listen(_broadcastState);
    _player.playerStateStream.listen((state) {
      isPlaying.value = state.playing;
      if (state.processingState == ProcessingState.completed) {
        if (isRepeat.value) {
          _player.seek(Duration.zero);
          _player.play();
        } else {
          skipToNext();
        }
      }
    });
  }

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
        MediaAction.skipToNext,
        MediaAction.skipToPrevious,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: _currentIndex,
    ));
  }

  void _groupSongsByFolder() {
    final Map<String, List<SongModel>> groups = {};
    for (var song in _songs) {
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

  List<SongModel>? _currentPlaylist;

  Future<void> playSongAt(int index, {List<SongModel>? playlist}) async {
    final list = playlist ?? _currentPlaylist ?? _songs;
    if (list.isEmpty) return;

    _currentPlaylist = list;
    _currentIndex = index.clamp(0, list.length - 1);
    final song = list[_currentIndex];
    currentSong.value = song;
    isMiniPlayerVisible.value = true;
    isMiniPlayerMinimized.value = false;

    try {
      if (song.uri != null) {
        await _player.setAudioSource(AudioSource.uri(Uri.parse(song.uri!)));

        // Build MediaItem with album art URI for system notification
        final artUri = Uri.parse(
            'content://media/external/audio/media/${song.id}/albumart');
        mediaItem.add(MediaItem(
          id: song.id.toString(),
          album: song.album ?? 'Unknown Album',
          title: song.title,
          artist: song.artist ?? 'Unknown Artist',
          duration: Duration(milliseconds: song.duration ?? 0),
          artUri: artUri,
          extras: {
            'songId': song.id,
            'path': song.data,
          },
        ));

        await _player.play();

        // Push current song to home screen widget
        HomeWidgetService.updateMusicWidget(
          title: song.title,
          artist: song.artist ?? 'Unknown',
          isPlaying: true,
        );
      }
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
      _currentPlaylist = folderSongs;
      songList.value = folderSongs;
      await playSongAt(0, playlist: folderSongs);
    } else {
      await playSongByName(folderName);
    }
  }

  @override
  Future<void> play() async {
    await _player.play();
    final song = currentSong.value;
    if (song != null) {
      HomeWidgetService.updateMusicWidget(
        title: song.title,
        artist: song.artist ?? 'Unknown',
        isPlaying: true,
      );
    }
  }

  @override
  Future<void> pause() async {
    await _player.pause();
    final song = currentSong.value;
    if (song != null) {
      HomeWidgetService.updateMusicWidget(
        title: song.title,
        artist: song.artist ?? 'Unknown',
        isPlaying: false,
      );
    }
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    currentSong.value = null;
    isPlaying.value = false;
    isMiniPlayerVisible.value = false;
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    final list = _currentPlaylist ?? _songs;
    if (list.isEmpty) return;
    int next;
    if (isShuffle.value) {
      next = Random().nextInt(list.length);
    } else {
      next = (_currentIndex + 1) % list.length;
    }
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

  void toggleShuffle() {
    isShuffle.value = !isShuffle.value;
  }

  void toggleRepeat() {
    isRepeat.value = !isRepeat.value;
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
