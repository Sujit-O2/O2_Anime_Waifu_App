import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:anime_waifu/services/anime_media/mal_sync_service.dart';
import 'package:anime_waifu/widgets/app_cached_image.dart';

class MalSyncPage extends StatefulWidget {
  const MalSyncPage({super.key});

  @override
  State<MalSyncPage> createState() => _MalSyncPageState();
}

class _MalSyncPageState extends State<MalSyncPage> {
  final TextEditingController _usernameCtrl = TextEditingController();
  bool _isEnabled = false;
  bool _loading = true;
  List<MalAnimeEntry> _malList = <MalAnimeEntry>[];

  String get _commentaryMood {
    if (_isEnabled && _malList.isNotEmpty) {
      return 'achievement';
    }
    if (_isEnabled) {
      return 'motivated';
    }
    return 'neutral';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() => _loading = true);
    }
    final bool enabled = await MalSyncService.isEnabled();
    final String? username = await MalSyncService.getUsername();
    final List<MalAnimeEntry> entries = enabled && username != null && username.isNotEmpty
        ? await MalSyncService.getMyList(limit: 30)
        : <MalAnimeEntry>[];

    if (!mounted) return;
    setState(() {
      _isEnabled = enabled;
      _usernameCtrl.text = username ?? '';
      _malList = entries;
      _loading = false;
    });
  }

  Future<void> _saveUsernameAndSync() async {
    final String username = _usernameCtrl.text.trim();
    if (username.isEmpty) {
      showSuccessSnackbar(context, 'Please enter a username.');
      return;
    }

    if (mounted) {
      setState(() => _loading = true);
    }
    await MalSyncService.setUsername(username);
    await _load();
    if (mounted) {
      if (_malList.isEmpty) {
        showSuccessSnackbar(
          context,
          'No entries found for $username. Check the username or privacy settings.',
        );
      } else {
        showSuccessSnackbar(
          context,
          'Synced ${_malList.length} MAL entries for $username.',
        );
      }
    }
  }

  Future<void> _disconnect() async {
    await MalSyncService.disconnect();
    _usernameCtrl.clear();
    if (mounted) {
      setState(() {
        _isEnabled = false;
        _malList = <MalAnimeEntry>[];
      });
      showSuccessSnackbar(context, 'MAL sync disconnected.');
    }
  }

  Future<void> _refresh() async {
    await _load();
  }

  Future<void> _openEntry(MalAnimeEntry entry) async {
    final Uri uri = Uri.parse('https://myanimelist.net/anime/${entry.malId}');
    final bool ok = await canLaunchUrl(uri);
    if (!ok) {
      if (mounted) {
        showSuccessSnackbar(context, 'Could not open MyAnimeList.');
      }
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: V2Theme.surfaceDark,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: V2Theme.primaryColor,
          backgroundColor: V2Theme.surfaceLight,
          child: _loading
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const <Widget>[
                    SizedBox(height: 220),
                    Center(
                      child: CircularProgressIndicator(
                        color: V2Theme.primaryColor,
                      ),
                    ),
                  ],
                )
              : ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                  children: <Widget>[
                    Row(
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
                                'MAL SYNC',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              Text(
                                'Connect your public MyAnimeList profile',
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF87A8FF),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AnimatedEntry(
                      index: 0,
                      child: GlassCard(
                        margin: EdgeInsets.zero,
                        glow: true,
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    'Sync status',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _isEnabled
                                        ? 'Connected as ${_usernameCtrl.text}'
                                        : 'Not connected yet',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _isEnabled
                                        ? 'Your recent list is pulled in and ready to browse.'
                                        : 'Use your public MAL username to fetch your anime list without a login flow.',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white60,
                                      fontSize: 12,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            ProgressRing(
                              progress: _isEnabled ? 1 : 0.22,
                              foreground: const Color(0xFF2E51A2),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  const Icon(
                                    Icons.sync_rounded,
                                    color: Color(0xFF87A8FF),
                                    size: 28,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${_malList.length}',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    'Items',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white54,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    AnimatedEntry(
                      index: 1,
                      child: WaifuCommentary(mood: _commentaryMood),
                    ),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: StatCard(
                            title: 'Connected',
                            value: _isEnabled ? 'Yes' : 'No',
                            icon: Icons.link_rounded,
                            color: Colors.greenAccent,
                          ),
                        ),
                        Expanded(
                          child: StatCard(
                            title: 'Entries',
                            value: '${_malList.length}',
                            icon: Icons.collections_bookmark_rounded,
                            color: const Color(0xFF87A8FF),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: StatCard(
                            title: 'Profile',
                            value: _usernameCtrl.text.isEmpty
                                ? 'Unset'
                                : _usernameCtrl.text,
                            icon: Icons.person_rounded,
                            color: V2Theme.primaryColor,
                          ),
                        ),
                        Expanded(
                          child: StatCard(
                            title: 'Source',
                            value: 'MAL',
                            icon: Icons.public_rounded,
                            color: V2Theme.secondaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GlassCard(
                      margin: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'MyAnimeList Username',
                            style: GoogleFonts.outfit(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _usernameCtrl,
                            style: GoogleFonts.outfit(color: Colors.white),
                            onSubmitted: (_) => _saveUsernameAndSync(),
                            decoration: InputDecoration(
                              hintText: 'Enter your public MAL username',
                              hintStyle: GoogleFonts.outfit(
                                color: Colors.white30,
                              ),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.05),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              suffixIcon: IconButton(
                                icon: const Icon(
                                  Icons.sync_rounded,
                                  color: Color(0xFF87A8FF),
                                ),
                                onPressed: _saveUsernameAndSync,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No login required. A public username is enough for basic sync.',
                            style: GoogleFonts.outfit(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _saveUsernameAndSync,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF2E51A2),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            icon: const Icon(Icons.download_rounded),
                            label: const Text('Fetch MyAnimeList'),
                          ),
                        ),
                        if (_isEnabled) ...<Widget>[
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _disconnect,
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                              icon: const Icon(Icons.logout_rounded),
                              label: const Text('Disconnect'),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (_isEnabled && _malList.isNotEmpty) ...<Widget>[
                      Text(
                        'MY ANIME LIST',
                        style: GoogleFonts.outfit(
                          color: Colors.white38,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ..._malList.map(
                        (MalAnimeEntry entry) => GestureDetector(
                          onTap: () => _openEntry(entry),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Row(
                              children: <Widget>[
                                AppCachedImage(
                                  url: entry.coverUrl,
                                  width: 48,
                                  height: 68,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        entry.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${entry.status.replaceAll('_', ' ')} • ${entry.episodesWatched} eps',
                                        style: GoogleFonts.outfit(
                                          color: Colors.white54,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (entry.score > 0)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      const Icon(
                                        Icons.star_rounded,
                                        color: Colors.amber,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${entry.score}',
                                        style: GoogleFonts.outfit(
                                          color: Colors.amber,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ] else ...<Widget>[
                      GlassCard(
                        margin: EdgeInsets.zero,
                        child: const EmptyState(
                          icon: Icons.collections_bookmark_rounded,
                          title: 'No synced MAL list yet',
                          subtitle:
                              'Connect a public username and your recent list entries will appear here.',
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}




