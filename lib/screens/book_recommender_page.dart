import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/free_apis_service.dart';
import '../widgets/waifu_background.dart';
import '../services/affection_service.dart';

class BookRecommenderPage extends StatefulWidget {
  const BookRecommenderPage({super.key});
  @override
  State<BookRecommenderPage> createState() => _BookRecommenderPageState();
}

class _BookRecommenderPageState extends State<BookRecommenderPage>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _books = [];
  bool _loading = false;
  final _searchCtrl = TextEditingController();
  String _selectedGenre = 'Romance';
  late AnimationController _fadeCtrl;

  static const _genres = [
    'Romance',
    'Fantasy',
    'Anime',
    'Manga',
    'Adventure',
    'Mystery',
    'Sci-Fi',
    'Drama'
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _searchBooks('romance love story');
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _searchBooks(String query) async {
    setState(() {
      _loading = true;
      _books = [];
    });
    _fadeCtrl.reset();
    try {
      final results =
          await FreeApisService.instance.searchBooks(query, limit: 10);
      if (mounted) {
        setState(() => _books = results);
        _fadeCtrl.forward();
        AffectionService.instance.addPoints(1);
      }
    } catch (_) {
      if (mounted) setState(() => _books = []);
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
                child: Text('BOOK PICKS',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5)),
              ),
              const Text('📚', style: TextStyle(fontSize: 22)),
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
                border: Border.all(color: Colors.amberAccent.withOpacity(0.3)),
              ),
              child: Row(children: [
                const SizedBox(width: 12),
                const Icon(Icons.search_rounded,
                    color: Colors.amberAccent, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    style:
                        GoogleFonts.outfit(color: Colors.white, fontSize: 14),
                    cursorColor: Colors.amberAccent,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Search any book or author…',
                      hintStyle: GoogleFonts.outfit(
                          color: Colors.white30, fontSize: 13),
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: (q) => _searchBooks(q.trim()),
                  ),
                ),
                GestureDetector(
                  onTap: () => _searchBooks(_searchCtrl.text.trim()),
                  child: Container(
                    margin: const EdgeInsets.all(6),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amberAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('GO',
                        style: GoogleFonts.outfit(
                            color: Colors.amberAccent,
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
                  _searchBooks(g.toLowerCase());
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: sel
                        ? Colors.amberAccent.withOpacity(0.18)
                        : Colors.white.withOpacity(0.04),
                    border: Border.all(
                        color: sel ? Colors.amberAccent : Colors.white12),
                  ),
                  child: Text(g,
                      style: GoogleFonts.outfit(
                          color: sel ? Colors.amberAccent : Colors.white54,
                          fontSize: 12,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.w500)),
                ),
              );
            }).toList()),
          ),

          const SizedBox(height: 10),

          // Books list
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.amberAccent))
                : _books.isEmpty
                    ? Center(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                            const Text('📚', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 12),
                            Text('No books found',
                                style:
                                    GoogleFonts.outfit(color: Colors.white38)),
                          ]))
                    : FadeTransition(
                        opacity: _fadeCtrl,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: _books.length,
                          itemBuilder: (ctx, i) => _buildBookCard(_books[i]),
                        ),
                      ),
          ),
        ])),
      ),
    );
  }

  Widget _buildBookCard(Map<String, dynamic> book) {
    return GestureDetector(
      onTap: () => HapticFeedback.selectionClick(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withOpacity(0.04),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Cover
          Container(
            width: 64,
            height: 90,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
            clipBehavior: Clip.antiAlias,
            child: book['cover'] != null
                ? Image.network(book['cover'],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                          color: Colors.amberAccent.withOpacity(0.1),
                          child: const Center(
                              child:
                                  Text('📖', style: TextStyle(fontSize: 28))),
                        ))
                : Container(
                    color: Colors.amberAccent.withOpacity(0.1),
                    child: const Center(
                        child: Text('📖', style: TextStyle(fontSize: 28))),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(book['title'] ?? 'Unknown',
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text('by ${book['author'] ?? 'Unknown'}',
                  style: GoogleFonts.outfit(
                      color: Colors.amberAccent.withOpacity(0.8), fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              if (book['year'] != null && book['year'] != '?') ...[
                const SizedBox(height: 2),
                Text('Published ${book['year']}',
                    style: GoogleFonts.outfit(
                        color: Colors.white38, fontSize: 11)),
              ],
              if ((book['subjects'] as List?)?.isNotEmpty == true) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: ((book['subjects'] as List?)?.take(3) ?? [])
                      .map((s) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amberAccent.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                                s.toString().length > 20
                                    ? '${s.toString().substring(0, 20)}…'
                                    : s.toString(),
                                style: GoogleFonts.outfit(
                                    color: Colors.amberAccent.withOpacity(0.6),
                                    fontSize: 10)),
                          ))
                      .toList(),
                ),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}
