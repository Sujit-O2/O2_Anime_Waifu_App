import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:anime_waifu/models/chat_message.dart';

class ChatStatisticsPage extends StatelessWidget {
  const ChatStatisticsPage({
    super.key,
    required this.messages,
  });

  final List<ChatMessage> messages;

  @override
  Widget build(BuildContext context) {
    final userMessages = messages.where((message) => message.role == 'user');
    final aiMessages = messages.where((message) => message.role == 'assistant');
    final userCount = userMessages.length;
    final aiCount = aiMessages.length;
    final totalWords = userMessages.fold<int>(
      0,
      (sum, message) =>
          sum +
          message.content
              .split(RegExp(r'\s+'))
              .where((word) => word.trim().isNotEmpty)
              .length,
    );
    final distinctDays = messages
        .map((message) => DateUtils.dateOnly(message.timestamp))
        .toSet()
        .length;
    final averageWords = userCount == 0 ? 0 : (totalWords / userCount).round();
    final hourMap = <int, int>{};
    for (final message in messages) {
      hourMap.update(message.timestamp.hour, (value) => value + 1,
          ifAbsent: () => 1);
    }
    final peakHour = hourMap.entries.isEmpty
        ? null
        : hourMap.entries.reduce(
            (left, right) => left.value >= right.value ? left : right,
          );
    final maxHourCount = hourMap.values.isEmpty
        ? 1
        : hourMap.values.reduce((left, right) => left > right ? left : right);
    final topWords = _extractTopWords(
      userMessages.map((message) => message.content),
    );
    final mood = messages.length >= 90
        ? 'achievement'
        : messages.length >= 24
            ? 'motivated'
            : 'neutral';

    return FeaturePageV2(
      title: 'CHAT STATISTICS',
      onBack: () => Navigator.pop(context),
      content: RefreshIndicator(
        onRefresh: () async {},
        color: V2Theme.primaryColor,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    AnimatedEntry(
                      index: 1,
                      child: GlassCard(
                        margin: EdgeInsets.zero,
                        glow: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Conversation Snapshot',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${messages.length} total messages across $distinctDays active days.',
                              style: GoogleFonts.outfit(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: <Widget>[
                                _miniMetric(
                                  label: 'You',
                                  value: '$userCount',
                                  color: V2Theme.primaryColor,
                                ),
                                _miniMetric(
                                  label: 'Her',
                                  value: '$aiCount',
                                  color: V2Theme.secondaryColor,
                                ),
                                _miniMetric(
                                  label: 'Avg Words',
                                  value: '$averageWords',
                                  color: V2Theme.accentColor,
                                ),
                                _miniMetric(
                                  label: 'Peak',
                                  value: peakHour == null
                                      ? '--'
                                      : '${peakHour.key.toString().padLeft(2, '0')}:00',
                                  color: Colors.greenAccent,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    WaifuCommentary(mood: mood),
                  ],
                ),
              ),
            ),
            if (messages.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'No chat history yet',
                  subtitle:
                      'Start talking and this page will fill in with timing, topic, and message patterns.',
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
                          title: 'User Messages',
                          value: '$userCount',
                          icon: Icons.person_outline_rounded,
                          color: V2Theme.primaryColor,
                        ),
                      ),
                      Expanded(
                        child: StatCard(
                          title: 'Assistant Replies',
                          value: '$aiCount',
                          icon: Icons.favorite_outline_rounded,
                          color: V2Theme.secondaryColor,
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
                          title: 'Words Sent',
                          value: '$totalWords',
                          icon: Icons.notes_rounded,
                          color: Colors.orangeAccent,
                        ),
                      ),
                      Expanded(
                        child: StatCard(
                          title: 'Days Active',
                          value: '$distinctDays',
                          icon: Icons.calendar_today_rounded,
                          color: Colors.lightGreenAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: AnimatedEntry(
                    index: 4,
                    child: GlassCard(
                      margin: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Top Topics',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (topWords.isEmpty)
                            Text(
                              'There is not enough text yet to detect recurring topics.',
                              style: GoogleFonts.outfit(
                                color: Colors.white60,
                              ),
                            )
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: topWords
                                  .map(
                                    (entry) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: V2Theme.primaryColor
                                            .withValues(alpha: 0.14),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        border: Border.all(
                                          color: V2Theme.primaryColor
                                              .withValues(alpha: 0.24),
                                        ),
                                      ),
                                      child: Text(
                                        '${entry.key} (${entry.value})',
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  child: AnimatedEntry(
                    index: 3,
                    child: GlassCard(
                      margin: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Hourly Activity',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your most active hour is ${peakHour == null ? '--' : peakHour.key.toString().padLeft(2, '0')}:00.',
                            style: GoogleFonts.outfit(
                              color: Colors.white60,
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            height: 120,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: List<Widget>.generate(24, (hour) {
                                final count = hourMap[hour] ?? 0;
                                final ratio = maxHourCount == 0
                                    ? 0.0
                                    : count / maxHourCount;
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 1.5,
                                    ),
                                    child: Tooltip(
                                      message:
                                          '${hour.toString().padLeft(2, '0')}:00 • $count messages',
                                      child: Align(
                                        alignment: Alignment.bottomCenter,
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 260,
                                          ),
                                          height: 12 + (ratio * 90),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(999),
                                            gradient: LinearGradient(
                                              begin: Alignment.bottomCenter,
                                              end: Alignment.topCenter,
                                              colors: <Color>[
                                                V2Theme.primaryColor
                                                    .withValues(
                                                  alpha: 0.35 + ratio * 0.35,
                                                ),
                                                V2Theme.secondaryColor
                                                    .withValues(
                                                  alpha: 0.2 + ratio * 0.6,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text(
                                '12 AM',
                                style: GoogleFonts.outfit(
                                  color: Colors.white30,
                                  fontSize: 10,
                                ),
                              ),
                              Text(
                                '12 PM',
                                style: GoogleFonts.outfit(
                                  color: Colors.white30,
                                  fontSize: 10,
                                ),
                              ),
                              Text(
                                '11 PM',
                                style: GoogleFonts.outfit(
                                  color: Colors.white30,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static List<MapEntry<String, int>> _extractTopWords(Iterable<String> blocks) {
    const stopWords = <String>{
      'a',
      'an',
      'and',
      'are',
      'be',
      'for',
      'from',
      'how',
      'i',
      'in',
      'is',
      'it',
      'me',
      'my',
      'of',
      'on',
      'that',
      'the',
      'this',
      'to',
      'was',
      'what',
      'with',
      'you',
      'your',
    };

    final counts = <String, int>{};
    for (final block in blocks) {
      for (final rawWord in block.toLowerCase().split(RegExp(r'[^a-z0-9]+'))) {
        if (rawWord.length < 3 || stopWords.contains(rawWord)) {
          continue;
        }
        counts.update(rawWord, (value) => value + 1, ifAbsent: () => 1);
      }
    }

    final sorted = counts.entries.toList()
      ..sort((left, right) => right.value.compareTo(left.value));
    return sorted.take(6).toList();
  }

  Widget _miniMetric({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: GoogleFonts.outfit(
              color: Colors.white60,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}



