import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/manga_service.dart';
import 'manga_detail_page.dart';

/// Real MangaDex Genre UUIDs — no more fake IDs
const _mdxGenres = {
  '🔥 Action':       '391b0423-d847-456f-aff0-8b0cfc03066b',
  '💕 Romance':      '423e2eae-a7a2-4a8b-ac03-a8351462d71d',
  '😂 Comedy':       '4d32cc48-9f00-4cca-9b5a-a56702952269',
  '🧙 Fantasy':      'cdc58593-87dd-415e-bbc0-2ec27bf404cc',
  '🚀 Sci-Fi':       '256c8bd9-4904-4360-bf4f-508a76d67183',
  '🎭 Drama':        'b9af3a63-f058-46de-a9a0-e0c13906197a',
  '🗡️ Adventure':   '87cc87cd-a395-47af-b27a-93258283bbc6',
  '😱 Horror':       'cdad7e68-1419-41dd-bdce-27753074a640',
  '🔮 Supernatural': 'eabc5b4c-6aff-42f3-b657-3e90cbd00b75',
  '🏫 School':       'caaa44eb-cd40-4177-b930-79d3ef2bbe87',
  '🌸 Harem':        'aafb99c1-7f60-43fa-b75f-fc9502ce29c7',
  '⚔️ Historical':   '33771934-028e-4cb3-8744-691e866a923e',
  '🏃 Sports':       '69964a64-2f90-4d33-beeb-f3ed2875eb4c',
  '💻 Slice of Life': 'e5301a23-ebd9-49dd-a0cb-2add944c7fe9',
  '🔞 Ecchi':        '2d1f5d56-a1e5-4d0d-a961-2193588b08ec',
  '🔞 Smut (Adult)': '5920b825-4181-4a17-befd-0de3eef9b827',
};

/// ComicK genre IDs (numeric strings)
const _comickGenres = {
  '🔥 Action':       '1',
  '💕 Romance':      '17',
  '😂 Comedy':       '3',
  '🧙 Fantasy':      '7',
  '🚀 Sci-Fi':       '30',
  '🎭 Drama':        '6',
  '🗡️ Adventure':   '2',
  '😱 Horror':       '10',
  '🔮 Supernatural': '38',
  '🏫 School':       '22',
  '🌸 Harem':        '8',
  '⚔️ Historical':   '9',
  '🏃 Sports':       '37',
  '💻 Slice of Life': '34',
  '🔞 Ecchi':        '46',
  '🔞 Adult':        '47',
};

/// MangaPark genre strings
const _mpGenres = {
  '🔥 Action':       'Action',
  '💕 Romance':      'Romance',
  '😂 Comedy':       'Comedy',
  '🧙 Fantasy':      'Fantasy',
  '🚀 Sci-Fi':       'Sci-fi',
  '🎭 Drama':        'Drama',
  '🗡️ Adventure':   'Adventure',
  '😱 Horror':       'Horror',
  '🔮 Supernatural': 'Supernatural',
  '🏫 School Life':  'School Life',
  '🌸 Harem':        'Harem',
  '⚔️ Historical':   'Historical',
  '🏃 Sports':       'Sports',
  '💻 Slice of Life': 'Slice of Life',
  '🔞 Ecchi':        'Ecchi',
  '🔞 Hentai':       'Hentai',
};

/// NHentai — uses search query strings
const _nhGenres = {
  '🇺🇸 English':     'language:english',
  '🇯🇵 Japanese':    'language:japanese',
  '🇰🇷 Korean':      'language:korean',
  '💗 Big Breasts':  'tag:big breasts',
  '🏫 Schoolgirl':   'tag:schoolgirl',
  '💕 Romance':      'tag:romance',
  '🍦 Vanilla':      'tag:vanilla',
  '🔓 Uncensored':   'tag:uncensored',
  '💔 NTR':          'tag:netorare',
  '🎨 Full Color':   'tag:full color',
  '📕 Doujinshi':    'tag:doujinshi',
  '🔞 Milf':         'tag:milf',
};

/// Toonily (Raw Manhwa) genre slugs
const _toonilyGenres = {
  '🔥 Action':       'action',
  '💕 Romance':      'romance',
  '😂 Comedy':       'comedy',
  '🧙 Fantasy':      'fantasy',
  '🎭 Drama':        'drama',
  '🌸 Harem':        'harem',
  '🏫 School Life':  'school-life',
  '🔞 Adult':        'adult',
  '🔞 Mature':       'mature',
  '🔞 Smut':         'smut',
  '💖 Josei':        'josei',
  '💙 Seinen':       'seinen',
};


