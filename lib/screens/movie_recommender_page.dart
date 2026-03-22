import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/free_apis_service.dart';
import '../widgets/waifu_background.dart';

class MovieRecommenderPage extends StatefulWidget {
  const MovieRecommenderPage({super.key});
  @override
  State<MovieRecommenderPage> createState() => _MovieRecommenderPageState();
}

class _MovieRecommenderPageState extends State<MovieRecommenderPage>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _movies = [];
  bool _loading = false;
  String _selectedGenre = 'Action';
  final _searchCtrl = TextEditingController();
  late AnimationController _fadeCtrl;

  static const _genres = [
    'Action',
    'Romance',
    'Comedy',
    'Sci-Fi',
    'Horror',
    'Drama',
    'Fantasy',
    'Sports'
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _load('action anime');
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load(String query) async {
    setState(() {
      _loading = true;
      _movies = [];
    });
    _fadeCtrl.reset();
    try {
      // Use JikanAPI: search anime movies
      final results = await FreeApisService.instance.searchAnimeMovies(query);
      if (mounted) {
        setState(() => _movies = results);
        _fadeCtrl.forward();
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A16),
      body: WaifuBackground(
        opacity: 0.10,
        tint: const Color(0xFF070A14),
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
                child: Text('MOVIE & ANIME',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5)),
              ),
              const Text('🎬', style: TextStyle(fontSize: 22)),
            ]),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
              ),
              child: Row(children: [
                const SizedBox(width: 12),
                const Icon(Icons.search_rounded,
                    color: Colors.purpleAccent, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    style:
                        GoogleFonts.outfit(color: Colors.white, fontSize: 14),
                    cursorColor: Colors.purpleAccent,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Search anime movies…',
                      hintStyle: GoogleFonts.outfit(
                          color: Colors.white30, fontSize: 13),
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: (q) => _load(q.trim()),
                  ),
                ),
                GestureDetector(
                  onTap: () => _load(_searchCtrl.text.trim()),
                  child: Container(
                    margin: const EdgeInsets.all(6),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.purpleAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('GO',
                        style: GoogleFonts.outfit(
                            color: Colors.purpleAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
              ]),
            ),
          ),

          // Genre chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(
              children: _genres.map((g) {
                final sel = g == _selectedGenre;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedGenre = g);
                    _load('${g.toLowerCase()} anime movie');
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: sel
                          ? Colors.purpleAccent.withOpacity(0.18)
                          : Colors.white.withOpacity(0.04),
                      border: Border.all(
                          color: sel ? Colors.purpleAccent : Colors.white12),
                    ),
                    child: Text(g,
                        style: GoogleFonts.outfit(
                            color: sel ? Colors.purpleAccent : Colors.white54,
                            fontSize: 12,
                            fontWeight:
                                sel ? FontWeight.w700 : FontWeight.w500)),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 10),

          // Results
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.purpleAccent))
                : _movies.isEmpty
                    ? Center(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                            const Text('🎬', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 12),
                            Text('No results found',
                                style:
                                    GoogleFonts.outfit(color: Colors.white38)),
                          ]))
                    : FadeTransition(
                        opacity: _fadeCtrl,
                        child: GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.65,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                          ),
                          itemCount: _movies.length,
                          itemBuilder: (ctx, i) => _buildCard(_movies[i]),
                        ),
                      ),
          ),
        ])),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> movie) {
    return GestureDetector(
      onTap: () => _showDetail(movie),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withOpacity(0.04),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Poster
          Expanded(
            child: movie['image']?.isNotEmpty == true
                ? Image.network(
                    movie['image'],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.purpleAccent.withOpacity(0.1),
                      child: const Center(
                          child: Text('🎬', style: TextStyle(fontSize: 40))),
                    ),
                  )
                : Container(
                    color: Colors.purpleAccent.withOpacity(0.1),
                    child: const Center(
                        child: Text('🎬', style: TextStyle(fontSize: 40))),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                movie['title'] ?? '',
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              if (movie['score'] != null && movie['score'] != 0.0)
                Row(children: [
                  const Icon(Icons.star_rounded,
                      color: Colors.amberAccent, size: 12),
                  const SizedBox(width: 3),
                  Text(
                    (movie['score'] as double).toStringAsFixed(1),
                    style: GoogleFonts.outfit(
                        color: Colors.amberAccent, fontSize: 11),
                  ),
                ]),
            ]),
          ),
        ]),
      ),
    );
  }

  void _showDetail(Map<String, dynamic> movie) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF12121E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        builder: (ctx, ctrl) => SingleChildScrollView(
          controller: ctrl,
          padding: const EdgeInsets.all(20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (movie['image']?.isNotEmpty == true)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    movie['image'],
                    width: 100,
                    height: 140,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(movie['title'] ?? '',
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      if ((movie['score'] as double?) != null &&
                          movie['score'] != 0.0)
                        Row(children: [
                          const Icon(Icons.star_rounded,
                              color: Colors.amberAccent, size: 16),
                          const SizedBox(width: 4),
                          Text((movie['score'] as double).toStringAsFixed(1),
                              style: GoogleFonts.outfit(
                                  color: Colors.amberAccent, fontSize: 14)),
                        ]),
                      const SizedBox(height: 6),
                      if ((movie['genres'] as List?)?.isNotEmpty == true)
                        Wrap(
                          spacing: 5,
                          runSpacing: 4,
                          children: ((movie['genres'] as List?) ?? [])
                              .take(3)
                              .map<Widget>(
                                (g) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.purpleAccent.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: Colors.purpleAccent
                                            .withOpacity(0.3)),
                                  ),
                                  child: Text(g,
                                      style: GoogleFonts.outfit(
                                          color: Colors.purpleAccent,
                                          fontSize: 10)),
                                ),
                              )
                              .toList(),
                        ),
                    ]),
              ),
            ]),
            const SizedBox(height: 16),
            if ((movie['synopsis'] as String?)?.isNotEmpty == true) ...[
              Text('Synopsis',
                  style: GoogleFonts.outfit(
                      color: Colors.white60,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(movie['synopsis'],
                  style: GoogleFonts.outfit(
                      color: Colors.white70, fontSize: 13, height: 1.6)),
            ],
          ]),
        ),
      ),
    );
  }
}
