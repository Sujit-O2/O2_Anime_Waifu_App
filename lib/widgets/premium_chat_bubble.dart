import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:anime_waifu/config/app_themes.dart';
import 'package:anime_waifu/models/chat_message.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

/// ═══════════════════════════════════════════════════════════════════════════
/// PREMIUM CHAT BUBBLE — Smooth animations, perfect alignment, polished look
/// ═══════════════════════════════════════════════════════════════════════════

class PremiumChatBubble extends StatefulWidget {
  final ChatMessage message;
  final bool showTimestamp;
  final double fontSize;
  final VoidCallback? onLongPress;
  final VoidCallback? onReact;
  final bool isSelected;
  /// Pass true only for freshly inserted messages. Old messages skip the
  /// animation entirely, saving one AnimationController per historical bubble.
  final bool isNew;

  const PremiumChatBubble({
    super.key,
    required this.message,
    this.showTimestamp = false,
    this.fontSize = 14,
    this.onLongPress,
    this.onReact,
    this.isSelected = false,
    this.isNew = false,
  });

  @override
  State<PremiumChatBubble> createState() => _PremiumChatBubbleState();
}

class _PremiumChatBubbleState extends State<PremiumChatBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _scaleAnim = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic),
    );
    if (widget.isNew) {
      _animCtrl.forward();
    } else {
      // Old message — skip animation, jump straight to final state
      _animCtrl.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.appTokens;
    final isUser = widget.message.role == 'user';

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              isUser ? 60 : 10,
              4,
              isUser ? 10 : 60,
              4,
            ),
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onLongPress: widget.onLongPress,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    decoration: BoxDecoration(
                      gradient: isUser
                          ? const LinearGradient(
                              colors: [
                                Color(0xFFFF4081),
                                Color(0xFFC2185B),
                                Color(0xFF7C4DFF),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              stops: [0.0, 0.5, 1.0],
                            )
                          : LinearGradient(
                              colors: [
                                tokens.panelElevated,
                                tokens.panel,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(22),
                        topRight: const Radius.circular(22),
                        bottomLeft: Radius.circular(isUser ? 22 : 6),
                        bottomRight: Radius.circular(isUser ? 6 : 22),
                      ),
                      border: widget.isSelected
                          ? Border.all(
                              color: theme.colorScheme.primary, width: 2.5)
                          : isUser
                              ? null
                              : Border(
                                  left: BorderSide(
                                    color: theme.colorScheme.primary
                                        .withValues(alpha: 0.6),
                                    width: 3.5,
                                  ),
                                  top: BorderSide(
                                      color: tokens.outline, width: 0.5),
                                  right: BorderSide(
                                      color: tokens.outline, width: 0.5),
                                  bottom: BorderSide(
                                      color: tokens.outline, width: 0.5),
                                ),
                      boxShadow: [
                        BoxShadow(
                          color: isUser
                              ? const Color(0xFFFF4081)
                                  .withValues(alpha: 0.3)
                              : theme.colorScheme.primary
                                  .withValues(alpha: 0.1),
                          blurRadius: isUser ? 18 : 12,
                          offset: const Offset(0, 4),
                          spreadRadius: isUser ? -2 : -3,
                        ),
                        if (!isUser)
                          BoxShadow(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.06),
                            blurRadius: 24,
                            offset: const Offset(-2, 0),
                            spreadRadius: 0,
                          ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(22),
                        topRight: const Radius.circular(22),
                        bottomLeft: Radius.circular(isUser ? 22 : 6),
                        bottomRight: Radius.circular(isUser ? 6 : 22),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (widget.message.imageUrl != null ||
                                    widget.message.imagePath != null)
                                  _buildImage(context),
                                if (widget.message.audioUrl != null)
                                  _InlineAudioPlayer(url: widget.message.audioUrl!),
                                if (widget.message.videoUrl != null)
                                  _InlineVideoPlayer(url: widget.message.videoUrl!),
                                if (widget.message.content.isNotEmpty)
                                  SelectableText(
                                    widget.message.content,
                                    style: GoogleFonts.outfit(
                                      color: isUser
                                          ? Colors.white
                                          : theme.colorScheme.onSurface,
                                      fontSize: widget.fontSize,
                                      fontWeight: FontWeight.w500,
                                      height: 1.6,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (widget.message.reaction != null)
                            Container(
                              margin: const EdgeInsets.only(
                                left: 14,
                                right: 14,
                                bottom: 10,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isUser
                                    ? Colors.white.withValues(alpha: 0.2)
                                    : theme.colorScheme.primary
                                        .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isUser
                                      ? Colors.white.withValues(alpha: 0.3)
                                      : theme.colorScheme.primary
                                          .withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                widget.message.reaction!,
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (widget.showTimestamp)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 6, right: 6),
                    child: Text(
                      _formatTimestamp(widget.message.timestamp),
                      style: GoogleFonts.outfit(
                        color: tokens.textSoft,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    final imageUrl = widget.message.imageUrl;
    final imagePath = widget.message.imagePath;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      constraints: const BoxConstraints(
        maxWidth: 280,
        maxHeight: 280,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: imageUrl != null
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 200,
                  color: Colors.grey[800],
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 200,
                  color: Colors.grey[800],
                  child: const Icon(Icons.error_outline, color: Colors.white54),
                ),
              )
            : imagePath != null
                ? Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 200,
                      color: Colors.grey[800],
                      child: const Icon(Icons.error_outline,
                          color: Colors.white54),
                    ),
                  )
                : const SizedBox.shrink(),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}

class PremiumTypingIndicator extends StatefulWidget {
  const PremiumTypingIndicator({super.key});

  @override
  State<PremiumTypingIndicator> createState() => _PremiumTypingIndicatorState();
}

class _PremiumTypingIndicatorState extends State<PremiumTypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTokens;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 60, 6),
      child: FadeTransition(
        opacity: CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                tokens.panelElevated,
                tokens.panel,
              ],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(22),
              topRight: Radius.circular(22),
              bottomLeft: Radius.circular(6),
              bottomRight: Radius.circular(22),
            ),
            border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
                width: 1.2),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (index) {
              return AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final delay = index * 0.25;
                  final value =
                      (_controller.value - delay).clamp(0.0, 1.0);
                  final animatedValue =
                      (value < 0.5 ? value * 2 : (1 - value) * 2);
                  final scale = 0.6 + animatedValue * 0.4;
                  final opacity = 0.3 + animatedValue * 0.7;

                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      margin: EdgeInsets.only(left: index > 0 ? 8 : 0),
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primary
                            .withValues(alpha: opacity),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary
                                .withValues(alpha: opacity * 0.4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ),
      ),
    );
  }
}

