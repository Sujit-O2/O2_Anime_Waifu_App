import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:anime_waifu/widgets/app_cached_image.dart';
import 'package:anime_waifu/core/v2_upgrade_kit.dart';

/// Character Database — view characters and voice actors for any anime.
/// Uses Jikan API anime/{id}/characters endpoint.
class CharacterDatabasePage extends StatefulWidget {
  final String animeId;
  final String animeTitle;
  const CharacterDatabasePage({
    super.key,
    required this.animeId,
    required this.animeTitle,
  });
  @override
  State<CharacterDatabasePage> createState() => _CharacterDatabasePageState();
}

class _CharacterDatabasePageState extends State<CharacterDatabasePage>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _characters = [];
  List<Map<String, dynamic>> _filteredCharacters = [];
  bool _loading = true;
  Map<String, dynamic>? _favoriteCharacter;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _load();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'characters_${widget.animeId}';
    final cachedData = prefs.getString(cacheKey);

    if (!forceRefresh && cachedData != null) {
      try {
        final data = jsonDecode(cachedData) as List;
        if (mounted) {
          setState(() {
            _characters = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
            _filteredCharacters = _characters;
            _loading = false;
          });
        }
        _animationController.forward();
        return;
      } catch (_) {}
    }

    try {
      final resp = await http.get(
        Uri.parse('https://api.jikan.moe/v4/anime/${widget.animeId}/characters'),
        headers: {'User-Agent': 'AnimeWaifuApp/3.0'},
      ).timeout(const Duration(seconds: 12));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body)['data'] as List? ?? [];
        final characters = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        await prefs.setString(cacheKey, jsonEncode(data));
        if (mounted) {
          setState(() {
            _characters = characters;
            _filteredCharacters = characters;
            _loading = false;
          });
        }
        _animationController.forward();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _filterCharacters(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCharacters = _characters;
      } else {
        _filteredCharacters = _characters.where((char) {
          final name = char['character']?['name']?.toString().toLowerCase() ?? '';
          final role = char['role']?.toString().toLowerCase() ?? '';
          return name.contains(query.toLowerCase()) || role.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _onRefresh() async {
    await _load(forceRefresh: true);
  }

  void _setFavorite(Map<String, dynamic> character) {
    setState(() {
      _favoriteCharacter = character;
    });
  }

  Map<String, int> _getRoleStatistics() {
    final stats = <String, int>{};
    for (final char in _characters) {
      final role = char['role'] as String? ?? 'Unknown';
      stats[role] = (stats[role] ?? 0) + 1;
    }
    return stats;
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 10,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey.shade800,
        highlightColor: Colors.grey.shade600,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleChart(Map<String, int> stats) {
    final sections = stats.entries.map((entry) {
      final color = entry.key == 'Main' ? Colors.deepOrange : Colors.blue;
      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: '${entry.key}\n${entry.value}',
        color: color,
        radius: 50,
        titleStyle: const TextStyle(color: Colors.white, fontSize: 12),
      );
    }).toList();

    return PieChart(
      PieChartData(
        sections: sections,
        sectionsSpace: 2,
        centerSpaceRadius: 40,
      ),
    );
  }

  Widget _buildAiCommentary(Map<String, dynamic> character) {
    final name = character['character']?['name'] ?? 'Unknown';
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('AI Commentary on $name',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'This character plays a crucial role in the story. Their personality and actions drive the plot forward in fascinating ways.',
            style: TextStyle(color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roleStats = _getRoleStatistics();

    return FeaturePageV2(
      title: 'CHARACTER DATABASE',
      onBack: () => Navigator.pop(context),
      content: RefreshIndicator(
        onRefresh: _onRefresh,
        color: V2Theme.primaryColor,
        child: _loading
          ? _buildShimmerLoading()
          : _characters.isEmpty
            ? Center(child: Text('No character data found',
                style: TextStyle(color: Colors.grey.shade600)))
            : FadeTransition(
                opacity: _fadeAnimation,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: TextField(
                          onChanged: _filterCharacters,
                          decoration: InputDecoration(
                            hintText: 'Search by name or role...',
                            prefixIcon: const Icon(Icons.search, color: Colors.deepOrange),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    if (roleStats.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Container(
                          height: 200,
                          padding: const EdgeInsets.all(12),
                          child: _buildRoleChart(roleStats),
                        ),
                      ),
                    if (_favoriteCharacter != null)
                      SliverToBoxAdapter(
                        child: _buildAiCommentary(_favoriteCharacter!),
                      ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => _CharacterTile(
                          data: _filteredCharacters[i],
                          index: i,
                          onFavorite: _setFavorite,
                        ),
                        childCount: _filteredCharacters.length,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _CharacterTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final int index;
  final Function(Map<String, dynamic>) onFavorite;
  const _CharacterTile({
    required this.data,
    required this.index,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final char = data['character'] as Map<String, dynamic>? ?? {};
    final role = data['role'] as String? ?? '';
    final name = char['name'] as String? ?? 'Unknown';
    final charImage = char['images']?['jpg']?['image_url'] ?? '';

    // Voice actors
    final voiceActors = data['voice_actors'] as List? ?? [];
    final jpVA = voiceActors.map((e) => Map<String, dynamic>.from(e as Map)).where(
      (va) => va['language'] == 'Japanese').toList();

    return AnimatedEntry(
      index: index,
      child: GestureDetector(
        onTap: () => onFavorite(data),
        child: GlassCard(
          margin: const EdgeInsets.only(bottom: 10),
          glow: role == 'Main',
          child: Row(
            children: [
              // Character image
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AppCachedImage(url: charImage, width: 55, height: 75, borderRadius: 10),
              ),
              const SizedBox(width: 12),

              // Character info
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: role == 'Main'
                          ? V2Theme.primaryColor.withValues(alpha: 0.2)
                          : Colors.grey.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(role, style: TextStyle(
                      color: role == 'Main' ? V2Theme.primaryColor : Colors.grey.shade500,
                      fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                  if (jpVA.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(children: [
                      Icon(Icons.mic, color: Colors.grey.shade600, size: 12),
                      const SizedBox(width: 4),
                      Expanded(child: Text(
                        jpVA[0]['person']?['name'] ?? '',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      )),
                    ]),
                  ],
                ],
              )),

              // VA image
              if (jpVA.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: () {
                    final vaImg = jpVA[0]['person']?['images']?['jpg']?['image_url'] ?? '';
                    return vaImg.isNotEmpty
                      ? AppCachedImage(url: vaImg, width: 40, height: 55, fit: BoxFit.cover)
                      : const SizedBox.shrink();
                  }(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}



