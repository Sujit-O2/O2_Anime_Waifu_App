import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:anime_waifu/services/user_profile/affection_service.dart';

class ChatAnalyticsPage extends StatefulWidget {
  const ChatAnalyticsPage({super.key});

  @override
  State<ChatAnalyticsPage> createState() => _ChatAnalyticsPageState();
}

class _ChatAnalyticsPageState extends State<ChatAnalyticsPage> {
  bool _loading = true;
  int _totalMessages = 0;
  int _userMessages = 0;
  int _ztMessages = 0;
  int _totalWords = 0;
  int _longestStreak = 0;
  Map<String, int> _topEmojis = <String, int>{};
  List<Map<String, dynamic>> _weekActivity = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final snap = await FirebaseFirestore.instance
          .collection('chats')
          .doc(user.uid)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .get();

      int userMsgs = 0;
      int ztMsgs = 0;
      int totalWords = 0;
      final emojiCount = <String, int>{};
      final emojiRegex = RegExp(
        r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]',
        unicode: true,
      );

      final weekDays = List<Map<String, dynamic>>.generate(7, (i) {
        final day = DateTime.now().subtract(Duration(days: 6 - i));
        return <String, dynamic>{'day': _dayLabel(day.weekday), 'count': 0};
      });

      final dayBounds = List<DateTime>.generate(
        7,
        (i) => DateTime.now().subtract(Duration(days: 6 - i)),
      );

      for (final doc in snap.docs) {
        final data = doc.data();
        final role = data['role'] as String? ?? '';
        final content = data['content'] as String? ?? '';
        final ts = data['timestamp'];

        if (role == 'user') {
          userMsgs++;
        } else {
          ztMsgs++;
        }

        final words = content.trim().isEmpty
            ? 0
            : content
                .trim()
                .split(RegExp(r'\s+'))
                .where((word) => word.isNotEmpty)
                .length;
        totalWords += words;

        for (final match in emojiRegex.allMatches(content)) {
          final emoji = match.group(0)!;
          emojiCount[emoji] = (emojiCount[emoji] ?? 0) + 1;
        }

        if (ts is Timestamp) {
          final dt = ts.toDate();
          for (int i = 0; i < dayBounds.length; i++) {
            final day = dayBounds[i];
            if (dt.year == day.year &&
                dt.month == day.month &&
                dt.day == day.day) {
              weekDays[i]['count'] = (weekDays[i]['count'] as int) + 1;
            }
          }
        }
      }

      final sortedEmoji = emojiCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      if (!mounted) {
        return;
      }

      setState(() {
        _totalMessages = snap.docs.length;
        _userMessages = userMsgs;
        _ztMessages = ztMsgs;
        _totalWords = totalWords;
        _topEmojis = Map<String, int>.fromEntries(sortedEmoji.take(5));
        _weekActivity = weekDays;
        _longestStreak = AffectionService.instance.streakDays;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _refresh() => _load();

  String _dayLabel(int weekday) {
    return <String>[
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun'
    ][weekday - 1];
  }

  double get _averageWordsPerMessage {
    if (_userMessages == 0) {
      return 0;
    }
    return _totalWords / _userMessages;
  }

  int get _peakDayCount {
    return _weekActivity.fold<int>(
      0,
      (maxValue, day) =>
          (day['count'] as int) > maxValue ? day['count'] as int : maxValue,
    );
  }

  String get _commentaryMood {
    if (_totalMessages >= 100) {
      return 'achievement';
    }
    if (_totalMessages >= 20) {
      return 'motivated';
    }
    return 'neutral';
  }

  @override
  Widget build(BuildContext context) {
    return FeaturePageV2(
      title: 'CHAT ANALYTICS',
      onBack: () => Navigator.pop(context),
      content: _loading
          ? _buildLoadingState()
          : RefreshIndicator(
              onRefresh: _refresh,
              color: V2Theme.primaryColor,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
                children: [
                      _buildOverviewCard(),
                      const SizedBox(height: 12),
                      WaifuCommentary(mood: _commentaryMood),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              title: 'Messages',
                              value: '$_totalMessages',
                              icon: Icons.chat_bubble_outline_rounded,
                              color: V2Theme.primaryColor,
                            ),
                          ),
                          Expanded(
                            child: StatCard(
                              title: 'Your Side',
                              value: '$_userMessages',
                              icon: Icons.person_outline_rounded,
                              color: V2Theme.secondaryColor,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              title: 'Zero Two',
                              value: '$_ztMessages',
                              icon: Icons.favorite_border_rounded,
                              color: Colors.purpleAccent,
                            ),
                          ),
                          Expanded(
                            child: StatCard(
                              title: 'Word Count',
                              value: '$_totalWords',
                              icon: Icons.text_fields_rounded,
                              color: Colors.amberAccent,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              title: 'Streak',
                              value: '${_longestStreak}d',
                              icon: Icons.local_fire_department_rounded,
                              color: Colors.orangeAccent,
                            ),
                          ),
                          Expanded(
                            child: StatCard(
                              title: 'Avg Length',
                              value: _averageWordsPerMessage == 0
                                  ? '0'
                                  : _averageWordsPerMessage.toStringAsFixed(1),
                              icon: Icons.analytics_rounded,
                              color: Colors.lightGreenAccent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildActivityCard(),
                      const SizedBox(height: 12),
                      _buildEmojiCard(),
                      const SizedBox(height: 12),
                      _buildInsightCard(),
                      if (_totalMessages == 0) ...[
                        const SizedBox(height: 12),
                        EmptyState(
                          icon: Icons.forum_outlined,
                          title: 'No chat history yet',
                          subtitle:
                              'Once you start talking, I will turn your conversations into insights and streaks here.',
                          buttonText: 'Refresh',
                          onButtonPressed: _load,
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildOverviewCard() {
    final ratio = _totalMessages == 0 ? 0.0 : _userMessages / _totalMessages;
    return AnimatedEntry(
      index: 1,
      child: GlassCard(
        margin: EdgeInsets.zero,
        glow: true,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Conversation health',
                    style: GoogleFonts.outfit(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _totalMessages == 0
                        ? 'Waiting for first message'
                        : '$_totalMessages messages tracked',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _totalMessages == 0
                        ? 'Start chatting and I will build a richer picture of your shared rhythm.'
                        : 'Your side contributes ${(_averageWordsPerMessage).toStringAsFixed(1)} words per message on average, with a $_longestStreak day streak currently stored.',
                    style: GoogleFonts.outfit(
                      color: Colors.white60,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            ProgressRing(
              progress: ratio,
              foreground: V2Theme.primaryColor,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.favorite_rounded,
                    color: V2Theme.primaryColor,
                    size: 28,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${(ratio * 100).round()}%',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Your share',
                    style: GoogleFonts.outfit(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard() {
    return AnimatedEntry(
      index: 2,
      child: GlassCard(
        margin: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last 7 Days Activity',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Peak daily volume: $_peakDayCount messages',
              style: GoogleFonts.outfit(
                color: Colors.white60,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 18),
            _activityChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmojiCard() {
    return AnimatedEntry(
      index: 3,
      child: GlassCard(
        margin: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Most Used Emojis',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Your most frequent mood markers from chat history.',
              style: GoogleFonts.outfit(
                color: Colors.white60,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            if (_topEmojis.isEmpty)
              Text(
                'No emojis found in chats yet.',
                style: GoogleFonts.outfit(
                  color: Colors.white38,
                  fontSize: 13,
                ),
              )
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _topEmojis.entries.map((entry) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white.withValues(alpha: 0.04),
                      border: Border.all(
                        color: V2Theme.primaryColor.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(entry.key, style: const TextStyle(fontSize: 24)),
                        const SizedBox(height: 4),
                        Text(
                          'x${entry.value}',
                          style: GoogleFonts.outfit(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard() {
    final message = _totalMessages == 0
        ? 'Your analytics room is ready. Once conversations start, I will highlight your rhythm here.'
        : _totalMessages > 100
            ? 'This is a deep archive now. Your conversation with Zero Two has real momentum.'
            : 'You are building a steady rhythm. A few more long chats will make the trend lines much richer.';

    return AnimatedEntry(
      index: 4,
      child: GlassCard(
        margin: EdgeInsets.zero,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: V2Theme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Waifu Insight',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    style: GoogleFonts.outfit(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        const SizedBox(height: 12),
        GlassCard(
          margin: EdgeInsets.zero,
          child: Column(
            children: List<Widget>.generate(
              4,
              (index) => Padding(
                padding: EdgeInsets.only(bottom: index == 3 ? 0 : 10),
                child: Container(
                  height: index == 0 ? 24 : 14,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _activityChart() {
    final maxCount = _peakDayCount == 0 ? 1 : _peakDayCount;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: _weekActivity.map((day) {
        final count = day['count'] as int;
        final height = (count / maxCount) * 110;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$count',
              style: GoogleFonts.outfit(
                color: count == 0 ? Colors.white38 : V2Theme.primaryColor,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              width: 28,
              height: count == 0 ? 8 : height.clamp(8, 110),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: count == 0
                    ? null
                    : const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [V2Theme.primaryColor, V2Theme.secondaryColor],
                      ),
                color: count == 0 ? Colors.white.withValues(alpha: 0.08) : null,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              day['day']?.toString() ?? '',
              style: GoogleFonts.outfit(
                color: Colors.white54,
                fontSize: 10,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}




