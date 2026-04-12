import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:anime_waifu/widgets/app_cached_image.dart';
import 'package:anime_waifu/widgets/waifu_background.dart';

/// Anime Calendar v2 — Weekly airing schedule with dark glass cards,
/// today indicator, score badges, staggered animations, and haptics.
class AnimeCalendarPage extends StatefulWidget {
  const AnimeCalendarPage({super.key});
  @override
  State<AnimeCalendarPage> createState() => _AnimeCalendarPageState();
}

class _AnimeCalendarPageState extends State<AnimeCalendarPage>
    with TickerProviderStateMixin {
  late TabController _tabCtrl;
  late AnimationController _fadeCtrl;
  final Map<String, List<Map<String, dynamic>>> _schedule = {};
  bool _loading = true;

  static const _days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _dayEmojis = ['🌙', '🔥', '💧', '🌿', '⚡', '🌸', '☀️'];

  @override
  void initState() {
    super.initState();
    final todayIndex = DateTime.now().weekday - 1;
    _tabCtrl = TabController(length: 7, vsync: this, initialIndex: todayIndex);
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
    _loadSchedule();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _fadeCtrl.dispose();
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
        await Future.delayed(const Duration(milliseconds: 350));
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  int get _totalAiring => _schedule.values.fold(0, (sum, list) => sum + list.length);

  @override
  Widget build(BuildContext context) {
    final todayIndex = DateTime.now().weekday - 1;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: WaifuBackground(
        opacity: 0.06,
        tint: const Color(0xFF060A14),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeCtrl,
            child: Column(children: [
              // ── Header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white12)),
                      child: const Icon(Icons.arrow_back_ios_new, color: Colors.white60, size: 16)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('ANIME CALENDAR', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                    Text('$_totalAiring anime airing this week', style: GoogleFonts.outfit(color: Colors.indigoAccent.withValues(alpha: 0.7), fontSize: 10)),
                  ])),
                  GestureDetector(
                    onTap: () { HapticFeedback.lightImpact(); _loadSchedule(); },
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white12)),
                      child: const Icon(Icons.refresh, color: Colors.white60, size: 18)),
                  ),
                ]),
              ),

              // ── Day Tabs ──
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
                child: TabBar(
                  controller: _tabCtrl,
                  isScrollable: true,
                  indicatorColor: Colors.indigoAccent,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white38,
                  labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 12),
                  tabs: List.generate(7, (i) => Tab(
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('${_dayEmojis[i]} ${_dayLabels[i]}'),
                      if (i == todayIndex)
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          width: 6, height: 6,
                          decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
                        ),
                    ]),
                  )),
                ),
              ),

              // ── Content ──
              Expanded(
                child: _loading
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const CircularProgressIndicator(color: Colors.indigoAccent),
                      const SizedBox(height: 12),
                      Text('Loading schedule...', style: GoogleFonts.outfit(color: Colors.white30, fontSize: 12)),
                    ]))
                  : TabBarView(
                      controller: _tabCtrl,
                      children: _days.map((day) => _buildDayList(day)).toList(),
                    ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildDayList(String day) {
    final anime = _schedule[day] ?? [];
    if (anime.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('📺', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        Text('No anime scheduled', style: GoogleFonts.outfit(color: Colors.white30, fontSize: 14)),
        const SizedBox(height: 4),
        Text('Check other days~', style: GoogleFonts.outfit(color: Colors.white24, fontSize: 11)),
      ]));
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
        final genres = (a['genres'] as List?)?.map((g) => g['name']?.toString() ?? '').take(2).join(', ') ?? '';

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 300 + i * 50),
          curve: Curves.easeOut,
          builder: (_, val, child) => Opacity(opacity: val, child: Transform.translate(offset: Offset(0, 12 * (1 - val)), child: child)),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.indigoAccent.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.indigoAccent.withValues(alpha: 0.15)),
            ),
            child: Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: cover.isNotEmpty
                  ? AppCachedImage(url: cover, width: 50, height: 70, fit: BoxFit.cover)
                  : Container(width: 50, height: 70, color: Colors.grey.shade900),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Row(children: [
                  if (score.isNotEmpty && score != 'null') ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(color: Colors.amberAccent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.star, color: Colors.amberAccent, size: 10),
                        const SizedBox(width: 2),
                        Text(score, style: GoogleFonts.outfit(color: Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text('$eps ep', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 10)),
                ]),
                if (genres.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(genres, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.outfit(color: Colors.white24, fontSize: 9)),
                ],
              ])),
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(color: Colors.indigoAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.live_tv, color: Colors.indigoAccent, size: 16),
              ),
            ]),
          ),
        );
      },
    );
  }
}



