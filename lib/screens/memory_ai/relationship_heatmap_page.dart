import 'package:anime_waifu/services/ai_personalization/relationship_heatmap_service.dart';
import 'dart:async';
import 'package:flutter/material.dart';

class RelationshipHeatmapPage extends StatefulWidget {
  const RelationshipHeatmapPage({super.key});

  @override
  State<RelationshipHeatmapPage> createState() =>
      _RelationshipHeatmapPageState();
}

class _RelationshipHeatmapPageState extends State<RelationshipHeatmapPage> {
  final _service = RelationshipHeatmapService.instance;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _service.initialize();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _addCheckIn() async {
    await _service.recordInteraction(
      messageCount: 12,
      durationSeconds: 420,
      emotionalIntensity: 0.65,
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = _service.getStatistics();
    final actions = _service.getRecommendedActions();
    final heatmap = _service.getHeatmapData(
      startDate: DateTime.now().subtract(const Duration(days: 27)),
      endDate: DateTime.now(),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Relationship Heatmap'),
        backgroundColor: Colors.pink.shade700,
        actions: [
          IconButton(
            tooltip: 'Log check-in',
            onPressed: _loading ? null : _addCheckIn,
            icon: const Icon(Icons.add_comment_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _StatsGrid(
                      stats: stats, streak: _service.getCurrentStreakDays()),
                  const SizedBox(height: 16),
                  Text('Last 4 Weeks', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 10),
                  _HeatmapGrid(values: heatmap.values.toList()),
                  const SizedBox(height: 18),
                  Text('Care Signals', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...actions.map((action) => _ActionTile(action: action)),
                  const SizedBox(height: 18),
                  Text('Recent Sessions', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ..._service.getRecentSessions(limit: 5).map(_SessionTile.new),
                  if (_service.getRecentSessions(limit: 1).isEmpty)
                    const _EmptyState(),
                ],
              ),
            ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final Map<String, dynamic> stats;
  final int streak;

  const _StatsGrid({required this.stats, required this.streak});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 1.55,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: [
        _StatCard('Chats', '${stats['total_sessions']}', Icons.chat_rounded),
        _StatCard('Messages', '${stats['total_messages']}', Icons.sms_rounded),
        _StatCard('Minutes', '${stats['total_duration_minutes']}',
            Icons.timer_rounded),
        _StatCard(
            'Streak', '$streak days', Icons.local_fire_department_rounded),
        _StatCard(
            'Best Day', '${stats['most_active_day']}', Icons.today_rounded),
        _StatCard('Best Hour', '${stats['most_active_hour']}', Icons.schedule),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: Colors.pink.shade600),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _HeatmapGrid extends StatelessWidget {
  final List<double> values;

  const _HeatmapGrid({required this.values});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: values.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
      ),
      itemBuilder: (context, index) {
        final value = values[index];
        return DecoratedBox(
          decoration: BoxDecoration(
            color:
                Color.lerp(Colors.grey.shade200, Colors.pink.shade600, value),
            borderRadius: BorderRadius.circular(6),
          ),
        );
      },
    );
  }
}

class _ActionTile extends StatelessWidget {
  final RelationshipAction action;

  const _ActionTile({required this.action});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.pink.shade50,
          child: Icon(Icons.favorite_rounded, color: Colors.pink.shade700),
        ),
        title: Text(action.title),
        subtitle: Text(action.detail),
        trailing: Text('${(action.priority * 100).round()}%'),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final ConversationSession session;

  const _SessionTile(this.session);

  @override
  Widget build(BuildContext context) {
    final minutes = (session.durationSeconds / 60).round();
    return Card(
      child: ListTile(
        leading: const Icon(Icons.history_rounded),
        title: Text('${session.messageCount} messages, $minutes min'),
        subtitle: Text(
          'Intensity ${(session.emotionalIntensity * 100).round()}% at ${session.hour.toString().padLeft(2, '0')}:00',
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Text(
          'No sessions yet. Tap the chat icon above to log a sample check-in and see the heatmap come alive.',
        ),
      ),
    );
  }
}