extension _MangaColorExt on MangaSource {
  Color get color {
    switch (this) {
      case MangaSource.dex:       return const Color(0xFFFF6740);
      case MangaSource.comick:    return const Color(0xFF3EB8FF);
      case MangaSource.mangapark: return const Color(0xFFAA52FF);
      case MangaSource.nhentai:   return Colors.pinkAccent;
      case MangaSource.manhwa:    return const Color(0xFFFF4FA8);
      default:                    return const Color(0xFFBB52FF); // Standard theme color for generic scrapers
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
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;
  late AnimationController _pulseCtrl;

  List<MangaItem> _trending = [];
  List<MangaItem> _searchResults = [];
  List<MangaItem> _genreResults = [];
  bool _loadingTrending = true;
  bool _loadingSearch = false;
  bool _loadingGenre = false;
  bool _loadingMore = false;
  String _searchQuery = '';
  String? _selectedGenreId;
  String? _selectedGenreName;

  // Pagination
  static const int _pageSize = 24;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _loadTrending();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTrending() async {
    setState(() { _loadingTrending = true; _hasMore = true; _trending = []; });
    final results = await MangaService.getTrending(limit: _pageSize);
    if (mounted) setState(() { _trending = results; _loadingTrending = false; _hasMore = results.length >= _pageSize; });
  }

  Future<void> _loadMoreTrending() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    // MangaDex supports offset-based pagination
    final results = await MangaService.getTrending(limit: _pageSize);
    if (mounted) {
      setState(() {
        _trending.addAll(results);
        _loadingMore = false;
        _hasMore = results.length >= _pageSize;
      });
    }
  }

  void _onSearchChanged(String val) {
    _debounce?.cancel();
    setState(() { _searchQuery = val; _loadingSearch = val.isNotEmpty; _selectedGenreId = null; _selectedGenreName = null; });
    if (val.isEmpty) { setState(() { _searchResults = []; _loadingSearch = false; }); return; }
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final results = await MangaService.searchManga(val, limit: _pageSize);
      if (mounted) setState(() { _searchResults = results; _loadingSearch = false; });
    });
  }

  Future<void> _selectGenre(String id, String name) async {
    setState(() {
      _selectedGenreId = id;
      _selectedGenreName = name;
      _loadingGenre = true;
      _genreResults = [];
      _searchCtrl.clear();
      _searchQuery = '';
      _searchResults = [];
    });
    final results = await MangaService.getByTag(id, limit: _pageSize);
    if (mounted) setState(() { _genreResults = results; _loadingGenre = false; });
  }

  void _clearGenre() {
    setState(() { _selectedGenreId = null; _selectedGenreName = null; _genreResults = []; });
  }

  void _switchSource(MangaSource src) {
    if (MangaService.currentSource == src) return;
    MangaService.currentSource = src;
    _searchCtrl.clear();
    _clearGenre();
    setState(() { _searchQuery = ''; _searchResults = []; });
    _loadTrending();
  }

  Map<String, String> get _genres {
    switch (MangaService.currentSource) {
      case MangaSource.dex:       return _mdxGenres;
      case MangaSource.comick:    return _comickGenres;
      case MangaSource.mangapark: return _mpGenres;
      case MangaSource.nhentai:   return _nhGenres;
      case MangaSource.manhwa:    return _toonilyGenres;
      default:                    return _toonilyGenres;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.5),
                radius: 1.4,
                colors: [Color(0xFF1E0B38), Color(0xFF080B18)],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildSourceTabs(),
                _buildSearchBar(),
                _buildGenreChips(),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white54, size: 18),
        ),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('MANGA READER', style: GoogleFonts.outfit(
              color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: 2.5)),
          Text('${MangaService.sourceName}  ·  Tap tabs to switch source',
              style: GoogleFonts.outfit(color: Colors.white30, fontSize: 10)),
        ]),
        const Spacer(),
        AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, __) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(colors: [
                const Color(0xFFBB52FF).withValues(alpha: 0.6 + _pulseCtrl.value * 0.4),
                const Color(0xFF6C4EFF).withValues(alpha: 0.6 + _pulseCtrl.value * 0.4),
              ]),
              boxShadow: [BoxShadow(color: const Color(0xFFBB52FF).withValues(alpha: 0.4 * _pulseCtrl.value), blurRadius: 12)],
            ),
            child: Text('📖 READ', style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ),
      ]),
    );
  }

  Widget _buildSourceTabs() {
    final List<MangaSource> standard = [
      MangaSource.comick, MangaSource.dex, MangaSource.mangapark, 
      MangaSource.reaperscans, MangaSource.asurascans, MangaSource.flamescans, MangaSource.luminous
    ];
    final List<MangaSource> adult = MangaSource.values.where((s) => !standard.contains(s)).toList();

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 12, top: 8),
            child: Text('📚 STANDARD', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
          ),
          ...standard.map((src) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _sourceTab(MangaService.sourceDisplayName(src), src, src.color),
          )),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 12, top: 8),
            child: Text('🔞 EXPLICIT', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
          ),
          ...adult.map((src) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _sourceTab(MangaService.sourceDisplayName(src), src, src.color),
          )),
        ],
      ),
    );
  }

  Widget _sourceTab(String label, MangaSource src, Color color) {
    final isActive = MangaService.currentSource == src;
    return GestureDetector(
      onTap: () => _switchSource(src),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isActive ? color.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.1)),
          boxShadow: isActive ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 10, spreadRadius: -2)] : null,
        ),
        child: Text(label, style: GoogleFonts.outfit(
          color: isActive ? color : Colors.white38,
          fontSize: 12,
          fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
        )),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: TextField(
          controller: _searchCtrl,
          onChanged: _onSearchChanged,
          style: GoogleFonts.outfit(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search manga, manhwa, manhua...',
            hintStyle: GoogleFonts.outfit(color: Colors.white30, fontSize: 13),
            prefixIcon: const Icon(Icons.search_rounded, color: Colors.white30, size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? GestureDetector(
                    onTap: () { _searchCtrl.clear(); _onSearchChanged(''); },
                    child: const Icon(Icons.close_rounded, color: Colors.white30, size: 18))
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildGenreChips() {
    final genres = _genres;
    if (genres.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          if (_selectedGenreId != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: _clearGenre,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white30),
                  ),
                  child: Row(children: [
                    const Icon(Icons.close_rounded, color: Colors.white, size: 13),
                    const SizedBox(width: 4),
                    Text('Clear', style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ]),
                ),
              ),
            ),
          ..._genres.entries.map((e) {
            final isSelected = _selectedGenreId == e.value;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => isSelected ? _clearGenre() : _selectGenre(e.value, e.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFBB52FF).withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFBB52FF) : Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Text(e.key, style: GoogleFonts.outfit(
                    color: isSelected ? Colors.white : Colors.white60,
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  )),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loadingTrending) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFBB52FF)));
    }

    if (_loadingSearch) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFBB52FF)));
    }

    if (_searchQuery.isNotEmpty && _searchResults.isNotEmpty) {
      return _buildGrid(_searchResults, label: 'Search Results for "$_searchQuery"');
    }

    if (_searchQuery.isNotEmpty && !_loadingSearch) {
      return _buildEmptyState('No results found for "$_searchQuery"');
    }

    if (_selectedGenreName != null) {
      if (_loadingGenre) return const Center(child: CircularProgressIndicator(color: Color(0xFFBB52FF)));
      if (_genreResults.isEmpty) return _buildEmptyState('Nothing found in $_selectedGenreName');
      return _buildGrid(_genreResults, label: '$_selectedGenreName Manga');
    }

    if (_trending.isEmpty) {
      return _buildEmptyState('Could not load content. Check your connection.');
    }

    return _buildGrid(_trending, label: 'Trending Now', allowLoadMore: true);
  }

  Widget _buildGrid(List<MangaItem> items, {required String label, bool allowLoadMore = false}) {
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (allowLoadMore && n is ScrollEndNotification && n.metrics.extentAfter < 200) {
          _loadMoreTrending();
        }
        return false;
      },
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            sliver: SliverToBoxAdapter(
              child: Text(label, style: GoogleFonts.outfit(
                color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
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
                          icon: const Icon(Icons.expand_more_rounded, color: Colors.white54),
                          label: Text('Load More', style: GoogleFonts.outfit(color: Colors.white54)),
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCard(MangaItem manga) {
    final coverUrl = manga.coverUrl;
    final isAdult = manga.contentRating == 'erotica' || manga.contentRating == 'pornographic';

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MangaDetailPage(manga: manga))),
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
                            errorWidget: (_, __, ___) => _coverPlaceholder(manga.title),
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
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.pinkAccent.shade700,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('18+', style: GoogleFonts.outfit(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                  ),
                // Status badge
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(manga.status.toUpperCase(),
                        style: GoogleFonts.outfit(color: manga.status == 'ongoing' ? Colors.greenAccent : Colors.white54, fontSize: 7, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            manga.title,
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
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

  Widget _coverPlaceholder(String title) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF2D1B4E), const Color(0xFF1A0E2E)],
        ),
      ),
      child: Text(
        title.isNotEmpty ? title[0].toUpperCase() : '?',
        style: GoogleFonts.outfit(color: Colors.white38, fontSize: 36, fontWeight: FontWeight.w900),
      ),
    );
  }

  Widget _shimmer() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white.withValues(alpha: 0.03), Colors.white.withValues(alpha: 0.08), Colors.white.withValues(alpha: 0.03)],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('📭', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        Text(msg, style: GoogleFonts.outfit(color: Colors.white38, fontSize: 13), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        if (_selectedGenreId != null)
          TextButton(onPressed: _clearGenre, child: Text('Back to Trending', style: GoogleFonts.outfit(color: const Color(0xFFBB52FF)))),
      ]),
    );
  }
}
