import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/affection_service.dart';
import '../widgets/waifu_background.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});
  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<Map<String, dynamic>> _xpBoard = [];
  List<Map<String, dynamic>> _affectionBoard = [];
  List<Map<String, dynamic>> _streakBoard = [];
  bool _loading = true;
  final _myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _load();
    _publishMyScore();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _publishMyScore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final aff = AffectionService.instance;
    try {
      await FirebaseFirestore.instance
          .collection('leaderboard')
          .doc(user.uid)
          .set({
        'uid': user.uid,
        'name': user.displayName ?? user.email?.split('@').first ?? 'Darling',
        'photoUrl': user.photoURL ?? '',
        'xp': aff.points,
        'affection': aff.points,
        'streak': aff.streakDays,
        'level': aff.levelName,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> _load() async {
    try {
      final ref = FirebaseFirestore.instance.collection('leaderboard');
      final xp = await ref.orderBy('xp', descending: true).limit(50).get();
      final aff =
          await ref.orderBy('affection', descending: true).limit(50).get();
      final streak =
          await ref.orderBy('streak', descending: true).limit(50).get();
      if (mounted) {
        setState(() {
          _xpBoard = xp.docs.map((d) => d.data()).toList();
          _affectionBoard = aff.docs.map((d) => d.data()).toList();
          _streakBoard = streak.docs.map((d) => d.data()).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
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
        title: Text('LEADERBOARD',
            style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.pinkAccent,
          labelColor: Colors.pinkAccent,
          unselectedLabelColor: Colors.white38,
          labelStyle:
              GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12),
          tabs: const [
            Tab(text: '⭐ XP'),
            Tab(text: '💖 Affection'),
            Tab(text: '🔥 Streak'),
          ],
        ),
      ),
      body: WaifuBackground(
        opacity: 0.08,
        tint: const Color(0xFF0A0814),
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.pinkAccent))
            : TabBarView(
                controller: _tabCtrl,
                children: [
                  _buildBoard(_xpBoard, 'xp', '⭐'),
                  _buildBoard(_affectionBoard, 'affection', '💖'),
                  _buildBoard(_streakBoard, 'streak', '🔥', suffix: ' days'),
                ],
              ),
      ),
    );
  }

  Widget _buildBoard(List<Map<String, dynamic>> data, String key, String emoji,
      {String suffix = ''}) {
    if (data.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('🏆', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text('No data yet — be the first!',
              style: GoogleFonts.outfit(color: Colors.white38, fontSize: 16)),
        ]),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: data.length,
      itemBuilder: (ctx, i) {
        final item = data[i];
        final isMe = item['uid'] == _myUid;
        final medals = ['🥇', '🥈', '🥉'];
        final rank = i < 3 ? medals[i] : '#${i + 1}';
        final name = (item['name'] as String?) ?? 'Darling';
        final value = item[key] ?? 0;
        return AnimatedContainer(
          duration: Duration(milliseconds: 200 + i * 30),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isMe
                ? Colors.pinkAccent.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.04),
            border: Border.all(
                color: isMe
                    ? Colors.pinkAccent.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.07)),
            boxShadow: isMe
                ? [
                    BoxShadow(
                        color: Colors.pinkAccent.withValues(alpha: 0.2),
                        blurRadius: 12)
                  ]
                : [],
          ),
          child: Row(children: [
            Text(rank,
                style: TextStyle(
                    fontSize: i < 3 ? 22 : 14,
                    color: i < 3 ? null : Colors.white38)),
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.pinkAccent.withValues(alpha: 0.3),
              backgroundImage: (item['photoUrl'] as String?)?.isNotEmpty == true
                  ? NetworkImage(item['photoUrl'] as String)
                  : null,
              child: (item['photoUrl'] as String?)?.isNotEmpty != true
                  ? Text(name[0].toUpperCase(),
                      style: GoogleFonts.outfit(
                          color: Colors.white, fontWeight: FontWeight.bold))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isMe ? '$name (you)' : name,
                        style: GoogleFonts.outfit(
                            color: isMe ? Colors.pinkAccent : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    Text(item['level'] as String? ?? '',
                        style: GoogleFonts.outfit(
                            color: Colors.white38, fontSize: 11)),
                  ]),
            ),
            Text('$emoji $value$suffix',
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
          ]),
        );
      },
    );
  }
}
