import 'dart:async' show unawaited;
import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:anime_waifu/services/utilities_core/download_service.dart';
import 'package:anime_waifu/widgets/app_cached_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anime_waifu/services/database_storage/app_db.dart';

/// Downloads v2 — Offline content manager with storage stats, grid/list toggle,
/// animated cards, search, and storage visualization.
class DownloadsPage extends StatefulWidget {
  const DownloadsPage({super.key});
  @override
  State<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends State<DownloadsPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;

  List<DownloadItem> _downloads = [];
  bool _loading = true;
  String _totalSize = '0 MB';
  double _totalSizeBytes = 0;
  bool _gridView = true;
  String _selectedType = 'All';
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    unawaited(AppDB.instance.recordUsage('downloads'));
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..forward();
    _searchCtrl.addListener(
        () => setState(() => _searchQuery = _searchCtrl.text.toLowerCase()));
    _load();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    final items = await DownloadService.getDownloads();
    final sizeBytes = await DownloadService.getTotalSize();
    final sizeMb = (sizeBytes / (1024 * 1024));
    if (mounted) {
      setState(() {
        _downloads = items;
        _totalSizeBytes = sizeMb;
        _totalSize = '${sizeMb.toStringAsFixed(1)} MB';
        _gridView = prefs.getBool('downloads_grid_view_v2') ?? _gridView;
        _selectedType =
            prefs.getString('downloads_type_filter_v2') ?? _selectedType;
        _loading = false;
      });
    }
  }

  Future<void> _delete(DownloadItem item) async {
    await DownloadService.deleteDownload(item.id);
    if (mounted) {
      showSuccessSnackbar(context, 'Download removed');
    }
    _load();
  }

  Future<void> _saveViewPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('downloads_grid_view_v2', _gridView);
    await prefs.setString('downloads_type_filter_v2', _selectedType);
  }

  void _toggleLayout() {
    HapticFeedback.lightImpact();
    setState(() => _gridView = !_gridView);
    _saveViewPrefs();
  }

  List<DownloadItem> get _filtered {
    final typeFiltered = _selectedType == 'All'
        ? _downloads
        : _downloads
            .where((d) => d.type == _selectedType.toLowerCase())
            .toList();
    if (_searchQuery.isEmpty) return typeFiltered;
    return typeFiltered
        .where((d) => d.title.toLowerCase().contains(_searchQuery))
        .toList();
  }

  int get _mangaCount => _downloads.where((d) => d.type == 'manga').length;
  int get _animeCount => _downloads.where((d) => d.type != 'manga').length;
  String get _commentaryMood => _downloads.isEmpty ? 'neutral' : 'achievement';

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return FeaturePageV2(
      title: 'DOWNLOADS',
      subtitle: '$_totalSize • ${_downloads.length} items',
      onBack: () => Navigator.pop(context),
      actions: [
        GestureDetector(
          onTap: _toggleLayout,
          child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12)),
              child: Icon(
                  _gridView
                      ? Icons.grid_view_rounded
                      : Icons.view_list_rounded,
                  color: Colors.white60,
                  size: 18)),
        ),
      ],
      content: FadeTransition(
        opacity: _fadeCtrl,
        child: Column(children: [
          // ── Filter Chips ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Anime', 'Manga'].map((type) {
                  final isSelected = _selectedType == type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(type),
                      selected: isSelected,
                      onSelected: (_) {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedType = type);
                        _saveViewPrefs();
                      },
                      selectedColor:
                          Colors.greenAccent.withValues(alpha: 0.18),
                      backgroundColor:
                          Colors.white.withValues(alpha: 0.05),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // ── Search ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.greenAccent.withValues(alpha: 0.15))),
              child: TextField(
                controller: _searchCtrl,
                style:
                    GoogleFonts.outfit(color: Colors.white, fontSize: 13),
                cursorColor: Colors.greenAccent,
                decoration: InputDecoration(
                    hintText: 'Search downloads...',
                    hintStyle: GoogleFonts.outfit(color: Colors.white24),
                    border: InputBorder.none,
                    icon: const Icon(Icons.search,
                        color: Colors.white30, size: 18)),
              ),
            ),
          ),

          // ── Stats Row ──
          AnimatedEntry(
            index: 1,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(children: [
                _statCard('📱', _totalSize, 'Storage', Colors.greenAccent),
                const SizedBox(width: 8),
                _statCard('📺', '$_animeCount', 'Anime', Colors.cyanAccent),
                const SizedBox(width: 8),
                _statCard('📖', '$_mangaCount', 'Manga', Colors.amberAccent),
                const SizedBox(width: 8),
                _statCard(
                    '📦', '${_downloads.length}', 'Total', Colors.pinkAccent),
              ]),
            ),
          ),

          // ── Storage Bar ──
          if (_totalSizeBytes > 0)
            AnimatedEntry(
              index: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: GlassCard(
                  margin: EdgeInsets.zero,
                  child: Column(children: [
                    Row(children: [
                      const Text('💾', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text('Storage Used',
                          style: GoogleFonts.outfit(
                              color: Colors.white54, fontSize: 11)),
                      const Spacer(),
                      Text(_totalSize,
                          style: GoogleFonts.outfit(
                              color: Colors.greenAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ]),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: (_totalSizeBytes / 1000)
                            .clamp(0.0, 1.0),
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        valueColor: AlwaysStoppedAnimation(
                            _totalSizeBytes > 500
                                ? Colors.orangeAccent
                                : Colors.greenAccent),
                        minHeight: 5,
                      ),
                    ),
                  ]),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: WaifuCommentary(mood: _commentaryMood),
          ),

          const SizedBox(height: 8),

          // ── Content ──
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Colors.greenAccent))
                : filtered.isEmpty
                    ? EmptyState(
                        icon: Icons.download_done_rounded,
                        title: _searchQuery.isNotEmpty
                            ? 'No matching downloads'
                            : 'No downloads yet',
                        subtitle:
                            'Download anime or manga for offline access.',
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: Colors.greenAccent,
                        child: _gridView
                            ? GridView.builder(
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(12),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        childAspectRatio: 0.55,
                                        crossAxisSpacing: 10,
                                        mainAxisSpacing: 10),
                                itemCount: filtered.length,
                                itemBuilder: (_, i) =>
                                    _buildGridCard(filtered[i], i),
                              )
                            : ListView.builder(
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(12),
                                itemCount: filtered.length,
                                itemBuilder: (_, i) =>
                                    _buildListCard(filtered[i], i),
                              ),
                      ),
          ),
        ]),
      ),
    );
  }

  Widget _statCard(String emoji, String value, String label, Color color) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: color.withValues(alpha: 0.05),
              border: Border.all(color: color.withValues(alpha: 0.15))),
          child: Column(children: [
            Text('$emoji $value',
                style: GoogleFonts.outfit(
                    color: color, fontSize: 11, fontWeight: FontWeight.w700)),
            Text(label,
                style: GoogleFonts.outfit(color: Colors.white30, fontSize: 8)),
          ]),
        ),
      );

  Widget _buildGridCard(DownloadItem item, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + index * 50),
      curve: Curves.easeOut,
      builder: (_, val, child) => Opacity(
          opacity: val,
          child: Transform.translate(
              offset: Offset(0, 16 * (1 - val)), child: child)),
      child: GestureDetector(
        onLongPress: () => _showDeleteDialog(item),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(
              child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(fit: StackFit.expand, children: [
              item.coverUrl.isNotEmpty
                  ? AppCachedImage(
                      url: item.coverUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover)
                  : Container(
                      color: Colors.grey.shade900,
                      child: const Icon(Icons.download, color: Colors.grey)),
              Positioned.fill(
                  child: DecoratedBox(
                      decoration: BoxDecoration(
                          gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.6)
                  ])))),
              Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                        color: Colors.greenAccent.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.offline_pin,
                        color: Colors.white, size: 12),
                  )),
              Positioned(
                  bottom: 6,
                  left: 6,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(6)),
                    child: Text(item.type == 'manga' ? '📖' : '📺',
                        style: const TextStyle(fontSize: 10)),
                  )),
            ]),
          )),
          const SizedBox(height: 6),
          Text(item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _buildListCard(DownloadItem item, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + index * 50),
      curve: Curves.easeOut,
      builder: (_, val, child) => Opacity(
          opacity: val,
          child: Transform.translate(
              offset: Offset(0, 12 * (1 - val)), child: child)),
      child: Dismissible(
        key: Key(item.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) {
          HapticFeedback.mediumImpact();
          _delete(item);
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.delete_outline, color: Colors.redAccent),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.greenAccent.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
            border:
                Border.all(color: Colors.greenAccent.withValues(alpha: 0.15)),
          ),
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: item.coverUrl.isNotEmpty
                  ? AppCachedImage(
                      url: item.coverUrl,
                      width: 50,
                      height: 70,
                      fit: BoxFit.cover)
                  : Container(
                      width: 50, height: 70, color: Colors.grey.shade900),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Text(
                        '${item.type == 'manga' ? '📖' : '📺'} ${item.type.toUpperCase()}',
                        style: GoogleFonts.outfit(
                            color: Colors.white38, fontSize: 10)),
                    if (item.pageCount > 0) ...[
                      const SizedBox(width: 6),
                      Text('· ${item.pageCount} pages',
                          style: GoogleFonts.outfit(
                              color: Colors.white30, fontSize: 10)),
                    ],
                  ]),
                ])),
            const Icon(Icons.offline_pin, color: Colors.greenAccent, size: 20),
          ]),
        ),
      ),
    );
  }

  void _showDeleteDialog(DownloadItem item) {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              backgroundColor: const Color(0xFF1A1A2E),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Text('Delete Download?',
                  style: GoogleFonts.outfit(
                      color: Colors.white, fontWeight: FontWeight.w800)),
              content: Text('Remove "${item.title}" from offline storage?',
                  style: GoogleFonts.outfit(color: Colors.white54)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel',
                        style: GoogleFonts.outfit(color: Colors.white54))),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _delete(item);
                    HapticFeedback.mediumImpact();
                  },
                  child: Text('Delete',
                      style: GoogleFonts.outfit(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ));
  }
}



