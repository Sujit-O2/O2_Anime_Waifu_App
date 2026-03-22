import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/chat_message.dart';

/// Beautiful statistics page showing insights about your conversation.
class ChatStatisticsPage extends StatelessWidget {
  final List<ChatMessage> messages;
  const ChatStatisticsPage({super.key, required this.messages});

  @override
  Widget build(BuildContext context) {
    final userMsgs = messages.where((m) => m.role == 'user').toList();
    final aiMsgs = messages.where((m) => m.role == 'assistant').toList();
    final total = messages.length;

    // Hour activity map
    final hourMap = <int, int>{};
    for (final m in messages) {
      hourMap[m.timestamp.hour] = (hourMap[m.timestamp.hour] ?? 0) + 1;
    }
    final peakHour = hourMap.entries.isEmpty
        ? null
        : hourMap.entries.reduce((a, b) => a.value > b.value ? a : b);

    // Word count
    final totalWords = userMsgs.fold<int>(
        0, (sum, m) => sum + m.content.split(' ').length);

    // Top words from user messages
    final wordCount = <String, int>{};
    final stopWords = {'i', 'a', 'the', 'is', 'it', 'to', 'and', 'you', 'me', 'my', 'in', 'that', 'do', 'what', 'can', 'will', 'of', 'for', 'on', 'are', 'be', 'this', 'with', 'how', 'when', 'was'};
    for (final m in userMsgs) {
      for (final word in m.content.toLowerCase().split(RegExp(r'\W+'))) {
        if (word.length > 2 && !stopWords.contains(word)) {
          wordCount[word] = (wordCount[word] ?? 0) + 1;
        }
      }
    }
    final topWords = (wordCount.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(5)
        .toList();

    // Days chatted
    final daySet = <String>{};
    for (final m in messages) {
      daySet.add('${m.timestamp.year}-${m.timestamp.month}-${m.timestamp.day}');
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0613),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white54),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Chat Statistics',
            style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Color(0xFF6C1B7A), Color(0xFF2D0050)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('💕 Your Story with Zero Two',
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('$total total messages • ${daySet.length} days chatted',
                  style: GoogleFonts.outfit(color: Colors.white60, fontSize: 12)),
            ]),
          ),
          const SizedBox(height: 16),
          // Stats grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _StatCard('💬 Your Messages', '${userMsgs.length}', Colors.pinkAccent),
              _StatCard('🤖 Her Replies', '${aiMsgs.length}', Colors.purpleAccent),
              _StatCard('📝 Total Words', '$totalWords', Colors.cyanAccent),
              _StatCard('📅 Days Chatted', '${daySet.length}', Colors.orangeAccent),
              if (peakHour != null)
                _StatCard('⏰ Peak Hour', '${peakHour.key}:00', Colors.greenAccent),
            ],
          ),
          const SizedBox(height: 20),
          // Top topics
          if (topWords.isNotEmpty) ...[
            Text('🏷️ Your Top Topics',
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: topWords.map((e) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.pinkAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.4)),
                  ),
                  child: Text('${e.key} (${e.value})',
                      style: GoogleFonts.outfit(
                          color: Colors.pinkAccent, fontSize: 12, fontWeight: FontWeight.w600)),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 20),
          // Activity heatmap by hour
          if (hourMap.isNotEmpty) ...[
            Text('📊 Hourly Activity',
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            SizedBox(
              height: 50,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(24, (h) {
                  final count = hourMap[h] ?? 0;
                  final maxCount = hourMap.values.isEmpty ? 1 : hourMap.values.reduce((a, b) => a > b ? a : b);
                  final height = maxCount == 0 ? 4.0 : (count / maxCount * 40 + 4).toDouble();
                  return Expanded(
                    child: Tooltip(
                      message: '$h:00 ($count msgs)',
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        height: height,
                        decoration: BoxDecoration(
                          color: count == 0 
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.pinkAccent.withValues(alpha: (count / maxCount * 0.8 + 0.2)),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('12am', style: GoogleFonts.outfit(color: Colors.white30, fontSize: 9)),
                  Text('12pm', style: GoogleFonts.outfit(color: Colors.white30, fontSize: 9)),
                  Text('11pm', style: GoogleFonts.outfit(color: Colors.white30, fontSize: 9)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 30),
        ]),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatCard(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: GoogleFonts.outfit(
                color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(value,
            style: GoogleFonts.outfit(
                color: color, fontSize: 24, fontWeight: FontWeight.w800)),
      ]),
    );
  }
}
