import 'dart:convert';

import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:anime_waifu/widgets/app_cached_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class AnimeOstPage extends StatefulWidget {
  const AnimeOstPage({super.key});

  @override
  State<AnimeOstPage> createState() => _AnimeOstPageState();
}

class _AnimeOstPageState extends State<AnimeOstPage> with SingleTickerProviderStateMixin {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _results = <Map<String, dynamic>>[];
  final Map<String, List<String>> _openings = <String, List<String>>{};
  final Map<String, List<String>> _endings = <String, List<String>>{};
  bool _loading = false;
  bool _loadingThemes = false;
  String? _selectedAnimeId;
  String? _selectedTitle;
  String? _lastPlayedSong;
  late AnimationController _animCtrl;


  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
    _restoreState();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _restoreState() async {
    final prefs = await SharedPreferences.getInstance();
    final lastQuery = prefs.getString('anime_ost_last_query_v2') ?? '';
    _searchCtrl.text = lastQuery;
    _lastPlayedSong = prefs.getString('anime_ost_last_song_v2');
    _selectedAnimeId = prefs.getString('anime_ost_last_id_v2');
    _selectedTitle = prefs.getString('anime_ost_last_title_v2');
    if (mounted) {
      setState(() {});
    }
    if (lastQuery.isNotEmpty) {
      await _search(lastQuery);
    }
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('anime_ost_last_query_v2', _searchCtrl.text.trim());
    if (_selectedAnimeId != null) {
      await prefs.setString('anime_ost_last_id_v2', _selectedAnimeId!);
    }
    if (_selectedTitle != null) {
      await prefs.setString('anime_ost_last_title_v2', _selectedTitle!);
    }
    if (_lastPlayedSong != null) {
      await prefs.setString('anime_ost_last_song_v2', _lastPlayedSong!);
    }
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _results = <Map<String, dynamic>>[];
        });
      }
      return;
    }

    setState(() => _loading = true);
    try {
      final q = Uri.encodeQueryComponent(query);
      final resp = await http.get(
        Uri.parse('https://api.jikan.moe/v4/anime?q=$q&limit=10'),
        headers: <String, String>{'User-Agent': 'AnimeWaifuApp/3.0'},
      ).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body)['data'] as List<dynamic>;
        if (mounted) {
          setState(() {
            _results = data
                .map((item) => Map<String, dynamic>.from(item as Map))
                .toList();
            _loading = false;
          });
        }
        await _saveState();
        return;
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _loading = false);
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
        headers: <String, String>{'User-Agent': 'AnimeWaifuApp/3.0'},
      ).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body)['data'] as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _openings[malId] =
                (data['openings'] as List<dynamic>? ?? <dynamic>[])
                    .map((item) => item.toString())
                    .toList();
            _endings[malId] = (data['endings'] as List<dynamic>? ?? <dynamic>[])
                .map((item) => item.toString())
                .toList();
            _loadingThemes = false;
          });
        }
        await _saveState();
        return;
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _loadingThemes = false);
    }
  }

  Future<void> _refresh() async {
    final query = _searchCtrl.text.trim();
    if (_selectedAnimeId != null && _selectedTitle != null) {
      await _loadThemes(_selectedAnimeId!, _selectedTitle!);
      return;
    }
    if (query.isNotEmpty) {
      await _search(query);
    }
  }

  Future<void> _playOnYouTube(String songTitle) async {
    final q = Uri.encodeQueryComponent('$songTitle anime opening full');
    setState(() => _lastPlayedSong = songTitle);
    await _saveState();
    await launchUrl(
      Uri.parse('https://www.youtube.com/results?search_query=$q'),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    final openingsCount = _selectedAnimeId == null
        ? 0
        : (_openings[_selectedAnimeId] ?? <String>[]).length;
    final endingsCount = _selectedAnimeId == null
        ? 0
        : (_endings[_selectedAnimeId] ?? <String>[]).length;

    return Scaffold(
      backgroundColor: const Color(0xFF071218),
      body: WaifuBackground(
        opacity: 0.06,
        tint: const Color(0xFF08151A),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(
                  children: <Widget>[
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white70,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'ANIME OST',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.4,
                            ),
                          ),
                          Text(
                            _selectedTitle ??
                                'Openings, endings, and theme hunting',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              color: Colors.tealAccent.withValues(alpha: 0.78),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: TextField(
                  controller: _searchCtrl,
                  style: GoogleFonts.outfit(color: Colors.white),
                  onSubmitted: _search,
                  decoration: InputDecoration(
                    hintText: 'Search anime for OST...',
                    hintStyle: GoogleFonts.outfit(color: Colors.white30),
                    prefixIcon: const Icon(Icons.music_note_rounded,
                        color: Colors.teal),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search, color: Colors.teal),
                      onPressed: () => _search(_searchCtrl.text),
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.06),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: _StatCard(
                        label: 'Results',
                        value: '${_results.length}',
                        color: Colors.tealAccent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatCard(
                        label: 'Openings',
                        value: '$openingsCount',
                        color: Colors.cyanAccent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatCard(
                        label: 'Endings',
                        value: '$endingsCount',
                        color: Colors.indigoAccent,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),

              ),
              if (_lastPlayedSong != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Last launched: $_lastPlayedSong',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.teal),
                      )
                    : RefreshIndicator(
                        onRefresh: _refresh,
                        color: Colors.teal,
                        child: _selectedAnimeId != null
                            ? _buildThemesView()
                            : _buildSearchResults(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_results.isEmpty) {
      return const SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: EmptyState(
          icon: Icons.library_music_outlined,
          title: 'No anime selected yet',
          subtitle:
              'Search for a series and I will line up its openings and endings for you.',
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      itemCount: _results.length,
      itemBuilder: (_, i) {
        final anime = _results[i];
        final cover = anime['images']?['jpg']?['image_url']?.toString() ?? '';
        final title = anime['title']?.toString() ?? 'Unknown';
        final malId = '${anime['mal_id']}';
        return GlassCard(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: cover.isNotEmpty
                  ? AppCachedImage(url: cover, width: 54, height: 74)
                  : Container(
                      width: 54, height: 74, color: Colors.grey.shade900),
            ),
            title: Text(
              title,
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
            ),
            subtitle: Text(
              '${anime['episodes'] ?? '?'} episodes',
              style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11),
            ),
            trailing:
                const Icon(Icons.library_music_rounded, color: Colors.teal),
            onTap: () => _loadThemes(malId, title),
          ),
        );
      },
    );
  }

  Widget _buildThemesView() {
    final openings = _openings[_selectedAnimeId] ?? <String>[];
    final endings = _endings[_selectedAnimeId] ?? <String>[];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: <Widget>[
        GlassCard(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading:
                const Icon(Icons.arrow_back_rounded, color: Colors.white70),
            title: Text(
              _selectedTitle ?? '',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              'Return to search results',
              style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11),
            ),
            onTap: () => setState(() => _selectedAnimeId = null),
          ),
        ),
        if (_loadingThemes)
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Center(
              child: CircularProgressIndicator(color: Colors.teal),
            ),
          )
        else if (openings.isEmpty && endings.isEmpty)
          const EmptyState(
            icon: Icons.music_off_rounded,
            title: 'No themes found',
            subtitle:
                'This anime did not return openings or endings this time. Try another title or refresh later.',
          )
        else ...<Widget>[
          if (openings.isNotEmpty) ...<Widget>[
            _sectionHeader('Openings'),
            ...openings.map((song) => _songTile(song, Colors.teal)),
          ],
          if (endings.isNotEmpty) ...<Widget>[
            const SizedBox(height: 16),
            _sectionHeader('Endings'),
            ...endings.map((song) => _songTile(song, Colors.indigoAccent)),
          ],
        ],
      ],
    );
  }

  Widget _sectionHeader(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Text(
          text,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      );

  Widget _songTile(String song, Color color) => GlassCard(
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.play_circle_fill_rounded, color: color, size: 34),
          title: Text(
            song,
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
          ),
          trailing: IconButton(
            icon:
                const Icon(Icons.open_in_new, color: Colors.white54, size: 20),
            onPressed: () => _playOnYouTube(song),
          ),
          onTap: () => _playOnYouTube(song),
        ),
      );
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      child: Column(
        children: <Widget>[
          Text(
            value,
            style: GoogleFonts.outfit(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.outfit(color: Colors.white38, fontSize: 10),
          ),
        ],
      ),
    );
  }
}



