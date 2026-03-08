part of '../main.dart';

class QuestsPage extends StatefulWidget {
  final AppThemeMode themeMode;
  final VoidCallback onBack;

  const QuestsPage({
    super.key,
    required this.themeMode,
    required this.onBack,
  });

  @override
  State<QuestsPage> createState() => _QuestsPageState();
}

class _QuestsPageState extends State<QuestsPage> {
  @override
  void initState() {
    super.initState();
    QuestsService.instance.addListener(_onQuestsChanged);
  }

  @override
  void dispose() {
    QuestsService.instance.removeListener(_onQuestsChanged);
    super.dispose();
  }

  void _onQuestsChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.getTheme(widget.themeMode);
    final primary = theme.primaryColor;
    final gradient = AppThemes.getGradient(widget.themeMode);
    final quests = QuestsService.instance.quests;

    final completedCount = quests.where((q) => q.isCompleted).length;
    final progress = quests.isEmpty ? 0.0 : completedCount / quests.length;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              gradient.first.withValues(alpha: 0.95),
              gradient.last.withValues(alpha: 0.95),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                      onPressed: widget.onBack,
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 40, minHeight: 40),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Daily Quests',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),

              // Progress Section
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: primary.withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.1),
                        blurRadius: 20,
                        spreadRadius: -5,
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Today\'s Progress',
                              style: GoogleFonts.outfit(
                                  color: Colors.white70, fontSize: 14)),
                          Text('$completedCount / ${quests.length}',
                              style: GoogleFonts.outfit(
                                  color: primary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Quests List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: quests.length,
                  itemBuilder: (context, index) {
                    final q = quests[index];
                    return _buildQuestCard(q, primary);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestCard(Quest q, Color primary) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: q.isCompleted
            ? primary.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: q.isCompleted
              ? primary.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: q.isCompleted
              ? null
              : () {
                  QuestsService.instance.completeQuest(q.id);
                  // Show a little snackbar reward
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Awesome! +${q.rewardPoints} Affection ❤️',
                          style: GoogleFonts.outfit()),
                      backgroundColor: primary.withOpacity(0.9),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Checkbox
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: q.isCompleted ? primary : Colors.transparent,
                    border: Border.all(
                      color: q.isCompleted ? primary : Colors.white38,
                      width: 2,
                    ),
                  ),
                  child: q.isCompleted
                      ? const Icon(Icons.check, size: 16, color: Colors.black)
                      : null,
                ),
                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        q.title,
                        style: GoogleFonts.outfit(
                          color: q.isCompleted ? Colors.white70 : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          decoration:
                              q.isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        q.description,
                        style: GoogleFonts.outfit(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                // Reward Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.favorite, color: primary, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '+${q.rewardPoints}',
                        style: GoogleFonts.outfit(
                          color: primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
