import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:anime_waifu/services/memory_context/smart_photo_memory_service.dart';
import 'package:anime_waifu/config/app_themes.dart';
import 'package:anime_waifu/services/database_storage/app_db.dart';

/// 💕 Photo Memory Album Screen
/// 
/// Beautiful gallery view of all shared photos with AI captions,
/// mood filtering, and anniversary slideshow generation.
class PhotoMemoryAlbumPage extends StatefulWidget {
  const PhotoMemoryAlbumPage({super.key});

  @override
  State<PhotoMemoryAlbumPage> createState() => _PhotoMemoryAlbumPageState();
}

class _PhotoMemoryAlbumPageState extends State<PhotoMemoryAlbumPage>
    with SingleTickerProviderStateMixin {
  final _service = SmartPhotoMemoryService.instance;
  late TabController _tabController;
  
  MoodType? _selectedMoodFilter;
  bool _showFavoritesOnly = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    unawaited(AppDB.instance.recordUsage('photo_memory'));
    _tabController = TabController(length: 4, vsync: this);
    _initializeService();
  }

  Future<void> _initializeService() async {
    await _service.initialize();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<PhotoMemory> _getFilteredMemories() {
    var memories = _service.getAllMemories();
    
    if (_showFavoritesOnly) {
      memories = memories.where((m) => m.isFavorite).toList();
    }
    
    if (_selectedMoodFilter != null) {
      memories = memories.where((m) => m.detectedMood == _selectedMoodFilter).toList();
    }
    
    return memories;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Photo Memories',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
              color: _showFavoritesOnly ? Colors.pinkAccent : Colors.white54,
            ),
            onPressed: () {
              setState(() => _showFavoritesOnly = !_showFavoritesOnly);
            },
            tooltip: 'Show favorites only',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'insights') {
                _showInsightsDialog();
              } else if (value == 'slideshow') {
                _generateSlideshow();
              } else if (value == 'clear') {
                _confirmClearAll();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'insights',
                child: Row(
                  children: [
                    Icon(Icons.analytics_outlined),
                    SizedBox(width: 8),
                    Text('Emotional Insights'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'slideshow',
                child: Row(
                  children: [
                    Icon(Icons.slideshow),
                    SizedBox(width: 8),
                    Text('Anniversary Slideshow'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.redAccent),
                    SizedBox(width: 8),
                    Text('Clear All', style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Today'),
            Tab(text: 'Week'),
            Tab(text: 'Month'),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.1),
              theme.colorScheme.secondary.withValues(alpha: 0.05),
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  const SizedBox(height: 120), // AppBar spacing
                  _buildMoodFilter(context),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildMemoryGrid(_getFilteredMemories()),
                        _buildMemoryGrid(_service.getTodayMemories()),
                        _buildMemoryGrid(_service.getWeekMemories()),
                        _buildMemoryGrid(_service.getMonthMemories()),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildMoodFilter(BuildContext context) {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildMoodChip(null, 'All', '📸', context),
          ...MoodType.values.map((mood) => 
            _buildMoodChip(mood, mood.label, mood.emoji, context)
          ),
        ],
      ),
    );
  }

  Widget _buildMoodChip(MoodType? mood, String label, String emoji, BuildContext context) {
    final isSelected = _selectedMoodFilter == mood;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 4),
            Text(label),
          ],
        ),
        onSelected: (selected) {
          setState(() {
            _selectedMoodFilter = selected ? mood : null;
          });
        },
        backgroundColor: context.appTokens.panel,
        selectedColor: context.appTokens.panelElevated,
        side: BorderSide(
          color: isSelected ? Theme.of(context).colorScheme.primary : context.appTokens.outline,
          width: isSelected ? 2 : 1,
        ),
      ),
    );
  }

  Widget _buildMemoryGrid(List<PhotoMemory> memories) {
    if (memories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No memories yet',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Share photos with Zero Two to create memories!',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: memories.length,
      itemBuilder: (context, index) {
        return _buildMemoryCard(memories[index]);
      },
    );
  }

  Widget _buildMemoryCard(PhotoMemory memory) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: () => _showMemoryDetail(memory),
      child: Hero(
        tag: 'memory_${memory.id}',
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Image
                Image.file(
                  File(memory.imagePath),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.broken_image, size: 48),
                  ),
                ),
                // Gradient overlay
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          memory.aiCaption,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              memory.detectedMood.emoji,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _formatTimestamp(memory.timestamp),
                                style: GoogleFonts.outfit(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Favorite badge
                if (memory.isFavorite)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.pinkAccent.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.pinkAccent.withValues(alpha: 0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    
    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else if (diff.inDays < 30) {
      return '${(diff.inDays / 7).floor()} weeks ago';
    } else if (diff.inDays < 365) {
      return '${(diff.inDays / 30).floor()} months ago';
    } else {
      return '${(diff.inDays / 365).floor()} years ago';
    }
  }

  void _showMemoryDetail(PhotoMemory memory) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MemoryDetailSheet(memory: memory),
    );
  }

  void _showInsightsDialog() {
    final insights = _service.getEmotionalInsights();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emotional Insights'),
        content: SingleChildScrollView(
          child: Text(insights),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateSlideshow() async {
    final slideshow = await _service.generateAnniversarySlideshow();
    
    if (slideshow == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not enough memories to create a slideshow yet!'),
        ),
      );
      return;
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _SlideshowScreen(slideshow: slideshow),
      ),
    );
  }

  void _confirmClearAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Memories?'),
        content: const Text(
          'This will permanently delete all photo memories. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _service.clearAllMemories();
              if (!mounted) return;
              Navigator.pop(context);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All memories cleared')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}

/// Memory detail bottom sheet
class _MemoryDetailSheet extends StatefulWidget {
  final PhotoMemory memory;

  const _MemoryDetailSheet({required this.memory});

  @override
  State<_MemoryDetailSheet> createState() => _MemoryDetailSheetState();
}

class _MemoryDetailSheetState extends State<_MemoryDetailSheet> {
  final _service = SmartPhotoMemoryService.instance;
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.memory.isFavorite;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);

    return Container(
      height: size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Image
          Expanded(
            child: Hero(
              tag: 'memory_${widget.memory.id}',
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: Image.file(
                  File(widget.memory.imagePath),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 64),
                ),
              ),
            ),
          ),
          // Details
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.memory.detectedMood.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.memory.aiCaption,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: _isFavorite ? Colors.pinkAccent : Colors.white54,
                      ),
                      onPressed: () async {
                        await _service.toggleFavorite(widget.memory.id);
                        setState(() => _isFavorite = !_isFavorite);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _formatFullTimestamp(widget.memory.timestamp),
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                if (widget.memory.userNote != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    widget.memory.userNote!,
                    style: GoogleFonts.outfit(fontSize: 14),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatFullTimestamp(DateTime timestamp) {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year} at ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}

/// Anniversary slideshow screen
class _SlideshowScreen extends StatelessWidget {
  final AnniversarySlideshow slideshow;

  const _SlideshowScreen({required this.slideshow});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(slideshow.title),
      ),
      body: PageView.builder(
        itemCount: slideshow.memories.length,
        itemBuilder: (context, index) {
          final memory = slideshow.memories[index];
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Image.file(
                    File(memory.imagePath),
                    fit: BoxFit.contain,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    memory.aiCaption,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
