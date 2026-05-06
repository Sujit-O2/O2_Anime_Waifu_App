import 'dart:async' show unawaited;
import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:anime_waifu/services/anime_media/watchlist_service.dart';
import 'package:anime_waifu/widgets/app_cached_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anime_waifu/services/database_storage/app_db.dart';

/// Watchlist v2 — Tabbed anime/manga favorites with search, grid/list toggle,
/// animated cards, empty states, swipe-to-remove with undo, and stats overview.
class WatchlistPage extends StatefulWidget {
  const WatchlistPage({super.key});
  @override
  State<WatchlistPage> createState() => _WatchlistPageState();
}

class _WatchlistPageState extends State<WatchlistPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late TabController _tabCtrl;

  List<WatchlistItem> _anime = [];
  List<WatchlistItem> _manga = [];
  bool _loading = true;
  bool _gridView = true;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    unawaited(AppDB.instance.recordUsage('watchlist'));
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..forward();
    _tabCtrl = TabController(length: 2, vsync: this);
    _searchCtrl.addListener(
        () => setState(() => _searchQuery = _searchCtrl.text.toLowerCase()));
    _load();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    final a = await WatchlistService.getAnimeWatchlist();
    final m = await WatchlistService.getMangaWatchlist();
    if (mounted) {
      setState(() {
        _anime = a;
        _manga = m;
        _gridView = prefs.getBool('watchlist_grid_view_v2') ?? _gridView;
        _loading = false;
      });
    }
  }

  Future<void> _remove(WatchlistItem item) async {
    if (item.type == 'anime') {
      await WatchlistService.removeAnime(item.id);
    } else {
      await WatchlistService.removeManga(item.id);
    }
    _load();
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('watchlist_grid_view_v2', _gridView);
  }

  Future<void> _removeWithUndo(WatchlistItem item) async {
    await _remove(item);
    if (mounted) {
      showUndoSnackbar(context, '${item.title} removed', () async {
        if (item.type == 'anime') {
          await WatchlistService.addAnime(item);
        } else {
          await WatchlistService.addManga(item);
        }
        _load();
      });
    }
  }

  void _toggleLayout() {
    HapticFeedback.lightImpact();
    setState(() => _gridView = !_gridView);
    _savePrefs();
  }

  List<WatchlistItem> _filterList(List<WatchlistItem> items) {
    if (_searchQuery.isEmpty) return items;
    return items
        .where((i) => i.title.toLowerCase().contains(_searchQuery))
        .toList();
  }

  String get _commentaryMood =>
      (_anime.length + _manga.length) > 0 ? 'achievement' : 'neutral';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: WaifuBackground(
        opacity: 0.07,
        tint: const Color(0xFF0A0612),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeCtrl,
            child: Column(children: [
              // ── Header ──
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
                            border: Border.all(color: Colors.white12)),
                        child: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.white60, size: 16)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('WATCHLIST',
                            style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5)),
                        Text('${_anime.length} anime • ${_manga.length} manga',
                            style: GoogleFonts.outfit(
                                color: Colors.pinkAccent.withValues(alpha: 0.7),
                                fontSize: 10)),
                      ])),
                  // View toggle
                  GestureDetector(
                    onTap: _toggleLayout,
                    child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white12)),
                        child: Icon(
                            _gridView
                                ? Icons.grid_view_rounded
                                : Icons.view_list_rounded,
                            color: Colors.white60,
                            size: 18)),
                  ),
                ]),
              ),

              // ── Search ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.pinkAccent.withValues(alpha: 0.15))),
                  child: TextField(
                    controller: _searchCtrl,
                    style:
                        GoogleFonts.outfit(color: Colors.white, fontSize: 13),
                    cursorColor: Colors.pinkAccent,
                    decoration: InputDecoration(
                        hintText: 'Search watchlist...',
                        hintStyle: GoogleFonts.outfit(color: Colors.white24),
                        border: InputBorder.none,
                        icon: const Icon(Icons.search,
                            color: Colors.white30, size: 18)),
                  ),
                ),
              ),

              // ── Tab Bar ──
              Container(
                margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TabBar(
                  controller: _tabCtrl,
                  indicatorColor: Colors.pinkAccent,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelColor: Colors.pinkAccent,
                  unselectedLabelColor: Colors.white38,
                  labelStyle: GoogleFonts.outfit(
                      fontSize: 12, fontWeight: FontWeight.w700),
                  dividerColor: Colors.transparent,
                  tabs: [
                    Tab(text: '📺 Anime (${_filterList(_anime).length})'),
                    Tab(text: '📖 Manga (${_filterList(_manga).length})'),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: WaifuCommentary(mood: _commentaryMood),
              ),

              const SizedBox(height: 8),

              // ── Content ──
              Expanded(
                child: _loading
                    ? const Center(
                        child:
                            CircularProgressIndicator(color: Colors.pinkAccent))
                    : TabBarView(
                        controller: _tabCtrl,
                        children: [
                          _buildContent(_filterList(_anime), 'anime'),
                          _buildContent(_filterList(_manga), 'manga'),
                        ],
                      ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(List<WatchlistItem> items, String type) {
    if (items.isEmpty) {
      return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.favorite_border, color: Colors.white12, size: 64),
        const SizedBox(height: 12),
        Text(_searchQuery.isNotEmpty ? 'No matching $type' : 'No favorites yet',
            style: GoogleFonts.outfit(color: Colors.white30, fontSize: 14)),
        const SizedBox(height: 4),
        Text('Tap ❤️ on any $type to save it here',
            style: GoogleFonts.outfit(color: Colors.white24, fontSize: 11)),
      ]));
    }

    if (_gridView) {
      return GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.55,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: items.length,
        itemBuilder: (_, i) => _buildGridCard(items[i], i),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      itemBuilder: (_, i) => _buildListCard(items[i], i),
    );
  }

  Widget _buildGridCard(WatchlistItem item, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + index * 50),
      curve: Curves.easeOut,
      builder: (_, val, child) => Opacity(
          opacity: val,
          child: Transform.translate(
              offset: Offset(0, 16 * (1 - val)), child: child)),
      child: GestureDetector(
        onLongPress: () => _showRemoveDialog(item),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    item.coverUrl.isNotEmpty
                        ? AppCachedImage(
                            url: item.coverUrl,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover)
                        : Container(
                            color: Colors.grey.shade900,
                            child: const Icon(Icons.image, color: Colors.grey)),
                    // Gradient overlay
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.6)
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Heart badge
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.pinkAccent.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.pinkAccent.withValues(alpha: 0.3),
                                blurRadius: 8)
                          ],
                        ),
                        child: const Icon(Icons.favorite,
                            color: Colors.white, size: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildListCard(WatchlistItem item, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + index * 50),
      curve: Curves.easeOut,
      builder: (_, val, child) => Opacity(
          opacity: val,
          child: Transform.translate(
              offset: Offset(0, 12 * (1 - val)), child: child)),
      child: Dismissible(
        key: Key(item.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) {
          HapticFeedback.mediumImpact();
          _removeWithUndo(item);
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.delete_outline, color: Colors.redAccent),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.pinkAccent.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
            border:
                Border.all(color: Colors.pinkAccent.withValues(alpha: 0.15)),
          ),
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: item.coverUrl.isNotEmpty
                  ? AppCachedImage(
                      url: item.coverUrl,
                      width: 50,
                      height: 70,
                      fit: BoxFit.cover)
                  : Container(
                      width: 50, height: 70, color: Colors.grey.shade900),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                      '${item.type == 'manga' ? '📖' : '📺'} ${item.type.toUpperCase()}',
                      style: GoogleFonts.outfit(
                          color: Colors.white38, fontSize: 10)),
                ])),
            const Icon(Icons.favorite, color: Colors.pinkAccent, size: 20),
          ]),
        ),
      ),
    );
  }

  void _showRemoveDialog(WatchlistItem item) {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              backgroundColor: const Color(0xFF1A1A2E),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Text('Remove from Watchlist?',
                  style: GoogleFonts.outfit(
                      color: Colors.white, fontWeight: FontWeight.w800)),
              content: Text('Remove "${item.title}" from your favorites?',
                  style: GoogleFonts.outfit(color: Colors.white54)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel',
                        style: GoogleFonts.outfit(color: Colors.white54))),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _remove(item);
                    HapticFeedback.mediumImpact();
                  },
                  child: Text('Remove',
                      style: GoogleFonts.outfit(
                          color: Colors.pinkAccent,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ));
  }
}



