import 'dart:async';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../widgets/app_cached_image.dart';
import '../models/anime_models.dart';
import '../services/anime_service.dart';
import '../services/watchlist_service.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/anime_visual_effects.dart';
import '../services/streak_service.dart';
import '../services/episode_alert_service.dart';
import '../services/download_service.dart';
import '../services/dynamic_theme_service.dart';
import '../widgets/premium_animations.dart';
import 'anime_player_page.dart';
import 'character_database_page.dart';

/// Main Anime browsing page — 4 servers, search, trending, visual effects.
class AnimeSectionPage extends StatefulWidget {
  const AnimeSectionPage({super.key});
  @override
  State<AnimeSectionPage> createState() => _AnimeSectionPageState();
}

class _AnimeSectionPageState extends State<AnimeSectionPage>
    with TickerProviderStateMixin {
  List<AnimeItem> _items = [];
  List<AnimeItem> _searchResults = [];
  bool _loading = true;
  bool _loadingSearch = false;
  String _searchQuery = '';
  Timer? _debounce;

  // Daily recommendation
  AnimeItem? _dailyPick;

  // Server colors
  static const Map<AnimeSource, Color> _sourceColors = {
    AnimeSource.amvstrm: Colors.blueAccent,
    AnimeSource.anilist: Colors.deepPurple,
    AnimeSource.jikanPopular: Colors.amber,
  };

  final ScrollController _gridScrollCtrl = ScrollController();
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _gridScrollCtrl.addListener(() {
      if (mounted) setState(() => _scrollOffset = _gridScrollCtrl.offset);
    });
    _loadContent();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _gridScrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadContent() async {
    setState(() { _loading = true; });
    final results = await AnimeService.getTrending(limit: 24);
    // Pick a random "daily recommendation" from results
    if (results.isNotEmpty) {
      _dailyPick = results[Random().nextInt(min(results.length, 6))];
    }
    if (mounted) setState(() { _items = results; _loading = false; });
  }

  void _switchSource(AnimeSource source) {
    AnimeService.currentSource = source;
    _searchQuery = '';
    _searchResults = [];
    _dailyPick = null;
    _loadContent();
  }

  void _onSearchChanged(String val) {
    _debounce?.cancel();
    _searchQuery = val;
    if (val.trim().isEmpty) {
      setState(() { _searchResults = []; _loadingSearch = false; });
      return;
    }
    setState(() => _loadingSearch = true);
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final results = await AnimeService.searchAnime(val.trim(), limit: 24);
      if (mounted) setState(() { _searchResults = results; _loadingSearch = false; });
    });
  }

  void _openAnimeDetail(AnimeItem anime) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => _AnimeDetailPage(anime: anime),
    ));
  }

  Future<void> _toggleFavorite(AnimeItem anime) async {
    final isFav = await WatchlistService.isAnimeFavorited(anime.id);
    if (isFav) {
      await WatchlistService.removeAnime(anime.id);
    } else {
      await WatchlistService.addAnime(WatchlistItem(
        id: anime.id, title: anime.title,
        coverUrl: anime.coverUrl, type: 'anime',
      ));
    }
    setState(() {}); // Refresh UI
  }

  @override
  Widget build(BuildContext context) {
    final isSearching = _searchQuery.trim().isNotEmpty;
    final displayItems = isSearching ? _searchResults : _items;
    final isLoading = isSearching ? _loadingSearch : _loading;
    final accent = _sourceColors[AnimeService.currentSource] ?? Colors.deepPurple;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // ✨ Star particle overlay
          const ParticleOverlay(
            particleCount: 8,
            emoji: '✨',
          ),

          Column(
            children: [
              // ── Server Selector Tabs with animated transitions ──
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  children: AnimeSource.values.map((source) {
                    final isActive = AnimeService.currentSource == source;
                    final color = _sourceColors[source] ?? Colors.deepPurple;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => _switchSource(source),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: isActive
                                ? color.withValues(alpha: 0.3)
                                : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isActive ? color : Colors.transparent,
                              width: 1.5,
                            ),
                            boxShadow: isActive ? [
                              BoxShadow(color: color.withValues(alpha: 0.3),
                                  blurRadius: 8, spreadRadius: -2),
                            ] : null,
                          ),
                          child: Center(child: Text(
                            AnimeService.sourceDisplayName(source),
                            style: TextStyle(
                              color: isActive ? Colors.white : Colors.grey.shade500,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                              fontSize: 12,
                            ),
                          )),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // ── Search Bar ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: TextField(
                  onChanged: _onSearchChanged,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search anime...',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    prefixIcon: Icon(Icons.search, color: accent),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.08),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),

              // ── Daily Recommendation Banner ──
              if (_dailyPick != null && !isSearching && !isLoading)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                  child: GestureDetector(
                    onTap: () => _openAnimeDetail(_dailyPick!),
                    child: GlassContainer(
                      opacity: 0.1,
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: _dailyPick!.coverUrl.isNotEmpty
                              ? AppCachedImage(url: _dailyPick!.coverUrl, width: 50, height: 70)
                              : const SizedBox(width: 50, height: 70),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Icon(Icons.auto_awesome, color: accent, size: 14),
                                const SizedBox(width: 4),
                                Text('Pick of the Day',
                                  style: TextStyle(color: accent,
                                      fontWeight: FontWeight.bold, fontSize: 11)),
                              ]),
                              const SizedBox(height: 4),
                              Text(_dailyPick!.title,
                                style: const TextStyle(color: Colors.white,
                                    fontWeight: FontWeight.w700, fontSize: 14),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                              if (_dailyPick!.score > 0)
                                Row(children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 12),
                                  const SizedBox(width: 2),
                                  Text('${_dailyPick!.score}',
                                    style: const TextStyle(color: Colors.amber,
                                        fontSize: 11, fontWeight: FontWeight.bold)),
                                ]),
                            ],
                          )),
                          Icon(Icons.arrow_forward_ios, color: accent, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),

              // ── Section Title ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    isSearching ? 'Search Results' : '🔥 Trending Now',
                    style: TextStyle(color: Colors.grey.shade300,
                        fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),

              // ── Grid with Shimmer Loading + 3D Tilt + Parallax + Pull-to-Refresh ──
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    final slide = Tween<Offset>(
                      begin: const Offset(0.05, 0), end: Offset.zero,
                    ).animate(animation);
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(position: slide, child: child),
                    );
                  },
                  child: isLoading
                    ? const ShimmerLoading(
                        key: ValueKey('shimmer'),
                        itemCount: 12, crossAxisCount: 3)
                    : displayItems.isEmpty
                      ? Center(
                          key: const ValueKey('empty'),
                          child: Text(
                            isSearching ? 'No results found' : 'No anime available',
                            style: TextStyle(color: Colors.grey.shade600)))
                      : RefreshIndicator(
                          key: ValueKey('grid_${AnimeService.currentSource.name}'),
                          onRefresh: _loadContent,
                          color: accent,
                          backgroundColor: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.95),
                          displacement: 60,
                          strokeWidth: 3,
                          child: GridView.builder(
                            controller: _gridScrollCtrl,
                            physics: const BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics()),
                            padding: const EdgeInsets.all(12),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 0.52,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            itemCount: displayItems.length,
                            itemBuilder: (_, i) {
                              // Parallax: shift cover based on scroll position
                              final parallaxShift = (_scrollOffset * 0.02) - (i * 3.0);
                              return TiltCard(
                                child: _AnimeTile(
                                  anime: displayItems[i],
                                  onTap: () => _openAnimeDetail(displayItems[i]),
                                  onFavorite: () => _toggleFavorite(displayItems[i]),
                                  accentColor: accent,
                                  parallaxOffset: parallaxShift.clamp(-15.0, 15.0),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ──────────────────────── Anime Tile with Swipe-to-Favorite ────────────────────

class _AnimeTile extends StatelessWidget {
  final AnimeItem anime;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final Color accentColor;
  final double parallaxOffset;
  const _AnimeTile({required this.anime, required this.onTap,
      required this.onFavorite, this.accentColor = Colors.deepPurple,
      this.parallaxOffset = 0.0});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('anime_${anime.id}'),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (_) async {
        onFavorite();
        return false;
      },
      background: Container(
        decoration: BoxDecoration(
          color: Colors.pinkAccent.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 16),
        child: const Icon(Icons.favorite, color: Colors.pinkAccent, size: 28),
      ),
      child: GestureDetector(
        onTap: onTap,
        onDoubleTap: onFavorite,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Cover image with parallax shift
                    Transform.translate(
                      offset: Offset(0, parallaxOffset),
                      child: anime.coverUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: anime.coverUrl, fit: BoxFit.cover,
                            memCacheWidth: 200,
                            placeholder: (_, __) => Container(color: Colors.grey.shade900),
                            errorWidget: (_, __, ___) => Container(
                              color: Colors.grey.shade900,
                              child: const Icon(Icons.broken_image, color: Colors.grey)))
                        : Container(color: Colors.grey.shade900,
                            child: const Icon(Icons.movie, color: Colors.grey)),
                    ),
                    // Score badge
                    if (anime.score > 0)
                      Positioned(
                        top: 4, right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.star, color: Colors.amber, size: 12),
                            const SizedBox(width: 2),
                            Text('${anime.score}',
                              style: const TextStyle(color: Colors.white, fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                          ]),
                        ),
                      ),
                    // Episode count
                    if (anime.totalEpisodes > 0)
                      Positioned(
                        bottom: 4, left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('${anime.totalEpisodes} ep',
                            style: const TextStyle(color: Colors.white, fontSize: 10,
                                fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(anime.title,
              maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 11,
                  fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────── Anime Detail Page with Glassmorphic Header ──────────

class _AnimeDetailPage extends StatefulWidget {
  final AnimeItem anime;
  const _AnimeDetailPage({required this.anime});
  @override
  State<_AnimeDetailPage> createState() => _AnimeDetailPageState();
}

class _AnimeDetailPageState extends State<_AnimeDetailPage> {
  List<AnimeEpisode> _episodes = [];
  bool _loading = true;
  bool _isFavorited = false;
  bool _isFollowed = false;
  String? _gogoSlug;
  ColorPalette _palette = ColorPalette.fallback();

  @override
  void initState() {
    super.initState();
    _loadEpisodes();
    _checkFavorite();
    _checkFollow();
    _extractColors();
  }

  Future<void> _extractColors() async {
    if (widget.anime.coverUrl.isNotEmpty) {
      final p = await DynamicThemeService.extractColors(widget.anime.coverUrl);
      if (mounted) setState(() => _palette = p);
    }
  }

  Future<void> _checkFavorite() async {
    _isFavorited = await WatchlistService.isAnimeFavorited(widget.anime.id);
    if (mounted) setState(() {});
  }

  Future<void> _toggleFavorite() async {
    if (_isFavorited) {
      await WatchlistService.removeAnime(widget.anime.id);
    } else {
      await WatchlistService.addAnime(WatchlistItem(
        id: widget.anime.id, title: widget.anime.title,
        coverUrl: widget.anime.coverUrl, type: 'anime',
      ));
    }
    _isFavorited = !_isFavorited;
    if (mounted) setState(() {});
    // Show heart burst animation on favorite
    if (_isFavorited && mounted) {
      HeartBurstOverlay.show(context);
    }
  }

  Future<void> _checkFollow() async {
    final malId = int.tryParse(widget.anime.id);
    if (malId == null) return;
    _isFollowed = await EpisodeAlertService.isFollowed(malId);
    if (mounted) setState(() {});
  }

  Future<void> _toggleFollow() async {
    final malId = int.tryParse(widget.anime.id);
    if (malId == null) return;
    if (_isFollowed) {
      await EpisodeAlertService.unfollowAnime(malId);
    } else {
      await EpisodeAlertService.followAnime(FollowedAnime(
        malId: malId,
        title: widget.anime.title,
        coverUrl: widget.anime.coverUrl,
        lastKnownEpisode: widget.anime.totalEpisodes,
      ));
    }
    _isFollowed = !_isFollowed;
    if (mounted) setState(() {});
  }

  void _showDownloadOptions() {
    if (_episodes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No episodes available to download'),
            backgroundColor: Colors.red),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _DownloadSheet(
        anime: widget.anime,
        episodes: _episodes,
      ),
    );
  }

  Future<void> _loadEpisodes() async {
    setState(() => _loading = true);
    _gogoSlug = await AnimeService.getGogoSlug(widget.anime.title);
    List<AnimeEpisode> eps = [];
    if (_gogoSlug != null) eps = await AnimeService.getGogoEpisodes(_gogoSlug!);
    if (eps.isEmpty) eps = await AnimeService.getEpisodes(widget.anime.id);
    _episodes = eps;
    if (mounted) setState(() => _loading = false);
  }

  void _playEpisode(AnimeEpisode ep) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => AnimePlayerPage(
        animeTitle: widget.anime.title,
        episode: ep,
        animeId: widget.anime.id,
        animeCoverUrl: widget.anime.coverUrl,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.anime;
    final accent = _palette.dominant;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Glassmorphic Hero Header ──
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: accent.withValues(alpha: 0.8),
            actions: [
              // ❤️ Favorite button
              IconButton(
                icon: Icon(
                  _isFavorited ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorited ? Colors.pinkAccent : Colors.white,
                ),
                onPressed: _toggleFavorite,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (a.coverUrl.isNotEmpty)
                    AppCachedImage(url: a.coverUrl, width: double.infinity, height: double.infinity, fit: BoxFit.cover),
                  // Glassmorphic gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.3),
                          Colors.black.withValues(alpha: 0.95),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                  // Info overlay with glass effect
                  Positioned(
                    bottom: 12, left: 12, right: 12,
                    child: GlassContainer(
                      opacity: 0.12,
                      blur: 20,
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(a.title, style: const TextStyle(
                            color: Colors.white, fontSize: 18,
                            fontWeight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          Row(children: [
                            if (a.score > 0) ...[
                              const Icon(Icons.star, color: Colors.amber, size: 14),
                              const SizedBox(width: 3),
                              Text('${a.score}', style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(width: 10),
                            ],
                            Text(a.status, style: TextStyle(
                                color: accent, fontSize: 12, fontWeight: FontWeight.w600)),
                            if (a.totalEpisodes > 0) ...[
                              const SizedBox(width: 10),
                              Text('${a.totalEpisodes} ep',
                                style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                            ],
                          ]),
                          if (a.genres.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(spacing: 6, runSpacing: 4,
                              children: a.genres.take(5).map((g) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(g, style: const TextStyle(
                                    color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                              )).toList()),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Synopsis ──
          if (a.description.isNotEmpty)
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(a.description,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 13, height: 1.5),
                maxLines: 6, overflow: TextOverflow.ellipsis),
            )),

          // ── Action Buttons (Characters + Streak) ──
          SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(children: [
                Expanded(child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => CharacterDatabasePage(
                      animeId: a.id, animeTitle: a.title))),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.deepOrange.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people, color: Colors.deepOrange, size: 18),
                        SizedBox(width: 6),
                        Text('Characters', style: TextStyle(
                          color: Colors.deepOrange, fontWeight: FontWeight.w700, fontSize: 13)),
                      ],
                    ),
                  ),
                )),
                const SizedBox(width: 10),
                FutureBuilder<StreakInfo>(
                  future: StreakService.getStreak(),
                  builder: (_, snap) {
                    final streak = snap.data?.current ?? 0;
                    final badge = StreakService.streakBadge(streak);
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                      ),
                      child: Row(children: [
                        Text(badge, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 4),
                        Text('$streak day streak',
                          style: const TextStyle(color: Colors.amber,
                            fontWeight: FontWeight.w700, fontSize: 12)),
                      ]),
                    );
                  },
                ),
              ]),
            )),

          // ── Follow + Download Buttons ──
          SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(children: [
                // Follow for episode alerts
                Expanded(child: GestureDetector(
                  onTap: _toggleFollow,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _isFollowed
                          ? Colors.green.withValues(alpha: 0.2)
                          : Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _isFollowed
                          ? Colors.green.withValues(alpha: 0.4)
                          : Colors.blue.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isFollowed ? Icons.notifications_active : Icons.notifications_none,
                          color: _isFollowed ? Colors.green : Colors.blue, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          _isFollowed ? 'Following' : 'Follow',
                          style: TextStyle(
                            color: _isFollowed ? Colors.green : Colors.blue,
                            fontWeight: FontWeight.w700, fontSize: 13)),
                      ],
                    ),
                  ),
                )),
                const SizedBox(width: 10),
                // Download button
                Expanded(child: GestureDetector(
                  onTap: () => _showDownloadOptions(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.download, color: Colors.green, size: 18),
                        SizedBox(width: 6),
                        Text('Download', style: TextStyle(
                          color: Colors.green, fontWeight: FontWeight.w700, fontSize: 13)),
                      ],
                    ),
                  ),
                )),
              ]),
            )),

          // ── Episodes ──
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text('Episodes',
              style: TextStyle(color: Colors.grey.shade200,
                  fontWeight: FontWeight.w700, fontSize: 18)),
          )),

          if (_loading)
            const SliverToBoxAdapter(child: Center(child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: Colors.deepPurple),
            )))
          else if (_episodes.isEmpty)
            SliverToBoxAdapter(child: Center(child: Padding(
              padding: const EdgeInsets.all(40),
              child: Text('No episodes found.\nStreaming sources may be unavailable.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600)),
            )))
          else
            SliverList(delegate: SliverChildBuilderDelegate(
              (context, index) {
                final ep = _episodes[index];
                return ListTile(
                  leading: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10)),
                    child: Center(child: Text('${ep.number}',
                      style: const TextStyle(color: Colors.white,
                          fontWeight: FontWeight.bold))),
                  ),
                  title: Text(ep.title,
                    style: const TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: ep.isFiller
                      ? const Text('Filler', style: TextStyle(color: Colors.orange, fontSize: 11))
                      : null,
                  trailing: Icon(Icons.play_circle_fill, color: accent, size: 32),
                  onTap: () => _playEpisode(ep),
                );
              },
              childCount: _episodes.length,
            )),
        ],
      ),
    );
  }
}

