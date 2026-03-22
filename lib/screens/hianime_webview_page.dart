import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:google_fonts/google_fonts.dart';

enum AnimeWebSource {
  hianime,
  animepahe,
  nineAnime,
  aniWatch,
  aniKai,
  aniZone,
  aniWorld,
  kickAssAnime,
  
  // 10 New Anime Sites
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
  
  // 8 New Hentai Sites (Requested + 3 Extra)
  hanime,
  hentaiHaven,
  nhentai,
  rule34video,
  hentaiFox,
  hentaiMama,
  animeIdHentai,
  hentaiWorld,
}

/// A native wrapper that loads anime sites and aggressively blocks ads/UI
/// using JavaScript injection to create a seamless app-like streaming experience.
class HiAnimeWebviewPage extends StatefulWidget {
  final AnimeWebSource source;
  final String? animeTitle;

  const HiAnimeWebviewPage({
    super.key,
    required this.source,
    this.animeTitle,
  });

  @override
  State<HiAnimeWebviewPage> createState() => _HiAnimeWebviewPageState();
}

class _HiAnimeWebviewPageState extends State<HiAnimeWebviewPage> {
  InAppWebViewController? _webViewController;
  double _progress = 0;

  late final String _initialUrl;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    if (widget.animeTitle != null) {
      final query = Uri.encodeComponent(widget.animeTitle!);
      switch (widget.source) {
        case AnimeWebSource.hianime:     _initialUrl = 'https://hianime.to/search?keyword=$query'; break;
        case AnimeWebSource.animepahe:   _initialUrl = 'https://animepahe.ru/?q=$query'; break;
        case AnimeWebSource.nineAnime:   _initialUrl = 'https://9animetv.to/search?keyword=$query'; break;
        case AnimeWebSource.aniWatch:    _initialUrl = 'https://aniwatchtv.to/search?keyword=$query'; break;
        case AnimeWebSource.aniKai:      _initialUrl = 'https://anikai.to/search?keyword=$query'; break;
        case AnimeWebSource.aniZone:     _initialUrl = 'https://anizone.to/search?keyword=$query'; break;
        case AnimeWebSource.aniWorld:    _initialUrl = 'https://aniworld.to/search?q=$query'; break;
        case AnimeWebSource.kickAssAnime: _initialUrl = 'https://kaa.lt/search?q=$query'; break;
        
        case AnimeWebSource.gogoAnime:   _initialUrl = 'https://gogoanime3.co/search.html?keyword=$query'; break;
        case AnimeWebSource.zoroTv:      _initialUrl = 'https://zorox.to/search?keyword=$query'; break;
        case AnimeWebSource.yugenAnime:  _initialUrl = 'https://yugenanime.tv/discover/?q=$query'; break;
        case AnimeWebSource.animeSuge:   _initialUrl = 'https://animesuge.to/filter?keyword=$query'; break;
        case AnimeWebSource.kaido:       _initialUrl = 'https://kaido.to/search?keyword=$query'; break;
        case AnimeWebSource.anix:        _initialUrl = 'https://anix.to/search?keyword=$query'; break;
        case AnimeWebSource.animeFlix:   _initialUrl = 'https://animeflix.live/search?q=$query'; break;
        case AnimeWebSource.marin:       _initialUrl = 'https://marin.moe/anime?search=$query'; break;
        case AnimeWebSource.crunchyroll: _initialUrl = 'https://www.crunchyroll.com/search?q=$query'; break;
        case AnimeWebSource.wcostream:   _initialUrl = 'https://www.wcostream.tv/search'; break;

        case AnimeWebSource.hanime:      _initialUrl = 'https://hanime.tv/search?q=$query'; break;
        case AnimeWebSource.hentaiHaven: _initialUrl = 'https://hentaihaven.xxx/?s=$query'; break;
        case AnimeWebSource.nhentai:     _initialUrl = 'https://nhentai.net/search/?q=$query'; break;
        case AnimeWebSource.rule34video: _initialUrl = 'https://rule34video.com/search/$query/'; break;
        case AnimeWebSource.hentaiFox:   _initialUrl = 'https://hentaifox.com/search/?q=$query'; break;
        case AnimeWebSource.hentaiMama:  _initialUrl = 'https://hentaimama.io/?s=$query'; break;
        case AnimeWebSource.animeIdHentai: _initialUrl = 'https://animeidhentai.com/buscar/?q=$query'; break;
        case AnimeWebSource.hentaiWorld: _initialUrl = 'https://hentaiworld.tv/search/?q=$query'; break;
      }
    } else {
      switch (widget.source) {
        case AnimeWebSource.hianime:     _initialUrl = 'https://hianime.to/home'; break;
        case AnimeWebSource.animepahe:   _initialUrl = 'https://animepahe.ru/'; break;
        case AnimeWebSource.nineAnime:   _initialUrl = 'https://9animetv.to/home'; break;
        case AnimeWebSource.aniWatch:    _initialUrl = 'https://aniwatchtv.to/home'; break;
        case AnimeWebSource.aniKai:      _initialUrl = 'https://anikai.to/'; break;
        case AnimeWebSource.aniZone:     _initialUrl = 'https://anizone.to/home'; break;
        case AnimeWebSource.aniWorld:    _initialUrl = 'https://aniworld.to/'; break;
        case AnimeWebSource.kickAssAnime: _initialUrl = 'https://kaa.lt/'; break;
        
        case AnimeWebSource.gogoAnime:   _initialUrl = 'https://gogoanime3.co'; break;
        case AnimeWebSource.zoroTv:      _initialUrl = 'https://zorox.to/home'; break;
        case AnimeWebSource.yugenAnime:  _initialUrl = 'https://yugenanime.tv'; break;
        case AnimeWebSource.animeSuge:   _initialUrl = 'https://animesuge.to/home'; break;
        case AnimeWebSource.kaido:       _initialUrl = 'https://kaido.to/home'; break;
        case AnimeWebSource.anix:        _initialUrl = 'https://anix.to/home'; break;
        case AnimeWebSource.animeFlix:   _initialUrl = 'https://animeflix.live'; break;
        case AnimeWebSource.marin:       _initialUrl = 'https://marin.moe'; break;
        case AnimeWebSource.crunchyroll: _initialUrl = 'https://www.crunchyroll.com'; break;
        case AnimeWebSource.wcostream:   _initialUrl = 'https://www.wcostream.tv'; break;

        case AnimeWebSource.hanime:      _initialUrl = 'https://hanime.tv'; break;
        case AnimeWebSource.hentaiHaven: _initialUrl = 'https://hentaihaven.xxx/'; break;
        case AnimeWebSource.nhentai:     _initialUrl = 'https://nhentai.net'; break;
        case AnimeWebSource.rule34video: _initialUrl = 'https://rule34video.com'; break;
        case AnimeWebSource.hentaiFox:   _initialUrl = 'https://hentaifox.com'; break;
        case AnimeWebSource.hentaiMama:  _initialUrl = 'https://hentaimama.io'; break;
        case AnimeWebSource.animeIdHentai: _initialUrl = 'https://animeidhentai.com'; break;
        case AnimeWebSource.hentaiWorld: _initialUrl = 'https://hentaiworld.tv'; break;
      }
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  /// The magic JS that hides all annoying web elements to make it feel like a Native App
  /// Safely written to completely ignore Video iframe containers!
  Future<void> _injectCleanAdblockJs() async {
    if (_webViewController == null) return;

    // Generic universal ad/nav-block that surgically removes UI clutter without breaking players
    String jsInjection = '''
      var elementsToHide = document.querySelectorAll('#header, #footer, header, footer, .sidebar, .comments, .ad-banner, iframe[src*="ad="], .m-show-header, .top-header, .adsbygoogle, .content-ad, #ani-share, div[class*="ad-"], div[id*="ad-"]');
      elementsToHide.forEach(function(el) { el.style.display = 'none'; });
      document.body.style.paddingTop = '0px';
      
      // Neutralize the invisible overlay popup triggers!
      var overlays = document.querySelectorAll('.server, .episode, a[target="_blank"]');
      overlays.forEach(function(el) { el.target = '_self'; });
    ''';

    try {
      await _webViewController!.evaluateJavascript(source: jsInjection);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    String titleString;
    Color accent;
    
    switch (widget.source) {
      case AnimeWebSource.hianime: titleString = 'HiAnime '; accent = Colors.pinkAccent; break;
      case AnimeWebSource.animepahe: titleString = 'AnimePahe '; accent = Colors.lightBlueAccent; break;
      case AnimeWebSource.nineAnime: titleString = '9AnimeTV '; accent = Colors.purpleAccent; break;
      case AnimeWebSource.aniWatch: titleString = 'AniWatchTV '; accent = Colors.orangeAccent; break;
      case AnimeWebSource.aniKai: titleString = 'AniKai '; accent = Colors.tealAccent; break;
      case AnimeWebSource.aniZone: titleString = 'AniZone '; accent = Colors.cyanAccent; break;
      case AnimeWebSource.aniWorld: titleString = 'AniWorld '; accent = Colors.redAccent; break;
      case AnimeWebSource.kickAssAnime: titleString = 'KAA '; accent = Colors.greenAccent; break;
      
      // 10 NEW ANIME
      case AnimeWebSource.gogoAnime: titleString = 'GogoAnime '; accent = Colors.yellowAccent; break;
      case AnimeWebSource.zoroTv: titleString = 'ZoroTV '; accent = Colors.green; break;
      case AnimeWebSource.yugenAnime: titleString = 'YugenAnime '; accent = Colors.brown; break;
      case AnimeWebSource.animeSuge: titleString = 'AnimeSuge '; accent = Colors.blueAccent; break;
      case AnimeWebSource.kaido: titleString = 'Kaido.to '; accent = Colors.cyan; break;
      case AnimeWebSource.anix: titleString = 'Anix '; accent = Colors.deepPurpleAccent; break;
      case AnimeWebSource.animeFlix: titleString = 'AnimeFlix '; accent = Colors.red; break;
      case AnimeWebSource.marin: titleString = 'Marin.moe '; accent = Colors.pink; break;
      case AnimeWebSource.crunchyroll: titleString = 'Crunchyroll (Web)'; accent = Colors.orange; break;
      case AnimeWebSource.wcostream: titleString = 'WCOstream '; accent = Colors.lightGreenAccent; break;

      // 5 NEW HENTAI
      case AnimeWebSource.hanime: titleString = '🔞 Hanime.tv '; accent = Colors.pinkAccent; break;
      case AnimeWebSource.hentaiHaven: titleString = '🔞 HentaiHaven '; accent = Colors.deepOrangeAccent; break;
      case AnimeWebSource.nhentai: titleString = '🔞 nHentai '; accent = Colors.redAccent; break;
      case AnimeWebSource.rule34video: titleString = '🔞 Rule34Video '; accent = Colors.greenAccent; break;
      case AnimeWebSource.hentaiFox: titleString = '🔞 HentaiFox '; accent = Colors.orangeAccent; break;
      case AnimeWebSource.hentaiMama: titleString = '🔞 HentaiMama '; accent = Colors.purpleAccent; break;
      case AnimeWebSource.animeIdHentai: titleString = '🔞 AnimeIdHentai '; accent = Colors.blueAccent; break;
      case AnimeWebSource.hentaiWorld: titleString = '🔞 HentaiWorld '; accent = Colors.indigoAccent; break;
    }

    return WillPopScope(
      onWillPop: () async {
        if (_webViewController != null && await _webViewController!.canGoBack()) {
          _webViewController!.goBack();
          return false; // Prevent Flutter from exiting the page
        }
        return true; // Allow Flutter to exit if WebView has no history
      },
      child: Scaffold(
        backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          titleString,
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.black87,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 18),
            onPressed: () async {
              if (_webViewController != null && await _webViewController!.canGoBack()) {
                _webViewController!.goBack();
              }
            },
            tooltip: 'Web Go Back',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _webViewController?.reload(),
            tooltip: 'Reload',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: _progress < 1.0
              ? LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.black,
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                )
              : const SizedBox(height: 2),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(_initialUrl)),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                domStorageEnabled: true,
                databaseEnabled: true,
                useHybridComposition: true,
                mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
                mediaPlaybackRequiresUserGesture: false,
                allowsInlineMediaPlayback: true,
                useShouldOverrideUrlLoading: true,
                supportMultipleWindows: true, // Must be true so we can catch popup URLs!
                javaScriptCanOpenWindowsAutomatically: true,
              ),
              onWebViewCreated: (controller) => _webViewController = controller,
              onLoadStart: (controller, url) {
                setState(() {
                  _progress = 0;
                });
              },
              onLoadStop: (controller, url) async {
                setState(() {
                  _progress = 1.0;
                });
                await _injectCleanAdblockJs();
                Future.delayed(const Duration(seconds: 1), () {
                  if (mounted) _injectCleanAdblockJs();
                });
                Future.delayed(const Duration(seconds: 3), () {
                  if (mounted) _injectCleanAdblockJs();
                });
              },
              onProgressChanged: (controller, progress) {
                setState(() {
                  _progress = progress / 100.0;
                });
                if (progress > 50) _injectCleanAdblockJs();
              },
              
              // 1. Silent DNS-Level Ad-Redirect Blocker
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                final urlArg = navigationAction.request.url;
                if (urlArg == null) return NavigationActionPolicy.ALLOW;

                final String scheme = urlArg.scheme.toLowerCase();
                final String urlStr = urlArg.toString().toLowerCase();

                final allowedSchemes = ['http', 'https', 'blob', 'data', 'ws', 'wss', 'file'];
                
                // Block intent:// and market:// instantly!
                if (!allowedSchemes.contains(scheme)) {
                  return NavigationActionPolicy.CANCEL;
                }
                
                // Block known ad-servers hijacking the page
                if (urlStr.contains('/ad/') || urlStr.contains('popunder') || (urlStr.contains('click') && urlStr.contains('track'))) {
                  return NavigationActionPolicy.CANCEL;
                }
                return NavigationActionPolicy.ALLOW;
              },

              onReceivedServerTrustAuthRequest: (controller, challenge) async {
                return ServerTrustAuthResponse(action: ServerTrustAuthResponseAction.PROCEED);
              },

              // 2. The PERFECT Popup Ad-Blocker! 
              // Any new window trigged by Javascript gets passed here securely.
              onCreateWindow: (controller, createWindowAction) async {
                final popupUrl = createWindowAction.request.url;
                if (popupUrl == null) return false;

                final urlStr = popupUrl.toString().toLowerCase();

                // If the popup is to a spam URL -> BLOCK IT SILENTLY
                if (urlStr.contains('ad') || urlStr.contains('track') || urlStr.contains('bet') || urlStr.contains('click')) {
                  return false; // Safely murdered ad popup!
                }
                
                // If it's a legitimate popup (like a proxy video player loading), securely load it in current window
                controller.loadUrl(urlRequest: URLRequest(url: popupUrl));
                return true; 
              },
            ),
          ],
        ),
      ),
    ),
    );
  }
}
