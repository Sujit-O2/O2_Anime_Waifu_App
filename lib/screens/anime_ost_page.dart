import 'dart:convert';
import 'package:flutter/material.dart';
import '../widgets/app_cached_image.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

/// Anime OST Player — browse anime openings/endings and play via YouTube.
class AnimeOstPage extends StatefulWidget {
  const AnimeOstPage({super.key});
  @override
  State<AnimeOstPage> createState() => _AnimeOstPageState();
}

class _AnimeOstPageState extends State<AnimeOstPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  Map<String, List<String>> _openings = {};
  Map<String, List<String>> _endings = {};
  bool _loading = false;
  String? _selectedAnimeId;
  String? _selectedTitle;
  bool _loadingThemes = false;

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      final q = Uri.encodeQueryComponent(query);
      final resp = await http.get(
        Uri.parse('https://api.jikan.moe/v4/anime?q=$q&limit=10'),
        headers: {'User-Agent': 'AnimeWaifuApp/3.0'},
      ).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body)['data'] as List;
        if (mounted) setState(() {
          _results = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadThemes(String malId, String title) async {
    setState(() {
      _loadingThemes = true;
      _selectedAnimeId = malId;
      _selectedTitle = title;
    });
    try {
      final resp = await http.get(
        Uri.parse('https://api.jikan.moe/v4/anime/$malId/themes'),
        headers: {'User-Agent': 'AnimeWaifuApp/3.0'},
      ).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body)['data'] as Map<String, dynamic>;
        final openings = (data['openings'] as List?)?.cast<String>() ?? [];
        final endings = (data['endings'] as List?)?.cast<String>() ?? [];
        if (mounted) setState(() {
          _openings[malId] = openings;
          _endings[malId] = endings;
          _loadingThemes = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingThemes = false);
    }
  }

  void _playOnYouTube(String songTitle) {
    final q = Uri.encodeQueryComponent('$songTitle anime opening full');
    launchUrl(Uri.parse('https://www.youtube.com/results?search_query=$q'),
        mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('🎵 Anime OST',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              Colors.teal.withValues(alpha: 0.5),
              Colors.black.withValues(alpha: 0.95),
            ]),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white),
              onSubmitted: _search,
              decoration: InputDecoration(
                hintText: 'Search anime for OST...',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                prefixIcon: const Icon(Icons.music_note, color: Colors.teal),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search, color: Colors.teal),
                  onPressed: () => _search(_searchCtrl.text),
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Results / Themes
          Expanded(
            child: _loading
              ? const Center(child: CircularProgressIndicator(color: Colors.teal))
              : _selectedAnimeId != null
                ? _buildThemesView()
                : _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_results.isEmpty) {
      return Center(child: Text('Search for an anime to see its openings & endings',
        style: TextStyle(color: Colors.grey.shade600), textAlign: TextAlign.center));
    }

    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (_, i) {
        final a = _results[i];
        final cover = a['images']?['jpg']?['image_url'] ?? '';
        final title = a['title'] as String? ?? 'Unknown';
        final malId = '${a['mal_id']}';

        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: cover.isNotEmpty
              ? AppCachedImage(url: cover, width: 50, height: 70)
              : Container(width: 50, height: 70, color: Colors.grey.shade900),
          ),
          title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
          subtitle: Text('${a['episodes'] ?? '?'} episodes',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          trailing: const Icon(Icons.library_music, color: Colors.teal),
          onTap: () => _loadThemes(malId, title),
        );
      },
    );
  }

  Widget _buildThemesView() {
    final ops = _openings[_selectedAnimeId] ?? [];
    final eds = _endings[_selectedAnimeId] ?? [];

    return Column(
      children: [
        // Back button + title
        ListTile(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => setState(() => _selectedAnimeId = null),
          ),
          title: Text(_selectedTitle ?? '',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),

        if (_loadingThemes)
          const Expanded(child: Center(
              child: CircularProgressIndicator(color: Colors.teal)))
        else
          Expanded(child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              if (ops.isNotEmpty) ...[
                _sectionHeader('🎬 Openings'),
                ...ops.map((op) => _songTile(op, Colors.teal)),
              ],
              if (eds.isNotEmpty) ...[
                const SizedBox(height: 16),
                _sectionHeader('🌙 Endings'),
                ...eds.map((ed) => _songTile(ed, Colors.indigo)),
              ],
              if (ops.isEmpty && eds.isEmpty)
                Center(child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Text('No themes found for this anime',
                    style: TextStyle(color: Colors.grey.shade600)),
                )),
            ],
          )),
      ],
    );
  }

  Widget _sectionHeader(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(
      color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
  );

  Widget _songTile(String song, Color color) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      tileColor: color.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Icon(Icons.play_circle_fill, color: color, size: 32),
      title: Text(song, style: const TextStyle(color: Colors.white, fontSize: 13)),
      trailing: IconButton(
        icon: const Icon(Icons.open_in_new, color: Colors.white54, size: 20),
        onPressed: () => _playOnYouTube(song),
      ),
      onTap: () => _playOnYouTube(song),
    ),
  );
}