// ──────────────────────── Download Sheet (real API) ──────────────────────────

class _DownloadSheet extends StatefulWidget {
  final AnimeItem anime;
  final List<AnimeEpisode> episodes;
  const _DownloadSheet({required this.anime, required this.episodes});
  @override
  State<_DownloadSheet> createState() => _DownloadSheetState();
}

class _DownloadSheetState extends State<_DownloadSheet> {
  final Map<String, _DlStatus> _status = {};

  Future<void> _downloadEp(AnimeEpisode ep) async {
    final key = ep.id;
    if (_status[key] == _DlStatus.downloading || _status[key] == _DlStatus.done) return;
    setState(() => _status[key] = _DlStatus.downloading);

    try {
      // Fetch the actual streaming URL for this episode
      final sources = await AnimeService.getVideoSources(ep.id);
      if (sources.isEmpty) {
        if (mounted) setState(() => _status[key] = _DlStatus.error);
        return;
      }

      // Pick best quality source
      String streamUrl = sources.first.url;
      for (final s in sources) {
        if (s.quality.contains('1080') || s.quality.contains('720')) {
          streamUrl = s.url;
          break;
        }
      }

      final result = await DownloadService.downloadAnimeEpisode(
        animeId: widget.anime.id,
        episodeId: ep.id,
        title: '${widget.anime.title} - Ep ${ep.number}',
        coverUrl: widget.anime.coverUrl,
        streamUrl: streamUrl,
        onProgress: (p) {
          // Could update progress UI here
        },
      );

      if (mounted) setState(() {
        _status[key] = result != null ? _DlStatus.done : _DlStatus.error;
      });
    } catch (_) {
      if (mounted) setState(() => _status[key] = _DlStatus.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade700,
              borderRadius: BorderRadius.circular(2)),
          ),
          Text('Download Episodes',
            style: TextStyle(color: Colors.grey.shade200,
                fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 4),
          Text('${widget.anime.title}',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 12),
          Expanded(child: ListView.builder(
            itemCount: widget.episodes.length,
            itemBuilder: (_, i) {
              final ep = widget.episodes[i];
              final st = _status[ep.id] ?? _DlStatus.idle;
              return ListTile(
                dense: true,
                leading: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8)),
                  child: Center(child: Text('${ep.number}',
                    style: const TextStyle(color: Colors.white,
                        fontWeight: FontWeight.bold, fontSize: 13))),
                ),
                title: Text(ep.title,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: _dlIcon(st),
                onTap: st == _DlStatus.idle || st == _DlStatus.error
                    ? () => _downloadEp(ep) : null,
              );
            },
          )),
        ],
      ),
    );
  }

  Widget _dlIcon(_DlStatus st) {
    switch (st) {
      case _DlStatus.idle:
        return const Icon(Icons.download, color: Colors.green, size: 22);
      case _DlStatus.downloading:
        return const SizedBox(width: 20, height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green));
      case _DlStatus.done:
        return const Icon(Icons.check_circle, color: Colors.green, size: 22);
      case _DlStatus.error:
        return const Icon(Icons.error, color: Colors.red, size: 22);
    }
  }
}

enum _DlStatus { idle, downloading, done, error }
