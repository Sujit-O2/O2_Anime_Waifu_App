import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:anime_waifu/services/user_profile/life_events_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LifeEventsPage extends StatefulWidget {
  const LifeEventsPage({super.key});
  @override
  State<LifeEventsPage> createState() => _LifeEventsPageState();
}

class _LifeEventsPageState extends State<LifeEventsPage>
    with SingleTickerProviderStateMixin {
  LifeEventData? _data;
  List<LifeEvent> _events = [];
  bool _loading = true;
  late AnimationController _sparkCtrl;

  @override
  void initState() {
    super.initState();
    _sparkCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _load();
  }

  @override
  void dispose() {
    _sparkCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final data = await LifeEventsService.instance.loadData();
    final events = await LifeEventsService.instance.loadAllEvents();
    if (mounted) setState(() { _data = data; _events = events; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return FeaturePageV2(
      title: 'YOUR STORY TOGETHER',
      subtitle: 'A timeline of meaningful moments',
      onBack: () => Navigator.pop(context),
      content: _loading ? _buildLoader() : _buildContent(),
    );
  }

  // Header is now handled by FeaturePageV2

  Widget _buildLoader() => const Center(
    child: CircularProgressIndicator(color: Color(0xFFBB52FF), strokeWidth: 2),
  );

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        if (_data != null) ...[
          _buildStatsCard(),
          const SizedBox(height: 16),
          _buildNextMilestone(),
          const SizedBox(height: 20),
        ],
        if (_events.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text('MOMENTS',
                style: GoogleFonts.outfit(
                    color: Colors.white54, fontSize: 11,
                    fontWeight: FontWeight.w800, letterSpacing: 1.5)),
          ),
          ..._events.map((e) => _EventCard(event: e)),
        ] else
          _buildEmptyState(),
      ],
    );
  }

  Widget _buildStatsCard() {
    final days = _data?.daysTogetherTotal ?? 0;
    return AnimatedBuilder(
      animation: _sparkCtrl,
      builder: (_, __) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              const Color(0xFFAA00FF).withValues(alpha: 0.2),
              const Color(0xFFFF4FA8).withValues(alpha: 0.15),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: const Color(0xFFBB52FF).withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFBB52FF).withValues(alpha: 0.15 + _sparkCtrl.value * 0.08),
              blurRadius: 24,
            ),
          ],
        ),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _StatItem(value: '$days', label: 'Days Together', emoji: '📅'),
            _divider(),
            _StatItem(
              value: _data?.firstChatDate != null
                  ? _formatShortDate(_data!.firstChatDate!)
                  : '—',
              label: 'First Chat', emoji: '💬',
            ),
            _divider(),
            _StatItem(
              value: _data?.firstLoveYouDate != null ? '💕' : '—',
              label: '"I love you"', emoji: '',
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _divider() => Container(
    width: 1, height: 40,
    color: Colors.white.withValues(alpha: 0.1),
  );

  Widget _buildNextMilestone() {
    final days = _data?.daysTogetherTotal ?? 0;
    final milestones = [7, 14, 30, 50, 100, 200, 365];
    final next = milestones.firstWhere((m) => m > days, orElse: () => -1);
    if (next == -1) return const SizedBox.shrink();
    final daysLeft = next - days;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFFFFD700).withValues(alpha: 0.08),
        border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        const Text('🎯', style: TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Next: Day $next Milestone',
                style: GoogleFonts.outfit(
                    color: const Color(0xFFFFD700), fontSize: 13, fontWeight: FontWeight.bold)),
            Text('$daysLeft day${daysLeft == 1 ? '' : 's'} to go',
                style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11)),
          ]),
        ),
        // Progress
        SizedBox(
          width: 60, height: 60,
          child: Stack(alignment: Alignment.center, children: [
            CircularProgressIndicator(
              value: days / next,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation(Color(0xFFFFD700)),
              strokeWidth: 4,
            ),
            Text('${((days / next) * 100).round()}%',
                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 10)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildEmptyState() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const SizedBox(height: 40),
      const Text('🌱', style: TextStyle(fontSize: 48)),
      const SizedBox(height: 12),
      Text('Your story is just beginning...',
          style: GoogleFonts.outfit(color: Colors.white38)),
      const SizedBox(height: 8),
      Text('Milestones and meaningful moments\nwill appear here as your bond grows.',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(color: Colors.white24, fontSize: 12, height: 1.5)),
    ]),
  );

  String _formatShortDate(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year.toString().substring(2)}';
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final String emoji;
  const _StatItem({required this.value, required this.label, required this.emoji});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (emoji.isNotEmpty) Text(emoji, style: const TextStyle(fontSize: 18)),
      const SizedBox(height: 4),
      Text(value,
          style: GoogleFonts.outfit(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
      Text(label,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(color: Colors.white38, fontSize: 10)),
    ],
  );
}

class _EventCard extends StatelessWidget {
  final LifeEvent event;
  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: event.type.color.withValues(alpha: 0.06),
        border: Border.all(color: event.type.color.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        Text(event.type.emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(event.description,
                style: GoogleFonts.outfit(
                    color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            if (event.date != null)
              Text(
                _formatDate(event.date!),
                style: GoogleFonts.outfit(color: Colors.white38, fontSize: 10),
              ),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: event.type.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(event.type.label,
              style: GoogleFonts.outfit(color: event.type.color, fontSize: 9)),
        ),
      ]),
    );
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}