class QuickReplyChips extends StatefulWidget {
  final List<String> replies;
  final Function(String) onReplyTap;

  const QuickReplyChips({
    super.key,
    required this.replies,
    required this.onReplyTap,
  });

  @override
  State<QuickReplyChips> createState() => _QuickReplyChipsState();
}

class _QuickReplyChipsState extends State<QuickReplyChips>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400 + widget.replies.length * 60),
    );

    _slideAnimations = List.generate(
      widget.replies.length,
      (i) => Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            i * 0.1,
            0.6 + i * 0.1,
            curve: Curves.easeOutCubic,
          ),
        ),
      ),
    );

    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant QuickReplyChips oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.replies != oldWidget.replies) {
      _controller.reset();
      _slideAnimations = List.generate(
        widget.replies.length,
        (i) => Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(
              i * 0.1,
              0.6 + i * 0.1,
              curve: Curves.easeOutCubic,
            ),
          ),
        ),
      );
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.replies.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: widget.replies.asMap().entries.map((entry) {
          final index = entry.key;
          final reply = entry.value;

          return AnimatedBuilder(
            animation: _slideAnimations[index],
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, 10 * (1 - _slideAnimations[index].value)),
                child: Opacity(
                  opacity: _slideAnimations[index].value,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        widget.onReplyTap(reply);
                      },
                      borderRadius: BorderRadius.circular(20),
                      splashColor:
                          theme.colorScheme.primary.withValues(alpha: 0.2),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary.withValues(alpha: 0.18),
                              theme.colorScheme.primary.withValues(alpha: 0.06),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.35),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          reply,
                          style: GoogleFonts.outfit(
                            color: theme.colorScheme.onSurface,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Inline Audio Player — shown inside chat bubble when audioUrl is set
// ─────────────────────────────────────────────────────────────────────────────
class _InlineAudioPlayer extends StatefulWidget {
  final String url;
  const _InlineAudioPlayer({required this.url});

  @override
  State<_InlineAudioPlayer> createState() => _InlineAudioPlayerState();
}

class _InlineAudioPlayerState extends State<_InlineAudioPlayer> {
  final AudioPlayer _player = AudioPlayer();
  PlayerState _state = PlayerState.stopped;
  Duration _pos = Duration.zero;
  Duration _total = Duration.zero;
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
    _player.onPlayerStateChanged.listen((s) { if (mounted) setState(() => _state = s); });
    _player.onPositionChanged.listen((p) { if (mounted) setState(() => _pos = p); });
    _player.onDurationChanged.listen((d) { if (mounted) setState(() => _total = d); });
  }

  @override
  void dispose() { _player.dispose(); super.dispose(); }

  Source get _src => widget.url.startsWith('/')
      ? DeviceFileSource(widget.url)
      : UrlSource(widget.url);

  String _fmt(Duration d) =>
      '${d.inMinutes.remainder(60).toString().padLeft(2,'0')}:${d.inSeconds.remainder(60).toString().padLeft(2,'0')}';

  Future<void> _download() async {
    if (_downloading) return;
    setState(() => _downloading = true);
    try {
      final bytes = widget.url.startsWith('/')
          ? await File(widget.url).readAsBytes()
          : (await http.get(Uri.parse(widget.url))).bodyBytes;
      final dir = await getExternalStorageDirectory() ?? await getTemporaryDirectory();
      final file = File('${dir.path}/o2_music_${DateTime.now().millisecondsSinceEpoch}.mp3');
      await file.writeAsBytes(bytes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved to ${file.path}'), backgroundColor: Colors.green.shade700),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: $e'), backgroundColor: Colors.red.shade700),
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = _state == PlayerState.playing;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.purple.shade900, Colors.deepPurple.shade800]),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: [
        Row(children: [
          const Icon(Icons.music_note_rounded, color: Colors.amberAccent, size: 18),
          const SizedBox(width: 6),
          const Expanded(child: Text('Generated Music', style: TextStyle(color: Colors.white70, fontSize: 12))),
          IconButton(
            padding: EdgeInsets.zero, constraints: const BoxConstraints(),
            icon: _downloading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amberAccent))
                : const Icon(Icons.download_rounded, color: Colors.amberAccent, size: 20),
            onPressed: _download,
          ),
        ]),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
            activeTrackColor: Colors.amberAccent, inactiveTrackColor: Colors.white24,
            thumbColor: Colors.amberAccent, overlayShape: SliderComponentShape.noOverlay,
          ),
          child: Slider(
            value: _total.inSeconds > 0 ? _pos.inSeconds.toDouble().clamp(0, _total.inSeconds.toDouble()) : 0,
            max: _total.inSeconds > 0 ? _total.inSeconds.toDouble() : 1,
            onChanged: (v) => _player.seek(Duration(seconds: v.round())),
          ),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(_fmt(_pos), style: const TextStyle(color: Colors.white38, fontSize: 10)),
          IconButton(
            iconSize: 36, padding: EdgeInsets.zero, constraints: const BoxConstraints(),
            icon: Icon(isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                color: Colors.amberAccent),
            onPressed: () async {
              if (isPlaying) { await _player.pause(); }
              else { await _player.play(_src); }
            },
          ),
          Text(_fmt(_total), style: const TextStyle(color: Colors.white38, fontSize: 10)),
        ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Inline Video Player — shown inside chat bubble when videoUrl is set
