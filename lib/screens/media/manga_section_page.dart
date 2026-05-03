import 'dart:async';

import 'package:anime_waifu/config/app_themes.dart';
import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:anime_waifu/services/anime_media/manga_service.dart';
import 'package:anime_waifu/services/anime_media/watchlist_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'manga_detail_page.dart';

/// Real MangaDex Genre UUIDs — no more fake IDs
const _mdxGenres = {
  '🔥 Action': '391b0423-d847-456f-aff0-8b0cfc03066b',
  '💕 Romance': '423e2eae-a7a2-4a8b-ac03-a8351462d71d',
  '😂 Comedy': '4d32cc48-9f00-4cca-9b5a-a56702952269',
  '🧙 Fantasy': 'cdc58593-87dd-415e-bbc0-2ec27bf404cc',
  '🚀 Sci-Fi': '256c8bd9-4904-4360-bf4f-508a76d67183',
  '🎭 Drama': 'b9af3a63-f058-46de-a9a0-e0c13906197a',
  '🗡️ Adventure': '87cc87cd-a395-47af-b27a-93258283bbc6',
  '😱 Horror': 'cdad7e68-1419-41dd-bdce-27753074a640',
  '🔮 Supernatural': 'eabc5b4c-6aff-42f3-b657-3e90cbd00b75',
  '🏫 School': 'caaa44eb-cd40-4177-b930-79d3ef2bbe87',
  '🌸 Harem': 'aafb99c1-7f60-43fa-b75f-fc9502ce29c7',
  '⚔️ Historical': '33771934-028e-4cb3-8744-691e866a923e',
  '🏃 Sports': '69964a64-2f90-4d33-beeb-f3ed2875eb4c',
  '💻 Slice of Life': 'e5301a23-ebd9-49dd-a0cb-2add944c7fe9',
  '🔞 Ecchi': '2d1f5d56-a1e5-4d0d-a961-2193588b08ec',
  '🔞 Smut (Adult)': '5920b825-4181-4a17-befd-0de3eef9b827',
};

/// ComicK genre IDs (numeric strings)
const _comickGenres = {
  '🔥 Action': '1',
  '💕 Romance': '17',
  '😂 Comedy': '3',
  '🧙 Fantasy': '7',
  '🚀 Sci-Fi': '30',
  '🎭 Drama': '6',
  '🗡️ Adventure': '2',
  '😱 Horror': '10',
  '🔮 Supernatural': '38',
  '🏫 School': '22',
  '🌸 Harem': '8',
  '⚔️ Historical': '9',
  '🏃 Sports': '37',
  '💻 Slice of Life': '34',
  '🔞 Ecchi': '46',
  '🔞 Adult': '47',
};

/// MangaPark genre strings
const _mpGenres = {
  '🔥 Action': 'Action',
  '💕 Romance': 'Romance',
  '😂 Comedy': 'Comedy',
  '🧙 Fantasy': 'Fantasy',
  '🚀 Sci-Fi': 'Sci-fi',
  '🎭 Drama': 'Drama',
  '🗡️ Adventure': 'Adventure',
  '😱 Horror': 'Horror',
  '🔮 Supernatural': 'Supernatural',
  '🏫 School Life': 'School Life',
  '🌸 Harem': 'Harem',
  '⚔️ Historical': 'Historical',
  '🏃 Sports': 'Sports',
  '💻 Slice of Life': 'Slice of Life',
  '🔞 Ecchi': 'Ecchi',
  '🔞 Hentai': 'Hentai',
};

/// NHentai — uses search query strings
const _nhGenres = {
  '🇺🇸 English': 'language:english',
  '🇯🇵 Japanese': 'language:japanese',
  '🇰🇷 Korean': 'language:korean',
  '💗 Big Breasts': 'tag:big breasts',
  '🏫 Schoolgirl': 'tag:schoolgirl',
  '💕 Romance': 'tag:romance',
  '🍦 Vanilla': 'tag:vanilla',
  '🔓 Uncensored': 'tag:uncensored',
  '💔 NTR': 'tag:netorare',
  '🎨 Full Color': 'tag:full color',
  '📕 Doujinshi': 'tag:doujinshi',
  '🔞 Milf': 'tag:milf',
};

