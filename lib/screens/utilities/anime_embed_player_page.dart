import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:anime_waifu/core/v2_upgrade_kit.dart';

class AnimeEmbedPlayerPage extends StatefulWidget {
  const AnimeEmbedPlayerPage({
    super.key,
    required this.animeTitle,
    required this.malId,
    required this.episodeNumber,
    this.subOrDub = 'sub',
  });

  final String animeTitle;
  final String malId;
  final int episodeNumber;
  final String subOrDub;

  @override
  State<AnimeEmbedPlayerPage> createState() => _AnimeEmbedPlayerPageState();
}

class _AnimeEmbedPlayerPageState extends State<AnimeEmbedPlayerPage> {
  final List<String> _embedHosts = <String>[
    'https://api.cinetaro.buzz/anime',
    'https://cinetaro.buzz/anime',
  ];

  InAppWebViewController? _wvc;
  bool _loading = true;
  String _subOrDub = 'sub';
  int _hostIndex = 0;

  String get _embedUrl {
    final String base = _embedHosts[_hostIndex];
    return '$base/${widget.malId}/${widget.episodeNumber}/1/$_subOrDub';
  }

  String get _commentaryMood {
    if (!_loading && _hostIndex == 0) {
      return 'achievement';
    }
    if (!_loading) {
      return 'motivated';
    }
    return 'neutral';
  }

  @override
  void initState() {
    super.initState();
    _subOrDub = widget.subOrDub;
    SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _tryNextHost() {
    if (_hostIndex >= _embedHosts.length - 1) {
      return;
    }
    setState(() {
      _hostIndex++;
      _loading = true;
    });
    _wvc?.loadUrl(urlRequest: URLRequest(url: WebUri(_embedUrl)));
  }

  void _toggleSubDub() {
    HapticFeedback.selectionClick();
    setState(() {
      _subOrDub = _subOrDub == 'sub' ? 'dub' : 'sub';
      _loading = true;
    });
    _wvc?.loadUrl(urlRequest: URLRequest(url: WebUri(_embedUrl)));
  }

  void _reload() {
    HapticFeedback.lightImpact();
    setState(() => _loading = true);
    _wvc?.reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(_embedUrl)),
            initialSettings: InAppWebViewSettings(
              mediaPlaybackRequiresUserGesture: false,
              allowsInlineMediaPlayback: true,
              useHybridComposition: true,
              javaScriptEnabled: true,
              domStorageEnabled: true,
              databaseEnabled: true,
              mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
              hardwareAcceleration: true,
              userAgent:
                  'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko)',
            ),
            onWebViewCreated: (InAppWebViewController controller) {
              _wvc = controller;
            },
            onLoadStart: (_, __) {
              if (mounted) {
                setState(() => _loading = true);
              }
            },
            onLoadStop: (_, __) {
              if (mounted) {
                setState(() => _loading = false);
              }
            },
            onReceivedError: (_, __, ___) {
              _tryNextHost();
            },
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: GlassCard(
                  margin: EdgeInsets.zero,
                  glow: true,
                  child: Row(
                    children: <Widget>[
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white70,
                          size: 18,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              widget.animeTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Episode ${widget.episodeNumber} • ${_subOrDub.toUpperCase()} • Host ${_hostIndex + 1}/${_embedHosts.length}',
                              style: GoogleFonts.outfit(
                                color: Colors.white60,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton(
                        onPressed: _toggleSubDub,
                        style: FilledButton.styleFrom(
                          backgroundColor:
                              V2Theme.primaryColor.withValues(alpha: 0.18),
                          foregroundColor: V2Theme.primaryColor,
                        ),
                        child: Text(_subOrDub.toUpperCase()),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _reload,
                        icon: const Icon(
                          Icons.refresh_rounded,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_loading)
            Container(
              color: Colors.black.withValues(alpha: 0.84),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const CircularProgressIndicator(
                      color: V2Theme.primaryColor,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Loading player...',
                      style: GoogleFonts.outfit(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: 260,
                child: Opacity(
                  opacity: 0.92,
                  child: WaifuCommentary(mood: _commentaryMood),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}



