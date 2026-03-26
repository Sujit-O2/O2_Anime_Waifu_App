import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Anime Calendar — shows which anime airs on each day of the week.
/// Uses Jikan API schedules endpoint.
class AnimeCalendarPage extends StatefulWidget {
  const AnimeCalendarPage({super.key});
  @override
  State<AnimeCalendarPage> createState() => _AnimeCalendarPageState();
}

class _AnimeCalendarPageState extends State<AnimeCalendarPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final Map<String, List<Map<String, dynamic>>> _schedule = {};
  bool _loading = true;

  static const List<String> _days = [
    'monday', 'tuesday', 'wednesday', 'thursday',
    'friday', 'saturday', 'sunday'
  ];
  static const List<String> _dayLabels = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  ];

  @override
  void initState() {
    super.initState();
    final todayIndex = DateTime.now().weekday - 1;
    _tabCtrl = TabController(length: 7, vsync: this, initialIndex: todayIndex);
    _loadSchedule();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSchedule() async {
    setState(() => _loading = true);
    try {
      for (final day in _days) {
        final resp = await http.get(
          Uri.parse('https://api.jikan.moe/v4/schedules?filter=$day&limit=20'),
          headers: {'User-Agent': 'AnimeWaifuApp/3.0'},
        ).timeout(const Duration(seconds: 10));
        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body)['data'] as List? ?? [];
          _schedule[day] = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
        await Future.delayed(const Duration(milliseconds: 350)); // Rate limit
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final todayIndex = DateTime.now().weekday - 1;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        title: const Text('📅 Anime Calendar',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              Colors.indigo.withValues(alpha: 0.5),
              Colors.black.withValues(alpha: 0.95),
            ]),
          ),
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          indicatorColor: Colors.indigo,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: List.generate(7, (i) => Tab(
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(_dayLabels[i]),
              if (i == todayIndex)
                Container(
                  margin: const EdgeInsets.only(left: 4),
                  width: 6, height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.greenAccent, shape: BoxShape.circle),
                ),
            ]),
          )),
        ),
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
        : TabBarView(
            controller: _tabCtrl,
            children: _days.map((day) => _buildDayList(day)).toList(),
          ),
    );
  }

  Widget _buildDayList(String day) {
    final anime = _schedule[day] ?? [];
    if (anime.isEmpty) {
      return Center(child: Text('No anime scheduled',
        style: TextStyle(color: Colors.grey.shade600)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: anime.length,
      itemBuilder: (_, i) {
        final a = anime[i];
        final cover = a['images']?['jpg']?['image_url'] ?? '';
        final title = a['title'] as String? ?? 'Unknown';
        final score = a['score']?.toString() ?? '';
        final eps = a['episodes']?.toString() ?? '?';

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            tileColor: Colors.white.withValues(alpha: 0.04),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: cover.isNotEmpty
                ? Image.network(cover, width: 45, height: 65, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 45, height: 65, color: Colors.grey.shade900))
                : Container(width: 45, height: 65, color: Colors.grey.shade900),
            ),
            title: Text(title,
              style: const TextStyle(color: Colors.white, fontSize: 13,
                  fontWeight: FontWeight.w600),
              maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: Row(children: [
              if (score.isNotEmpty && score != 'null') ...[
                const Icon(Icons.star, color: Colors.amber, size: 12),
                Text(' $score', style: TextStyle(
                    color: Colors.grey.shade500, fontSize: 11)),
                const SizedBox(width: 8),
              ],
              Text('$eps ep', style: TextStyle(
                  color: Colors.grey.shade600, fontSize: 11)),
            ]),
            trailing: const Icon(Icons.live_tv, color: Colors.indigo, size: 20),
          ),
        );
      },
    );
  }
}
