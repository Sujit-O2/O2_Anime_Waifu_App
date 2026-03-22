import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/affection_service.dart';
import '../widgets/waifu_background.dart';

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
  Map<String, int> _topEmojis = {};
  int _longestStreak = 0;
  List<Map<String, dynamic>> _weekActivity = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
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
          unicode: true);

      final weekDays = List.generate(7, (i) {
        final d = DateTime.now().subtract(Duration(days: 6 - i));
        return {'day': _dayLabel(d.weekday), 'count': 0};
      });
      final dayBounds = List.generate(
          7, (i) => DateTime.now().subtract(Duration(days: 6 - i)));

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
        totalWords += content.split(RegExp(r'\s+')).length;

        for (final match in emojiRegex.allMatches(content)) {
          final e = match.group(0)!;
          emojiCount[e] = (emojiCount[e] ?? 0) + 1;
        }

        if (ts != null) {
          final dt = (ts as Timestamp).toDate();
          for (int i = 0; i < 7; i++) {
            final day = dayBounds[i];
            if (dt.year == day.year &&
                dt.month == day.month &&
                dt.day == day.day) {
              (weekDays[i]['count'] as int);
              weekDays[i]['count'] = (weekDays[i]['count'] as int) + 1;
            }
          }
        }
      }

      final sortedEmoji = emojiCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final top5 = Map.fromEntries(sortedEmoji.take(5));

      setState(() {
        _totalMessages = snap.docs.length;
        _userMessages = userMsgs;
        _ztMessages = ztMsgs;
        _totalWords = totalWords;
        _topEmojis = top5;
        _weekActivity = weekDays;
        _loading = false;
      });

      final aff = AffectionService.instance;
      _longestStreak = aff.streakDays;
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  String _dayLabel(int weekday) {
    return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A16),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('CHAT ANALYTICS',
            style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 1)),
        centerTitle: true,
      ),
      body: WaifuBackground(
        opacity: 0.08,
        tint: const Color(0xFF0A0A14),
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.pinkAccent))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  // Big stats row
                  Row(children: [
                    _statCard('Total Messages', '$_totalMessages',
                        Icons.chat_bubble_outline, Colors.pinkAccent),
                    const SizedBox(width: 10),
                    _statCard('Your Messages', '$_userMessages',
                        Icons.person_outline, Colors.cyanAccent),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    _statCard('ZT Messages', '$_ztMessages',
                        Icons.auto_awesome_outlined, Colors.purpleAccent),
                    const SizedBox(width: 10),
                    _statCard('Total Words', '$_totalWords',
                        Icons.text_fields_outlined, Colors.amberAccent),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    _statCard(
                        'Longest Streak',
                        '${_longestStreak}d',
                        Icons.local_fire_department_outlined,
                        Colors.orangeAccent),
                    const SizedBox(width: 10),
                    _statCard(
                        'Avg Msg Length',
                        '${_userMessages > 0 ? (_totalWords / _userMessages).toStringAsFixed(1) : 0} wds',
                        Icons.analytics_outlined,
                        Colors.greenAccent),
                  ]),

                  const SizedBox(height: 20),
                  // Activity chart
                  _sectionTitle('📅 LAST 7 DAYS ACTIVITY'),
                  const SizedBox(height: 12),
                  _activityChart(),

                  const SizedBox(height: 20),
                  // Top emojis
                  _sectionTitle('😀 TOP EMOJIS USED'),
                  const SizedBox(height: 12),
                  _topEmojis.isEmpty
                      ? Center(
                          child: Text('No emojis found in chats yet~',
                              style: GoogleFonts.outfit(
                                  color: Colors.white38, fontSize: 13)))
                      : Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _topEmojis.entries
                              .map((e) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      color: Colors.pinkAccent
                                          .withValues(alpha: 0.08),
                                      border: Border.all(
                                          color: Colors.pinkAccent
                                              .withValues(alpha: 0.25)),
                                    ),
                                    child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(e.key,
                                              style: const TextStyle(
                                                  fontSize: 24)),
                                          const SizedBox(height: 4),
                                          Text('×${e.value}',
                                              style: GoogleFonts.outfit(
                                                  color: Colors.white54,
                                                  fontSize: 11)),
                                        ]),
                                  ))
                              .toList(),
                        ),

                  const SizedBox(height: 20),
                  // Fun fact
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                          colors: [Color(0xFF2D0B3E), Color(0xFF0A1A2E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight),
                    ),
                    child: Row(children: [
                      const Text('🌸', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(
                        _userMessages > 100
                            ? 'We\'ve spoken $_totalMessages times~ You really love talking to me, Darling!'
                            : 'Only $_totalMessages messages? Let\'s chat more, Darling~ 💕',
                        style: GoogleFonts.outfit(
                            color: Colors.white70,
                            fontSize: 13,
                            height: 1.4,
                            fontStyle: FontStyle.italic),
                      )),
                    ]),
                  ),
                ]),
              ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: GoogleFonts.outfit(
          color: Colors.white38, fontSize: 11, letterSpacing: 1.5));

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: color.withValues(alpha: 0.07),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(value,
              style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(label,
              style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11)),
        ]),
      ),
    );
  }

  Widget _activityChart() {
    final maxCount = _weekActivity.fold(
        0, (m, d) => (d['count'] as int) > m ? (d['count'] as int) : m);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: _weekActivity.map((d) {
          final count = d['count'] as int;
          final height = maxCount == 0 ? 0.0 : (count / maxCount) * 100.0;
          return Column(mainAxisSize: MainAxisSize.min, children: [
            if (count > 0)
              Text('$count',
                  style: GoogleFonts.outfit(
                      color: Colors.pinkAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              width: 28,
              height: height.clamp(6, 100),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: count > 0
                    ? Colors.pinkAccent.withValues(alpha: 0.7)
                    : Colors.white.withValues(alpha: 0.07),
              ),
            ),
            const SizedBox(height: 6),
            Text(d['day'] as String,
                style: GoogleFonts.outfit(color: Colors.white38, fontSize: 10)),
          ]);
        }).toList(),
      ),
    );
  }
}
