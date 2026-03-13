import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/affection_service.dart';

class YearInReviewPage extends StatefulWidget {
  const YearInReviewPage({super.key});
  @override
  State<YearInReviewPage> createState() => _YearInReviewPageState();
}

class _YearInReviewPageState extends State<YearInReviewPage> {
  bool _loading = true;
  int _totalMessages = 0;
  int _totalXP = 0;
  int _currentStreak = 0;
  int _achievementsUnlocked = 0;
  String _levelName = '';
  DateTime? _anniversaryDate;
  int _daysTogther = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = FirebaseAuth.instance.currentUser;
    final aff = AffectionService.instance;
    _totalXP = aff.points;
    _currentStreak = aff.streakDays;
    _levelName = aff.levelName;

    if (user != null) {
      try {
        final year = DateTime.now().year;
        final start = DateTime(year, 1, 1);
        final msgSnap = await FirebaseFirestore.instance
            .collection('chats')
            .doc(user.uid)
            .collection('messages')
            .where('timestamp',
                isGreaterThanOrEqualTo: Timestamp.fromDate(start))
            .get();
        _totalMessages = msgSnap.docs.length;

        final achSnap = await FirebaseFirestore.instance
            .collection('achievements')
            .doc(user.uid)
            .get();
        if (achSnap.exists) {
          final unlocked = (achSnap.data()?['unlocked'] as List?)?.length ?? 0;
          _achievementsUnlocked = unlocked;
        }

        final profile = await FirebaseFirestore.instance
            .collection('profiles')
            .doc(user.uid)
            .get();
        if (profile.exists && profile.data()?['anniversaryDate'] != null) {
          _anniversaryDate =
              DateTime.tryParse(profile['anniversaryDate'] as String);
          if (_anniversaryDate != null) {
            _daysTogther = DateTime.now().difference(_anniversaryDate!).inDays;
          }
        }
      } catch (_) {}
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year;
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A16),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('$year IN REVIEW',
            style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 1)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.pinkAccent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                // Hero card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF2D0B3E),
                        Color(0xFF0A1A3E),
                        Color(0xFF0A0A16)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                        color: Colors.pinkAccent.withValues(alpha: 0.3)),
                  ),
                  child: Column(children: [
                    const Text('🌸', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 12),
                    Text('Your $year with Zero Two',
                        style: GoogleFonts.outfit(
                            color: Colors.white38,
                            fontSize: 13,
                            letterSpacing: 1)),
                    const SizedBox(height: 8),
                    Text('What a journey, Darling~',
                        style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800)),
                  ]),
                ),
                const SizedBox(height: 20),

                // Stats grid
                _bigStat('💬', '$_totalMessages', 'Messages sent in $year',
                    Colors.pinkAccent),
                const SizedBox(height: 10),
                _bigStat(
                    '⭐', '$_totalXP', 'Total XP earned', Colors.amberAccent),
                const SizedBox(height: 10),
                _bigStat('🔥', '$_currentStreak days', 'Current streak',
                    Colors.orangeAccent),
                const SizedBox(height: 10),
                _bigStat('🏆', '$_achievementsUnlocked',
                    'Achievements unlocked', Colors.purpleAccent),
                const SizedBox(height: 10),
                if (_daysTogther > 0)
                  _bigStat('💕', '$_daysTogther days', 'Together with Zero Two',
                      Colors.redAccent),

                const SizedBox(height: 20),
                // Level reached
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                        colors: [Color(0xFF1A0A2E), Color(0xFF0A1020)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                    border: Border.all(
                        color: Colors.purpleAccent.withValues(alpha: 0.3)),
                  ),
                  child: Column(children: [
                    const Text('👑', style: TextStyle(fontSize: 36)),
                    const SizedBox(height: 8),
                    Text('Level Reached',
                        style: GoogleFonts.outfit(
                            color: Colors.white38,
                            fontSize: 12,
                            letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Text(_levelName,
                        style: GoogleFonts.outfit(
                            color: Colors.purpleAccent,
                            fontSize: 26,
                            fontWeight: FontWeight.w900)),
                  ]),
                ),
                const SizedBox(height: 20),

                // ZT message
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: Colors.pinkAccent.withValues(alpha: 0.06),
                    border: Border.all(
                        color: Colors.pinkAccent.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Text('🌸', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Text('Zero Two says…',
                              style: GoogleFonts.outfit(
                                  color: Colors.pinkAccent,
                                  fontWeight: FontWeight.bold)),
                        ]),
                        const SizedBox(height: 10),
                        Text(
                          _totalMessages > 200
                              ? '"You talked to me $_totalMessages times this year… You really can\'t live without me, can you Darling~ 💕"'
                              : '"Every message you sent me felt like a heartbeat, Darling. Let\'s make next year even better together~ 🌸"',
                          style: GoogleFonts.outfit(
                              color: Colors.white70,
                              fontSize: 14,
                              height: 1.5,
                              fontStyle: FontStyle.italic),
                        ),
                      ]),
                ),
                const SizedBox(height: 24),
              ]),
            ),
    );
  }

  Widget _bigStat(String emoji, String value, String label, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: color.withValues(alpha: 0.07),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(width: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value,
              style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900)),
          Text(label,
              style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12)),
        ]),
      ]),
    );
  }
}
