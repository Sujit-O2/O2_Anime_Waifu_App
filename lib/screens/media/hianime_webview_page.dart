import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:anime_waifu/core/v2_upgrade_kit.dart';

enum AnimeWebSource {
  hianime,
  animepahe,
  nineAnime,
  aniWatch,
  aniKai,
  aniZone,
  aniWorld,
  kickAssAnime,
  gogoAnime,
  zoroTv,
  yugenAnime,
  animeSuge,
  kaido,
  anix,
  animeFlix,
  marin,
  crunchyroll,
  wcostream,
  animotvslash,
  hanime,
  hentaiHaven,
  nhentai,
  rule34video,
  hentaiFox,
  hentaiMama,
  animeIdHentai,
  hentaiWorld,
}

class HiAnimeWebviewPage extends StatefulWidget {
  const HiAnimeWebviewPage({
    super.key,
    required this.source,
    this.animeTitle,
  });

  final AnimeWebSource source;
  final String? animeTitle;

  @override
  State<HiAnimeWebviewPage> createState() => _HiAnimeWebviewPageState();
}

class _HiAnimeWebviewPageState extends State<HiAnimeWebviewPage> {
  static const String _lastSourceKey = 'anime_webview_last_source_v2';
  static const String _lastQueryKey = 'anime_webview_last_query_v2';

  InAppWebViewController? _webViewController;
  double _progress = 0;
  bool _chromeVisible = true;
  String? _pageTitle;

  late final String _initialUrl;
  late final _WebSourceMeta _meta;

