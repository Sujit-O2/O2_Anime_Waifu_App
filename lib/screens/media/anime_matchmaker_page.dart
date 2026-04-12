import 'dart:convert';

import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnimeMatchmakerPage extends StatefulWidget {
  const AnimeMatchmakerPage({super.key});

  @override
  State<AnimeMatchmakerPage> createState() => _AnimeMatchmakerPageState();
}

class _AnimeMatchmakerPageState extends State<AnimeMatchmakerPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  final List<Map<String, dynamic>> _matches = <Map<String, dynamic>>[
    <String, dynamic>{
      'name': 'Kira',
      'avatar': 'L',
      'similarity': 94,
      'common': <String>['Death Note', 'Code Geass', 'Monster'],
      'bio':
          'Strategic thriller addict looking for someone who loves mind games.',
      'energy': 'Intense',
    },
    <String, dynamic>{
      'name': 'Gintoki Fan',
      'avatar': 'S',
      'similarity': 88,
      'common': <String>['Gintama', 'Jujutsu Kaisen', 'One Punch Man'],
      'bio': 'Comedy first, chaos second, strawberry milk always.',
      'energy': 'Chaotic',
    },
    <String, dynamic>{
      'name': 'El Psy Kongroo',
      'avatar': 'M',
      'similarity': 82,
      'common': <String>['Steins;Gate', 'Re:Zero', 'Erased'],
      'bio': 'Sci-fi soulmate hunting for another timeline traveler.',
      'energy': 'Brainy',
    },
    <String, dynamic>{
      'name': 'Nakama',
      'avatar': 'N',
      'similarity': 76,
      'common': <String>['One Piece', 'Naruto', 'Bleach'],
      'bio': 'Big shonen heart, loyal to the crew, always ready to binge.',
      'energy': 'Warm',
    },
  ];

  final Set<String> _requested = <String>{};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..forward();
    _restoreRequests();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _restoreRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('anime_matchmaker_requests_v2');
    if (raw == null || !mounted) {
      return;
    }
    final decoded = (jsonDecode(raw) as List<dynamic>)
        .map((item) => item.toString())
        .toSet();
    setState(() => _requested.addAll(decoded));
  }

  Future<void> _saveRequests() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'anime_matchmaker_requests_v2',
      jsonEncode(_requested.toList()),
    );
  }

  Future<void> _refresh() async {
    HapticFeedback.selectionClick();
    await _restoreRequests();
  }

  List<Map<String, dynamic>> get _filteredMatches {
    if (_searchQuery.isEmpty) {
      return _matches;
    }
    return _matches.where((match) {
      final query = _searchQuery.toLowerCase();
      final common = (match['common'] as List<String>).join(' ').toLowerCase();
      return match['name'].toString().toLowerCase().contains(query) ||
          match['bio'].toString().toLowerCase().contains(query) ||
          common.contains(query);
    }).toList();
  }

  Future<void> _sendRequest(Map<String, dynamic> match) async {
    final name = match['name'].toString();
    HapticFeedback.mediumImpact();
    setState(() => _requested.add(name));
    await _saveRequests();
    if (mounted) {
      showSuccessSnackbar(context, 'Match request sent to $name');
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredMatches;
    final averageSimilarity = _matches.isEmpty
        ? 0
        : (_matches
                    .map((match) => match['similarity'] as int)
                    .reduce((a, b) => a + b) /
                _matches.length)
            .round();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0A13),
      body: WaifuBackground(
        opacity: 0.06,
        tint: const Color(0xFF0E0914),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeCtrl,
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
                              'ANIME MATCHMAKER',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.4,
                              ),
                            ),
                            Text(
                              'Find your next binge soulmate',
                              style: GoogleFonts.outfit(
                                color: Colors.pinkAccent.withValues(alpha: 0.7),
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
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: V2SearchBar(
                    hintText: 'Search by vibe, anime, or name...',
                    onChanged: (value) =>
                        setState(() => _searchQuery = value.trim()),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: _statCard(
                          'Profiles',
                          '${_matches.length}',
                          Colors.pinkAccent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _statCard(
                          'Avg Match',
                          '$averageSimilarity%',
                          Colors.greenAccent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _statCard(
                          'Sent',
                          '${_requested.length}',
                          Colors.cyanAccent,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),

                ),
                const SizedBox(height: 12),
                Expanded(
                  child: filtered.isEmpty
                      ? EmptyState(
                          icon: Icons.favorite_border_rounded,
                          title: 'No matches found',
                          subtitle:
                              'Try another anime title or interest and I will keep searching, darling.',
                          buttonText: 'Clear Search',
                          onButtonPressed: () =>
                              setState(() => _searchQuery = ''),
                        )
                      : RefreshIndicator(
                          onRefresh: _refresh,
                          color: Colors.pinkAccent,
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final match = filtered[index];
                              return AnimatedEntry(
                                index: index,
                                child: _matchCard(match),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
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

  Widget _matchCard(Map<String, dynamic> match) {
    final name = match['name'].toString();
    final requested = _requested.contains(name);
    final common = (match['common'] as List<String>).cast<String>();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white12,
                child: Text(
                  match['avatar'].toString(),
                  style: const TextStyle(fontSize: 20, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      name,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      match['bio'].toString(),
                      style: GoogleFonts.outfit(
                        color: Colors.white60,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  '${match['similarity']}%',
                  style: GoogleFonts.outfit(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: common
                .map(
                  (anime) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.pinkAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      anime,
                      style: GoogleFonts.outfit(
                        color: Colors.pinkAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '${match['energy']} energy',
                  style: GoogleFonts.outfit(
                    color: Colors.white38,
                    fontSize: 11,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: requested ? null : () => _sendRequest(match),
                icon: Icon(
                  requested ? Icons.check_rounded : Icons.favorite_rounded,
                ),
                label: Text(requested ? 'Sent' : 'Match & Chat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      requested ? Colors.white12 : Colors.pinkAccent,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}



