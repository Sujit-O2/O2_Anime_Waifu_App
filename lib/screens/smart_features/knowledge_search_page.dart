import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:anime_waifu/services/smart_features/knowledge_search_service.dart';
import 'package:anime_waifu/services/database_storage/app_db.dart';

class KnowledgeSearchPage extends StatefulWidget {
  const KnowledgeSearchPage({super.key});

  @override
  State<KnowledgeSearchPage> createState() => _KnowledgeSearchPageState();
}

class _KnowledgeSearchPageState extends State<KnowledgeSearchPage> {
  final _service = KnowledgeSearchService.instance;
  final _searchCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _sourceCtrl = TextEditingController();

  List<KnowledgeSearchResult> _results = [];
  List<String> _recentSearches = [];
  Map<String, dynamic> _stats = {'total': 0, 'sources': <String, int>{}};
  bool _loading = false;
  bool _aiLoading = false;
  String _selectedSource = 'All';
  Timer? _debounce;

  static const _bg = Color(0xFF0A0B14);
  static const _accent = Color(0xFF00BCD4);

  final List<String> _sourceFilters = [
    'All',
    'Chats',
    'Notes',
    'Memories',
    'Documents',
    'Emails',
  ];

  @override
  void initState() {
    super.initState();
    unawaited(AppDB.instance.recordUsage('knowledge_search'));
    _loadInitialData();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _sourceCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _loading = true);
    try {
      final stats = await _service.getStatistics();
      final recent = await _service.getRecentSearches();
      final entries = await _service.getAllEntries();
      if (mounted) {
        setState(() {
          _stats = stats;
          _recentSearches = recent;
          _results = _searchCtrl.text.isEmpty ? entries : _results;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _performSearch(_searchCtrl.text);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      final entries = await _service.getAllEntries(
          filterSource:
              _selectedSource == 'All' ? null : _selectedSource.toLowerCase());
      if (mounted) {
        setState(() {
          _results = entries;
          _aiLoading = false;
        });
      }
      return;
    }

    setState(() {
      _loading = true;
      _aiLoading = true;
    });

    try {
      final results = await _service.search(query);
      final filtered = _selectedSource == 'All'
          ? results
          : results
              .where((r) =>
                  r.source.toLowerCase() == _selectedSource.toLowerCase())
              .toList();

      if (mounted) {
        setState(() {
          _results = filtered;
          _loading = false;
          _aiLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _aiLoading = false;
        });
      }
    }
  }

  Future<void> _addContent() async {
    _titleCtrl.clear();
    _contentCtrl.clear();
    _sourceCtrl.text = 'note';

    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1B2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Content to Knowledge Base',
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
            const SizedBox(height: 16),
            _buildTextField(_titleCtrl, 'Title', Icons.title_rounded),
            const SizedBox(height: 12),
            _buildTextField(_contentCtrl, 'Content', Icons.description_rounded,
                maxLines: 5),
            const SizedBox(height: 12),
            _buildSourceDropdown(),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveContent,
                icon: const Icon(Icons.save_rounded, size: 18),
                label: Text('Save to Knowledge Base',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController ctrl, String label, IconData icon,
      {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.outfit(color: Colors.white54, fontSize: 13),
        prefixIcon: Icon(icon, color: _accent, size: 18),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _accent.withValues(alpha: 0.5)),
        ),
      ),
    );
  }

