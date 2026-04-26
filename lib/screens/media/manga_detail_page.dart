import 'package:anime_waifu/services/anime_media/manga_service.dart';
import 'package:anime_waifu/config/app_themes.dart';
import 'package:anime_waifu/widgets/app_cached_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'manga_reader_page.dart';

class MangaDetailPage extends StatefulWidget {
  final MangaItem manga;
  const MangaDetailPage({super.key, required this.manga});
  @override
  State<MangaDetailPage> createState() => _MangaDetailPageState();
}

class _MangaDetailPageState extends State<MangaDetailPage> {
  List<ChapterItem> _chapters = [];
  bool _loadingChapters = true;
  bool _inReadingList = false;
  bool _showFullDesc = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('manga_reading_list_v1') ?? [];
    final chapters = await MangaService.getChapters(widget.manga.id);
    if (mounted) {
      setState(() {
        _inReadingList = list.contains(widget.manga.id);
        _chapters = chapters;
        _loadingChapters = false;
      });
    }
  }

  Future<void> _toggleReadingList() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('manga_reading_list_v1') ?? [];
    if (_inReadingList) {
      list.remove(widget.manga.id);
    } else {
      list.add(widget.manga.id);
    }
    await prefs.setStringList('manga_reading_list_v1', list);
    if (!mounted) return;
    setState(() => _inReadingList = !_inReadingList);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            _inReadingList
                ? '📚 Added to Reading List'
                : 'Removed from Reading List',
            style: GoogleFonts.outfit()),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        duration: const Duration(seconds: 2),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final manga = widget.manga;
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(manga),
          SliverToBoxAdapter(child: _buildInfo(manga)),
          SliverToBoxAdapter(child: _buildTags(manga)),
          SliverToBoxAdapter(child: _buildDescription(manga)),
          SliverToBoxAdapter(child: _buildChapterHeader()),
          _buildChapterList(),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(MangaItem manga) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tokens = context.appTokens;
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new, color: colors.onSurface),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _inReadingList
                ? Icons.bookmark_rounded
                : Icons.bookmark_outline_rounded,
            color: _inReadingList ? colors.primary : tokens.textMuted,
          ),
          onPressed: _toggleReadingList,
          tooltip: _inReadingList
              ? 'Remove from Reading List'
              : 'Add to Reading List',
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Blurred background
            if (manga.coverUrl != null)
              ImageFiltered(
                imageFilter:
                    const ColorFilter.mode(Colors.black45, BlendMode.darken),
                child: AppCachedImage(
                    url: manga.coverUrl!,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover),
              )
            else
              Container(color: tokens.panelElevated),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, theme.scaffoldBackgroundColor],
                  stops: const [0.4, 1.0],
                ),
              ),
            ),
            // Cover card centered
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Hero(
                  tag: 'manga_cover_${manga.id}',
                  child: Container(
                    width: 130,
                    height: 190,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: tokens.outlineStrong,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colors.primary.withValues(alpha: 0.28),
                          blurRadius: 30,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: manga.coverUrl != null
                          ? AppCachedImage(
                              url: manga.coverUrl!,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover)
                          : _placeholder(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: context.appTokens.panelElevated,
        child: Center(
          child: Icon(
            Icons.menu_book_outlined,
            color: context.appTokens.textMuted,
            size: 48,
          ),
        ),
      );

  Widget _buildInfo(MangaItem manga) {
    final colors = Theme.of(context).colorScheme;
    final tokens = context.appTokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(manga.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                  color: colors.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  height: 1.2)),
          const SizedBox(height: 12),
          Wrap(spacing: 12, children: [
            _infoBadge(
              _statusLabel(manga.status),
              _statusColor(manga.status),
              icon: Icons.circle,
            ),
            if (manga.year != null) _infoBadge('${manga.year}', Colors.white38),
            _infoBadge(manga.contentRating.toUpperCase(), Colors.blueGrey),
          ]),
          const SizedBox(height: 14),
          // Start Reading button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _chapters.isNotEmpty
                  ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MangaReaderPage(
                            chapter: _chapters.last, // first chapter (earliest)
                            mangaTitle: manga.title,
                          ),
                        ),
                      )
                  : null,
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              label: Text('Start Reading',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: tokens.glassGradient,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: tokens.outline),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _metaStat(
                    'Chapters',
                    _loadingChapters ? '...' : '${_chapters.length}',
                    Icons.menu_book_rounded,
                  ),
                ),
                Expanded(
                  child: _metaStat(
                    'Status',
                    _statusLabel(manga.status)
                        .replaceFirst(RegExp(r'^[^A-Za-z]+'), '')
                        .trim(),
                    Icons.bolt_rounded,
                  ),
                ),
                Expanded(
                  child: _metaStat(
                    'Rating',
                    manga.contentRating.toUpperCase(),
                    Icons.verified_user_rounded,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaStat(String label, String value, IconData icon) {
    final colors = Theme.of(context).colorScheme;
    final tokens = context.appTokens;
    return Column(
      children: [
        Icon(icon, color: colors.primary, size: 18),
        const SizedBox(height: 8),
        Text(
          value,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            color: colors.onSurface,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            color: tokens.textMuted,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _infoBadge(String text, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) Icon(icon, color: color, size: 8),
          if (icon != null) const SizedBox(width: 4),
          Text(text, style: GoogleFonts.outfit(color: color, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildTags(MangaItem manga) {
    final tokens = context.appTokens;
    if (manga.tags.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: manga.tags
            .take(8)
            .map((tag) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: tokens.panel,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: tokens.outline),
                  ),
                  child: Text(tag,
                      style: GoogleFonts.outfit(
                          color: tokens.textMuted, fontSize: 10)),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildDescription(MangaItem manga) {
    final colors = Theme.of(context).colorScheme;
    final tokens = context.appTokens;
    final desc = manga.description;
    if (desc.isEmpty) return const SizedBox.shrink();
    final truncated = desc.length > 200;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: tokens.glassGradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: tokens.outline),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('SYNOPSIS',
              style: GoogleFonts.outfit(
                  color: colors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5)),
          const SizedBox(height: 8),
          Text(
            _showFullDesc || !truncated ? desc : '${desc.substring(0, 200)}...',
            style: GoogleFonts.outfit(
                color: tokens.textSoft, fontSize: 13, height: 1.5),
          ),
          if (truncated)
            GestureDetector(
              onTap: () => setState(() => _showFullDesc = !_showFullDesc),
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _showFullDesc ? 'Show less ▲' : 'Read more ▼',
                  style: GoogleFonts.outfit(
                      color: colors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _buildChapterHeader() {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
      child: Row(children: [
        Text('CHAPTERS',
            style: GoogleFonts.outfit(
                color: colors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5)),
        const SizedBox(width: 8),
        if (!_loadingChapters)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('${_chapters.length}',
                style: GoogleFonts.outfit(
                    color: colors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ),
      ]),
    );
  }

  Widget _buildChapterList() {
    if (_loadingChapters) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(
                color: Color(0xFFBB52FF), strokeWidth: 2),
          ),
        ),
      );
    }
    if (_chapters.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text('No English chapters available',
                style: GoogleFonts.outfit(color: context.appTokens.textMuted)),
          ),
        ),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (ctx, i) => _ChapterTile(
          chapter: _chapters[i],
          mangaTitle: widget.manga.title,
          index: i,
        ),
        childCount: _chapters.length,
      ),
    );
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'ongoing':
        return '● Ongoing';
      case 'completed':
        return '✓ Completed';
      case 'hiatus':
        return '⏸ Hiatus';
      default:
        return s;
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'ongoing':
        return Colors.greenAccent;
      case 'completed':
        return Colors.blueAccent;
      case 'hiatus':
        return Colors.orangeAccent;
      default:
        return Colors.grey;
    }
  }
}

// ── Chapter tile ──────────────────────────────────────────────────────────────
class _ChapterTile extends StatelessWidget {
  final ChapterItem chapter;
  final String mangaTitle;
  final int index;
  const _ChapterTile(
      {required this.chapter, required this.mangaTitle, required this.index});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tokens = context.appTokens;
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              MangaReaderPage(chapter: chapter, mangaTitle: mangaTitle),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: tokens.glassGradient,
          border: Border.all(color: tokens.outline),
        ),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.primary.withValues(alpha: 0.12),
            ),
            child: Center(
              child: Text(
                chapter.chapter ?? '?',
                style: GoogleFonts.outfit(
                    color: colors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(chapter.displayTitle,
                  style: GoogleFonts.outfit(
                      color: colors.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              if (chapter.publishedAt != null)
                Text(
                  _formatDate(chapter.publishedAt!),
                  style:
                      GoogleFonts.outfit(color: tokens.textMuted, fontSize: 11),
                ),
            ]),
          ),
          if (chapter.pageCount > 0)
            Text('${chapter.pageCount}p',
                style:
                    GoogleFonts.outfit(color: tokens.textMuted, fontSize: 11)),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right_rounded, color: tokens.textMuted, size: 18),
        ]),
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inDays == 0) return 'Today';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 30) return '${diff.inDays}d ago';
      if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
      return '${(diff.inDays / 365).floor()}y ago';
    } catch (_) {
      return '';
    }
  }
}
