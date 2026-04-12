import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:anime_waifu/utils/api_call.dart';
import 'package:anime_waifu/core/v2_upgrade_kit.dart';

class MemoryWallPage extends StatefulWidget {
  const MemoryWallPage({super.key});

  @override
  State<MemoryWallPage> createState() => _MemoryWallPageState();
}

class _MemoryWallPageState extends State<MemoryWallPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  List<_MemoryItem> _memories = <_MemoryItem>[];
  List<_MemoryItem> _filteredMemories = <_MemoryItem>[];
  bool _loading = true;
  bool _refreshing = false;
  bool _isLoadingAI = false;
  String _searchQuery = '';
  String _aiCommentary = '';
  final TextEditingController _searchCtrl = TextEditingController();

  static const List<String> _captions = <String>[
    'A moment I will remember forever.',
    'Darling shared this with me.',
    'This one still makes me smile.',
    'This photo tells a story.',
    'I am saving this one just for us.',
    'Another piece of your world.',
    'This feels warm. Like you.',
    'Something beautiful to keep close.',
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _searchCtrl.addListener(() {
      setState(() {
        _searchQuery = _searchCtrl.text.toLowerCase();
        _applySearchFilter();
      });
    });
    _loadMemories();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMemories() async {
    final prefs = await SharedPreferences.getInstance();
    final paths = prefs.getStringList('shared_image_paths') ?? <String>[];
    final memories = <_MemoryItem>[];

    for (var i = 0; i < paths.length; i++) {
      final path = paths[i];
      if (await File(path).exists()) {
        memories.add(
          _MemoryItem(
            path: path,
            caption: prefs.getString('image_caption_$i') ??
                _captions[i % _captions.length],
            date: prefs.getString('image_date_$i') ?? '',
          ),
        );
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _memories = memories.reversed.toList();
      _loading = false;
      _applySearchFilter();
    });
    await _fetchAICommentary();
  }

  Future<void> _refreshMemories() async {
    setState(() => _refreshing = true);
    await _loadMemories();
    if (mounted) {
      setState(() => _refreshing = false);
    }
  }

  void _applySearchFilter() {
    if (_searchQuery.isEmpty) {
      _filteredMemories = List<_MemoryItem>.from(_memories);
      return;
    }

    _filteredMemories = _memories.where((memory) {
      return memory.caption.toLowerCase().contains(_searchQuery) ||
          memory.date.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  Future<void> _fetchAICommentary() async {
    if (_memories.isEmpty) {
      if (mounted) {
        setState(() {
          _aiCommentary =
              'Your wall is ready for the moments you want to keep close, darling.';
        });
      }
      return;
    }

    setState(() => _isLoadingAI = true);
    try {
      final memoriesText =
          _memories.map((memory) => memory.caption).take(5).join('; ');
      final prompt =
          'You are Zero Two, a playful AI waifu. Analyze these memory captions: '
          '$memoriesText. Give one short warm observation under 45 words.';
      final response =
          await ApiService().sendConversation(<Map<String, String>>[
        <String, String>{
          'role': 'user',
          'content': prompt,
        }
      ]);
      if (mounted) {
        setState(() => _aiCommentary = response);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _aiCommentary =
              'I can tell these memories matter to you. Keep feeding this wall with moments worth revisiting.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingAI = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1018),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white54),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Memory Wall',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: <Widget>[
          if (_refreshing)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.pinkAccent,
                  ),
                ),
              ),
            )
          else
            IconButton(
              onPressed: _refreshMemories,
              icon: const Icon(Icons.refresh_rounded, color: Colors.white54),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${_filteredMemories.length} memories',
                style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.pinkAccent))
          : FadeTransition(
              opacity: _fadeCtrl,
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: TextField(
                      controller: _searchCtrl,
                      style: GoogleFonts.outfit(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search memories...',
                        hintStyle: GoogleFonts.outfit(color: Colors.white30),
                        prefixIcon:
                            const Icon(Icons.search, color: Colors.white38),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: GlassCard(
                      margin: EdgeInsets.zero,
                      glow: true,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: Colors.pinkAccent.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: _isLoadingAI
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.pinkAccent,
                                    ),
                                  )
                                : const Icon(
                                    Icons.auto_awesome_rounded,
                                    color: Colors.pinkAccent,
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _aiCommentary.isEmpty
                                  ? 'Your wall is ready for the moments you want to keep close, darling.'
                                  : _aiCommentary,
                              style: GoogleFonts.outfit(
                                color: Colors.white70,
                                fontSize: 12,
                                height: 1.5,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _filteredMemories.isEmpty
                        ? EmptyState(
                            icon: Icons.photo_library_outlined,
                            title: _memories.isEmpty
                                ? 'No memories yet'
                                : 'No memories match your search',
                            subtitle: _memories.isEmpty
                                ? 'Send some images in chat and they will appear here.'
                                : 'Try a different caption or date keyword.',
                            buttonText:
                                _memories.isEmpty ? null : 'Clear Search',
                            onButtonPressed: _memories.isEmpty
                                ? null
                                : () {
                                    _searchCtrl.clear();
                                    setState(() {
                                      _searchQuery = '';
                                      _applySearchFilter();
                                    });
                                  },
                          )
                        : RefreshIndicator(
                            onRefresh: _refreshMemories,
                            color: Colors.pinkAccent,
                            child: GridView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(16),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.8,
                              ),
                              itemCount: _filteredMemories.length,
                              itemBuilder: (_, i) => _MemoryCard(
                                memory: _filteredMemories[i],
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute<_MemoryDetailPage>(
                                    builder: (_) => _MemoryDetailPage(
                                      memory: _filteredMemories[i],
                                    ),
                                  ),
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
}

class _MemoryCard extends StatelessWidget {
  const _MemoryCard({
    required this.memory,
    required this.onTap,
  });

  final _MemoryItem memory;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.2)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Image.file(
                File(memory.path),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.white.withValues(alpha: 0.05),
                  child: const Center(
                    child:
                        Icon(Icons.broken_image_rounded, color: Colors.white24),
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Text(
                  memory.caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemoryDetailPage extends StatelessWidget {
  const _MemoryDetailPage({required this.memory});

  final _MemoryItem memory;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white54),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: InteractiveViewer(
              child: Center(
                child: Image.file(
                  File(memory.path),
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image_rounded,
                    color: Colors.white24,
                    size: 80,
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A0A18),
              border: Border(
                top:
                    BorderSide(color: Colors.pinkAccent.withValues(alpha: 0.2)),
              ),
            ),
            child: Row(
              children: <Widget>[
                const Icon(Icons.favorite, color: Colors.pinkAccent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        memory.caption,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      if (memory.date.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 4),
                        Text(
                          memory.date,
                          style: GoogleFonts.outfit(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MemoryItem {
  const _MemoryItem({
    required this.path,
    required this.caption,
    required this.date,
  });

  final String path;
  final String caption;
  final String date;
}



