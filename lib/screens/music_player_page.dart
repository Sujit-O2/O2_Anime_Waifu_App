import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:anime_waifu/services/music_player_service.dart';

class MusicPlayerPage extends StatefulWidget {
  const MusicPlayerPage({super.key});

  @override
  State<MusicPlayerPage> createState() => _MusicPlayerPageState();
}

class _MusicPlayerPageState extends State<MusicPlayerPage>
    with SingleTickerProviderStateMixin {
  final _service = MusicPlayerService();
  late AnimationController _rotateCtrl;
  bool _showList = false;

  @override
  void initState() {
    super.initState();
    _rotateCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 8))
          ..repeat();
    _service.init();
    _service.isPlaying.addListener(_onPlayState);
  }

  void _onPlayState() {
    if (_service.isPlaying.value) {
      _rotateCtrl.repeat();
    } else {
      _rotateCtrl.stop();
    }
  }

  @override
  void dispose() {
    _rotateCtrl.dispose();
    _service.isPlaying.removeListener(_onPlayState);
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Stack(
        children: [
          // Animated gradient bg
          Positioned.fill(
            child: ValueListenableBuilder<SongModel?>(
              valueListenable: _service.currentSong,
              builder: (_, song, __) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF1a0038),
                        Color(0xFF0A0A0F),
                        Color(0xFF001a30)
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // ── Top bar ──────────────────────────────────────────────
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white70, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text('NOW PLAYING',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2)),
                      ),
                      IconButton(
                        icon: Icon(
                            _showList
                                ? Icons.music_note_rounded
                                : Icons.queue_music_rounded,
                            color: Colors.white70,
                            size: 22),
                        onPressed: () => setState(() => _showList = !_showList),
                      ),
                    ],
                  ),
                ),

                if (_showList) _buildSongList() else _buildPlayer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayer() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Album art (animated vinyl)
            ValueListenableBuilder<SongModel?>(
              valueListenable: _service.currentSong,
              builder: (_, song, __) {
                return RotationTransition(
                  turns: _rotateCtrl,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purpleAccent.withValues(alpha: 0.4),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: song != null
                          ? QueryArtworkWidget(
                              id: song.id,
                              type: ArtworkType.AUDIO,
                              nullArtworkWidget: _defaultArtwork(),
                              artworkBorder: BorderRadius.circular(999),
                              artworkWidth: 220,
                              artworkHeight: 220,
                              artworkFit: BoxFit.cover,
                            )
                          : _defaultArtwork(),
                    ),
                  ),
                );
              },
            ),

            // Title + Artist
            ValueListenableBuilder<SongModel?>(
              valueListenable: _service.currentSong,
              builder: (_, song, __) {
                return Column(
                  children: [
                    Text(
                      song?.title ?? 'No Song Selected',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      song?.artist ?? 'Unknown Artist',
                      style: GoogleFonts.outfit(
                          color: Colors.white54, fontSize: 14),
                    ),
                  ],
                );
              },
            ),

            // Seek bar
            ValueListenableBuilder<Duration>(
              valueListenable: _service.position,
              builder: (_, pos, __) {
                return ValueListenableBuilder<Duration>(
                  valueListenable: _service.duration,
                  builder: (_, dur, __) {
                    final total = dur.inMilliseconds.toDouble();
                    final current = pos.inMilliseconds.toDouble().clamp(
                        0.0, (total.isFinite && total > 0) ? total : 1.0);
                    return Column(
                      children: [
                        SliderTheme(
                          data: SliderThemeData(
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6),
                            overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 14),
                            activeTrackColor: Colors.purpleAccent,
                            inactiveTrackColor: Colors.white12,
                            thumbColor: Colors.white,
                            overlayColor:
                                Colors.purpleAccent.withValues(alpha: 0.2),
                          ),
                          child: Slider(
                            value: current,
                            min: 0,
                            max: (total.isFinite && total > 0) ? total : 1,
                            onChanged: (v) => _service
                                .seekTo(Duration(milliseconds: v.toInt())),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_fmt(pos),
                                  style: const TextStyle(
                                      color: Colors.white38, fontSize: 11)),
                              Text(_fmt(dur),
                                  style: const TextStyle(
                                      color: Colors.white38, fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),

            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ctrlBtn(Icons.skip_previous_rounded, 36,
                    () => _service.skipPrevious()),
                ValueListenableBuilder<bool>(
                  valueListenable: _service.isPlaying,
                  builder: (_, playing, __) => GestureDetector(
                    onTap: () => _service.playPause(),
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF9B59B6), Color(0xFF3498DB)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purpleAccent.withValues(alpha: 0.5),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
                ),
                _ctrlBtn(
                    Icons.skip_next_rounded, 36, () => _service.skipNext()),
              ],
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildSongList() {
    return Expanded(
      child: ValueListenableBuilder<List<SongModel>>(
        valueListenable: _service.songList,
        builder: (_, songs, __) {
          if (songs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.music_off_rounded,
                      color: Colors.white24, size: 48),
                  const SizedBox(height: 16),
                  Text('No music found on device',
                      style: GoogleFonts.outfit(
                          color: Colors.white38, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text('Add some music files to your device',
                      style: GoogleFonts.outfit(
                          color: Colors.white24, fontSize: 12)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: songs.length,
            itemBuilder: (context, i) {
              final song = songs[i];
              return ValueListenableBuilder<SongModel?>(
                valueListenable: _service.currentSong,
                builder: (_, current, __) {
                  final isActive = current?.id == song.id;
                  return ListTile(
                    onTap: () {
                      _service.playSongAt(i);
                      setState(() => _showList = false);
                    },
                    leading: SizedBox(
                      width: 48,
                      height: 48,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: QueryArtworkWidget(
                          id: song.id,
                          type: ArtworkType.AUDIO,
                          nullArtworkWidget: Container(
                            color: Colors.white10,
                            child: const Icon(Icons.music_note_rounded,
                                color: Colors.white30, size: 24),
                          ),
                          artworkFit: BoxFit.cover,
                        ),
                      ),
                    ),
                    title: Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        color: isActive ? Colors.purpleAccent : Colors.white,
                        fontSize: 13,
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      song.artist ?? 'Unknown',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                          color: Colors.white38, fontSize: 11),
                    ),
                    trailing: isActive
                        ? ValueListenableBuilder<bool>(
                            valueListenable: _service.isPlaying,
                            builder: (_, playing, __) => Icon(
                              playing
                                  ? Icons.equalizer_rounded
                                  : Icons.pause_rounded,
                              color: Colors.purpleAccent,
                              size: 20,
                            ),
                          )
                        : null,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _defaultArtwork() {
    return Container(
      width: 220,
      height: 220,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
          colors: [
            Color(0xFF9B59B6),
            Color(0xFF3498DB),
            Color(0xFF1abc9c),
            Color(0xFF9B59B6)
          ],
        ),
      ),
      child:
          const Icon(Icons.music_note_rounded, color: Colors.white30, size: 80),
    );
  }

  Widget _ctrlBtn(IconData icon, double size, VoidCallback onTap) {
    return IconButton(
      icon: Icon(icon, color: Colors.white70, size: size),
      onPressed: onTap,
    );
  }
}

/// Compact mini-player bar — shown at the bottom of the chat when music is playing.
class MiniMusicPlayer extends StatelessWidget {
  final VoidCallback onTap;
  const MiniMusicPlayer({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final service = MusicPlayerService();
    return ValueListenableBuilder<bool>(
      valueListenable: service.isMiniPlayerVisible,
      builder: (_, isVisible, __) {
        if (!isVisible) return const SizedBox.shrink();

        return ValueListenableBuilder<SongModel?>(
          valueListenable: service.currentSong,
          builder: (_, song, __) {
            if (song == null) return const SizedBox.shrink();

            return ValueListenableBuilder<bool>(
              valueListenable: service.isMiniPlayerMinimized,
              builder: (_, isMinimized, __) {
                if (isMinimized) {
                  return Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: service.toggleMinimize,
                      child: Container(
                        margin: const EdgeInsets.only(right: 12, bottom: 6),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D1B69),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.purpleAccent.withValues(alpha: 0.5),
                              width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purpleAccent.withValues(alpha: 0.4),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.music_note_rounded,
                            color: Colors.white, size: 24),
                      ),
                    ),
                  );
                }

                return Dismissible(
                  key: const Key('mini_music_player_dismiss'),
                  direction: DismissDirection.horizontal,
                  onDismissed: (_) => service.hideMiniPlayer(),
                  child: GestureDetector(
                    onTap: onTap,
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2D1B69), Color(0xFF11113B)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.purpleAccent.withValues(alpha: 0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purpleAccent.withValues(alpha: 0.2),
                            blurRadius: 12,
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          // Artwork
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 40,
                              height: 40,
                              child: QueryArtworkWidget(
                                id: song.id,
                                type: ArtworkType.AUDIO,
                                nullArtworkWidget: Container(
                                  color: const Color(0xFF9B59B6),
                                  child: const Icon(Icons.music_note_rounded,
                                      color: Colors.white54, size: 20),
                                ),
                                artworkFit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Title + Artist
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  song.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  song.artist ?? 'Unknown',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Controls
                          ValueListenableBuilder<bool>(
                            valueListenable: service.isPlaying,
                            builder: (_, playing, __) {
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                        Icons.skip_previous_rounded,
                                        color: Colors.white70,
                                        size: 20),
                                    onPressed: service.skipPrevious,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: Icon(
                                      playing
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      color: Colors.purpleAccent,
                                      size: 26,
                                    ),
                                    onPressed: service.playPause,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(Icons.skip_next_rounded,
                                        color: Colors.white70, size: 20),
                                    onPressed: service.skipNext,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: Colors.white54,
                                        size: 24),
                                    onPressed: service.toggleMinimize,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
