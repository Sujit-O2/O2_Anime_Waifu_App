import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

import 'package:anime_waifu/core/v2_upgrade_kit.dart';

/// Anime Watch Party — Sync video playback with friends + live chat.
class AnimeWatchPartyPage extends StatefulWidget {
  final String animeTitle;
  final String videoUrl;

  const AnimeWatchPartyPage({
    super.key,
    this.animeTitle = 'Watch Party',
    this.videoUrl =
        'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
  });

  @override
  State<AnimeWatchPartyPage> createState() => _AnimeWatchPartyPageState();
}

class _AnimeWatchPartyPageState extends State<AnimeWatchPartyPage>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _videoController;
  final TextEditingController _chatInput = TextEditingController();
  final TextEditingController _urlInput = TextEditingController();
  final List<Map<String, String>> _messages = <Map<String, String>>[
    <String, String>{'user': 'Alex', 'msg': 'This animation is insane!! 🔥'},
    <String, String>{'user': 'Sara', 'msg': 'Ufotable carrying as usual'},
    <String, String>{'user': 'Zoro', 'msg': 'Did I get lost again?'},
  ];

  bool _showControls = true;
  final int _viewersCount = 4;
  late String _currentUrl;
  late String _currentTitle;
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..forward();
    _currentUrl = widget.videoUrl;
    _currentTitle = widget.animeTitle;
    _initVideo(_currentUrl);
    _startMockSync();
  }

  void _initVideo(String url) {
    _videoController = VideoPlayerController.networkUrl(Uri.parse(url))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
          _videoController.play();
          _videoController.setLooping(true);
        }
      }).catchError((dynamic e) {
        debugPrint('Watch Party video error: $e');
      });
  }

  void _changeVideo() {
    _urlInput.text = _currentUrl;
    showDialog(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        backgroundColor: V2Theme.surfaceDark.withValues(alpha: 0.95),
        title: Text(
          'Enter Video URL',
          style: GoogleFonts.outfit(color: Colors.white),
        ),
        content: TextField(
          controller: _urlInput,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Paste MP4 video URL...',
            hintStyle: TextStyle(color: Colors.grey.shade600),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.08),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              final String url = _urlInput.text.trim();
              if (url.isNotEmpty) {
                Navigator.pop(ctx);
                _videoController.dispose();
                setState(() => _currentUrl = url);
                _initVideo(url);
              }
            },
            child: const Text('Play', style: TextStyle(color: V2Theme.primaryColor)),
          ),
        ],
      ),
    );
  }

  void _startMockSync() async {
    while (mounted) {
      await Future<void>.delayed(const Duration(seconds: 45));
      if (mounted) {
        setState(() {
          _messages.add(
              <String, String>{'user': 'Hinata', 'msg': 'Woah look at that!'});
        });
      }
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _videoController.dispose();
    _chatInput.dispose();
    _urlInput.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final String text = _chatInput.text.trim();
    if (text.isEmpty) {
      return;
    }
    setState(() {
      _messages.add(<String, String>{'user': 'You', 'msg': text});
      _chatInput.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: V2Theme.surfaceDark,
      body: WaifuBackground(
        opacity: 0.08,
        tint: V2Theme.surfaceDark,
        child: SafeArea(
          child: Column(
            children: <Widget>[
              // App Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: Row(
                  children: <Widget>[
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white70,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            '🎬 Watch Party',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Syncing with $_viewersCount viewers',
                            style: GoogleFonts.outfit(
                              color: Colors.greenAccent,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.video_library, color: Colors.white),
                      tooltip: 'Change Video',
                      onPressed: _changeVideo,
                    ),
                    IconButton(
                      icon: const Icon(Icons.people_alt, color: Colors.white),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Inviting friends...')),
                        );
                      },
                    )
                  ],
                ),
              ),

              // Video Player Section
              GestureDetector(
                onTap: () => setState(() => _showControls = !_showControls),
                child: Container(
                  width: double.infinity,
                  height: 250,
                  color: Colors.black,
                  child: _videoController.value.isInitialized
                      ? Stack(
                          alignment: Alignment.center,
                          children: <Widget>[
                            AspectRatio(
                              aspectRatio: _videoController.value.aspectRatio,
                              child: VideoPlayer(_videoController),
                            ),
                            if (_showControls)
                              Container(
                                color: Colors.black45,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    IconButton(
                                      iconSize: 48,
                                      color: Colors.white,
                                      icon: Icon(_videoController.value.isPlaying
                                          ? Icons.pause
                                          : Icons.play_arrow),
                                      onPressed: () {
                                        setState(() {
                                          _videoController.value.isPlaying
                                              ? _videoController.pause()
                                              : _videoController.play();
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            if (_showControls)
                              Positioned(
                                bottom: 10,
                                left: 10,
                                right: 10,
                                child: VideoProgressIndicator(
                                  _videoController,
                                  allowScrubbing: true,
                                  colors: const VideoProgressColors(
                                    playedColor: V2Theme.primaryColor,
                                  ),
                                ),
                              ),
                          ],
                        )
                      : const Center(
                          child: CircularProgressIndicator(
                            color: V2Theme.primaryColor,
                          ),
                        ),
                ),
              ),

              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                width: double.infinity,
                child: Text(
                  _currentTitle,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),

              // Chat Section
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _messages.length,
                  itemBuilder: (BuildContext context, int index) {
                    final Map<String, String> m = _messages[index];
                    final bool isMe = m['user'] == 'You';
                    return AnimatedEntry(
                      index: index,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: isMe
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            if (!isMe)
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: Colors
                                    .primaries[index % Colors.primaries.length],
                                child: Text(m['user']![0]),
                              ),
                            if (!isMe) const SizedBox(width: 8),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? V2Theme.primaryColor
                                          .withValues(alpha: 0.2)
                                      : Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: isMe
                                        ? const Radius.circular(16)
                                        : Radius.zero,
                                    bottomRight: isMe
                                        ? Radius.zero
                                        : const Radius.circular(16),
                                  ),
                                  border: Border.all(
                                    color: isMe
                                        ? V2Theme.primaryColor
                                            .withValues(alpha: 0.5)
                                        : Colors.white.withValues(alpha: 0.1),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    if (!isMe)
                                      Text(
                                        m['user']!,
                                        style: TextStyle(
                                          color: Colors.grey.shade400,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    if (!isMe) const SizedBox(height: 2),
                                    Text(
                                      m['msg']!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Input Section
              GlassCard(
                margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.emoji_emotions_outlined, color: Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _chatInput,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Say something in party chat...',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send_rounded,
                          color: V2Theme.primaryColor),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}