// ─────────────────────────────────────────────────────────────────────────────
class _InlineVideoPlayer extends StatefulWidget {
  final String url;
  const _InlineVideoPlayer({required this.url});

  @override
  State<_InlineVideoPlayer> createState() => _InlineVideoPlayerState();
}

class _InlineVideoPlayerState extends State<_InlineVideoPlayer> {
  VideoPlayerController? _ctrl;
  bool _initialized = false;
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final ctrl = widget.url.startsWith('/')
        ? VideoPlayerController.file(File(widget.url))
        : VideoPlayerController.networkUrl(Uri.parse(widget.url));
    await ctrl.initialize();
    ctrl.setLooping(true);
    if (mounted) setState(() { _ctrl = ctrl; _initialized = true; });
  }

  @override
  void dispose() { _ctrl?.dispose(); super.dispose(); }

  Future<void> _download() async {
    if (_downloading) return;
    setState(() => _downloading = true);
    try {
      final bytes = widget.url.startsWith('/')
          ? await File(widget.url).readAsBytes()
          : (await http.get(Uri.parse(widget.url))).bodyBytes;
      final dir = await getExternalStorageDirectory() ?? await getTemporaryDirectory();
      final file = File('${dir.path}/o2_video_${DateTime.now().millisecondsSinceEpoch}.mp4');
      await file.writeAsBytes(bytes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved to ${file.path}'), backgroundColor: Colors.green.shade700),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: $e'), backgroundColor: Colors.red.shade700),
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: Colors.black),
      clipBehavior: Clip.hardEdge,
      child: Column(children: [
        if (!_initialized)
          const SizedBox(height: 120, child: Center(child: CircularProgressIndicator(color: Colors.deepPurpleAccent)))
        else
          AspectRatio(
            aspectRatio: _ctrl!.value.aspectRatio,
            child: VideoPlayer(_ctrl!),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(children: [
            const Icon(Icons.videocam_rounded, color: Colors.deepPurpleAccent, size: 16),
            const SizedBox(width: 4),
            const Expanded(child: Text('Generated Video', style: TextStyle(color: Colors.white54, fontSize: 11))),
            if (_initialized) IconButton(
              padding: EdgeInsets.zero, constraints: const BoxConstraints(),
              icon: Icon(
                _ctrl!.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.deepPurpleAccent, size: 22,
              ),
              onPressed: () => setState(() {
                _ctrl!.value.isPlaying ? _ctrl!.pause() : _ctrl!.play();
              }),
            ),
            IconButton(
              padding: EdgeInsets.zero, constraints: const BoxConstraints(),
              icon: _downloading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.deepPurpleAccent))
                  : const Icon(Icons.download_rounded, color: Colors.deepPurpleAccent, size: 20),
              onPressed: _download,
            ),
          ]),
        ),
      ]),
    );
  }
}
