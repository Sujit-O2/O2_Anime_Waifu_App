import 'package:anime_waifu/services/memory_context/conversation_bookmarks_service.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class ConversationBookmarksPage extends StatefulWidget {
  const ConversationBookmarksPage({super.key});

  @override
  State<ConversationBookmarksPage> createState() =>
      _ConversationBookmarksPageState();
}

class _ConversationBookmarksPageState
    extends State<ConversationBookmarksPage> {
  final _service = ConversationBookmarksService.instance;
  final _messageCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  String _query = '';
  String? _activeTag;
  bool _loading = true;
  bool _showAdd = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _noteCtrl.dispose();
    _tagsCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await _service.initialize();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _addBookmark() async {
    if (_messageCtrl.text.trim().isEmpty) return;
    HapticFeedback.mediumImpact();
    await _service.addBookmark(
      messageId: DateTime.now().microsecondsSinceEpoch.toString(),
      messageText: _messageCtrl.text.trim(),
      sender: 'User',
      timestamp: DateTime.now(),
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      tags: _tagsCtrl.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList(),
    );
    _messageCtrl.clear();
    _noteCtrl.clear();
    _tagsCtrl.clear();
    if (mounted) setState(() => _showAdd = false);
  }

  List<BookmarkedMessage> get _filtered {
    if (_activeTag != null) return _service.getBookmarksByTag(_activeTag!);
    if (_query.trim().isNotEmpty) return _service.searchBookmarks(_query);
    return _service.getAllBookmarks();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final stats = _service.getStatistics();
    final tags = _service.getAllTags();
    final bookmarks = _filtered;

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cs.tertiary, cs.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text('Conversation Bookmarks',
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold, color: cs.onTertiary)),
        iconTheme: IconThemeData(color: cs.onTertiary),
        actions: [
          IconButton(
            icon: Icon(_showAdd ? Icons.close_rounded : Icons.add_rounded,
                color: cs.onTertiary),
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() => _showAdd = !_showAdd);
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Stats bar
                Container(
                  color: cs.surfaceContainerLow,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Icon(Icons.bookmark_rounded,
                          color: cs.primary, size: 18),
                      const SizedBox(width: 6),
                      Text(
                          '${stats['total_bookmarks']} saved',
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600)),
                      const Spacer(),
                      if (tags.isNotEmpty)
                        Text('${tags.length} tags',
                            style: GoogleFonts.outfit(
                                color: cs.onSurface.withAlpha(153),
                                fontSize: 12)),
                    ],
                  ),
                ),
                // Add form
                if (_showAdd)
                  Card(
                    margin: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Save a Message',
                              style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _messageCtrl,
                            minLines: 2,
                            maxLines: 5,
                            decoration: InputDecoration(
                              labelText: 'Message to remember',
                              alignLabelWithHint: true,
                              border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _noteCtrl,
                            decoration: InputDecoration(
                              labelText: 'Why it matters (optional)',
                              border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _tagsCtrl,
                            decoration: InputDecoration(
                              labelText: 'Tags (comma separated)',
                              hintText: 'love, important, funny',
                              border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _addBookmark,
                              icon: const Icon(Icons.star_rounded),
                              label: Text('Save Bookmark',
                                  style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Search
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search bookmarks...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _query = '');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      isDense: true,
                    ),
                    onChanged: (v) => setState(() {
                      _query = v;
                      _activeTag = null;
                    }),
                  ),
                ),
                // Tag chips
                if (tags.isNotEmpty)
                  SizedBox(
                    height: 48,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      children: tags
                          .map((tag) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(tag,
                                      style:
                                          GoogleFonts.outfit(fontSize: 12)),
                                  selected: _activeTag == tag,
                                  onSelected: (_) => setState(() {
                                    HapticFeedback.selectionClick();
                                    _activeTag =
                                        _activeTag == tag ? null : tag;
                                    _query = '';
                                    _searchCtrl.clear();
                                  }),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                // List
                Expanded(
                  child: bookmarks.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.bookmark_border_rounded,
                                  size: 64, color: Colors.grey),
                              const SizedBox(height: 12),
                              Text('No bookmarks yet',
                                  style: GoogleFonts.outfit(
                                      fontSize: 18, color: Colors.grey)),
                              Text(
                                  'Tap + to save meaningful messages',
                                  style: GoogleFonts.outfit(
                                      color: Colors.grey)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: bookmarks.length,
                          itemBuilder: (context, index) {
                            final bm = bookmarks[index];
                            return _BookmarkCard(
                              bookmark: bm,
                              onDelete: () async {
                                HapticFeedback.mediumImpact();
                                await _service.removeBookmark(bm.id);
                                if (mounted) setState(() {});
                              },
                              onTagTap: (tag) => setState(() {
                                _activeTag = tag;
                                _query = '';
                                _searchCtrl.clear();
                              }),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _BookmarkCard extends StatelessWidget {
  final BookmarkedMessage bookmark;
  final VoidCallback onDelete;
  final ValueChanged<String> onTagTap;

  const _BookmarkCard({
    required this.bookmark,
    required this.onDelete,
    required this.onTagTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.format_quote_rounded,
                    color: cs.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    bookmark.messageText,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            if (bookmark.note != null) ...[
              const SizedBox(height: 6),
              Text(bookmark.note!,
                  style: GoogleFonts.outfit(
                      color: cs.onSurface.withAlpha(153),
                      fontSize: 12,
                      fontStyle: FontStyle.italic)),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  _formatDate(bookmark.bookmarkedAt),
                  style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: cs.onSurface.withAlpha(120)),
                ),
                const Spacer(),
                if (bookmark.tags.isNotEmpty)
                  Wrap(
                    spacing: 4,
                    children: bookmark.tags
                        .map((tag) => GestureDetector(
                              onTap: () => onTagTap(tag),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: cs.primaryContainer,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(tag,
                                    style: GoogleFonts.outfit(
                                        fontSize: 10,
                                        color: cs.onPrimaryContainer)),
                              ),
                            ))
                        .toList(),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year}';
}