/// Toonily (Raw Manhwa) genre slugs
const _toonilyGenres = {
  '🔥 Action': 'action',
  '💕 Romance': 'romance',
  '😂 Comedy': 'comedy',
  '🧙 Fantasy': 'fantasy',
  '🎭 Drama': 'drama',
  '🌸 Harem': 'harem',
  '🏫 School Life': 'school-life',
  '🔞 Adult': 'adult',
  '🔞 Mature': 'mature',
  '🔞 Smut': 'smut',
  '💖 Josei': 'josei',
  '💙 Seinen': 'seinen',
};

extension _MangaColorExt on MangaSource {
  Color get color {
    switch (this) {
      case MangaSource.dex:
        return const Color(0xFFFF6740);
      case MangaSource.comick:
        return const Color(0xFF3EB8FF);
      case MangaSource.mangapark:
        return const Color(0xFFAA52FF);
      case MangaSource.nhentai:
        return Colors.pinkAccent;
      case MangaSource.manhwa:
        return const Color(0xFFFF4FA8);
      default:
        return const Color(
            0xFFBB52FF); // Standard theme color for generic scrapers
    }
  }
}

class MangaSectionPage extends StatefulWidget {
  const MangaSectionPage({super.key});
  @override
  State<MangaSectionPage> createState() => _MangaSectionPageState();
}

