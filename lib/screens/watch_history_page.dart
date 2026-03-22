import 'package:flutter/material.dart';
import '../services/watch_history_service.dart';

/// Watch History page with "Continue Watching" carousel and full history list.
class WatchHistoryPage extends StatefulWidget {
  const WatchHistoryPage({super.key});
  @override
  State<WatchHistoryPage> createState() => _WatchHistoryPageState();
}

class _WatchHistoryPageState extends State<WatchHistoryPage> {
  List<WatchHistoryEntry> _continueWatching = [];
  List<WatchHistoryEntry> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final cw = await WatchHistoryService.getContinueWatching();
    final hist = await WatchHistoryService.getHistory();
    if (mounted) setState(() {
      _continueWatching = cw;
      _history = hist;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('📊 Watch History',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              Colors.cyan.withValues(alpha: 0.5),
              Colors.black.withValues(alpha: 0.95),
            ]),
          ),
        ),
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.white54),
              onPressed: _showClearDialog,
            ),
        ],
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: Colors.cyan))
        : _history.isEmpty
          ? Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history, color: Colors.grey.shade700, size: 60),
                const SizedBox(height: 12),
                Text('No watch history yet',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                const SizedBox(height: 4),
                Text('Start watching anime to track your progress',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
              ],
            ))
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                // ── Continue Watching Carousel ──
                if (_continueWatching.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 8),
                    child: Text('▶️ Continue Watching',
                      style: TextStyle(color: Colors.white,
                          fontWeight: FontWeight.w700, fontSize: 16)),
                  ),
                  SizedBox(
                    height: 180,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _continueWatching.length,
                      itemBuilder: (_, i) => _ContinueCard(
                        entry: _continueWatching[i]),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Full History ──
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 8),
                  child: Text('📜 All History',
                    style: TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w700, fontSize: 16)),
                ),
                ..._history.map((e) => _HistoryTile(entry: e)),
              ],
            ),
    );
  }

  void _showClearDialog() {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: Colors.grey.shade900,
      title: const Text('Clear History?', style: TextStyle(color: Colors.white)),
      content: Text('This will remove all watch history.',
        style: TextStyle(color: Colors.grey.shade400)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
          child: const Text('Cancel')),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            await WatchHistoryService.clearHistory();
            _load();
          },
          child: const Text('Clear', style: TextStyle(color: Colors.red)),
        ),
      ],
    ));
  }
}

class _ContinueCard extends StatelessWidget {
  final WatchHistoryEntry entry;
  const _ContinueCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  entry.animeCoverUrl.isNotEmpty
                    ? Image.network(entry.animeCoverUrl, fit: BoxFit.cover)
                    : Container(color: Colors.grey.shade900),
                  // Progress bar
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: LinearProgressIndicator(
                      value: entry.progress,
                      backgroundColor: Colors.black54,
                      valueColor: const AlwaysStoppedAnimation(Colors.cyan),
                      minHeight: 3,
                    ),
                  ),
                  // Play overlay
                  Center(child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow, color: Colors.white, size: 24),
                  )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(entry.animeTitle, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 11,
                fontWeight: FontWeight.w600)),
          Text('Ep ${entry.episodeNumber} • ${entry.progressText}',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final WatchHistoryEntry entry;
  const _HistoryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final ago = DateTime.now().difference(entry.watchedAt);
    String timeAgo;
    if (ago.inMinutes < 60) {
      timeAgo = '${ago.inMinutes}m ago';
    } else if (ago.inHours < 24) {
      timeAgo = '${ago.inHours}h ago';
    } else {
      timeAgo = '${ago.inDays}d ago';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        tileColor: Colors.white.withValues(alpha: 0.04),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: entry.animeCoverUrl.isNotEmpty
            ? Image.network(entry.animeCoverUrl, width: 45, height: 60, fit: BoxFit.cover)
            : Container(width: 45, height: 60, color: Colors.grey.shade900),
        ),
        title: Text(entry.animeTitle,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('Episode ${entry.episodeNumber} • ${entry.progressText}',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
        trailing: Text(timeAgo,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 10)),
      ),
    );
  }
}
