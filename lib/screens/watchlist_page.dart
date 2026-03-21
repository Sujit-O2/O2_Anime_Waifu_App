import 'package:flutter/material.dart';
import '../services/watchlist_service.dart';

/// Watchlist page showing favorited anime and manga in a tabbed grid.
class WatchlistPage extends StatefulWidget {
  const WatchlistPage({super.key});
  @override
  State<WatchlistPage> createState() => _WatchlistPageState();
}

class _WatchlistPageState extends State<WatchlistPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<WatchlistItem> _anime = [];
  List<WatchlistItem> _manga = [];
  bool _loading = true;

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
    final a = await WatchlistService.getAnimeWatchlist();
    final m = await WatchlistService.getMangaWatchlist();
    if (mounted) setState(() { _anime = a; _manga = m; _loading = false; });
  }

  Future<void> _remove(WatchlistItem item) async {
    if (item.type == 'anime') {
      await WatchlistService.removeAnime(item.id);
    } else {
      await WatchlistService.removeManga(item.id);
    }
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('❤️ My Watchlist',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              Colors.pinkAccent.withValues(alpha: 0.5),
              Colors.black.withValues(alpha: 0.95),
            ]),
          ),
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.pinkAccent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(text: '📺 Anime (${_anime.length})'),
            Tab(text: '📖 Manga (${_manga.length})'),
          ],
        ),
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: Colors.pinkAccent))
        : TabBarView(
            controller: _tabCtrl,
            children: [
              _buildGrid(_anime),
              _buildGrid(_manga),
            ],
          ),
    );
  }

  Widget _buildGrid(List<WatchlistItem> items) {
    if (items.isEmpty) {
      return Center(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_border, color: Colors.grey.shade700, size: 60),
          const SizedBox(height: 12),
          Text('No favorites yet',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
          const SizedBox(height: 4),
          Text('Tap ❤️ on any anime or manga to save it here',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
        ],
      ));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.58,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        return GestureDetector(
          onLongPress: () => _showRemoveDialog(item),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      item.coverUrl.isNotEmpty
                        ? Image.network(item.coverUrl, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey.shade900,
                              child: const Icon(Icons.broken_image, color: Colors.grey)))
                        : Container(color: Colors.grey.shade900,
                            child: const Icon(Icons.image, color: Colors.grey)),
                      Positioned(
                        top: 4, right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.pinkAccent.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.favorite, color: Colors.white, size: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(item.title,
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 11,
                    fontWeight: FontWeight.w600)),
            ],
          ),
        );
      },
    );
  }

  void _showRemoveDialog(WatchlistItem item) {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: Colors.grey.shade900,
      title: const Text('Remove from Watchlist?',
        style: TextStyle(color: Colors.white)),
      content: Text('Remove "${item.title}" from your favorites?',
        style: TextStyle(color: Colors.grey.shade400)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
          child: const Text('Cancel')),
        TextButton(
          onPressed: () { Navigator.pop(context); _remove(item); },
          child: const Text('Remove', style: TextStyle(color: Colors.pinkAccent)),
        ),
      ],
    ));
  }
}