  Widget _buildSourceDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _sourceCtrl.text.isNotEmpty ? _sourceCtrl.text : 'note',
          onChanged: (value) => _sourceCtrl.text = value ?? 'note',
          isExpanded: true,
          dropdownColor: const Color(0xFF1A1B2E),
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
          items: ['chat', 'note', 'bookmark', 'memory', 'document', 'email']
              .map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s.toUpperCase(),
                        style: GoogleFonts.outfit(
                            color: Colors.white70, fontSize: 13)),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Future<void> _saveContent() async {
    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();
    final source =
        _sourceCtrl.text.trim().isNotEmpty ? _sourceCtrl.text.trim() : 'note';

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Title and content are required',
            style: GoogleFonts.outfit(color: Colors.white)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }

    await _service.indexContent(
      source: source,
      content: content,
      title: title,
      createdAt: DateTime.now(),
    );

    if (mounted) {
      Navigator.pop(context);
      HapticFeedback.lightImpact();
      final stats = await _service.getStatistics();
      setState(() => _stats = stats);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Content indexed successfully!',
            style: GoogleFonts.outfit(color: Colors.white)),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  void _showResultDetails(KnowledgeSearchResult result) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1B2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                _sourceBadge(result.source),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(result.title,
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Text(result.content,
                  style: GoogleFonts.outfit(
                      color: Colors.white70, fontSize: 14, height: 1.6)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sourceBadge(String source) {
    final color = _sourceColor(source);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        source.toUpperCase(),
        style: GoogleFonts.outfit(
            color: color, fontWeight: FontWeight.w700, fontSize: 10),
      ),
    );
  }

  Color _sourceColor(String source) {
    switch (source.toLowerCase()) {
      case 'chat':
        return const Color(0xFF81C784);
      case 'note':
        return const Color(0xFF64B5F6);
      case 'bookmark':
        return const Color(0xFFFFB74D);
      case 'memory':
        return const Color(0xFFBA68C8);
      case 'document':
        return const Color(0xFFFF7043);
      case 'email':
        return const Color(0xFF4FC3F7);
      default:
        return _accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white60, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('🔍 Knowledge Search',
            style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: _accent),
            onPressed: _addContent,
            tooltip: 'Add Content',
          ),
          IconButton(
            icon:
                const Icon(Icons.delete_outline_rounded, color: Colors.white54),
            onPressed: () async {
              await _service.clearIndex();
              await _loadInitialData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Knowledge base cleared',
                      style: GoogleFonts.outfit(color: Colors.white)),
                  backgroundColor: Colors.redAccent,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ));
              }
            },
            tooltip: 'Clear Index',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                _buildSearchBar(),
                const SizedBox(height: 12),
                _buildFilterChips(),
                const SizedBox(height: 8),
                _buildStatsRow(),
              ],
            ),
          ),
          Expanded(
            child: _loading && _results.isEmpty
                ? _buildLoadingState()
                : _results.isEmpty
                    ? _searchCtrl.text.isEmpty
                        ? _buildRecentSearches()
                        : _buildEmptyState()
                    : _buildResultsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: TextField(
        controller: _searchCtrl,
        style: GoogleFonts.outfit(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Search your knowledge base...',
          hintStyle: GoogleFonts.outfit(color: Colors.white38, fontSize: 14),
          prefixIcon:
              const Icon(Icons.search_rounded, color: _accent, size: 20),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded,
                      color: Colors.white38, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    _performSearch('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _sourceFilters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _sourceFilters[index];
          final isSelected = _selectedSource == filter;
          return FilterChip(
            label: Text(filter,
                style: GoogleFonts.outfit(
                    color: isSelected ? Colors.black : Colors.white70,
                    fontWeight: FontWeight.w600,
                    fontSize: 12)),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                _selectedSource = filter;
              });
              _performSearch(_searchCtrl.text);
            },
            backgroundColor: Colors.white.withValues(alpha: 0.04),
            selectedColor: _accent,
            checkmarkColor: Colors.black,
            side: BorderSide(color: isSelected ? _accent : Colors.white12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 4),
          );
        },
      ),
    );
  }

  Widget _buildStatsRow() {
    final sources = _stats['sources'] as Map? ?? {};
    final total = _stats['total'] as int? ?? 0;
    return Row(
      children: [
        Text('$total items indexed',
            style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11)),
        const Spacer(),
        if (_aiLoading)
          Row(
            children: [
              const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: _accent)),
              const SizedBox(width: 6),
              Text('AI processing...',
                  style: GoogleFonts.outfit(color: _accent, fontSize: 11)),
            ],
          ),
        if (!_aiLoading && sources.isNotEmpty)
          ...sources.entries.take(3).map((e) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text('${e.key}: ${e.value}',
                    style: GoogleFonts.outfit(
                        color: Colors.white38, fontSize: 10)),
              )),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(strokeWidth: 3, color: _accent)),
          const SizedBox(height: 16),
          Text('Searching your knowledge base...',
              style: GoogleFonts.outfit(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                  fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildRecentSearches() {
    if (_recentSearches.isEmpty) {
      return _buildEmptyState();
    }
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SizedBox(height: 8),
        Text('Recent Searches',
            style: GoogleFonts.outfit(
                color: Colors.white54,
                fontWeight: FontWeight.w600,
                fontSize: 13)),
        const SizedBox(height: 12),
        ..._recentSearches.map((search) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: ListTile(
                leading: const Icon(Icons.history_rounded,
                    color: Colors.white38, size: 18),
                title: Text(search,
                    style: GoogleFonts.outfit(
                        color: Colors.white70, fontSize: 14)),
                trailing: const Icon(Icons.north_west_rounded,
                    color: Colors.white24, size: 16),
                onTap: () {
                  _searchCtrl.text = search;
                  _performSearch(search);
                },
              ),
            )),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔍', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text('No results found',
              style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18)),
          const SizedBox(height: 8),
          Text(
              'Try a different search term or add content\nto your knowledge base~',
              style: GoogleFonts.outfit(color: Colors.white38, fontSize: 13),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addContent,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text('Add Content',
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700, fontSize: 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final result = _results[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showResultDetails(result),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _sourceBadge(result.source),
                      const SizedBox(width: 8),
                      if (result.score > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                              '${(result.score * 100).toStringAsFixed(0)}%',
                              style: GoogleFonts.outfit(
                                  color: _accent,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10)),
                        ),
                      const Spacer(),
                      const Icon(Icons.chevron_right_rounded,
                          color: Colors.white24, size: 18),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(result.title,
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Text(
                      result.summary.isNotEmpty
                          ? result.summary
                          : result.content,
                      style: GoogleFonts.outfit(
                          color: Colors.white54, fontSize: 13, height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  if (result.matchedKeywords.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: result.matchedKeywords
                          .take(5)
                          .map((k) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(k,
                                    style: GoogleFonts.outfit(
                                        color: Colors.white38, fontSize: 10)),
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
