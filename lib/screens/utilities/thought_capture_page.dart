import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:anime_waifu/core/v2_upgrade_kit.dart';

class ThoughtCapturePage extends StatefulWidget {
  const ThoughtCapturePage({super.key});

  @override
  State<ThoughtCapturePage> createState() => _ThoughtCapturePageState();
}

class _ThoughtCapturePageState extends State<ThoughtCapturePage>
    with TickerProviderStateMixin {
  late AnimationController _animController;
  List<CapturedThought> _thoughts = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedMood = 'All';
  final List<String> _moods = [
    'All',
    '💡 Idea',
    '📝 Note',
    '🎯 Goal',
    '❤️ Feeling'
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        duration: const Duration(milliseconds: 600), vsync: this)
      ..forward();
    _loadData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await V2Storage.init();
    final saved = V2Storage.getMap('thoughts_data');
    setState(() {
      if (saved != null && saved['thoughts'] != null) {
        _thoughts = (saved['thoughts'] as List)
            .map((t) => CapturedThought.fromJson(t))
            .toList();
      } else {
        _thoughts = _generateSampleThoughts();
      }
      _isLoading = false;
    });
  }

  List<CapturedThought> _generateSampleThoughts() {
    return [
      CapturedThought(
          id: '1',
          content: 'Learn Flutter state management patterns',
          mood: '💡 Idea',
          createdAt: DateTime.now().subtract(const Duration(hours: 2))),
      CapturedThought(
          id: '2',
          content: 'Remember to call mom this weekend',
          mood: '📝 Note',
          createdAt: DateTime.now().subtract(const Duration(hours: 5))),
      CapturedThought(
          id: '3',
          content: 'Finish the project documentation',
          mood: '🎯 Goal',
          createdAt: DateTime.now().subtract(const Duration(days: 1))),
      CapturedThought(
          id: '4',
          content: 'Grateful for the supportive team at work',
          mood: '❤️ Feeling',
          createdAt:
              DateTime.now().subtract(const Duration(days: 1, hours: 3))),
      CapturedThought(
          id: '5',
          content: 'Try that new ramen place downtown',
          mood: '💡 Idea',
          createdAt: DateTime.now().subtract(const Duration(days: 2))),
    ];
  }

  Future<void> _saveData() async {
    await V2Storage.setMap('thoughts_data',
        {'thoughts': _thoughts.map((t) => t.toJson()).toList()});
  }

  List<CapturedThought> get _filteredThoughts {
    return _thoughts.where((t) {
      final matchesSearch =
          t.content.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesMood = _selectedMood == 'All' || t.mood == _selectedMood;
      return matchesSearch && matchesMood;
    }).toList();
  }

  void _addThought() {
    final contentController = TextEditingController();
    String mood = '💡 Idea';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          height: MediaQuery.of(ctx).size.height * 0.65,
          decoration: const BoxDecoration(
              color: V2Theme.surfaceLight,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
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
                          borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              const Text('Capture Thought',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 24),
              TextField(
                  controller: contentController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 4,
                  autofocus: true,
                  decoration: InputDecoration(
                      hintText: 'What\'s on your mind?',
                      hintStyle: TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: V2Theme.darkGlass,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none))),
              const SizedBox(height: 20),
              const Text('Mood/Type', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 12),
              Wrap(
                  spacing: 8,
                  children: _moods
                      .where((m) => m != 'All')
                      .map((m) => GestureDetector(
                            onTap: () => setModalState(() => mood = m),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                gradient:
                                    mood == m ? V2Theme.primaryGradient : null,
                                color: mood == m ? null : V2Theme.darkGlass,
                                borderRadius: BorderRadius.circular(20),
                                border: mood == m
                                    ? null
                                    : Border.all(color: Colors.white12),
                              ),
                              child: Text(m,
                                  style: TextStyle(
                                      color: mood == m
                                          ? Colors.white
                                          : Colors.white70)),
                            ),
                          ))
                      .toList()),
              const Spacer(),
              SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                      onPressed: () {
                        if (contentController.text.isEmpty) return;
                        HapticFeedback.mediumImpact();
                        final thought = CapturedThought(
                            id: DateTime.now()
                                .millisecondsSinceEpoch
                                .toString(),
                            content: contentController.text,
                            mood: mood,
                            createdAt: DateTime.now());
                        setState(() => _thoughts.insert(0, thought));
                        _saveData();
                        Navigator.pop(ctx);
                        showSuccessSnackbar(context, 'Thought captured! 💭');
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: V2Theme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16))),
                      child: const Text('Save',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)))),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteThought(CapturedThought thought) {
    setState(() => _thoughts.remove(thought));
    _saveData();
    showUndoSnackbar(context, 'Thought deleted', () {
      setState(() => _thoughts.insert(0, thought));
      _saveData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: V2Theme.surfaceDark,
      body: CustomScrollView(
        slivers: [
          _buildHeader(),
          _buildSearchBar(),
          _buildMoodFilters(),
          _buildThoughtsList(),
        ],
      ),
      floatingActionButton: V2FloatingActionButton(onPressed: _addThought),
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
            child: const Text('Thought Capture',
                style: TextStyle(fontWeight: FontWeight.bold))),
        background: Container(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
              Colors.cyan.withValues(alpha: 0.4),
              Colors.transparent
            ]))),
      ),
      leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context)),
      actions: [
        IconButton(icon: const Icon(Icons.cloud_sync), onPressed: () {})
      ],
    );
  }

  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: AnimatedEntry(
          index: 0,
          child: Padding(
              padding: const EdgeInsets.all(16),
              child: V2SearchBar(
                  hintText: 'Search thoughts...',
                  onChanged: (v) => setState(() => _searchQuery = v)))),
    );
  }

  Widget _buildMoodFilters() {
    return SliverToBoxAdapter(
      child: AnimatedEntry(
          index: 1,
          child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                  children: _moods.map((mood) {
                final isSelected = _selectedMood == mood;
                return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(mood),
                      selected: isSelected,
                      onSelected: (s) => setState(() => _selectedMood = mood),
                      selectedColor: V2Theme.primaryColor,
                      backgroundColor: V2Theme.darkGlass,
                      labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70),
                    ));
              }).toList()))),
    );
  }

  Widget _buildThoughtsList() {
    if (_isLoading) {
      return const SliverFillRemaining(
          child: Center(
              child: CircularProgressIndicator(color: V2Theme.primaryColor)));
    }
    if (_filteredThoughts.isEmpty) {
      return SliverFillRemaining(
          child: EmptyState(
              icon: Icons.lightbulb_outline,
              title: _searchQuery.isEmpty ? 'No Thoughts Yet' : 'No Results',
              subtitle: _searchQuery.isEmpty
                  ? 'Capture your first thought!'
                  : 'Try a different search',
              buttonText: _searchQuery.isEmpty ? 'Capture' : null,
              onButtonPressed: _searchQuery.isEmpty ? _addThought : null));
    }
    return SliverPadding(
      padding: const EdgeInsets.only(top: 16, bottom: 100),
      sliver: SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
        final thought = _filteredThoughts[index];
        return AnimatedEntry(
            index: index + 2,
            child: SwipeToDismissItem(
                onDismissed: () => _deleteThought(thought),
                child: GlassCard(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (ctx) => Container(
                              padding: const EdgeInsets.all(24),
                              decoration: const BoxDecoration(
                                  color: V2Theme.surfaceLight,
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(30))),
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Center(
                                        child: Container(
                                            width: 40,
                                            height: 4,
                                            decoration: BoxDecoration(
                                                color: Colors.white24,
                                                borderRadius:
                                                    BorderRadius.circular(2)))),
                                    const SizedBox(height: 24),
                                    Text(thought.mood,
                                        style: const TextStyle(fontSize: 32)),
                                    const SizedBox(height: 16),
                                    Text(thought.content,
                                        style: const TextStyle(
                                            fontSize: 18, color: Colors.white),
                                        textAlign: TextAlign.center),
                                    const SizedBox(height: 16),
                                    Text(_formatDateTime(thought.createdAt),
                                        style: const TextStyle(
                                            color: Colors.white54)),
                                    const SizedBox(height: 24),
                                  ]),
                            ));
                  },
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color:
                                    V2Theme.primaryColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12)),
                            child: Text(thought.mood,
                                style: const TextStyle(fontSize: 24))),
                        const SizedBox(width: 16),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(thought.content,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 15),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 8),
                              Text(_formatTime(thought.createdAt),
                                  style: const TextStyle(
                                      color: Colors.white38, fontSize: 12)),
                            ])),
                      ]),
                )));
      }, childCount: _filteredThoughts.length)),
    );
  }

  String _formatTime(DateTime dt) {
    if (dt.day == DateTime.now().day) {
      return 'Today, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day}/${dt.month}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year} at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

class CapturedThought {
  final String id;
  final String content;
  final String mood;
  final DateTime createdAt;

  CapturedThought(
      {required this.id,
      required this.content,
      required this.mood,
      required this.createdAt});
  factory CapturedThought.fromJson(Map<String, dynamic> json) =>
      CapturedThought(
          id: json['id'],
          content: json['content'],
          mood: json['mood'],
          createdAt: DateTime.parse(json['createdAt']));
  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'mood': mood,
        'createdAt': createdAt.toIso8601String()
      };
}



