import 'dart:async' show unawaited;
import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:anime_waifu/config/app_themes.dart';
import 'package:anime_waifu/services/anime_media/free_apis_service.dart';
import 'package:anime_waifu/services/user_profile/affection_service.dart';
import 'package:anime_waifu/widgets/app_cached_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anime_waifu/services/database_storage/app_db.dart';

class AnimeRecommenderPage extends StatefulWidget {
  const AnimeRecommenderPage({super.key});
  @override
  State<AnimeRecommenderPage> createState() => _AnimeRecommenderPageState();
}

class _AnimeRecommenderPageState extends State<AnimeRecommenderPage>
    with SingleTickerProviderStateMixin {
  static const String _modeKey = 'anime_recommender_mode_v2';
  static const String _queryKey = 'anime_recommender_query_v2';

  List<Map<String, dynamic>> _animeList = [];
  bool _loading = false;
  String _mode = 'Top Anime';
  final _searchCtrl = TextEditingController();
  late AnimationController _fadeCtrl;

  final _modes = ['Top Anime', 'Search', 'Romance', 'Action', 'Fantasy'];

  @override
  void initState() {
    super.initState();
    unawaited(AppDB.instance.recordUsage('anime_recommender'));
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _restoreState();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _restoreState() async {
    final prefs = await SharedPreferences.getInstance();
    _mode = prefs.getString(_modeKey) ?? 'Top Anime';
    _searchCtrl.text = prefs.getString(_queryKey) ?? '';
    if (mounted) {
      setState(() {});
    }
    await _load(_mode);
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, _mode);
    await prefs.setString(_queryKey, _searchCtrl.text.trim());
  }

  double get _averageScore {
    if (_animeList.isEmpty) {
      return 0;
    }
    final total = _animeList
        .map((anime) => (anime['score'] as double? ?? 0.0))
        .fold<double>(0, (sum, score) => sum + score);
    return _animeList.isEmpty ? 0 : total / _animeList.length;
  }

  Future<void> _load(String mode) async {
    setState(() {
      _loading = true;
      _animeList = [];
      _mode = mode;
    });
    await _saveState();
    _fadeCtrl.reset();
    try {
      List<Map<String, dynamic>> results;
      if (mode == 'Search') {
        final q = _searchCtrl.text.trim();
        results = q.isEmpty
            ? await FreeApisService.instance.getTopAnime()
            : await FreeApisService.instance.searchAnime(q);
      } else if (mode == 'Top Anime') {
        results = await FreeApisService.instance.getTopAnime(limit: 12);
      } else {
        final genre = mode == 'Romance'
            ? 'romance'
            : mode == 'Action'
                ? 'action'
                : 'fantasy';
        results = await FreeApisService.instance.searchAnime(genre, limit: 10);
      }
      if (mounted) {
        setState(() => _animeList = results);
        _fadeCtrl.forward();
        AffectionService.instance.addPoints(1);
      }
    } catch (_) {
      if (mounted) setState(() => _animeList = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    await _load(_mode);
  }

  Future<void> _activateSearchMode() async {
    setState(() => _mode = 'Search');
    await _saveState();
  }

  Widget _buildLoadingGrid() {
    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.62,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return GlassCard(
          margin: EdgeInsets.zero,
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 12,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 10,
                      width: 72,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
              ),
            ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.appTokens;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: tokens.textSoft, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.deepPurpleAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.recommend_rounded,
                  color: Colors.deepPurpleAccent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Anime Discovery',
                      style: GoogleFonts.outfit(
                          color: theme.colorScheme.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                  Text('Find your next favorite',
                      style: GoogleFonts.outfit(
                          color: tokens.textSoft,
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.deepPurpleAccent.withValues(alpha: 0.15),
                  Colors.deepPurpleAccent.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.deepPurpleAccent.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.api_rounded,
                    color: Colors.deepPurpleAccent, size: 14),
                const SizedBox(width: 6),
                Text('Jikan',
                    style: GoogleFonts.outfit(
                        color: Colors.deepPurpleAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.scaffoldBackgroundColor,
              theme.scaffoldBackgroundColor.withValues(alpha: 0.95),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                children: [
                  // Premium mode display card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.deepPurpleAccent.withValues(alpha: 0.08),
                          Colors.deepPurpleAccent.withValues(alpha: 0.04),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.deepPurpleAccent.withValues(alpha: 0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurpleAccent.withValues(alpha: 0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.explore_rounded,
                                      color: Colors.deepPurpleAccent, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    'DISCOVERY MODE',
                                    style: GoogleFonts.outfit(
                                      color: tokens.textSoft,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _mode,
                                style: GoogleFonts.outfit(
                                  color: theme.colorScheme.onSurface,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _mode == 'Search'
                                    ? 'Search by title or genre and refine your next binge.'
                                    : 'Switch lanes to browse top lists or themed recommendation drops.',
                                style: GoogleFonts.outfit(
                                  color: tokens.textSoft,
                                  fontSize: 14,
                                  height: 1.4,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Colors.deepPurpleAccent.withValues(alpha: 0.2),
                                Colors.deepPurpleAccent.withValues(alpha: 0.1),
                              ],
                            ),
                            border: Border.all(
                              color: Colors.deepPurpleAccent.withValues(alpha: 0.4),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.movie_filter_rounded,
                                color: Colors.deepPurpleAccent,
                                size: 24,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_animeList.length}',
                                style: GoogleFonts.outfit(
                                  color: theme.colorScheme.onSurface,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                'Anime',
                                style: GoogleFonts.outfit(
                                  color: tokens.textMuted,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Premium stats grid
                  Row(
                    children: [
                      _buildPremiumStatCard(
                        'Results',
                        '${_animeList.length}',
                        Icons.grid_view_rounded,
                        Colors.deepPurpleAccent,
                      ),
                      const SizedBox(width: 12),
                      _buildPremiumStatCard(
                        'Mode',
                        _mode == 'Top Anime' ? 'Top' : _mode,
                        Icons.tune_rounded,
                        Colors.cyanAccent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildPremiumStatCard(
                        'Avg Score',
                        _animeList.isEmpty
                            ? '--'
                            : _averageScore.toStringAsFixed(1),
                        Icons.star_rounded,
                        Colors.amberAccent,
                      ),
                      const SizedBox(width: 12),
                      _buildPremiumStatCard(
                        'Genres',
                        _mode == 'Search' ? 'Free' : 'Curated',
                        Icons.category_rounded,
                        Colors.lightGreenAccent,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Premium mode selector
            const SizedBox(height: 16),
            Text('DISCOVERY MODES',
                style: GoogleFonts.outfit(
                  color: tokens.textSoft,
                  fontSize: 12,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w800,
                )),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: _modes.map((m) {
                  final sel = m == _mode;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () =>
                            m == 'Search' ? _activateSearchMode() : _load(m),
                        splashColor: Colors.deepPurpleAccent.withValues(alpha: 0.1),
                        highlightColor: Colors.deepPurpleAccent.withValues(alpha: 0.05),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: sel
                                ? LinearGradient(
                                    colors: [
                                      Colors.deepPurpleAccent.withValues(alpha: 0.25),
                                      Colors.deepPurpleAccent.withValues(alpha: 0.15),
                                    ],
                                  )
                                : LinearGradient(
                                    colors: [
                                      tokens.panel.withValues(alpha: 0.8),
                                      tokens.panelElevated.withValues(alpha: 0.6),
                                    ],
                                  ),
                            border: Border.all(
                              color: sel
                                  ? Colors.deepPurpleAccent.withValues(alpha: 0.4)
                                  : tokens.outline,
                              width: sel ? 2 : 1,
                            ),
                            boxShadow: sel
                                ? [
                                    BoxShadow(
                                      color: Colors.deepPurpleAccent.withValues(alpha: 0.2),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(m.toUpperCase(),
                              style: GoogleFonts.outfit(
                                  color: sel
                                      ? Colors.white
                                      : theme.colorScheme.onSurface.withValues(alpha: 0.8),
                                  fontSize: 13,
                                  fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                                  letterSpacing: 0.5)),
                        ),
                      ),
                    ),
                  );
                }).toList(),
            ),
          ),

          const SizedBox(height: 10),

            // Anime grid
            Expanded(
              child: _loading
                  ? _buildLoadingGrid()
                  : _animeList.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                          children: [
                            EmptyState(
                              icon: Icons.search_off_rounded,
                              title: 'No anime found yet',
                              subtitle: _mode == 'Search'
                                  ? 'Try another title, genre, or switch back to the curated top list.'
                                  : 'Refresh the recommendations and I will fetch a fresh set for you.',
                              buttonText: 'Show Top Anime',
                              onButtonPressed: () {
                                _searchCtrl.clear();
                                _load('Top Anime');
                              },
                            ),
                          ],
                        )
                      : RefreshIndicator(
                          onRefresh: _refresh,
                          color: Colors.deepPurpleAccent,
                          child: FadeTransition(
                            opacity: _fadeCtrl,
                            child: GridView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.62,
                              ),
                              itemCount: _animeList.length,
                              itemBuilder: (ctx, i) => AnimatedEntry(
                                index: i,
                                child: _buildAnimeCard(_animeList[i]),
                              ),
                            ),
                          ),
                        ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildAnimeCard(Map<String, dynamic> anime) {
    final genres = (anime['genres'] as List<dynamic>? ?? []).take(2).join(', ');
    final score = (anime['score'] as double? ?? 0.0);
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _showDetail(anime);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withValues(alpha: 0.04),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Cover image
          Expanded(
            child: Stack(children: [
              anime['image'] != null && anime['image'].isNotEmpty
                  ? AppCachedImage(
                      url: anime['image'],
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover)
                  : Container(
                      color: Colors.deepPurpleAccent.withValues(alpha: 0.1),
                      child: const Center(
                          child: Text('??', style: TextStyle(fontSize: 40))),
                    ),
              if (score > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.star_rounded,
                          color: Colors.amberAccent, size: 12),
                      const SizedBox(width: 2),
                      Text(score.toStringAsFixed(1),
                          style: GoogleFonts.outfit(
                              color: Colors.amberAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),
            ]),
          ),
          // Info
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(anime['title'] ?? '',
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              if (genres.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(genres,
                    style: GoogleFonts.outfit(
                        color: Colors.deepPurpleAccent.withValues(alpha: 0.8),
                        fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
              if (anime['episodes'] != null && anime['episodes'] != '?') ...[
                const SizedBox(height: 2),
                Text('${anime['episodes']} eps',
                    style: GoogleFonts.outfit(
                        color: Colors.white38, fontSize: 10)),
              ],
            ]),
          ),
        ]),
      ),
    );
  }

  void _showDetail(Map<String, dynamic> anime) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        expand: false,
        builder: (_, ctrl) => SingleChildScrollView(
          controller: ctrl,
          padding: const EdgeInsets.all(20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (anime['image'] != null && anime['image'].isNotEmpty)
                ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AppCachedImage(
                        url: anime['image'], width: 90, height: 130)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(anime['title'] ?? '',
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      if ((anime['score'] as double? ?? 0) > 0)
                        Row(children: [
                          const Icon(Icons.star_rounded,
                              color: Colors.amberAccent, size: 16),
                          const SizedBox(width: 4),
                          Text((anime['score'] as double).toStringAsFixed(1),
                              style: GoogleFonts.outfit(
                                  color: Colors.amberAccent,
                                  fontWeight: FontWeight.w700)),
                        ]),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: (anime['genres'] as List<dynamic>? ?? [])
                            .take(4)
                            .map((g) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurpleAccent
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: Colors.deepPurpleAccent
                                            .withValues(alpha: 0.3)),
                                  ),
                                  child: Text(g.toString(),
                                      style: GoogleFonts.outfit(
                                          color: Colors.deepPurpleAccent,
                                          fontSize: 10)),
                                ))
                            .toList(),
                      ),
                    ]),
              ),
            ]),
            const SizedBox(height: 16),
            if (anime['synopsis'] != null && anime['synopsis'].isNotEmpty) ...[
              Text('SYNOPSIS',
                  style: GoogleFonts.outfit(
                      color: Colors.white54, fontSize: 11, letterSpacing: 1.5)),
              const SizedBox(height: 8),
              Text(anime['synopsis'],
                  style: GoogleFonts.outfit(
                      color: Colors.white70, fontSize: 13, height: 1.6),
                  maxLines: 8,
                  overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }

  Widget _buildPremiumStatCard(String title, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    final tokens = context.appTokens;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.outfit(
                color: theme.colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.outfit(
                color: tokens.textSoft,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }


}