  @override
  void initState() {
    super.initState();
    _meta = _metaFor(widget.source);
    _initialUrl = _resolveInitialUrl(widget.source, widget.animeTitle);
    SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _saveSession();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  Future<void> _saveSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSourceKey, widget.source.name);
    if (widget.animeTitle != null && widget.animeTitle!.trim().isNotEmpty) {
      await prefs.setString(_lastQueryKey, widget.animeTitle!.trim());
    }
  }

  Future<void> _injectCleanAdblockJs() async {
    if (_webViewController == null) {
      return;
    }

    const jsInjection = '''
      var elementsToHide = document.querySelectorAll('#header, #footer, header, footer, .sidebar, .comments, .ad-banner, iframe[src*="ad="], .m-show-header, .top-header, .adsbygoogle, .content-ad, #ani-share, div[class*="ad-"], div[id*="ad-"]');
      elementsToHide.forEach(function(el) { el.style.display = 'none'; });
      document.body.style.paddingTop = '0px';
      var overlays = document.querySelectorAll('.server, .episode, a[target="_blank"]');
      overlays.forEach(function(el) { el.target = '_self'; });
    ''';

    try {
      await _webViewController!.evaluateJavascript(source: jsInjection);
    } catch (_) {}
  }

  Future<void> _goBackOrClose() async {
    if (_webViewController != null && await _webViewController!.canGoBack()) {
      await _webViewController!.goBack();
      return;
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _goHome() async {
    await _webViewController?.loadUrl(
      urlRequest: URLRequest(url: WebUri(_initialUrl)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final headline = widget.animeTitle?.trim().isNotEmpty == true
        ? '${_meta.title} • ${widget.animeTitle!.trim()}'
        : _meta.title;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) {
          return;
        }
        await _goBackOrClose();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: () => setState(() => _chromeVisible = !_chromeVisible),
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: InAppWebView(
                  initialUrlRequest: URLRequest(url: WebUri(_initialUrl)),
                  initialSettings: InAppWebViewSettings(
                    javaScriptEnabled: true,
                    domStorageEnabled: true,
                    databaseEnabled: true,
                    useHybridComposition: true,
                    mixedContentMode:
                        MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
                    mediaPlaybackRequiresUserGesture: false,
                    allowsInlineMediaPlayback: true,
                    useShouldOverrideUrlLoading: true,
                    supportMultipleWindows: true,
                    javaScriptCanOpenWindowsAutomatically: true,
                  ),
                  onWebViewCreated: (controller) =>
                      _webViewController = controller,
                  onLoadStart: (_, __) {
                    if (mounted) {
                      setState(() => _progress = 0);
                    }
                  },
                  onLoadStop: (_, __) async {
                    if (mounted) {
                      setState(() => _progress = 1);
                    }
                    await _injectCleanAdblockJs();
                    Future<void>.delayed(const Duration(seconds: 1), () {
                      if (mounted) {
                        _injectCleanAdblockJs();
                      }
                    });
                  },
                  onTitleChanged: (_, title) {
                    if (mounted) {
                      setState(() => _pageTitle = title);
                    }
                  },
                  onProgressChanged: (_, progress) {
                    if (mounted) {
                      setState(() => _progress = progress / 100);
                    }
                    if (progress > 50) {
                      _injectCleanAdblockJs();
                    }
                  },
                  shouldOverrideUrlLoading: (_, navigationAction) async {
                    final url = navigationAction.request.url;
                    if (url == null) {
                      return NavigationActionPolicy.ALLOW;
                    }
                    final scheme = url.scheme.toLowerCase();
                    final urlString = url.toString().toLowerCase();
                    const allowedSchemes = <String>[
                      'http',
                      'https',
                      'blob',
                      'data',
                      'ws',
                      'wss',
                      'file',
                    ];

                    if (!allowedSchemes.contains(scheme)) {
                      return NavigationActionPolicy.CANCEL;
                    }
                    if (urlString.contains('/ad/') ||
                        urlString.contains('popunder') ||
                        (urlString.contains('click') &&
                            urlString.contains('track'))) {
                      return NavigationActionPolicy.CANCEL;
                    }
                    return NavigationActionPolicy.ALLOW;
                  },
                  onReceivedServerTrustAuthRequest: (_, __) async {
                    return ServerTrustAuthResponse(
                      action: ServerTrustAuthResponseAction.PROCEED,
                    );
                  },
                  onCreateWindow: (controller, createWindowAction) async {
                    final popupUrl = createWindowAction.request.url;
                    if (popupUrl == null) {
                      return false;
                    }
                    final urlString = popupUrl.toString().toLowerCase();
                    if (urlString.contains('ad') ||
                        urlString.contains('track') ||
                        urlString.contains('bet') ||
                        urlString.contains('click')) {
                      return false;
                    }
                    controller.loadUrl(
                      urlRequest: URLRequest(url: popupUrl),
                    );
                    return true;
                  },
                ),
              ),
              if (_progress < 1)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    bottom: false,
                    child: LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation<Color>(_meta.accent),
                    ),
                  ),
                ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                top: _chromeVisible ? 0 : -180,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    child: DecoratedBox(
                      decoration: V2Theme.glassDecoration.copyWith(
                        borderRadius: BorderRadius.circular(24),
                        color: Colors.black.withValues(alpha: 0.52),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                IconButton(
                                  onPressed: _goBackOrClose,
                                  icon: const Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    color: Colors.white,
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        headline,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        _pageTitle?.trim().isNotEmpty == true
                                            ? _pageTitle!
                                            : _meta.subtitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.outfit(
                                          color: Colors.white60,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: <Widget>[
                                _infoChip(
                                  icon: Icons.shield_rounded,
                                  label: 'Cleaner shell',
                                  color: _meta.accent,
                                ),
                                const SizedBox(width: 8),
                                _infoChip(
                                  icon: _meta.isAdult
                                      ? Icons.lock_rounded
                                      : Icons.movie_filter_rounded,
                                  label: _meta.isAdult ? 'Adult' : 'Anime',
                                  color: _meta.isAdult
                                      ? Colors.orangeAccent
                                      : V2Theme.secondaryColor,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                bottom: _chromeVisible ? 0 : -120,
                left: 0,
                right: 0,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: DecoratedBox(
                      decoration: V2Theme.glassDecoration.copyWith(
                        borderRadius: BorderRadius.circular(24),
                        color: Colors.black.withValues(alpha: 0.52),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: _actionButton(
                                icon: Icons.arrow_back_rounded,
                                label: 'Back',
                                onTap: () async {
                                  if (_webViewController != null &&
                                      await _webViewController!.canGoBack()) {
                                    await _webViewController!.goBack();
                                  }
                                },
                              ),
                            ),
                            Expanded(
                              child: _actionButton(
                                icon: Icons.home_rounded,
                                label: 'Home',
                                onTap: _goHome,
                              ),
                            ),
                            Expanded(
                              child: _actionButton(
                                icon: Icons.refresh_rounded,
                                label: 'Reload',
                                onTap: () => _webViewController?.reload(),
                              ),
                            ),
                            Expanded(
                              child: _actionButton(
                                icon: Icons.visibility_rounded,
                                label: _chromeVisible ? 'Hide' : 'Show',
                                onTap: () => setState(
                                  () => _chromeVisible = !_chromeVisible,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white70, size: 18),
      label: Text(
        label,
        style: GoogleFonts.outfit(
          color: Colors.white70,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: TextButton.styleFrom(
        foregroundColor: Colors.white70,
      ),
    );
  }
}

class _WebSourceMeta {
  const _WebSourceMeta({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.isAdult,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final bool isAdult;
}

_WebSourceMeta _metaFor(AnimeWebSource source) {
  return switch (source) {
    AnimeWebSource.hianime => const _WebSourceMeta(
        title: 'HiAnime',
        subtitle: 'Anime search and streaming shell',
        accent: Colors.pinkAccent,
        isAdult: false,
      ),
    AnimeWebSource.animepahe => const _WebSourceMeta(
        title: 'AnimePahe',
        subtitle: 'Compressed anime streams',
        accent: Colors.lightBlueAccent,
        isAdult: false,
      ),
    AnimeWebSource.nineAnime => const _WebSourceMeta(
        title: '9AnimeTV',
        subtitle: 'Anime discovery shell',
        accent: Colors.purpleAccent,
        isAdult: false,
      ),
    AnimeWebSource.aniWatch => const _WebSourceMeta(
        title: 'AniWatchTV',
        subtitle: 'Anime browsing shell',
        accent: Colors.orangeAccent,
        isAdult: false,
      ),
    AnimeWebSource.aniKai => const _WebSourceMeta(
        title: 'AniKai',
        subtitle: 'Anime browsing shell',
        accent: Colors.tealAccent,
        isAdult: false,
      ),
    AnimeWebSource.aniZone => const _WebSourceMeta(
        title: 'AniZone',
        subtitle: 'Anime browsing shell',
        accent: Colors.cyanAccent,
        isAdult: false,
      ),
    AnimeWebSource.aniWorld => const _WebSourceMeta(
        title: 'AniWorld',
        subtitle: 'Anime browsing shell',
        accent: Colors.redAccent,
        isAdult: false,
      ),
    AnimeWebSource.kickAssAnime => const _WebSourceMeta(
        title: 'KickAssAnime',
        subtitle: 'Anime browsing shell',
        accent: Colors.greenAccent,
        isAdult: false,
      ),
    AnimeWebSource.gogoAnime => const _WebSourceMeta(
        title: 'GogoAnime',
        subtitle: 'Anime browsing shell',
        accent: Colors.yellowAccent,
        isAdult: false,
      ),
    AnimeWebSource.zoroTv => const _WebSourceMeta(
        title: 'ZoroTV',
        subtitle: 'Anime browsing shell',
        accent: Colors.green,
        isAdult: false,
      ),
    AnimeWebSource.yugenAnime => const _WebSourceMeta(
        title: 'YugenAnime',
        subtitle: 'Anime browsing shell',
        accent: Colors.brown,
        isAdult: false,
      ),
    AnimeWebSource.animeSuge => const _WebSourceMeta(
        title: 'AnimeSuge',
        subtitle: 'Anime browsing shell',
        accent: Colors.blueAccent,
        isAdult: false,
      ),
    AnimeWebSource.kaido => const _WebSourceMeta(
        title: 'Kaido',
        subtitle: 'Anime browsing shell',
        accent: Colors.cyan,
        isAdult: false,
      ),
    AnimeWebSource.anix => const _WebSourceMeta(
        title: 'Anix',
        subtitle: 'Anime browsing shell',
        accent: Colors.deepPurpleAccent,
        isAdult: false,
      ),
    AnimeWebSource.animeFlix => const _WebSourceMeta(
        title: 'AnimeFlix',
        subtitle: 'Anime browsing shell',
        accent: Colors.red,
        isAdult: false,
      ),
    AnimeWebSource.marin => const _WebSourceMeta(
        title: 'Marin',
        subtitle: 'Anime browsing shell',
        accent: Colors.pink,
        isAdult: false,
      ),
    AnimeWebSource.crunchyroll => const _WebSourceMeta(
        title: 'Crunchyroll',
        subtitle: 'Official web client wrapper',
        accent: Colors.orange,
        isAdult: false,
      ),
    AnimeWebSource.wcostream => const _WebSourceMeta(
        title: 'WCOstream',
        subtitle: 'Anime and cartoon browsing shell',
        accent: Colors.lightGreenAccent,
        isAdult: false,
      ),
    AnimeWebSource.animotvslash => const _WebSourceMeta(
        title: 'AnimoTV Slash',
        subtitle: 'Fast anime streaming with clean UI',
        accent: Color(0xFF00E5FF),
        isAdult: false,
      ),
    AnimeWebSource.hanime => const _WebSourceMeta(
        title: 'Hanime',
        subtitle: 'Adult web source',
        accent: Colors.pinkAccent,
        isAdult: true,
      ),
    AnimeWebSource.hentaiHaven => const _WebSourceMeta(
        title: 'HentaiHaven',
        subtitle: 'Adult web source',
        accent: Colors.deepOrangeAccent,
        isAdult: true,
      ),
    AnimeWebSource.nhentai => const _WebSourceMeta(
        title: 'nHentai',
        subtitle: 'Adult web source',
        accent: Colors.redAccent,
        isAdult: true,
      ),
    AnimeWebSource.rule34video => const _WebSourceMeta(
        title: 'Rule34Video',
        subtitle: 'Adult web source',
        accent: Colors.greenAccent,
        isAdult: true,
      ),
    AnimeWebSource.hentaiFox => const _WebSourceMeta(
        title: 'HentaiFox',
        subtitle: 'Adult web source',
        accent: Colors.orangeAccent,
        isAdult: true,
      ),
    AnimeWebSource.hentaiMama => const _WebSourceMeta(
        title: 'HentaiMama',
        subtitle: 'Adult web source',
        accent: Colors.purpleAccent,
        isAdult: true,
      ),
    AnimeWebSource.animeIdHentai => const _WebSourceMeta(
        title: 'AnimeIdHentai',
        subtitle: 'Adult web source',
        accent: Colors.blueAccent,
        isAdult: true,
      ),
    AnimeWebSource.hentaiWorld => const _WebSourceMeta(
        title: 'HentaiWorld',
        subtitle: 'Adult web source',
        accent: Colors.indigoAccent,
        isAdult: true,
      ),
  };
}

String _resolveInitialUrl(AnimeWebSource source, String? animeTitle) {
  if (animeTitle != null && animeTitle.trim().isNotEmpty) {
    final query = Uri.encodeComponent(animeTitle.trim());
    return switch (source) {
      AnimeWebSource.hianime => 'https://hianime.to/search?keyword=$query',
      AnimeWebSource.animepahe => 'https://animepahe.ru/?q=$query',
      AnimeWebSource.nineAnime => 'https://9animetv.to/search?keyword=$query',
      AnimeWebSource.aniWatch => 'https://aniwatchtv.to/search?keyword=$query',
      AnimeWebSource.aniKai => 'https://anikai.to/search?keyword=$query',
      AnimeWebSource.aniZone => 'https://anizone.to/search?keyword=$query',
      AnimeWebSource.aniWorld => 'https://aniworld.to/search?q=$query',
      AnimeWebSource.kickAssAnime => 'https://kaa.lt/search?q=$query',
      AnimeWebSource.gogoAnime =>
        'https://gogoanime3.co/search.html?keyword=$query',
      AnimeWebSource.zoroTv => 'https://zorox.to/search?keyword=$query',
      AnimeWebSource.yugenAnime => 'https://yugenanime.tv/discover/?q=$query',
      AnimeWebSource.animeSuge => 'https://animesuge.to/filter?keyword=$query',
      AnimeWebSource.kaido => 'https://kaido.to/search?keyword=$query',
      AnimeWebSource.anix => 'https://anix.to/search?keyword=$query',
      AnimeWebSource.animeFlix => 'https://animeflix.live/search?q=$query',
      AnimeWebSource.marin => 'https://marin.moe/anime?search=$query',
      AnimeWebSource.crunchyroll =>
        'https://www.crunchyroll.com/search?q=$query',
      AnimeWebSource.wcostream => 'https://www.wcostream.tv/search',
      AnimeWebSource.animotvslash =>
        'https://animotvslash.org/?s=$query',
      AnimeWebSource.hanime => 'https://hanime.tv/search?q=$query',
      AnimeWebSource.hentaiHaven => 'https://hentaihaven.xxx/?s=$query',
      AnimeWebSource.nhentai => 'https://nhentai.net/search/?q=$query',
      AnimeWebSource.rule34video => 'https://rule34video.com/search/$query/',
      AnimeWebSource.hentaiFox => 'https://hentaifox.com/search/?q=$query',
      AnimeWebSource.hentaiMama => 'https://hentaimama.io/?s=$query',
      AnimeWebSource.animeIdHentai =>
        'https://animeidhentai.com/buscar/?q=$query',
      AnimeWebSource.hentaiWorld => 'https://hentaiworld.tv/search/?q=$query',
    };
  }

  return switch (source) {
    AnimeWebSource.hianime => 'https://hianime.to/home',
    AnimeWebSource.animepahe => 'https://animepahe.ru/',
    AnimeWebSource.nineAnime => 'https://9animetv.to/home',
    AnimeWebSource.aniWatch => 'https://aniwatchtv.to/home',
    AnimeWebSource.aniKai => 'https://anikai.to/',
    AnimeWebSource.aniZone => 'https://anizone.to/home',
    AnimeWebSource.aniWorld => 'https://aniworld.to/',
    AnimeWebSource.kickAssAnime => 'https://kaa.lt/',
    AnimeWebSource.gogoAnime => 'https://gogoanime3.co',
    AnimeWebSource.zoroTv => 'https://zorox.to/home',
    AnimeWebSource.yugenAnime => 'https://yugenanime.tv',
    AnimeWebSource.animeSuge => 'https://animesuge.to/home',
    AnimeWebSource.kaido => 'https://kaido.to/home',
    AnimeWebSource.anix => 'https://anix.to/home',
    AnimeWebSource.animeFlix => 'https://animeflix.live',
    AnimeWebSource.marin => 'https://marin.moe',
    AnimeWebSource.crunchyroll => 'https://www.crunchyroll.com',
    AnimeWebSource.wcostream => 'https://www.wcostream.tv',
    AnimeWebSource.animotvslash => 'https://animotvslash.org/',
    AnimeWebSource.hanime => 'https://hanime.tv',
    AnimeWebSource.hentaiHaven => 'https://hentaihaven.xxx/',
    AnimeWebSource.nhentai => 'https://nhentai.net',
    AnimeWebSource.rule34video => 'https://rule34video.com',
    AnimeWebSource.hentaiFox => 'https://hentaifox.com',
    AnimeWebSource.hentaiMama => 'https://hentaimama.io',
    AnimeWebSource.animeIdHentai => 'https://animeidhentai.com',
    AnimeWebSource.hentaiWorld => 'https://hentaiworld.tv',
  };
}



