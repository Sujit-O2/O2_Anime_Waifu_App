import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:anime_waifu/services/anime_media/watch_history_service.dart';
import 'package:anime_waifu/widgets/app_cached_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WatchHistoryPage extends StatefulWidget {
  const WatchHistoryPage({super.key});

  @override
  State<WatchHistoryPage> createState() => _WatchHistoryPageState();
}

class _WatchHistoryPageState extends State<WatchHistoryPage> {
  List<WatchHistoryEntry> _continueWatching = <WatchHistoryEntry>[];
  List<WatchHistoryEntry> _history = <WatchHistoryEntry>[];
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final cw = await WatchHistoryService.getContinueWatching();
    final hist = await WatchHistoryService.getHistory();
    if (!mounted) {
      return;
    }
    setState(() {
      _continueWatching = cw;
      _history = hist;
      _loading = false;
    });
  }

  List<WatchHistoryEntry> get _filteredHistory {
    if (_searchQuery.isEmpty) {
      return _history;
    }
    return _history.where((entry) {
      final query = _searchQuery.toLowerCase();
      return entry.animeTitle.toLowerCase().contains(query) ||
          'episode ${entry.episodeNumber}'.contains(query);
    }).toList();
  }

  String get _commentaryMood => _history.isEmpty ? 'neutral' : 'achievement';

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredHistory;
    return Scaffold(
      backgroundColor: const Color(0xFF09111A),
      body: WaifuBackground(
        opacity: 0.06,
        tint: const Color(0xFF08111A),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(
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
                            'WATCH HISTORY',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.4,
                            ),
                          ),
                          Text(
                            'Pick up exactly where you left off',
                            style: GoogleFonts.outfit(
                              color: Colors.cyanAccent.withValues(alpha: 0.7),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_history.isNotEmpty)
                      IconButton(
                        onPressed: _showClearDialog,
                        icon: const Icon(
                          Icons.delete_sweep_rounded,
                          color: Colors.white54,
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: V2SearchBar(
                  hintText: 'Search by anime or episode...',
                  onChanged: (value) =>
                      setState(() => _searchQuery = value.trim()),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: _StatCard(
                        label: 'Continue',
                        value: '${_continueWatching.length}',
                        color: Colors.cyanAccent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatCard(
                        label: 'History',
                        value: '${_history.length}',
                        color: Colors.pinkAccent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatCard(
                        label: 'Tracked',
                        value: '${filtered.length}',
                        color: Colors.greenAccent,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),

              ),
              const SizedBox(height: 12),
              Expanded(
                child: _loading
                    ? const Center(
                        child:
                            CircularProgressIndicator(color: Colors.cyanAccent),
                      )
                    : filtered.isEmpty
                        ? EmptyState(
                            icon: Icons.history_toggle_off_rounded,
                            title: _history.isEmpty
                                ? 'No watch history yet'
                                : 'No history matches your search',
                            subtitle: _history.isEmpty
                                ? 'Start watching anime and I will keep your progress ready for later.'
                                : 'Try a different title or clear the search.',
                            buttonText:
                                _history.isEmpty ? null : 'Clear Search',
                            onButtonPressed: _history.isEmpty
                                ? null
                                : () => setState(() => _searchQuery = ''),
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            color: Colors.cyanAccent,
                            child: ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(12),
                              children: <Widget>[
                                if (_continueWatching.isNotEmpty) ...<Widget>[
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 4, bottom: 8),
                                    child: Text(
                                      'Continue Watching',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 180,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: _continueWatching.length,
                                      itemBuilder: (_, i) => _ContinueCard(
                                        entry: _continueWatching[i],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                Padding(
                                  padding:
                                      const EdgeInsets.only(left: 4, bottom: 8),
                                  child: Text(
                                    'All History',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                ...filtered
                                    .map((entry) => _HistoryTile(entry: entry)),
                              ],
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClearDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF141B24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Clear history?',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'This will remove your continue watching queue and history list.',
          style: GoogleFonts.outfit(color: Colors.white60),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await WatchHistoryService.clearHistory();
              if (mounted) {
                showSuccessSnackbar(context, 'Watch history cleared');
              }
              _load();
            },
            child: Text(
              'Clear',
              style: GoogleFonts.outfit(
                color: Colors.redAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      child: Column(
        children: <Widget>[
          Text(
            value,
            style: GoogleFonts.outfit(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.outfit(color: Colors.white38, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.entry});

  final WatchHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      margin: const EdgeInsets.only(right: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  entry.animeCoverUrl.isNotEmpty
                      ? AppCachedImage(
                          url: entry.animeCoverUrl,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Container(color: Colors.grey.shade900),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(
                      value: entry.progress,
                      backgroundColor: Colors.black54,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.cyanAccent),
                      minHeight: 4,
                    ),
                  ),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            entry.animeTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'Ep ${entry.episodeNumber} • ${entry.progressText}',
            style: GoogleFonts.outfit(color: Colors.white38, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.entry});

  final WatchHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final ago = DateTime.now().difference(entry.watchedAt);
    final timeAgo = ago.inMinutes < 60
        ? '${ago.inMinutes}m ago'
        : ago.inHours < 24
            ? '${ago.inHours}h ago'
            : '${ago.inDays}d ago';

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        tileColor: Colors.white.withValues(alpha: 0.04),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: entry.animeCoverUrl.isNotEmpty
              ? AppCachedImage(
                  url: entry.animeCoverUrl,
                  width: 45,
                  height: 60,
                  fit: BoxFit.cover,
                )
              : Container(width: 45, height: 60, color: Colors.grey.shade900),
        ),
        title: Text(
          entry.animeTitle,
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          'Episode ${entry.episodeNumber} • ${entry.progressText}',
          style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11),
        ),
        trailing: Text(
          timeAgo,
          style: GoogleFonts.outfit(color: Colors.white30, fontSize: 10),
        ),
      ),
    );
  }
}



