import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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

class _CharacterDatabasePageState extends State<CharacterDatabasePage> {
  List<Map<String, dynamic>> _characters = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final resp = await http.get(
        Uri.parse('https://api.jikan.moe/v4/anime/${widget.animeId}/characters'),
        headers: {'User-Agent': 'AnimeWaifuApp/3.0'},
      ).timeout(const Duration(seconds: 12));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body)['data'] as List? ?? [];
        if (mounted) setState(() {
          _characters = data.cast<Map<String, dynamic>>();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        title: Text('Characters — ${widget.animeTitle}',
          style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white,
              fontSize: 16)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              Colors.deepOrange.withValues(alpha: 0.5),
              Colors.black.withValues(alpha: 0.95),
            ]),
          ),
        ),
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: Colors.deepOrange))
        : _characters.isEmpty
          ? Center(child: Text('No character data found',
              style: TextStyle(color: Colors.grey.shade600)))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _characters.length,
              itemBuilder: (_, i) => _CharacterTile(data: _characters[i]),
            ),
    );
  }
}

class _CharacterTile extends StatelessWidget {
  final Map<String, dynamic> data;
  const _CharacterTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final char = data['character'] as Map<String, dynamic>? ?? {};
    final role = data['role'] as String? ?? '';
    final name = char['name'] as String? ?? 'Unknown';
    final charImage = char['images']?['jpg']?['image_url'] ?? '';

    // Voice actors
    final voiceActors = data['voice_actors'] as List? ?? [];
    final jpVA = voiceActors.cast<Map<String, dynamic>>().where(
      (va) => va['language'] == 'Japanese').toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: role == 'Main'
              ? Colors.deepOrange.withValues(alpha: 0.3)
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          // Character image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: charImage.isNotEmpty
              ? Image.network(charImage, width: 55, height: 75, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 55, height: 75, color: Colors.grey.shade900,
                    child: const Icon(Icons.person, color: Colors.grey)))
              : Container(width: 55, height: 75, color: Colors.grey.shade900,
                  child: const Icon(Icons.person, color: Colors.grey)),
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
                      ? Colors.deepOrange.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(role, style: TextStyle(
                  color: role == 'Main' ? Colors.deepOrange : Colors.grey.shade500,
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
                  ? Image.network(vaImg, width: 40, height: 55, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink())
                  : const SizedBox.shrink();
              }(),
            ),
        ],
      ),
    );
  }
}
