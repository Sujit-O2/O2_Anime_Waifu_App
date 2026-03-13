import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/free_apis_service.dart';
import '../widgets/waifu_background.dart';
import '../services/affection_service.dart';

class AnimeRecommenderPage extends StatefulWidget {
  const AnimeRecommenderPage({super.key});
  @override
  State<AnimeRecommenderPage> createState() => _AnimeRecommenderPageState();
}

class _AnimeRecommenderPageState extends State<AnimeRecommenderPage>
    with SingleTickerProviderStateMixin {
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
    _load('Top Anime');
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load(String mode) async {
    setState(() {
      _loading = true;
      _animeList = [];
      _mode = mode;
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A16),
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
                      color: Colors.white.withOpacity(0.06),
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
                    color: Colors.deepPurpleAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.deepPurpleAccent.withOpacity(0.3)),
                  ),
                  child: Text('JikanAPI 🌸',
                      style: GoogleFonts.outfit(
                          color: Colors.deepPurpleAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ),
              ]),
            ),

            // Mode chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: _modes.map((m) {
                  final sel = m == _mode;
                  return GestureDetector(
                    onTap: () => m == 'Search'
                        ? setState(() => _mode = 'Search')
                        : _load(m),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: sel
                            ? Colors.deepPurpleAccent.withOpacity(0.2)
                            : Colors.white.withOpacity(0.04),
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
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.deepPurpleAccent.withOpacity(0.3)),
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
                          hintText: 'Search anime title or genre…',
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
                          color: Colors.deepPurpleAccent.withOpacity(0.2),
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
                  ? const Center(
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.deepPurpleAccent))
                  : _animeList.isEmpty
                      ? Center(
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                              const Text('🌸', style: TextStyle(fontSize: 48)),
                              const SizedBox(height: 12),
                              Text('No results found',
                                  style: GoogleFonts.outfit(
                                      color: Colors.white38)),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () => _load('Top Anime'),
                                child: Text('Show Top Anime',
                                    style: GoogleFonts.outfit(
                                        color: Colors.deepPurpleAccent,
                                        fontWeight: FontWeight.w700)),
                              ),
                            ]))
                      : FadeTransition(
                          opacity: _fadeCtrl,
                          child: GridView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.62,
                            ),
                            itemCount: _animeList.length,
                            itemBuilder: (ctx, i) =>
                                _buildAnimeCard(_animeList[i]),
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
          color: Colors.white.withOpacity(0.04),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Cover image
          Expanded(
            child: Stack(children: [
              anime['image'] != null && anime['image'].isNotEmpty
                  ? Image.network(anime['image'],
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                            color: Colors.deepPurpleAccent.withOpacity(0.1),
                            child: const Center(
                                child:
                                    Text('🌸', style: TextStyle(fontSize: 40))),
                          ))
                  : Container(
                      color: Colors.deepPurpleAccent.withOpacity(0.1),
                      child: const Center(
                          child: Text('🌸', style: TextStyle(fontSize: 40))),
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
                        color: Colors.deepPurpleAccent.withOpacity(0.8),
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
      backgroundColor: const Color(0xFF12121E),
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
                    child: Image.network(anime['image'],
                        width: 90, height: 130, fit: BoxFit.cover)),
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
                                        .withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: Colors.deepPurpleAccent
                                            .withOpacity(0.3)),
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
