import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:anime_waifu/services/anime_media/episode_alert_service.dart';
import 'package:anime_waifu/widgets/app_cached_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


class EpisodeAlertsPage extends StatefulWidget {
  const EpisodeAlertsPage({super.key});

  @override
  State<EpisodeAlertsPage> createState() => _EpisodeAlertsPageState();
}

class _EpisodeAlertsPageState extends State<EpisodeAlertsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  List<FollowedAnime> _followed = <FollowedAnime>[];
  List<EpisodeAlert> _alerts = <EpisodeAlert>[];
  bool _loading = true;
  bool _checking = false;
  DateTime? _lastCheckTime;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() => _loading = true);
    }

    final followed = await EpisodeAlertService.getFollowedAnime();
    final alerts = await EpisodeAlertService.getPendingAlerts();
    final lastCheck = await EpisodeAlertService.getLastCheckTime();

    if (!mounted) {
      return;
    }

    setState(() {
      _followed = followed;
      _alerts = alerts;
      _lastCheckTime = lastCheck;
      _loading = false;
    });
  }

  Future<void> _checkNow() async {
    if (_checking) {
      return;
    }
    setState(() => _checking = true);
    final newAlerts = await EpisodeAlertService.checkForNewEpisodes();
    await _load();
    if (!mounted) {
      return;
    }
    setState(() => _checking = false);
    showSuccessSnackbar(
      context,
      newAlerts.isEmpty
          ? 'No new episode drops right now.'
          : '${newAlerts.length} new episode alerts found.',
    );
  }

  Future<void> _unfollow(FollowedAnime anime) async {
    await EpisodeAlertService.unfollowAnime(anime.malId);
    await _load();
    if (!mounted) {
      return;
    }
    showUndoSnackbar(
      context,
      'Stopped following ${anime.title}.',
      () async {
        await EpisodeAlertService.followAnime(anime);
        await _load();
      },
    );
  }

  Future<void> _clearAlerts() async {
    await EpisodeAlertService.clearAlerts();
    await _load();
    if (!mounted) {
      return;
    }
    showSuccessSnackbar(context, 'Cleared all pending alerts.');
  }

  @override
  Widget build(BuildContext context) {
    final mood = _alerts.isNotEmpty
        ? 'achievement'
        : _followed.isNotEmpty
            ? 'motivated'
            : 'neutral';

    return FeaturePageV2(
      title: 'EPISODE ALERTS',
      subtitle: 'Track followed shows and spot new drops fast.',
      onBack: () => Navigator.of(context).pop(),
      actions: [
        IconButton(
          onPressed: _checking ? null : _checkNow,
          icon: _checking
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: V2Theme.primaryColor,
                  ),
                )
              : const Icon(
                  Icons.refresh_rounded,
                  color: V2Theme.primaryColor,
                ),
        ),
      ],
      content: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: WaifuCommentary(mood: mood),
          ),
              if (!_loading) ...<Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: StatCard(
                          title: 'Following',
                          value: '${_followed.length}',
                          icon: Icons.notifications_active_rounded,
                          color: V2Theme.primaryColor,
                        ),
                      ),
                      Expanded(
                        child: StatCard(
                          title: 'Pending Alerts',
                          value: '${_alerts.length}',
                          icon: Icons.campaign_rounded,
                          color: Colors.orangeAccent,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: StatCard(
                          title: 'Airing Now',
                          value:
                              '${_followed.where((item) => item.isAiring).length}',
                          icon: Icons.live_tv_rounded,
                          color: V2Theme.secondaryColor,
                        ),
                      ),
                      Expanded(
                        child: StatCard(
                          title: 'Last Check',
                          value: _formatCheckTime(_lastCheckTime),
                          icon: Icons.schedule_rounded,
                          color: Colors.lightGreenAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: V2Theme.primaryGradient,
                    ),
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white54,
                    tabs: <Widget>[
                      Tab(text: 'Following (${_followed.length})'),
                      Tab(text: 'Alerts (${_alerts.length})'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: V2Theme.primaryColor,
                        ),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: <Widget>[
                          RefreshIndicator(
                            onRefresh: _load,
                            color: V2Theme.primaryColor,
                            child: _buildFollowingTab(),
                          ),
                          RefreshIndicator(
                            onRefresh: _load,
                            color: V2Theme.primaryColor,
                            child: _buildAlertsTab(),
                          ),
                        ],
                      ),
              ),
        ],
      ),
    );
  }

  Widget _buildFollowingTab() {
    if (_followed.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const <Widget>[
          SizedBox(height: 120),
          EmptyState(
            icon: Icons.notifications_none_rounded,
            title: 'Nothing followed yet',
            subtitle:
                'Tap follow from any anime detail page and the new episodes will show up here.',
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _followed.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final anime = _followed[index];
        return Dismissible(
          key: ValueKey<int>(anime.malId),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => _unfollow(anime),
          background: Container(
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.redAccent.withValues(alpha: 0.32),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.centerRight,
            child: const Icon(
              Icons.notifications_off_outlined,
              color: Colors.redAccent,
            ),
          ),
          child: GlassCard(
            margin: EdgeInsets.zero,
            child: Row(
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: anime.coverUrl.isEmpty
                      ? Container(
                          width: 58,
                          height: 78,
                          color: Colors.white10,
                          child: const Icon(
                            Icons.movie_creation_outlined,
                            color: Colors.white38,
                          ),
                        )
                      : AppCachedImage(
                          url: anime.coverUrl,
                          width: 58,
                          height: 78,
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        anime.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: <Widget>[
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: anime.isAiring
                                  ? Colors.lightGreenAccent
                                  : Colors.white38,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            anime.isAiring ? 'Currently airing' : 'Finished',
                            style: GoogleFonts.outfit(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Last known episode: ${anime.lastKnownEpisode}',
                        style: GoogleFonts.outfit(
                          color: V2Theme.secondaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAlertsTab() {
    if (_alerts.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 120),
        children: const <Widget>[
          EmptyState(
            icon: Icons.check_circle_outline_rounded,
            title: 'No alerts waiting',
            subtitle:
                'Run a manual refresh or keep following airing shows and this panel will light up.',
          ),
        ],
      );
    }

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _clearAlerts,
              icon: const Icon(Icons.done_all_rounded),
              label: const Text('Mark all read'),
              style: TextButton.styleFrom(
                foregroundColor: V2Theme.primaryColor,
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: _alerts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final alert = _alerts[index];
              return GlassCard(
                margin: EdgeInsets.zero,
                glow: true,
                child: Row(
                  children: <Widget>[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: alert.coverUrl.isEmpty
                          ? Container(
                              width: 58,
                              height: 78,
                              color: Colors.white10,
                              child: const Icon(
                                Icons.notifications_active_outlined,
                                color: Colors.white38,
                              ),
                            )
                          : AppCachedImage(
                              url: alert.coverUrl,
                              width: 58,
                              height: 78,
                            ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            alert.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Episode ${alert.newEpisode} is out now.',
                            style: GoogleFonts.outfit(
                              color: Colors.orangeAccent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Previous checkpoint: ${alert.previousEpisode} • ${_timeAgo(alert.createdAt)}',
                            style: GoogleFonts.outfit(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  static String _timeAgo(DateTime createdAt) {
    final difference = DateTime.now().difference(createdAt);
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }
    return '${difference.inDays}d ago';
  }

  static String _formatCheckTime(DateTime? dateTime) {
    if (dateTime == null) {
      return 'Never';
    }
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours}h';
    }
    return '${difference.inDays}d';
  }
}



