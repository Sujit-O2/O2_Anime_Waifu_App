import 'package:anime_waifu/services/user_profile/affection_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Displays user's best records and high scores across all games
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
  Map<String, dynamic> bestRecords = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBestRecords();
  }

  Future<void> _loadBestRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final affectionService = AffectionService.instance;
      
      setState(() {
        bestRecords = {
          // 🎮 Mini Games
          'rps_wins': prefs.getInt('game_rps_wins') ?? 0,
          'rps_losses': prefs.getInt('game_rps_losses') ?? 0,
          'trivia_wins': prefs.getInt('game_trivia_wins') ?? 0,
          'trivia_total': prefs.getInt('game_trivia_total') ?? 0,
          'ttt_wins': prefs.getInt('game_ttt_wins') ?? 0,
          'ttt_losses': prefs.getInt('game_ttt_losses') ?? 0,
          
          // ❤️ Relationship
          'affection_points': affectionService.points,
          'affection_level': affectionService.levelName,
          
          // 📊 Game Progress
          'daily_quests_completed': prefs.getInt('daily_quests_completed') ?? 0,
          'milestones_reached': prefs.getInt('milestones_reached') ?? 0,
          'boss_defeats': prefs.getInt('boss_defeats') ?? 0,
          'raid_gold_earned': prefs.getInt('raid_gold_earned') ?? 0,
          
          // 🎪 Events & Achievements
          'event_participation': prefs.getInt('event_participation') ?? 0,
          'achievements_unlocked': prefs.getInt('achievements_unlocked') ?? 0,
          'legendary_pulls': prefs.getInt('legendary_pulls') ?? 0,
        };
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading best records: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoading();
    }

    return widget.compact ? _buildCompact() : _buildFull();
  }

  Widget _buildLoading() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const SizedBox(
        height: 100,
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildCompact() {
    return Card(
      color: Colors.black.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🏆 RECORDS',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildRecordRow('RPS Wins', '${bestRecords['rps_wins']}', Colors.cyanAccent),
            _buildRecordRow('Trivia', '${bestRecords['trivia_wins']}/${bestRecords['trivia_total']}', Colors.amberAccent),
            _buildRecordRow('Affection', '${bestRecords['affection_level']} (${bestRecords['affection_points']}pts)', Colors.pinkAccent),
            _buildRecordRow('Events', '${bestRecords['event_participation']}', Colors.deepPurpleAccent),
          ],
        ),
      ),
    );
  }

  Widget _buildFull() {
    return SingleChildScrollView(
      child: Column(
        children: [
          if (widget.showHeader)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events, color: Colors.amber, size: 28),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BEST RECORDS',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        'Your lifetime achievements and high scores',
                        style: GoogleFonts.outfit(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          
          // 🎮 Mini Games Section
          _buildSection(
            '🎮 MINI GAMES',
            [
              _buildRecordTile(
                'Rock-Paper-Scissors',
                '${bestRecords['rps_wins'] ?? 0} wins · ${bestRecords['rps_losses'] ?? 0} losses',
                ((int.tryParse(bestRecords['rps_wins']?.toString() ?? '0') ?? 0) / ((int.tryParse(bestRecords['rps_wins']?.toString() ?? '0') ?? 0) + (int.tryParse(bestRecords['rps_losses']?.toString() ?? '0') ?? 0)) * 100),
                Colors.cyanAccent,
              ),
              _buildRecordTile(
                'Anime Trivia',
                '${bestRecords['trivia_wins'] ?? 0}/${bestRecords['trivia_total'] ?? 0} correct',
                ((int.tryParse(bestRecords['trivia_wins']?.toString() ?? '0') ?? 0) / ((int.tryParse(bestRecords['trivia_total']?.toString() ?? '0') ?? 0) + 1) * 100),
                Colors.amberAccent,
              ),
              _buildRecordTile(
                'Tic-Tac-Toe',
                '${bestRecords['ttt_wins'] ?? 0} wins · ${bestRecords['ttt_losses'] ?? 0} losses',
                ((int.tryParse(bestRecords['ttt_wins']?.toString() ?? '0') ?? 0) / ((int.tryParse(bestRecords['ttt_wins']?.toString() ?? '0') ?? 0) + (int.tryParse(bestRecords['ttt_losses']?.toString() ?? '0') ?? 0) + 1) * 100),
                Colors.lightGreenAccent,
              ),
            ],
          ),
          
          // ❤️ Relationship Section
          _buildSection(
            '❤️ RELATIONSHIP',
            [
              _buildRecordTile(
                'Affection Status',
                bestRecords['affection_level'] as String,
                (bestRecords['affection_points'] as int) / 10000.0,
                Colors.pinkAccent,
                showProgressBar: true,
              ),
              _buildRecordTile(
                'Daily Quests',
                '${bestRecords['daily_quests_completed']} completed',
                null,
                Colors.purpleAccent,
              ),
            ],
          ),
          
          // 🏅 Achievements Section
          _buildSection(
            '🏅 ACHIEVEMENTS',
            [
              _buildRecordTile(
                'Achievements Unlocked',
                '${bestRecords['achievements_unlocked']}',
                null,
                Colors.deepOrangeAccent,
              ),
              _buildRecordTile(
                'Milestones Reached',
                '${bestRecords['milestones_reached']}',
                null,
                Colors.tealAccent,
              ),
              _buildRecordTile(
                'Events Participated',
                '${bestRecords['event_participation']}',
                null,
                Colors.deepPurpleAccent,
              ),
            ],
          ),
          
          // ⚔️ Combat Section
          _buildSection(
            '⚔️ COMBAT',
            [
              _buildRecordTile(
                'Boss Defeats',
                '${bestRecords['boss_defeats']}',
                null,
                Colors.redAccent,
              ),
              _buildRecordTile(
                'Raid Rewards',
                '${bestRecords['raid_gold_earned']} gold earned',
                null,
                Colors.amberAccent,
              ),
            ],
          ),
          
          // ✨ Gacha Section
          _buildSection(
            '✨ GACHA',
            [
              _buildRecordTile(
                'Legendary Pulls',
                '${bestRecords['legendary_pulls']}',
                null,
                Colors.yellowAccent,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: _loadBestRecords,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white10,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> records) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              color: Colors.white60,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          ...records,
        ],
      ),
    );
  }

  Widget _buildRecordTile(
    String label,
    String value,
    double? winRate,
    Color color, {
    bool showProgressBar = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        color: color.withValues(alpha: 0.05),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                if (showProgressBar) const SizedBox(height: 6),
                if (showProgressBar)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (winRate ?? 0).clamp(0, 1),
                      minHeight: 4,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }


}



