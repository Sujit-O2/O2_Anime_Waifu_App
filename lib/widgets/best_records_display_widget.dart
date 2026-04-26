import 'dart:math' as math;

import 'package:anime_waifu/services/user_profile/affection_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Displays lifetime records and high scores across the app.
class BestRecordsDisplay extends StatefulWidget {
  final bool compact;
  final bool showHeader;

  const BestRecordsDisplay({
    super.key,
    this.compact = false,
    this.showHeader = true,
  });

  @override
  State<BestRecordsDisplay> createState() => _BestRecordsDisplayState();
}

class _BestRecordsDisplayState extends State<BestRecordsDisplay> {
  static final _emptyRecords = _RecordsSnapshot.empty();

  _RecordsSnapshot? _records;
  bool _isLoading = true;
  bool _isRefreshing = false;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _loadBestRecords(showLoading: true);
  }

  Future<void> _loadBestRecords({bool showLoading = false}) async {
    if (_isRefreshing && !showLoading) return;
    final generation = ++_loadGeneration;

    if (showLoading && mounted) {
      setState(() => _isLoading = true);
    } else if (mounted) {
      setState(() => _isRefreshing = true);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final affectionService = AffectionService.instance;
      final records = _RecordsSnapshot(
        rpsWins: prefs.getInt('game_rps_wins') ?? 0,
        rpsLosses: prefs.getInt('game_rps_losses') ?? 0,
        triviaWins: prefs.getInt('game_trivia_wins') ?? 0,
        triviaTotal: prefs.getInt('game_trivia_total') ?? 0,
        tttWins: prefs.getInt('game_ttt_wins') ?? 0,
        tttLosses: prefs.getInt('game_ttt_losses') ?? 0,
        affectionPoints: affectionService.points,
        affectionLevel: affectionService.levelName,
        dailyQuestsCompleted: prefs.getInt('daily_quests_completed') ?? 0,
        milestonesReached: prefs.getInt('milestones_reached') ?? 0,
        bossDefeats: prefs.getInt('boss_defeats') ?? 0,
        raidGoldEarned: prefs.getInt('raid_gold_earned') ?? 0,
        eventParticipation: prefs.getInt('event_participation') ?? 0,
        achievementsUnlocked: prefs.getInt('achievements_unlocked') ?? 0,
        legendaryPulls: prefs.getInt('legendary_pulls') ?? 0,
      );

      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _records = records;
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading best records: $e');
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: _isLoading
          ? const _RecordsLoading(key: ValueKey('loading'))
          : widget.compact
              ? _buildCompact(context, key: const ValueKey('compact'))
              : _buildFull(context, key: const ValueKey('full')),
    );
  }

  Widget _buildCompact(BuildContext context, {required Key key}) {
    final records = _records ?? _emptyRecords;

    return Semantics(
      key: key,
      label: 'Best records summary',
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: _cardDecoration(Colors.amberAccent),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.emoji_events_rounded,
                    color: Colors.amberAccent, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Records',
                  style: _titleStyle(14),
                ),
                const Spacer(),
                _RefreshIconButton(
                  isRefreshing: _isRefreshing,
                  onPressed: _isLoading
                      ? null
                      : () => _loadBestRecords(showLoading: false),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildRecordRow(
                'RPS Wins', '${records.rpsWins}', Colors.cyanAccent),
            _buildRecordRow(
              'Trivia',
              '${records.triviaWins}/${records.triviaTotal}',
              Colors.amberAccent,
            ),
            _buildRecordRow(
              'Affection',
              '${records.affectionLevel} (${records.affectionPoints} pts)',
              Colors.pinkAccent,
            ),
            _buildRecordRow(
              'Events',
              '${records.eventParticipation}',
              Colors.deepPurpleAccent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFull(BuildContext context, {required Key key}) {
    final records = _records ?? _emptyRecords;
    final width = MediaQuery.sizeOf(context).width;
    final useGrid = width >= 560;

    final sections = [
      _RecordSection(
        title: 'Mini Games',
        icon: Icons.sports_esports_rounded,
        tiles: [
          _RecordTileData(
            label: 'Rock-Paper-Scissors',
            value: '${records.rpsWins} wins / ${records.rpsLosses} losses',
            progress:
                _safeRate(records.rpsWins, records.rpsWins + records.rpsLosses),
            color: Colors.cyanAccent,
          ),
          _RecordTileData(
            label: 'Anime Trivia',
            value: '${records.triviaWins}/${records.triviaTotal} correct',
            progress: _safeRate(records.triviaWins, records.triviaTotal),
            color: Colors.amberAccent,
          ),
          _RecordTileData(
            label: 'Tic-Tac-Toe',
            value: '${records.tttWins} wins / ${records.tttLosses} losses',
            progress:
                _safeRate(records.tttWins, records.tttWins + records.tttLosses),
            color: Colors.lightGreenAccent,
          ),
        ],
      ),
      _RecordSection(
        title: 'Relationship',
        icon: Icons.favorite_rounded,
        tiles: [
          _RecordTileData(
            label: 'Affection Status',
            value: '${records.affectionLevel} - ${records.affectionPoints} pts',
            progress: (records.affectionPoints / 10000).clamp(0.0, 1.0),
            color: Colors.pinkAccent,
          ),
          _RecordTileData(
            label: 'Daily Quests',
            value: '${records.dailyQuestsCompleted} completed',
            color: Colors.purpleAccent,
          ),
        ],
      ),
      _RecordSection(
        title: 'Achievements',
        icon: Icons.workspace_premium_rounded,
        tiles: [
          _RecordTileData(
            label: 'Achievements Unlocked',
            value: '${records.achievementsUnlocked}',
            color: Colors.deepOrangeAccent,
          ),
          _RecordTileData(
            label: 'Milestones Reached',
            value: '${records.milestonesReached}',
            color: Colors.tealAccent,
          ),
          _RecordTileData(
            label: 'Events Participated',
            value: '${records.eventParticipation}',
            color: Colors.deepPurpleAccent,
          ),
        ],
      ),
      _RecordSection(
        title: 'Combat & Gacha',
        icon: Icons.auto_awesome_rounded,
        tiles: [
          _RecordTileData(
            label: 'Boss Defeats',
            value: '${records.bossDefeats}',
            color: Colors.redAccent,
          ),
          _RecordTileData(
            label: 'Raid Rewards',
            value: '${records.raidGoldEarned} gold earned',
            color: Colors.amberAccent,
          ),
          _RecordTileData(
            label: 'Legendary Pulls',
            value: '${records.legendaryPulls}',
            color: Colors.yellowAccent,
          ),
        ],
      ),
    ];

    return RefreshIndicator(
      key: key,
      color: Colors.pinkAccent,
      backgroundColor: const Color(0xFF17111E),
      onRefresh: () => _loadBestRecords(showLoading: false),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showHeader) _buildHeader(records),
            const SizedBox(height: 16),
            for (final section in sections) ...[
              _buildSection(section, useGrid: useGrid),
              const SizedBox(height: 18),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(_RecordsSnapshot records) {
    final totalWins = records.rpsWins + records.triviaWins + records.tttWins;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(Colors.pinkAccent),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.amberAccent.withValues(alpha: 0.14),
              border:
                  Border.all(color: Colors.amberAccent.withValues(alpha: 0.36)),
            ),
            child: const Icon(Icons.emoji_events_rounded,
                color: Colors.amberAccent, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Best Records', style: _titleStyle(20)),
                const SizedBox(height: 3),
                Text(
                  '$totalWins wins tracked across games and milestones',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: Colors.white.withValues(alpha: 0.62),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _RefreshIconButton(
            isRefreshing: _isRefreshing,
            onPressed:
                _isLoading ? null : () => _loadBestRecords(showLoading: false),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(_RecordSection section, {required bool useGrid}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(section.icon, color: Colors.white60, size: 18),
            const SizedBox(width: 8),
            Text(
              section.title,
              style: GoogleFonts.outfit(
                color: Colors.white.withValues(alpha: 0.68),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (useGrid)
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth =
                  math.max(220.0, (constraints.maxWidth - 10) / 2);
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final tile in section.tiles)
                    RepaintBoundary(
                      child: SizedBox(
                        width: itemWidth,
                        child: _RecordTile(data: tile),
                      ),
                    ),
                ],
              );
            },
          )
        else
          for (final tile in section.tiles) ...[
            RepaintBoundary(child: _RecordTile(data: tile)),
            const SizedBox(height: 10),
          ],
      ],
    );
  }

  Widget _buildRecordRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _titleStyle(double size) {
    return GoogleFonts.outfit(
      color: Colors.white,
      fontSize: size,
      fontWeight: FontWeight.w900,
    );
  }

  BoxDecoration _cardDecoration(Color accent) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      color: const Color(0xFF0D0D1A).withValues(alpha: 0.72),
      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      boxShadow: [
        BoxShadow(
          color: accent.withValues(alpha: 0.08),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.24),
          blurRadius: 18,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  double? _safeRate(int wins, int total) {
    if (total <= 0) return null;
    return (wins / total).clamp(0.0, 1.0);
  }
}

class _RecordTile extends StatelessWidget {
  final _RecordTileData data;

  const _RecordTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final progress = data.progress;

    return Semantics(
      label: progress == null
          ? '${data.label}, ${data.value}'
          : '${data.label}, ${data.value}, ${(progress * 100).round()} percent',
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: data.color.withValues(alpha: 0.26)),
          color: data.color.withValues(alpha: 0.055),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    data.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (progress != null)
                  Text(
                    '${(progress * 100).round()}%',
                    style: GoogleFonts.outfit(
                      color: data.color.withValues(alpha: 0.9),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              data.value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                color: data.color,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (progress != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: Colors.white.withValues(alpha: 0.09),
                  valueColor: AlwaysStoppedAnimation(data.color),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RefreshIconButton extends StatelessWidget {
  final bool isRefreshing;
  final VoidCallback? onPressed;

  const _RefreshIconButton({
    required this.onPressed,
    this.isRefreshing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Refresh records',
      child: IconButton.filledTonal(
        onPressed: isRefreshing ? null : onPressed,
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 160),
          child: isRefreshing
              ? const SizedBox.square(
                  key: ValueKey('refreshing'),
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(
                  Icons.refresh_rounded,
                  key: ValueKey('refresh'),
                  size: 18,
                ),
        ),
        color: Colors.white,
        style: IconButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.08),
          disabledBackgroundColor: Colors.white.withValues(alpha: 0.04),
          minimumSize: const Size.square(40),
        ),
      ),
    );
  }
}

class _RecordsLoading extends StatelessWidget {
  const _RecordsLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFF0D0D1A).withValues(alpha: 0.72),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: const SizedBox(
        height: 96,
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _RecordSection {
  final String title;
  final IconData icon;
  final List<_RecordTileData> tiles;

  const _RecordSection({
    required this.title,
    required this.icon,
    required this.tiles,
  });
}

class _RecordTileData {
  final String label;
  final String value;
  final double? progress;
  final Color color;

  const _RecordTileData({
    required this.label,
    required this.value,
    required this.color,
    this.progress,
  });
}

class _RecordsSnapshot {
  final int rpsWins;
  final int rpsLosses;
  final int triviaWins;
  final int triviaTotal;
  final int tttWins;
  final int tttLosses;
  final int affectionPoints;
  final String affectionLevel;
  final int dailyQuestsCompleted;
  final int milestonesReached;
  final int bossDefeats;
  final int raidGoldEarned;
  final int eventParticipation;
  final int achievementsUnlocked;
  final int legendaryPulls;

  const _RecordsSnapshot({
    required this.rpsWins,
    required this.rpsLosses,
    required this.triviaWins,
    required this.triviaTotal,
    required this.tttWins,
    required this.tttLosses,
    required this.affectionPoints,
    required this.affectionLevel,
    required this.dailyQuestsCompleted,
    required this.milestonesReached,
    required this.bossDefeats,
    required this.raidGoldEarned,
    required this.eventParticipation,
    required this.achievementsUnlocked,
    required this.legendaryPulls,
  });

  factory _RecordsSnapshot.empty() {
    return const _RecordsSnapshot(
      rpsWins: 0,
      rpsLosses: 0,
      triviaWins: 0,
      triviaTotal: 0,
      tttWins: 0,
      tttLosses: 0,
      affectionPoints: 0,
      affectionLevel: 'New Bond',
      dailyQuestsCompleted: 0,
      milestonesReached: 0,
      bossDefeats: 0,
      raidGoldEarned: 0,
      eventParticipation: 0,
      achievementsUnlocked: 0,
      legendaryPulls: 0,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is _RecordsSnapshot &&
            other.rpsWins == rpsWins &&
            other.rpsLosses == rpsLosses &&
            other.triviaWins == triviaWins &&
            other.triviaTotal == triviaTotal &&
            other.tttWins == tttWins &&
            other.tttLosses == tttLosses &&
            other.affectionPoints == affectionPoints &&
            other.affectionLevel == affectionLevel &&
            other.dailyQuestsCompleted == dailyQuestsCompleted &&
            other.milestonesReached == milestonesReached &&
            other.bossDefeats == bossDefeats &&
            other.raidGoldEarned == raidGoldEarned &&
            other.eventParticipation == eventParticipation &&
            other.achievementsUnlocked == achievementsUnlocked &&
            other.legendaryPulls == legendaryPulls;
  }

  @override
  int get hashCode => Object.hashAll([
        rpsWins,
        rpsLosses,
        triviaWins,
        triviaTotal,
        tttWins,
        tttLosses,
        affectionPoints,
        affectionLevel,
        dailyQuestsCompleted,
        milestonesReached,
        bossDefeats,
        raidGoldEarned,
        eventParticipation,
        achievementsUnlocked,
        legendaryPulls,
      ]);
}
