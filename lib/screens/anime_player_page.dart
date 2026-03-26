import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../models/anime_models.dart';
import '../services/anime_service.dart';
import '../services/watch_history_service.dart';
import '../services/streak_service.dart';
import 'anime_embed_player_page.dart';
import 'hianime_webview_page.dart';

/// Full-screen anime video player with:
///  - Real sub/dub source switching via Consumet API
///  - Auto watch history recording
///  - Streak tracking on play
///  - Position saving for auto-resume
///  - Quality selector (1080p/720p/480p)
class AnimePlayerPage extends StatefulWidget {
  final String animeTitle;
  final AnimeEpisode episode;
  final String? animeId;       // MAL ID for watch history
  final String? animeCoverUrl; // Cover for history entry
  const AnimePlayerPage({
    super.key,
    required this.animeTitle,
    required this.episode,
    this.animeId,
    this.animeCoverUrl,
  });
  @override
  State<AnimePlayerPage> createState() => _AnimePlayerPageState();
}

class _AnimePlayerPageState extends State<AnimePlayerPage> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _loading = true;
  String? _error;
  List<AnimeVideoSource> _sources = [];
  int _currentSourceIndex = 0;
  String _subOrDub = 'sub';
  bool _debugMode = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _loadSources();
    // Record streak immediately when user opens player
    StreakService.recordActivity();
  }

  @override
  void dispose() {
    // Save current position for auto-resume before disposing
    _savePosition();
    _chewieController?.dispose();
    _videoController?.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  /// Save current playback position for auto-resume.
  Future<void> _savePosition() async {
    if (_videoController == null || widget.animeId == null) return;
    final pos = _videoController!.value.position;
    final dur = _videoController!.value.duration;
    if (dur.inMilliseconds <= 0) return;

    await WatchHistoryService.saveProgress(
      animeId: widget.animeId!,
      animeTitle: widget.animeTitle,
      animeCoverUrl: widget.animeCoverUrl ?? '',
      episodeId: widget.episode.id,
      episodeNumber: widget.episode.number,
      positionMs: pos.inMilliseconds,
      durationMs: dur.inMilliseconds,
    );
  }

  Future<void> _loadSources() async {
    setState(() { _loading = true; _error = null; });

    try {
      List<AnimeVideoSource> sources = [];

      if (_subOrDub == 'dub') {
        sources = await AnimeService.getVideoSourcesForType(widget.episode.id, 'dub');
      }

      if (sources.isEmpty) {
        sources = await AnimeService.getVideoSources(widget.episode.id);
      }

      // ── If no M3U8 sources found, always go to Cinetaro embed ──────────
      if (sources.isEmpty) {
        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (_) => AnimeEmbedPlayerPage(
            animeTitle:    widget.animeTitle,
            // Use MAL ID if available, otherwise use episode number as key
            malId:         widget.animeId ?? widget.episode.number.toString(),
            episodeNumber: widget.episode.number,
            subOrDub:      _subOrDub,
          ),
        ));
        return; // ← CRITICAL: must return here so we don't access empty list
      }

      // ── We have sources: init the native M3U8 player ───────────────────
      _sources = sources;
      _currentSourceIndex = 0;

      for (int i = 0; i < sources.length; i++) {
        if (sources[i].quality.contains('1080')) { _currentSourceIndex = i; break; }
        if (sources[i].quality.contains('720'))  _currentSourceIndex = i;
      }

      await _initPlayer(_sources[_currentSourceIndex]);
    } catch (e) {
      if (mounted) setState(() {
        _loading = false;
        _error = 'Failed to load video: $e';
      });
    }
  }

  Future<void> _initPlayer(AnimeVideoSource source) async {
    _chewieController?.dispose();
    _videoController?.dispose();

    final uri = Uri.parse(source.url);

    // Dynamic Header Injection to completely trick CDN bot protection
    final injectionHeaders = <String, String>{
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko)',
    };
    
    // Inherit precise rotation cookies and Referrers pulled dynamically from APIs (like Consumet)
    if (source.headers != null && source.headers!.isNotEmpty) {
      injectionHeaders.addAll(source.headers!);
    } else {
      // Fallback to domain origin spoofing
      injectionHeaders['Referer'] = '${uri.scheme}://${uri.host}/';
      injectionHeaders['Origin'] = '${uri.scheme}://${uri.host}/';
    }

    _videoController = VideoPlayerController.networkUrl(
      uri,
      httpHeaders: injectionHeaders,
    );

    try {
      await _videoController!.initialize();

      // Restore position for auto-resume
      if (widget.animeId != null) {
        final lastPos = await WatchHistoryService.getLastPosition(
            widget.animeId!, widget.episode.id);
        if (lastPos != null && lastPos > 0) {
          await _videoController!.seekTo(Duration(milliseconds: lastPos));
        }
      }

      final progressColor = _subOrDub == 'dub' ? Colors.orange : Colors.deepPurple;

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: progressColor,
          handleColor: progressColor.withValues(alpha: 0.6),
          backgroundColor: Colors.grey.shade800,
          bufferedColor: Colors.grey.shade600,
        ),
        placeholder: Container(color: Colors.black),
        errorBuilder: (context, errorMessage) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 40),
              const SizedBox(height: 8),
              Text(errorMessage,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadSources,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );

      // Inline 30s history recording
      bool historyRecorded = false;
      _videoController!.addListener(() {
        if (historyRecorded || widget.animeId == null) return;
        if ((_videoController?.value.position.inSeconds ?? 0) >= 30) {
          historyRecorded = true;
          _savePosition();
        }
      });

      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) setState(() {
        _loading = false;
        _error = 'Video connection blocked by your Internet Provider.\n\n'
                 'This happens frequently in India.\n'
                 'Please install "1.1.1.1" (WARP) or a free VPN from the Play Store, '
                 'turn it ON, and try playing again.\n\n'
                 'Technical error: $e';
      });
    }
  }

  void _switchQuality(int index) {
    if (index == _currentSourceIndex) return;
    _savePosition(); // Save position before switching
    _currentSourceIndex = index;
    setState(() => _loading = true);
    _initPlayer(_sources[index]);
  }

  void _toggleSubDub() {
    _savePosition(); // Save position before switching
    setState(() {
      _subOrDub = _subOrDub == 'sub' ? 'dub' : 'sub';
    });
    _loadSources();
  }

  /// Enter Picture-in-Picture mode via Android MethodChannel.
  Future<void> _enterPip() async {
    try {
      const channel = MethodChannel('com.animewaifu/pip');
      final supported = await channel.invokeMethod<bool>('enterPip') ?? false;
      if (!supported && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PiP not supported on this device'),
              backgroundColor: Colors.orange),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PiP not available'),
              backgroundColor: Colors.orange),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _subOrDub == 'dub' ? Colors.orange : Colors.deepPurple;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video player
          if (_chewieController != null && !_loading && _error == null)
            Center(child: Chewie(controller: _chewieController!)),

          // Loading indicator
          if (_loading)
            Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: accent),
                const SizedBox(height: 16),
                Text(
                  'Loading ${widget.animeTitle}\n'
                  'Episode ${widget.episode.number} '
                  '(${_subOrDub.toUpperCase()})...',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                ),
              ],
            )),

          // Error state
          if (_error != null && !_loading)
            Center(child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off, color: accent, size: 48),
                  const SizedBox(height: 16),
                  Text(_error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                  const SizedBox(height: 20),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    ElevatedButton.icon(
                      onPressed: _loadSources,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(backgroundColor: accent),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: _toggleSubDub,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: accent)),
                      child: Text(
                        'Try ${_subOrDub == 'sub' ? 'DUB' : 'SUB'}',
                        style: TextStyle(color: accent)),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  const Text('STILL FAILING? WATCH NATIVELY ON:', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _showWebviewSelector,
                    icon: const Icon(Icons.travel_explore),
                    label: const Text('Select Alternative Ad-Free Streamer'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.indigoAccent),
                  ),
                ],
              ),
            )),

          // Top bar
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      '${widget.animeTitle} — Ep ${widget.episode.number}',
                      style: const TextStyle(color: Colors.white, fontSize: 14,
                          fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.bug_report,
                        color: _debugMode ? Colors.redAccent : Colors.white38),
                    onPressed: () => setState(() => _debugMode = !_debugMode),
                  ),
                  // Sub/Dub toggle — real API switch
                  GestureDetector(
                    onTap: _toggleSubDub,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: accent.withValues(alpha: 0.5)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(
                          _subOrDub == 'sub' ? '🇯🇵' : '🇺🇸',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _subOrDub.toUpperCase(),
                          style: const TextStyle(color: Colors.white,
                              fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Web Streamers button
                  IconButton(
                    icon: const Icon(Icons.travel_explore, color: Colors.lightBlueAccent, size: 22),
                    onPressed: _showWebviewSelector,
                    tooltip: 'Watch Natively on Ad-Free Streamers',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                  const SizedBox(width: 4),
                  // PiP button
                  IconButton(
                    icon: const Icon(Icons.picture_in_picture_alt, color: Colors.white70, size: 20),
                    onPressed: _enterPip,
                    tooltip: 'Picture-in-Picture',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                  const SizedBox(width: 4),
                  // Quality selector
                  if (_sources.length > 1)
                    PopupMenuButton<int>(
                      icon: Icon(Icons.hd, color: accent),
                      color: Colors.grey.shade900,
                      onSelected: _switchQuality,
                      itemBuilder: (_) => _sources.asMap().entries.map((e) =>
                        PopupMenuItem(
                          value: e.key,
                          child: Row(children: [
                            if (e.key == _currentSourceIndex)
                              Icon(Icons.check, color: accent, size: 16)
                            else
                              const SizedBox(width: 16),
                            const SizedBox(width: 8),
                            Text(
                              e.value.quality,
                              style: TextStyle(
                                color: e.key == _currentSourceIndex
                                    ? accent : Colors.white,
                                fontWeight: e.key == _currentSourceIndex
                                    ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ]),
                        ),
                      ).toList(),
                    ),
                ]),
              ),
            ),
          ),

          // Debug Overlay
          if (_debugMode && _sources.isNotEmpty)
            Positioned(
              top: 70, left: 16, right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.redAccent),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('DEBUG MODE: NETWORK STREAM INFO',
                          style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 8),
                      Text('URL:\n${_sources[_currentSourceIndex].url}',
                          style: const TextStyle(color: Colors.cyanAccent, fontSize: 10, fontFamily: 'monospace')),
                      const SizedBox(height: 8),
                      Text('INJECTED HEADERS:\n${_videoController?.dataSource ?? "..."}',
                          style: const TextStyle(color: Colors.greenAccent, fontSize: 10, fontFamily: 'monospace')),
                      const SizedBox(height: 8),
                      Text('CONTROLLER STATUS:\n${_videoController?.value.hasError ?? false ? _videoController?.value.errorDescription : 'Initialized & Playing'}',
                          style: TextStyle(color: (_videoController?.value.hasError ?? false) ? Colors.red : Colors.greenAccent, fontSize: 10, fontFamily: 'monospace')),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showWebviewSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 20),
              const Text('SELECT AD-FREE STREAMER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 13)),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12, runSpacing: 12, alignment: WrapAlignment.center,
                children: [
                  _buildProviderBtn('HiAnime', AnimeWebSource.hianime, Colors.pinkAccent),
                  _buildProviderBtn('AnimePahe', AnimeWebSource.animepahe, Colors.lightBlueAccent),
                  _buildProviderBtn('9AnimeTV', AnimeWebSource.nineAnime, Colors.purpleAccent),
                  _buildProviderBtn('AniWatchTV', AnimeWebSource.aniWatch, Colors.orangeAccent),
                  _buildProviderBtn('AniKai', AnimeWebSource.aniKai, Colors.tealAccent),
                  _buildProviderBtn('AniZone', AnimeWebSource.aniZone, Colors.cyanAccent),
                  _buildProviderBtn('AniWorld', AnimeWebSource.aniWorld, Colors.redAccent),
                  _buildProviderBtn('KickAss', AnimeWebSource.kickAssAnime, Colors.greenAccent),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      }
    );
  }

  Widget _buildProviderBtn(String label, AnimeWebSource source, Color color) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.15),
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const Icon(Icons.play_circle_fill, size: 18),
      label: Text(label),
      onPressed: () {
        Navigator.pop(context);
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HiAnimeWebviewPage(source: source, animeTitle: widget.animeTitle)));
      },
    );
  }
}
