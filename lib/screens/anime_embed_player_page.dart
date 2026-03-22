import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// WebView-based anime player using the Cinetaro embed API.
/// URL format: https://api.cinetaro.buzz/anime/{malId}/{episode}/{season}/{sub|dub}
/// Falls back to AllAnime embed if Cinetaro fails.
class AnimeEmbedPlayerPage extends StatefulWidget {
  final String animeTitle;
  final String malId;
  final int episodeNumber;
  final String subOrDub; // 'sub' or 'dub'

  const AnimeEmbedPlayerPage({
    super.key,
    required this.animeTitle,
    required this.malId,
    required this.episodeNumber,
    this.subOrDub = 'sub',
  });

  @override
  State<AnimeEmbedPlayerPage> createState() => _AnimeEmbedPlayerPageState();
}

class _AnimeEmbedPlayerPageState extends State<AnimeEmbedPlayerPage> {
  InAppWebViewController? _wvc;
  bool _loading = true;
  String _subOrDub = 'sub';
  final List<String> _embedHosts = [
    'https://api.cinetaro.buzz/anime',
    'https://cinetaro.buzz/anime',
  ];
  int _hostIndex = 0;

  String get _embedUrl {
    final base = _embedHosts[_hostIndex];
    return '$base/${widget.malId}/${widget.episodeNumber}/1/$_subOrDub';
  }

  @override
  void initState() {
    super.initState();
    _subOrDub = widget.subOrDub;
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _tryNextHost() {
    if (_hostIndex < _embedHosts.length - 1) {
      setState(() {
        _hostIndex++;
        _loading = true;
      });
      _wvc?.loadUrl(urlRequest: URLRequest(url: WebUri(_embedUrl)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: Text(
          '${widget.animeTitle} — EP ${widget.episodeNumber}',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _subOrDub = _subOrDub == 'sub' ? 'dub' : 'sub';
                _loading = true;
              });
              _wvc?.loadUrl(urlRequest: URLRequest(url: WebUri(_embedUrl)));
            },
            child: Text(
              _subOrDub.toUpperCase(),
              style: const TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white54),
            onPressed: () {
              setState(() => _loading = true);
              _wvc?.reload();
            },
          ),
        ],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
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
              userAgent: 'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko)',
            ),
            onWebViewCreated: (controller) => _wvc = controller,
            onLoadStart: (controller, url) {
              setState(() => _loading = true);
            },
            onLoadStop: (controller, url) {
              setState(() => _loading = false);
            },
            onReceivedError: (controller, request, error) {
              _tryNextHost();
            },
          ),
          if (_loading)
            Container(
              color: Colors.black87,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.pinkAccent),
                    SizedBox(height: 16),
                    Text('Loading player...', style: TextStyle(color: Colors.white54)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
