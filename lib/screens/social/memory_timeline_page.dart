import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:anime_waifu/services/ai_personalization/emotional_memory_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MemoryTimelinePage extends StatefulWidget {
  const MemoryTimelinePage({super.key});

  @override
  State<MemoryTimelinePage> createState() => _MemoryTimelinePageState();
}

class _MemoryTimelinePageState extends State<MemoryTimelinePage> {
  List<EmotionalMemory> _memories = <EmotionalMemory>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() => _loading = true);
    }
    final memories = await EmotionalMemoryService.instance.getAllMemories();
    if (!mounted) {
      return;
    }
    setState(() {
      _memories = memories;
      _loading = false;
    });
  }

  Future<void> _pin(EmotionalMemory memory) async {
    await EmotionalMemoryService.instance.pinMemory(memory.id);
    await _load();
    if (!mounted) {
      return;
    }
    showSuccessSnackbar(context, 'Pinned memory to the top tier.');
  }

  Future<void> _forget(EmotionalMemory memory) async {
    final approved = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: V2Theme.surfaceLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Forget this memory?',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              memory.text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                height: 1.4,
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Forget'),
              ),
            ],
          ),
        ) ??
        false;

    if (!approved) {
      return;
    }

    await EmotionalMemoryService.instance.forgetMemory(memory.id);
    await _load();
    if (!mounted) {
      return;
    }
    showSuccessSnackbar(context, 'Memory removed from the timeline.');
  }

  @override
  Widget build(BuildContext context) {
    final pinnedCount = _memories.where((memory) => memory.pinned).length;
    final highImportance =
        _memories.where((memory) => memory.importance >= 0.75).length;
    final mood = _memories.length >= 10
        ? 'achievement'
        : _memories.isEmpty
            ? 'neutral'
            : 'motivated';

    return Scaffold(
      backgroundColor: V2Theme.surfaceDark,
      body: WaifuBackground(
        opacity: 0.08,
        tint: V2Theme.surfaceDark,
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _load,
            color: V2Theme.primaryColor,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white70,
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    'Memory Timeline',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    'Emotional moments, pins, and important memories.',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                      ],
                    ),
                  ),
                ),
                if (_loading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: V2Theme.primaryColor,
                      ),
                    ),
                  )
                else if (_memories.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.history_toggle_off_rounded,
                      title: 'No memories saved yet',
                      subtitle:
                          'Meaningful emotional moments will appear here automatically after your chats.',
                    ),
                  )
                else ...<Widget>[
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: StatCard(
                              title: 'All Memories',
                              value: '${_memories.length}',
                              icon: Icons.auto_stories_rounded,
                              color: V2Theme.primaryColor,
                            ),
                          ),
                          Expanded(
                            child: StatCard(
                              title: 'Pinned',
                              value: '$pinnedCount',
                              icon: Icons.push_pin_rounded,
                              color: Colors.amberAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: StatCard(
                              title: 'High Weight',
                              value: '$highImportance',
                              icon: Icons.favorite_rounded,
                              color: Colors.pinkAccent,
                            ),
                          ),
                          Expanded(
                            child: StatCard(
                              title: 'Latest',
                              value: _formatDate(_memories.first.timestamp),
                              icon: Icons.schedule_rounded,
                              color: V2Theme.secondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverList.separated(
                    itemCount: _memories.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final memory = _memories[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: AnimatedEntry(
                          index: index,
                          child: GlassCard(
                            margin: EdgeInsets.zero,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: _emotionColor(memory.emotion)
                                        .withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    _emotionIcon(memory.emotion),
                                    color: _emotionColor(memory.emotion),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Row(
                                        children: <Widget>[
                                          Expanded(
                                            child: Text(
                                              memory.emotion.label,
                                              style: GoogleFonts.outfit(
                                                color: _emotionColor(
                                                    memory.emotion),
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          if (memory.pinned)
                                            const Icon(
                                              Icons.push_pin_rounded,
                                              color: Colors.amberAccent,
                                              size: 18,
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        memory.text,
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          height: 1.45,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        child: LinearProgressIndicator(
                                          minHeight: 6,
                                          value: memory.importance,
                                          backgroundColor: Colors.white10,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            _emotionColor(memory.emotion),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: <Widget>[
                                          Text(
                                            '${(memory.importance * 10).round()}/10 importance',
                                            style: GoogleFonts.outfit(
                                              color: Colors.white54,
                                              fontSize: 11,
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            _formatDate(memory.timestamp),
                                            style: GoogleFonts.outfit(
                                              color: Colors.white38,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: <Widget>[
                                          if (!memory.pinned)
                                            FilledButton.tonal(
                                              onPressed: () => _pin(memory),
                                              style: FilledButton.styleFrom(
                                                backgroundColor: Colors
                                                    .amberAccent
                                                    .withValues(alpha: 0.16),
                                                foregroundColor:
                                                    Colors.amberAccent,
                                              ),
                                              child: const Text('Pin'),
                                            ),
                                          const Spacer(),
                                          TextButton(
                                            onPressed: () => _forget(memory),
                                            child: const Text(
                                              'Forget',
                                              style: TextStyle(
                                                color: Colors.redAccent,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Color _emotionColor(MemoryEmotion emotion) {
    return switch (emotion) {
      MemoryEmotion.love => Colors.pinkAccent,
      MemoryEmotion.happy => Colors.greenAccent,
      MemoryEmotion.sad => V2Theme.secondaryColor,
      MemoryEmotion.angry => Colors.deepOrangeAccent,
      MemoryEmotion.scared => Colors.amberAccent,
      MemoryEmotion.amused => Colors.purpleAccent,
      MemoryEmotion.neutral => Colors.white54,
    };
  }

  static IconData _emotionIcon(MemoryEmotion emotion) {
    return switch (emotion) {
      MemoryEmotion.love => Icons.favorite_rounded,
      MemoryEmotion.happy => Icons.sentiment_very_satisfied_rounded,
      MemoryEmotion.sad => Icons.sentiment_dissatisfied_rounded,
      MemoryEmotion.angry => Icons.local_fire_department_rounded,
      MemoryEmotion.scared => Icons.bolt_rounded,
      MemoryEmotion.amused => Icons.mood_rounded,
      MemoryEmotion.neutral => Icons.chat_bubble_outline_rounded,
    };
  }

  static String _formatDate(DateTime? timestamp) {
    if (timestamp == null) {
      return 'Unknown';
    }
    final difference = DateTime.now().difference(timestamp);
    if (difference.inDays == 0) {
      return 'Today';
    }
    if (difference.inDays == 1) {
      return 'Yesterday';
    }
    if (difference.inDays < 30) {
      return '${difference.inDays}d ago';
    }
    return '${(difference.inDays / 30).floor()}mo ago';
  }
}



