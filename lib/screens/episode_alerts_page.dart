import 'package:flutter/material.dart';
import '../widgets/app_cached_image.dart';
import '../services/episode_alert_service.dart';

/// Episode Alerts Page — view followed anime + pending new episode alerts.
class EpisodeAlertsPage extends StatefulWidget {
  const EpisodeAlertsPage({super.key});
  @override
  State<EpisodeAlertsPage> createState() => _EpisodeAlertsPageState();
}

class _EpisodeAlertsPageState extends State<EpisodeAlertsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<FollowedAnime> _followed = [];
  List<EpisodeAlert> _alerts = [];
  bool _loading = true;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _followed = await EpisodeAlertService.getFollowedAnime();
    _alerts = await EpisodeAlertService.getPendingAlerts();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _checkNow() async {
    setState(() => _checking = true);
    final newAlerts = await EpisodeAlertService.checkForNewEpisodes();
    if (newAlerts.isNotEmpty) {
      _alerts = await EpisodeAlertService.getPendingAlerts();
    }
    _followed = await EpisodeAlertService.getFollowedAnime();
    if (mounted) setState(() => _checking = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(newAlerts.isEmpty
            ? 'All caught up! No new episodes.'
            : '🎉 ${newAlerts.length} new episode(s) found!'),
        backgroundColor: newAlerts.isEmpty ? Colors.grey.shade800 : Colors.green,
      ));
    }
  }

  Future<void> _unfollow(int malId) async {
    await EpisodeAlertService.unfollowAnime(malId);
    _load();
  }

  Future<void> _clearAlerts() async {
    await EpisodeAlertService.clearAlerts();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        title: const Text('🔔 Episode Alerts',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              Colors.orange.withValues(alpha: 0.5),
              Colors.black.withValues(alpha: 0.95),
            ]),
          ),
        ),
        actions: [
          if (_checking)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(child: SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange))),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.orange),
              onPressed: _checkNow,
              tooltip: 'Check for new episodes',
            ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.orange,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(text: '📡 Following (${_followed.length})'),
            Tab(text: '🔔 Alerts (${_alerts.length})'),
          ],
        ),
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: Colors.orange))
        : TabBarView(
            controller: _tabCtrl,
            children: [
              _buildFollowedTab(),
              _buildAlertsTab(),
            ],
          ),
    );
  }

  Widget _buildFollowedTab() {
    if (_followed.isEmpty) {
      return Center(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none, color: Colors.grey.shade700, size: 60),
          const SizedBox(height: 12),
          Text('Not following any anime',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
          const SizedBox(height: 4),
          Text('Tap the 🔔 Follow button on any anime\nto get new episode alerts',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
        ],
      ));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _followed.length,
      itemBuilder: (_, i) {
        final anime = _followed[i];
        return Dismissible(
          key: Key('${anime.malId}'),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => _unfollow(anime.malId),
          background: Container(
            color: Colors.red.withValues(alpha: 0.2),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.notifications_off, color: Colors.red),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              tileColor: Colors.white.withValues(alpha: 0.04),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: anime.coverUrl.isNotEmpty
                  ? AppCachedImage(url: anime.coverUrl, width: 45, height: 60)
                  : Container(width: 45, height: 60, color: Colors.grey.shade900),
              ),
              title: Text(anime.title,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Row(children: [
                Icon(anime.isAiring ? Icons.circle : Icons.check_circle,
                  color: anime.isAiring ? Colors.green : Colors.grey, size: 8),
                const SizedBox(width: 4),
                Text(
                  anime.isAiring ? 'Airing • ${anime.lastKnownEpisode} eps'
                      : 'Finished • ${anime.lastKnownEpisode} eps',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
              ]),
              trailing: IconButton(
                icon: const Icon(Icons.notifications_off_outlined,
                    color: Colors.red, size: 20),
                onPressed: () => _unfollow(anime.malId),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAlertsTab() {
    if (_alerts.isEmpty) {
      return Center(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline, color: Colors.grey.shade700, size: 60),
          const SizedBox(height: 12),
          Text('No new episode alerts',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
          const SizedBox(height: 4),
          Text('Tap 🔄 to check for new episodes',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
        ],
      ));
    }

    return Column(
      children: [
        // Clear all button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: _clearAlerts,
                icon: const Icon(Icons.done_all, size: 16),
                label: const Text('Mark all read', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(foregroundColor: Colors.orange),
              ),
            ],
          ),
        ),
        Expanded(child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: _alerts.length,
          itemBuilder: (_, i) {
            final alert = _alerts[i];
            final ago = DateTime.now().difference(alert.createdAt);
            final timeAgo = ago.inHours < 1 ? '${ago.inMinutes}m ago'
                : ago.inHours < 24 ? '${ago.inHours}h ago'
                : '${ago.inDays}d ago';

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                tileColor: Colors.orange.withValues(alpha: 0.06),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: alert.coverUrl.isNotEmpty
                    ? AppCachedImage(url: alert.coverUrl, width: 45, height: 60)
                    : Container(width: 45, height: 60, color: Colors.grey.shade900),
                ),
                title: Text(alert.title,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  '🎉 Episode ${alert.newEpisode} is out! '
                  '(was ${alert.previousEpisode})',
                  style: const TextStyle(color: Colors.orange, fontSize: 11)),
                trailing: Text(timeAgo,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 10)),
              ),
            );
          },
        )),
      ],
    );
  }
}