class _MangaSectionPageState extends State<MangaSectionPage>
    with TickerProviderStateMixin {
  static const String _sourceKey = 'manga_section_source_v2';
  static const String _queryKey = 'manga_section_query_v2';
  static const String _genreIdKey = 'manga_section_genre_id_v2';
  static const String _genreNameKey = 'manga_section_genre_name_v2';

  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;
  late AnimationController _pulseCtrl;

  List<MangaItem> _trending = [];
  List<MangaItem> _searchResults = [];
  List<MangaItem> _genreResults = [];
  Set<String> _favoriteIds = <String>{};
  bool _loadingTrending = true;
  bool _loadingSearch = false;
  bool _loadingGenre = false;
  bool _loadingMore = false;
  String _searchQuery = '';
  String? _selectedGenreId;
  String? _selectedGenreName;
  bool _isSummaryVisible = true;

  // Pagination
  static const int _pageSize = 24;
  int _trendingOffset = 0;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _pulseCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _restoreState().then((_) {
      // Ensure we load content after state restoration
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _restoreState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSource = prefs.getString(_sourceKey);
    final savedQuery = prefs.getString(_queryKey) ?? '';
    final savedGenreId = prefs.getString(_genreIdKey);
    final savedGenreName = prefs.getString(_genreNameKey);

    for (final source in MangaSource.values) {
      if (source.name == savedSource) {
        MangaService.currentSource = source;
        break;
      }
    }

    _searchQuery = savedQuery;
    _searchCtrl.text = savedQuery;
    _selectedGenreId = savedGenreId;
    _selectedGenreName = savedGenreName;

    await _loadFavorites();
    await _loadTrending();

    if (_selectedGenreId != null && _selectedGenreName != null) {
      await _selectGenre(_selectedGenreId!, _selectedGenreName!,
          persist: false);
      return;
    }
    if (_searchQuery.isNotEmpty) {
      await _performSearch(_searchQuery, persist: false);
    }
  }

  Future<void> _persistState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sourceKey, MangaService.currentSource.name);
    await prefs.setString(_queryKey, _searchQuery);
    if (_selectedGenreId == null) {
      await prefs.remove(_genreIdKey);
      await prefs.remove(_genreNameKey);
    } else {
      await prefs.setString(_genreIdKey, _selectedGenreId!);
      await prefs.setString(_genreNameKey, _selectedGenreName ?? '');
    }
  }

  Future<void> _loadFavorites() async {
    final watchlist = await WatchlistService.getMangaWatchlist();
    if (!mounted) {
      return;
    }
    if (!mounted) return;
    setState(() {
      _favoriteIds = watchlist.map((item) => item.id).toSet();
    });
  }

  Future<void> _loadTrending() async {
    setState(() {
      _loadingTrending = true;
      _hasMore = true;
      _trending = [];
      _trendingOffset = 0;
    });
    List<MangaItem> results = <MangaItem>[];
    try {
      results = await MangaService.getTrending(limit: _pageSize, offset: 0);
    } catch (_) {
      results = <MangaItem>[];
    }
    if (mounted) {
      setState(() {
        _trending = results;
        _loadingTrending = false;
        _trendingOffset = results.length;
        _hasMore = results.length >= _pageSize;
      });
    }
  }

  Future<void> _loadMoreTrending() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    List<MangaItem> results = <MangaItem>[];
    try {
      results = await MangaService.getTrending(limit: _pageSize, offset: _trendingOffset);
    } catch (_) {
      results = <MangaItem>[];
    }
    if (mounted) {
      setState(() {
        _trending.addAll(results);
        _trendingOffset += results.length;
        _loadingMore = false;
        _hasMore = results.length >= _pageSize;
      });
    }
  }

  Future<void> _performSearch(String val, {bool persist = true}) async {
    if (persist) {
      _searchQuery = val;
      await _persistState();
    }
    if (val.isEmpty) {
      if (!mounted) {
        return;
      }
      if (!mounted) return;
      setState(() {
        _searchResults = <MangaItem>[];
        _loadingSearch = false;
      });
      return;
    }

    List<MangaItem> results = <MangaItem>[];
    try {
      results = await MangaService.searchManga(val, limit: _pageSize);
    } catch (_) {
      results = <MangaItem>[];
    }
    if (mounted) {
      setState(() {
        _searchResults = results;
        _loadingSearch = false;
      });
    }
  }

  Future<void> _selectGenre(String id, String name,
      {bool persist = true}) async {
    setState(() {
      _selectedGenreId = id;
      _selectedGenreName = name;
      _loadingGenre = true;
      _genreResults = [];
      _searchCtrl.clear();
      _searchQuery = '';
      _searchResults = <MangaItem>[];
    });
    if (persist) {
      await _persistState();
    }
    List<MangaItem> results = <MangaItem>[];
    try {
      results = await MangaService.getByTag(id, limit: _pageSize);
    } catch (_) {
      results = <MangaItem>[];
    }
    if (mounted) {
      setState(() {
        _genreResults = results;
        _loadingGenre = false;
      });
    }
  }

  void _clearGenre() {
    setState(() {
      _selectedGenreId = null;
      _selectedGenreName = null;
      _genreResults = <MangaItem>[];
    });
    _persistState();
  }

  Future<void> _switchSource(MangaSource src) async {
    if (MangaService.currentSource == src) return;
    HapticFeedback.selectionClick();
    MangaService.currentSource = src;
    _searchCtrl.clear();
    _clearGenre();
    setState(() {
      _searchQuery = '';
      _searchResults = <MangaItem>[];
    });
    await _persistState();
    await _loadTrending();
  }

  Map<String, String> get _genres {
    switch (MangaService.currentSource) {
      case MangaSource.dex:
        return _mdxGenres;
      case MangaSource.comick:
        return _comickGenres;
      case MangaSource.mangapark:
        return _mpGenres;
      case MangaSource.nhentai:
        return _nhGenres;
      case MangaSource.manhwa:
        return _toonilyGenres;
      default:
        return _toonilyGenres;
    }
  }

  Future<void> _refreshPage() async {
    await _loadFavorites();
    await _loadTrending();
    if (_selectedGenreId != null && _selectedGenreName != null) {
      await _selectGenre(_selectedGenreId!, _selectedGenreName!,
          persist: false);
      return;
    }
    if (_searchQuery.isNotEmpty) {
      await _performSearch(_searchQuery, persist: false);
    }
  }

  Future<void> _toggleFavorite(MangaItem manga) async {
    final isFavorite = _favoriteIds.contains(manga.id);
    HapticFeedback.mediumImpact();
    if (isFavorite) {
      await WatchlistService.removeManga(manga.id);
      if (!mounted) {
        return;
      }
      if (!mounted) return;
      setState(() {
        _favoriteIds.remove(manga.id);
      });
      showUndoSnackbar(
        context,
        'Removed ${manga.title} from your manga shelf.',
        () async {
          await WatchlistService.addManga(
            WatchlistItem(
              id: manga.id,
              title: manga.title,
              coverUrl: manga.coverUrl ?? '',
              type: 'manga',
            ),
          );
          if (mounted) {
            setState(() {
              _favoriteIds.add(manga.id);
            });
          }
        },
      );
      return;
    }

    await WatchlistService.addManga(
      WatchlistItem(
        id: manga.id,
        title: manga.title,
        coverUrl: manga.coverUrl ?? '',
        type: 'manga',
      ),
    );
    if (!mounted) {
      return;
    }
    if (!mounted) return;
    setState(() {
      _favoriteIds.add(manga.id);
    });
    showUndoSnackbar(
      context,
      'Saved ${manga.title} to your manga shelf.',
      () async {
        await WatchlistService.removeManga(manga.id);
        if (mounted) {
          setState(() {
            _favoriteIds.remove(manga.id);
          });
        }
      },
    );
  }

  List<MangaItem> get _activeItems {
    if (_selectedGenreId != null) {
      return _genreResults;
    }
    if (_searchQuery.isNotEmpty) {
      return _searchResults;
    }
    return _trending;
  }

  String get _commentaryMood {
    if (_favoriteIds.length >= 8) {
      return 'achievement';
    }
    if (_activeItems.length >= 12 || _searchQuery.isNotEmpty) {
      return 'motivated';
    }
    if (_activeItems.isEmpty &&
        !_loadingGenre &&
        !_loadingSearch &&
        !_loadingTrending) {
      return 'relaxed';
    }
    return 'neutral';
  }

  bool get _isCompactScreen {
    final size = MediaQuery.sizeOf(context);
    return size.height < 920 || size.width < 430;
  }

  bool get _isUltraCompactScreen {
    final size = MediaQuery.sizeOf(context);
    return size.height < 760 || size.width < 390;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.appTokens;
    final primary = theme.colorScheme.primary;
    final compact = _isCompactScreen;

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
              child: const Icon(Icons.menu_book_rounded,
                  color: Colors.deepPurpleAccent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Manga Library',
                      style: GoogleFonts.outfit(
                          color: theme.colorScheme.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                  Text('${MangaService.sourceName} • Switch sources below',
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            child: Text('${_favoriteIds.length}',
                style: GoogleFonts.outfit(
                    color: Colors.deepPurpleAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
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
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n is ScrollEndNotification && n.metrics.extentAfter < 200) {
                if (_searchQuery.isEmpty && _selectedGenreName == null) {
                  _loadMoreTrending();
                }
              }
              return false;
            },
            child: RefreshIndicator(
              onRefresh: _refreshPage,
              color: primary,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, compact ? 8 : 12),
                    sliver: SliverToBoxAdapter(
                      child: _buildTopSummary(compact),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _buildSourceTabs(),
                  ),
                  SliverToBoxAdapter(
                    child: _buildSearchBar(),
                  ),
                  SliverToBoxAdapter(
                    child: _buildGenreChips(compact),
                  ),
                  ..._buildBodySlivers(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopSummary(bool compact) {
    if (compact) {
      return Column(
        children: <Widget>[
          // Collapsible summary card - can be hidden by tapping
          GestureDetector(
            onTap: () {
              setState(() {
                _isSummaryVisible = !_isSummaryVisible;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: EdgeInsets.zero,
              child: _isSummaryVisible
                  ? GlassCard(
                      padding: EdgeInsets.all(_isUltraCompactScreen ? 12 : 14),
                      glow: true,
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  _selectedGenreName != null
                                      ? 'Genre: $_selectedGenreName'
                                      : _searchQuery.isNotEmpty
                                          ? 'Search: $_searchQuery'
                                          : 'Trending shelves',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: _isUltraCompactScreen ? 15 : 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${_activeItems.length} visible  ·  ${_favoriteIds.length} saved  ·  ${_genres.length} genres',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    color: Colors.white60,
                                    fontSize: _isUltraCompactScreen ? 10.5 : 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          ProgressRing(
                            progress:
                                ((_activeItems.length).clamp(0, _pageSize)) / _pageSize,
                            size: _isUltraCompactScreen ? 64 : 72,
                            strokeWidth: _isUltraCompactScreen ? 6 : 7,
                            foreground: const Color(0xFFBB52FF),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Icon(
                                  Icons.menu_book_rounded,
                                  color: const Color(0xFFBB52FF),
                                  size: _isUltraCompactScreen ? 16 : 18,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_activeItems.length}',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: _isUltraCompactScreen ? 13 : 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          if (_isSummaryVisible) const SizedBox(height: 8),
        ],
      );
    }

    return Column(
      children: <Widget>[
        GlassCard(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(18),
          glow: true,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Shelf mood',
                      style: GoogleFonts.outfit(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _selectedGenreName != null
                          ? 'Genre lane: $_selectedGenreName'
                          : _searchQuery.isNotEmpty
                              ? 'Search lane is active.'
                              : 'Trending shelves are ready.',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Save favorites, switch sources, and keep your next chapter close.',
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
                progress:
                    ((_activeItems.length).clamp(0, _pageSize)) / _pageSize,
                foreground: const Color(0xFFBB52FF),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(
                      Icons.menu_book_rounded,
                      color: Color(0xFFBB52FF),
                      size: 28,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_activeItems.length}',
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
        WaifuCommentary(mood: _commentaryMood),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: StatCard(
                title: 'Trending',
                value: '${_trending.length}',
                icon: Icons.local_fire_department_rounded,
                color: const Color(0xFFBB52FF),
              ),
            ),
            Expanded(
              child: StatCard(
                title: 'Shelf',
                value: '${_favoriteIds.length}',
                icon: Icons.favorite_rounded,
                color: Colors.pinkAccent,
              ),
            ),
          ],
        ),
        Row(
          children: <Widget>[
            Expanded(
              child: StatCard(
                title: 'Sources',
                value: '${MangaSource.values.length}',
                icon: Icons.hub_rounded,
                color: V2Theme.secondaryColor,
              ),
            ),
            Expanded(
              child: StatCard(
                title: 'Genres',
                value: '${_genres.length}',
                icon: Icons.category_rounded,
                color: Colors.orangeAccent,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSourceTabs() {
    final List<MangaSource> standard = [
      MangaSource.comick,
      MangaSource.dex,
      MangaSource.mangapark,
      MangaSource.reaperscans,
      MangaSource.asurascans,
      MangaSource.flamescans,
      MangaSource.luminous
    ];

    final List<MangaSource> adult =
        MangaSource.values.where((s) => !standard.contains(s)).toList();
    final tokens = context.appTokens;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('MANGA SOURCES',
                style: GoogleFonts.outfit(
                    color: tokens.textSoft,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                // Standard sources section
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('📚 STANDARD',
                          style: GoogleFonts.outfit(
                              color: tokens.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1)),
                      const SizedBox(height: 8),
                      Row(
                        children: standard
                            .map((src) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: _sourceTab(
                                      MangaService.sourceDisplayName(src),
                                      src,
                                      src.color),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),

                // Adult sources section
                if (adult.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('🔞 ADULT',
                            style: GoogleFonts.outfit(
                                color: tokens.textMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1)),
                        const SizedBox(height: 8),
                        Row(
                          children: adult
                              .map((src) => Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: _sourceTab(
                                        MangaService.sourceDisplayName(src),
                                        src,
                                        src.color),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sourceTab(String label, MangaSource src, Color color) {
    final theme = Theme.of(context);
    final tokens = context.appTokens;
    final isActive = MangaService.currentSource == src;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _switchSource(src),
        splashColor: color.withValues(alpha: 0.1),
        highlightColor: color.withValues(alpha: 0.05),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: isActive
                ? LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.25),
                      color.withValues(alpha: 0.15),
                    ],
                  )
                : LinearGradient(
                    colors: [
                      tokens.panel.withValues(alpha: 0.8),
                      tokens.panelElevated.withValues(alpha: 0.6),
                    ],
                  ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive ? color.withValues(alpha: 0.4) : tokens.outline,
              width: isActive ? 2 : 1,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Text(label,
              style: GoogleFonts.outfit(
                color: isActive
                    ? Colors.white
                    : theme.colorScheme.onSurface.withValues(alpha: 0.8),
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                letterSpacing: 0.5,
              )),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final theme = Theme.of(context);
    final tokens = context.appTokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        controller: _searchCtrl,
        style: GoogleFonts.outfit(color: theme.colorScheme.onSurface, fontSize: 15),
        cursorColor: Colors.deepPurpleAccent,
        decoration: InputDecoration(
          hintText: 'Search manga...',
          hintStyle: GoogleFonts.outfit(color: tokens.textSoft, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: Colors.deepPurpleAccent, size: 22),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded, color: tokens.textSoft, size: 20),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() {
                      _searchQuery = '';
                      _searchResults = [];
                    });
                    _persistState();
                  },
                )
              : null,
          filled: true,
          fillColor: theme.colorScheme.surface.withValues(alpha: 0.8),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.deepPurpleAccent.withValues(alpha: 0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.deepPurpleAccent.withValues(alpha: 0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.deepPurpleAccent, width: 1.5),
          ),
        ),
        onChanged: (val) {
          _debounce?.cancel();
          _debounce = Timer(const Duration(milliseconds: 500), () {
            if (val.trim().isEmpty) {
              setState(() {
                _searchQuery = '';
                _searchResults = [];
                _loadingSearch = false;
              });
              _persistState();
              return;
            }
            setState(() {
              _loadingSearch = true;
              _searchQuery = val.trim();
              _selectedGenreId = null;
              _selectedGenreName = null;
            });
            _performSearch(val.trim());
          });
        },
      ),
    );
  }

  Widget _buildGenreChips(bool compact) {
    if (_genres.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        children: [
          GestureDetector(
            onTap: _clearGenre,
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _selectedGenreId == null
                    ? Colors.deepPurpleAccent
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'All',
                style: GoogleFonts.outfit(
                  color:
                      _selectedGenreId == null ? Colors.white : Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          ..._genres.entries.map((entry) => GestureDetector(
                onTap: () => _selectGenre(entry.key, entry.value),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _selectedGenreId == entry.key
                        ? Colors.deepPurpleAccent
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    entry.value,
                    style: GoogleFonts.outfit(
                      color: _selectedGenreId == entry.key
                          ? Colors.white
                          : Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  List<Widget> _buildBodySlivers() {
    if (_loadingTrending || _loadingSearch || (_selectedGenreName != null && _loadingGenre)) {
      return [
        const SliverFillRemaining(
          child: Center(child: CircularProgressIndicator()),
        )
      ];
    }

    if (_searchQuery.isNotEmpty && _searchResults.isNotEmpty) {
      return _buildGridSlivers(_searchResults, label: 'Search Results for "$_searchQuery"');
    }

    if (_searchQuery.isNotEmpty && !_loadingSearch) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _buildEmptyState('No results found for "$_searchQuery"'),
        )
      ];
    }

    if (_selectedGenreName != null) {
      if (_genreResults.isEmpty) {
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child: _buildEmptyState('Nothing found in $_selectedGenreName'),
          )
        ];
      }
      return _buildGridSlivers(_genreResults, label: '$_selectedGenreName Manga');
    }

    if (_trending.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _buildEmptyState('Could not load content. Check your connection.'),
        )
      ];
    }

    return _buildGridSlivers(_trending, label: 'Trending Now', allowLoadMore: true);
  }

  List<Widget> _buildGridSlivers(List<MangaItem> items,
      {required String label, bool allowLoadMore = false}) {
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
        sliver: SliverToBoxAdapter(
          child: SectionHeader(
            padding: EdgeInsets.zero,
            title: label,
            subtitle:
                'Tap a cover to dive in, or long press the heart to save favorites.',
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        sliver: SliverGrid(
          delegate: SliverChildBuilderDelegate(
            (context, i) => _buildCard(items[i]),
            childCount: items.length,
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 12,
            childAspectRatio: 0.56,
          ),
        ),
      ),
      if (allowLoadMore && _hasMore)
        SliverToBoxAdapter(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: _loadingMore
                  ? const CircularProgressIndicator(color: Color(0xFFBB52FF))
                  : TextButton.icon(
                      onPressed: _loadMoreTrending,
                      icon: const Icon(Icons.expand_more_rounded,
                          color: Colors.white54),
                      label: Text('Load More',
                          style: GoogleFonts.outfit(color: Colors.white54)),
                    ),
            ),
          ),
        ),
    ];
  }

  Widget _buildCard(MangaItem manga) {
    final coverUrl = manga.coverUrl;
    final isAdult = manga.contentRating == 'erotica' ||
        manga.contentRating == 'pornographic';
    final isFavorite = _favoriteIds.contains(manga.id);

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => MangaDetailPage(manga: manga))),
      onDoubleTap: () => _toggleFavorite(manga),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    color: Colors.white.withValues(alpha: 0.05),
                    child: coverUrl != null
                        ? CachedNetworkImage(
                            imageUrl: coverUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            memCacheWidth: 200,
                            placeholder: (_, __) => _shimmer(),
                            errorWidget: (_, __, ___) =>
                                _coverPlaceholder(manga.title),
                          )
                        : _coverPlaceholder(manga.title),
                  ),
                ),
                // Adult badge
                if (isAdult)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.pinkAccent.shade700,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('18+',
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                if (isFavorite)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.pinkAccent.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                // Status badge
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(manga.status.toUpperCase(),
                        style: GoogleFonts.outfit(
                            color: manga.status == 'ongoing'
                                ? Colors.greenAccent
                                : Colors.white54,
                            fontSize: 7,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            manga.title,
            style: GoogleFonts.outfit(
                color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (manga.tags.isNotEmpty)
            Text(
              manga.tags.take(2).join(' · '),
              style: GoogleFonts.outfit(color: Colors.white38, fontSize: 9),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  Widget _coverPlaceholder(String? title) {
    final String safeTitle = title ?? '';
    return Container(
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2D1B4E), Color(0xFF1A0E2E)],
        ),
      ),
      child: Text(
        safeTitle.isNotEmpty ? safeTitle[0].toUpperCase() : '?',
        style: GoogleFonts.outfit(
            color: Colors.white38, fontSize: 36, fontWeight: FontWeight.w900),
      ),
    );
  }

  Widget _shimmer() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.03),
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.03)
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return EmptyState(
      icon: Icons.menu_book_rounded,
      title: 'Shelf is empty',
      subtitle: msg,
      buttonText: _selectedGenreId != null ? 'Back to Trending' : 'Refresh',
      onButtonPressed: _selectedGenreId != null ? _clearGenre : _refreshPage,
    );
  }
}
