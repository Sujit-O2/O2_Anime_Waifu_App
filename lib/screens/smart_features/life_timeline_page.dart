import 'dart:async' show unawaited;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:anime_waifu/services/smart_features/life_timeline_service.dart';
import 'package:anime_waifu/services/database_storage/app_db.dart';

class LifeTimelinePage extends StatefulWidget {
  const LifeTimelinePage({super.key});

  @override
  State<LifeTimelinePage> createState() => _LifeTimelinePageState();
}

class _LifeTimelinePageState extends State<LifeTimelinePage>
    with SingleTickerProviderStateMixin {
  final _service = LifeTimelineService.instance;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  List<TimelineActivity> _activities = [];
  Map<String, int> _streakData = {};
  bool _loading = false;
  String _selectedFilter = 'All';

  static const _bg = Color(0xFF0A0B14);
  static const _accent = Color(0xFF9C27B0);
  static const _surface = Color(0xFF151620);

  final List<String> _filters = ['All', 'Chat', 'Photo', 'Mood', 'Task', 'Event', 'Note'];

  @override
  void initState() {
    super.initState();
    unawaited(AppDB.instance.recordUsage('life_timeline'));
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
    _loadData();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final activities = await _service.getActivities();
      final streak = await _service.getActivityStreak();
      if (mounted) {
        setState(() {
          _activities = activities;
          _streakData = streak;
          _loading = false;
        });
        _animCtrl.forward();
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<TimelineActivity> get _filteredActivities {
    if (_selectedFilter == 'All') return _activities;
    final type = ActivityType.values.firstWhere(
      (e) => _service.getTypeLabel(e) == _selectedFilter,
      orElse: () => ActivityType.note,
    );
    return _activities.where((a) => a.type == type).toList();
  }

  Map<String, List<TimelineActivity>> get _groupedActivities {
    final grouped = <String, List<TimelineActivity>>{};
    for (final a in _filteredActivities) {
      final key = '${a.timestamp.year}-${a.timestamp.month}-${a.timestamp.day}';
      grouped.putIfAbsent(key, () => []).add(a);
    }
    return grouped;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today';
    }
    if (date.year == now.year && date.month == now.month && date.day == now.day - 1) {
      return 'Yesterday';
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text('Life Timeline', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: _bg,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_fire_department, color: Colors.orange, size: 16),
                const SizedBox(width: 4),
                Text('${_streakData['totalDays'] ?? 0} days',
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                children: [
                  _buildFilterBar(),
                  _buildStatsRow(),
                  Expanded(child: _buildTimeline()),
                ],
              ),
            ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final filter = _filters[i];
          final selected = filter == _selectedFilter;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = filter),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? _accent : _surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? _accent : Colors.grey[700]!,
                ),
              ),
              child: Center(
                child: Text(filter,
                    style: GoogleFonts.outfit(
                      color: selected ? Colors.white : Colors.grey[400],
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    )),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsRow() {
    if (_activities.isEmpty) return const SizedBox(height: 12);
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.analytics, '${_activities.length}', 'Activities'),
          _buildStatItem(Icons.calendar_today, '${_streakData['totalDays'] ?? 0}', 'Days'),
          _buildStatItem(Icons.category, '${_getUniqueTypes()}', 'Types'),
        ],
      ),
    );
  }

  int _getUniqueTypes() {
    return _activities.map((e) => e.type).toSet().length;
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: _accent, size: 20),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 11)),
      ],
    );
  }

  Widget _buildTimeline() {
    final grouped = _groupedActivities;
    if (grouped.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timeline, size: 64, color: Colors.grey[700]),
            const SizedBox(height: 16),
            Text('No activities yet', style: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 16)),
            const SizedBox(height: 8),
            Text('Your life events will appear here', style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: grouped.length,
      itemBuilder: (context, i) {
        final entry = grouped.entries.elementAt(i);
        final dateParts = entry.key.split('-');
        final date = DateTime(
            int.parse(dateParts[0]), int.parse(dateParts[1]), int.parse(dateParts[2]));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(_formatDate(date),
                        style: GoogleFonts.outfit(
                            color: _accent, fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Divider(color: Colors.grey[800])),
                ],
              ),
            ),
            ...entry.value.map((activity) => _buildActivityCard(activity)),
          ],
        );
      },
    );
  }

  Widget _buildActivityCard(TimelineActivity activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: _accent.withValues(alpha: 0.5), width: 3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_service.getTypeEmoji(activity.type), style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity.title,
                    style: GoogleFonts.outfit(
                        color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                if (activity.description != null) ...[
                  const SizedBox(height: 4),
                  Text(activity.description!,
                      style: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 12),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 6),
                Text(
                    '${activity.timestamp.hour.toString().padLeft(2, '0')}:${activity.timestamp.minute.toString().padLeft(2, '0')} • ${_service.getTypeLabel(activity.type)}',
                    style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 11)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.grey, size: 16),
            onPressed: () => _showActivityOptions(activity),
          ),
        ],
      ),
    );
  }

  void _showActivityOptions(TimelineActivity activity) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey[600], borderRadius: BorderRadius.circular(2)),
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.redAccent),
              title: Text('Delete Activity',
                  style: GoogleFonts.outfit(color: Colors.redAccent)),
              onTap: () async {
                Navigator.pop(context);
                await _service.deleteActivity(activity.id);
                _loadData();
              },
            ),
            ListTile(
              leading: const Icon(Icons.info, color: Colors.grey),
              title: Text('Details', style: GoogleFonts.outfit(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
