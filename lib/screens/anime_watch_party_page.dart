import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Anime Watch Party — Sync video playback with friends + live chat.
class AnimeWatchPartyPage extends StatefulWidget {
  final String animeTitle;
  final String videoUrl;

  const AnimeWatchPartyPage({
    super.key,
    this.animeTitle = 'Watch Party',
    this.videoUrl = 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4', 
  });

  @override
  State<AnimeWatchPartyPage> createState() => _AnimeWatchPartyPageState();
}

class _AnimeWatchPartyPageState extends State<AnimeWatchPartyPage> {
  late VideoPlayerController _videoController;
  final TextEditingController _chatInput = TextEditingController();
  final TextEditingController _urlInput = TextEditingController();
  final List<Map<String, String>> _messages = [
    {'user': 'Alex', 'msg': 'This animation is insane!! 🔥'},
    {'user': 'Sara', 'msg': 'Ufotable carrying as usual'},
    {'user': 'Zoro', 'msg': 'Did I get lost again?'},
  ];

  bool _showControls = true;
  int _viewersCount = 4;
  late String _currentUrl;
  late String _currentTitle;

  @override
  void initState() {
    super.initState();
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
      }).catchError((e) {
        debugPrint('Watch Party video error: $e');
      });
  }

  void _changeVideo() {
    _urlInput.text = _currentUrl;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.95),
        title: const Text('Enter Video URL', style: TextStyle(color: Colors.white)),
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              final url = _urlInput.text.trim();
              if (url.isNotEmpty) {
                Navigator.pop(ctx);
                _videoController.dispose();
                setState(() => _currentUrl = url);
                _initVideo(url);
              }
            },
            child: const Text('Play', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _startMockSync() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 45));
      if (mounted) {
        setState(() {
          _messages.add({'user': 'Hinata', 'msg': 'Woah look at that!'});
        });
      }
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    _chatInput.dispose();
    _urlInput.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _chatInput.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add({'user': 'You', 'msg': text});
      _chatInput.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🎬 Watch Party', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white)),
            Text('Syncing with $_viewersCount viewers', style: const TextStyle(fontSize: 12, color: Colors.greenAccent)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.video_library, color: Colors.white),
            tooltip: 'Change Video',
            onPressed: _changeVideo,
          ),
          IconButton(
            icon: const Icon(Icons.people_alt, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Inviting friends...')));
            },
          )
        ],
      ),
      body: Column(
        children: [
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
                      children: [
                        AspectRatio(
                          aspectRatio: _videoController.value.aspectRatio,
                          child: VideoPlayer(_videoController),
                        ),
                        if (_showControls)
                          Container(
                            color: Colors.black45,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  iconSize: 48,
                                  color: Colors.white,
                                  icon: Icon(_videoController.value.isPlaying ? Icons.pause : Icons.play_arrow),
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
                            bottom: 10, left: 10, right: 10,
                            child: VideoProgressIndicator(_videoController, allowScrubbing: true, colors: const VideoProgressColors(playedColor: Colors.redAccent)),
                          ),
                      ],
                    )
                  : const Center(child: CircularProgressIndicator(color: Colors.redAccent)),
            ),
          ),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Theme.of(context).scaffoldBackgroundColor,
            width: double.infinity,
            child: Text(_currentTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),

          // Chat Section
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final m = _messages[index];
                final isMe = m['user'] == 'You';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isMe) CircleAvatar(radius: 14, backgroundColor: Colors.primaries[index % Colors.primaries.length], child: Text(m['user']![0])),
                      if (!isMe) const SizedBox(width: 8),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.redAccent.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                              bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                            ),
                            border: Border.all(color: isMe ? Colors.redAccent.withValues(alpha: 0.5) : Colors.transparent),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isMe) Text(m['user']!, style: TextStyle(color: Colors.grey.shade400, fontSize: 10, fontWeight: FontWeight.bold)),
                              if (!isMe) const SizedBox(height: 2),
                              Text(m['msg']!, style: const TextStyle(color: Colors.white, fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Input Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Row(
              children: [
                const Icon(Icons.emoji_emotions_outlined, color: Colors.grey),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _chatInput,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Say something in party chat...',
                      hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.redAccent),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
