import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:anime_waifu/core/v2_upgrade_kit.dart';

class MemoryVaultPage extends StatefulWidget {
  const MemoryVaultPage({super.key});

  @override
  State<MemoryVaultPage> createState() => _MemoryVaultPageState();
}

class _MemoryVaultPageState extends State<MemoryVaultPage>
    with TickerProviderStateMixin {
  late AnimationController _animController;
  List<MemoryEntry> _memories = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Achievement',
    'Milestone',
    'Special',
    'Daily'
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        duration: const Duration(milliseconds: 600), vsync: this)
      ..forward();
    _loadMemories();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadMemories() async {
    await V2Storage.init();
    final saved = V2Storage.getMap('memory_vault_data');
    setState(() {
      if (saved != null && saved['memories'] != null) {
        _memories = (saved['memories'] as List)
            .map((m) => MemoryEntry.fromJson(m))
            .toList();
      } else {
        _memories = _generateSampleMemories();
      }
      _isLoading = false;
    });
  }

  List<MemoryEntry> _generateSampleMemories() {
    return [
      MemoryEntry(
          id: '1',
          title: 'First Login',
          description: 'Welcome to the app!',
          date: DateTime.now().subtract(const Duration(days: 30)),
          category: 'Milestone',
          emoji: '🎉'),
      MemoryEntry(
          id: '2',
          title: '100 Day Streak',
          description: 'Amazing consistency!',
          date: DateTime.now().subtract(const Duration(days: 10)),
          category: 'Achievement',
          emoji: '🔥'),
      MemoryEntry(
          id: '3',
          title: 'Waifu Level Up',
          description: 'Reached level 15',
          date: DateTime.now().subtract(const Duration(days: 5)),
          category: 'Special',
          emoji: '⭐'),
      MemoryEntry(
          id: '4',
          title: 'Daily Check-in',
          description: 'Kept the streak alive',
          date: DateTime.now().subtract(const Duration(days: 1)),
          category: 'Daily',
          emoji: '✅'),
      MemoryEntry(
          id: '5',
          title: 'First Task Done',
          description: 'Completed first task',
          date: DateTime.now().subtract(const Duration(days: 25)),
          category: 'Milestone',
          emoji: '🎯'),
    ];
  }

  Future<void> _saveMemories() async {
    await V2Storage.setMap('memory_vault_data', {
      'memories': _memories.map((m) => m.toJson()).toList(),
    });
  }

  void _addMemory() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String selectedEmoji = '💭';
    String selectedCat = 'Daily';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: V2Theme.surfaceLight,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 20),
              const Text('Save a Memory',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 24),
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                    hintText: 'Title',
                    hintStyle: TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: V2Theme.darkGlass,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                    hintText: 'Description',
                    hintStyle: TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: V2Theme.darkGlass,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none)),
              ),
              const SizedBox(height: 16),
              const Text('Category', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _categories
                    .where((c) => c != 'All')
                    .map((cat) => ChoiceChip(
                          label: Text(cat),
                          selected: selectedCat == cat,
                          onSelected: (s) =>
                              setModalState(() => selectedCat = cat),
                          selectedColor: V2Theme.primaryColor,
                          backgroundColor: V2Theme.darkGlass,
                          labelStyle: TextStyle(
                              color: selectedCat == cat
                                  ? Colors.white
                                  : Colors.white70),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
              const Text('Emoji', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['💭', '🎉', '⭐', '🔥', '💪', '🌟', '🎯', '💖']
                    .map((e) => GestureDetector(
                          onTap: () => setModalState(() => selectedEmoji = e),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: selectedEmoji == e
                                  ? V2Theme.primaryColor.withValues(alpha: 0.3)
                                  : V2Theme.darkGlass,
                              borderRadius: BorderRadius.circular(12),
                              border: selectedEmoji == e
                                  ? Border.all(color: V2Theme.primaryColor)
                                  : null,
                            ),
                            child:
                                Text(e, style: const TextStyle(fontSize: 24)),
                          ),
                        ))
                    .toList(),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (titleController.text.isEmpty) return;
                    HapticFeedback.mediumImpact();
                    final newMemory = MemoryEntry(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: titleController.text,
                      description: descController.text,
                      date: DateTime.now(),
                      category: selectedCat,
                      emoji: selectedEmoji,
                    );
                    setState(() => _memories.insert(0, newMemory));
                    _saveMemories();
                    Navigator.pop(context);
                    showSuccessSnackbar(context, 'Memory saved! 💕');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: V2Theme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Save Memory',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteMemory(String id) {
    final memory = _memories.firstWhere((m) => m.id == id);
    setState(() => _memories.removeWhere((m) => m.id == id));
    _saveMemories();
    HapticFeedback.mediumImpact();
    showUndoSnackbar(context, 'Memory "${memory.title}" deleted', () {
      setState(() => _memories.insert(0, memory));
      _saveMemories();
    });
  }

  List<MemoryEntry> get _filteredMemories {
    return _memories.where((m) {
      final matchesSearch =
          m.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              m.description.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory =
          _selectedCategory == 'All' || m.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: V2Theme.surfaceDark,
      body: CustomScrollView(
        slivers: [
          _buildHeader(),
          _buildSearchBar(),
          _buildCategories(),
          _buildStats(),
          _buildMemoryList(),
        ],
      ),
      floatingActionButton: V2FloatingActionButton(onPressed: _addMemory),
    );
  }

  Widget _buildHeader() {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: V2Theme.surfaceDark,
      flexibleSpace: FlexibleSpaceBar(
        title: FadeTransition(
          opacity: _animController,
          child: const Text('Memory Vault',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                V2Theme.secondaryColor.withValues(alpha: 0.4),
                Colors.transparent
              ],
            ),
          ),
        ),
      ),
      leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context)),
      actions: [IconButton(icon: const Icon(Icons.tune), onPressed: () {})],
    );
  }

  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: AnimatedEntry(
        index: 0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: V2SearchBar(
            hintText: "Search memories...",
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return SliverToBoxAdapter(
      child: AnimatedEntry(
        index: 1,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: _categories.map((cat) {
              final isSelected = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (s) => setState(() => _selectedCategory = cat),
                  selectedColor: V2Theme.primaryColor,
                  backgroundColor: V2Theme.darkGlass,
                  labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70),
                  checkmarkColor: Colors.white,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildStats() {
    final total = _memories.length;
    final thisMonth =
        _memories.where((m) => m.date.month == DateTime.now().month).length;

    return SliverToBoxAdapter(
      child: AnimatedEntry(
        index: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Expanded(
                  child: StatCard(
                      title: 'Total Memories',
                      value: '$total',
                      icon: Icons.photo_library,
                      color: V2Theme.primaryColor)),
              Expanded(
                  child: StatCard(
                      title: 'This Month',
                      value: '$thisMonth',
                      icon: Icons.calendar_month,
                      color: V2Theme.secondaryColor)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemoryList() {
    if (_isLoading) {
      return const SliverFillRemaining(
          child: Center(
              child: CircularProgressIndicator(color: V2Theme.primaryColor)));
    }

    if (_filteredMemories.isEmpty) {
      return SliverFillRemaining(
        child: EmptyState(
          icon: Icons.photo_album,
          title: _searchQuery.isEmpty ? 'No Memories Yet' : 'No Results',
          subtitle: _searchQuery.isEmpty
              ? 'Start saving your special moments!'
              : 'Try a different search term',
          buttonText: _searchQuery.isEmpty ? 'Add First Memory' : null,
          onButtonPressed: _searchQuery.isEmpty ? _addMemory : null,
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.only(top: 16, bottom: 100),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final memory = _filteredMemories[index];
            return AnimatedEntry(
              index: index + 3,
              child: SwipeToDismissItem(
                onDismissed: () => _deleteMemory(memory.id),
                dismissText: 'Archive',
                dismissColor: Colors.orange,
                child: _buildMemoryCard(memory),
              ),
            );
          },
          childCount: _filteredMemories.length,
        ),
      ),
    );
  }

  Widget _buildMemoryCard(MemoryEntry memory) {
    return GlassCard(
      onTap: () {
        HapticFeedback.lightImpact();
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (context) => Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: V2Theme.surfaceLight,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(memory.emoji, style: const TextStyle(fontSize: 64)),
                const SizedBox(height: 16),
                Text(memory.title,
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 8),
                Text(memory.description,
                    style: TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.white54),
                    const SizedBox(width: 8),
                    Text(_formatDate(memory.date),
                        style: const TextStyle(color: Colors.white54)),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: V2Theme.primaryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(memory.emoji, style: const TextStyle(fontSize: 32)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(memory.title,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 4),
                Text(memory.description,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: V2Theme.secondaryColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(memory.category,
                          style: const TextStyle(
                              fontSize: 11, color: V2Theme.secondaryColor)),
                    ),
                    const SizedBox(width: 8),
                    Text(_formatDate(memory.date),
                        style: const TextStyle(
                            fontSize: 11, color: Colors.white54)),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white24),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class MemoryEntry {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String category;
  final String emoji;

  MemoryEntry(
      {required this.id,
      required this.title,
      required this.description,
      required this.date,
      required this.category,
      required this.emoji});

  factory MemoryEntry.fromJson(Map<String, dynamic> json) {
    return MemoryEntry(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      date: DateTime.parse(json['date']),
      category: json['category'],
      emoji: json['emoji'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'date': date.toIso8601String(),
        'category': category,
        'emoji': emoji,
      };
}



