import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:anime_waifu/services/anime_media/free_apis_service.dart';
import 'package:anime_waifu/services/user_profile/affection_service.dart';
import 'package:anime_waifu/widgets/app_cached_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    return total / _animeList.length;
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
    return Scaffold(
      backgroundColor: V2Theme.surfaceDark,
      body: WaifuBackground(
        opacity: 0.11,
        tint: const Color(0xFF07071A),
        child: SafeArea(
          child: Column(children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white60, size: 16),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('ANIME PICKS',
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.deepPurpleAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.deepPurpleAccent.withValues(alpha: 0.3)),
                  ),
                  child: Text('Jikan API',
                      style: GoogleFonts.outfit(
                          color: Colors.deepPurpleAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                children: [
                  GlassCard(
                    margin: EdgeInsets.zero,
                    padding: const EdgeInsets.all(18),
                    glow: true,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Discovery mode',
                                style: GoogleFonts.outfit(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _mode,
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _mode == 'Search'
                                    ? 'Search by title or genre and refine your next binge.'
                                    : 'Switch lanes to browse top lists or themed recommendation drops.',
                                style: GoogleFonts.outfit(
                                  color: Colors.white60,
                                  fontSize: 12,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        ProgressRing(
                          progress: (_animeList.length.clamp(0, 12)) / 12,
                          foreground: Colors.deepPurpleAccent,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.movie_filter_rounded,
                                color: Colors.deepPurpleAccent,
                                size: 28,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${_animeList.length}',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'Visible',
                                style: GoogleFonts.outfit(
                                  color: Colors.white54,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'Results',
                          value: '${_animeList.length}',
                          icon: Icons.grid_view_rounded,
                          color: Colors.deepPurpleAccent,
                        ),
                      ),
                      Expanded(
                        child: StatCard(
                          title: 'Mode',
                          value: _mode == 'Top Anime' ? 'Top' : _mode,
                          icon: Icons.tune_rounded,
                          color: Colors.cyanAccent,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'Avg Score',
                          value: _animeList.isEmpty
                              ? '--'
                              : _averageScore.toStringAsFixed(1),
                          icon: Icons.star_rounded,
                          color: Colors.amberAccent,
                        ),
                      ),
                      Expanded(
                        child: StatCard(
                          title: 'Genres',
                          value: _mode == 'Search' ? 'Free' : 'Curated',
                          icon: Icons.category_rounded,
                          color: Colors.lightGreenAccent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Mode chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: _modes.map((m) {
                  final sel = m == _mode;
                  return GestureDetector(
                    onTap: () =>
                        m == 'Search' ? _activateSearchMode() : _load(m),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: sel
                            ? Colors.deepPurpleAccent.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.04),
                        border: Border.all(
                            color:
                                sel ? Colors.deepPurpleAccent : Colors.white12),
                      ),
                      child: Text(m,
                          style: GoogleFonts.outfit(
                              color: sel
                                  ? Colors.deepPurpleAccent
                                  : Colors.white54,
                              fontSize: 12,
                              fontWeight:
                                  sel ? FontWeight.w700 : FontWeight.w500)),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Search bar (when Search mode)
            if (_mode == 'Search') ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.deepPurpleAccent.withValues(alpha: 0.3)),
                  ),
                  child: Row(children: [
                    const SizedBox(width: 12),
                    const Icon(Icons.search_rounded,
                        color: Colors.deepPurpleAccent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        style: GoogleFonts.outfit(
                            color: Colors.white, fontSize: 14),
                        cursorColor: Colors.deepPurpleAccent,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Search anime title or genre...',
                          hintStyle: GoogleFonts.outfit(
                              color: Colors.white30, fontSize: 13),
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onSubmitted: (_) => _load('Search'),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _load('Search'),
                      child: Container(
                        margin: const EdgeInsets.all(6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.deepPurpleAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('GO',
                            style: GoogleFonts.outfit(
                                color: Colors.deepPurpleAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ]),
                ),
              ),
            ],

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
}



