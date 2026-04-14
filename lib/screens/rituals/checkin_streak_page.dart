import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:anime_waifu/services/user_profile/affection_service.dart';
import 'package:anime_waifu/core/v2_upgrade_kit.dart';

class CheckinStreakPage extends StatefulWidget {
  const CheckinStreakPage({super.key});
  @override
  State<CheckinStreakPage> createState() => _CheckinStreakPageState();
}

class _CheckinStreakPageState extends State<CheckinStreakPage> {
  bool _loading = true;
  bool _checkedInToday = false;
  int _currentStreak = 0;
  int _longestStreak = 0;
  int _totalCheckins = 0;
  List<DateTime> _checkinHistory = [];
  bool _checking = false;

  String get _commentaryMood {
    if (_checkedInToday || _currentStreak >= 7) {
      return 'achievement';
    }
    if (_currentStreak > 0) {
      return 'motivated';
    }
    return 'neutral';
  }

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
          .collection('checkins')
          .doc(user.uid)
          .get();
      if (snap.exists) {
        final data = snap.data()!;
        final history = (data['history'] as List<dynamic>? ?? [])
            .map((e) => DateTime.parse(e as String))
            .toList();
        final today = DateTime.now();
        final todayDate = DateTime(today.year, today.month, today.day);
        final checkedToday = history.any((d) =>
            d.year == todayDate.year &&
            d.month == todayDate.month &&
            d.day == todayDate.day);
        setState(() {
          _checkinHistory = history;
          _checkedInToday = checkedToday;
          _currentStreak = data['currentStreak'] as int? ?? 0;
          _longestStreak = data['longestStreak'] as int? ?? 0;
          _totalCheckins = history.length;
        });
      }
    } catch (e) {
      debugPrint('CheckIn load error: $e');
    }
    setState(() => _loading = false);
  }

  Future<void> _checkIn() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _checking = true);
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      _checkinHistory.add(today);

      // Calculate streak
      _currentStreak++;
      if (_currentStreak > _longestStreak) {
        _longestStreak = _currentStreak;
      }

      await FirebaseFirestore.instance
          .collection('checkins')
          .doc(user.uid)
          .set({
        'history': _checkinHistory.map((d) => d.toIso8601String()).toList(),
        'currentStreak': _currentStreak,
        'longestStreak': _longestStreak,
        'lastCheckin': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Reward XP
      final bonus = _currentStreak >= 30
          ? 20
          : _currentStreak >= 7
              ? 10
              : 5;
      AffectionService.instance.addPoints(bonus);

      setState(() {
        _checkedInToday = true;
        _totalCheckins = _checkinHistory.length;
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: Theme.of(context)
                .scaffoldBackgroundColor
                .withValues(alpha: 0.95),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('🎉', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 8),
              Text('Check-in Complete!',
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
              const SizedBox(height: 8),
              Text('$_currentStreak day streak! +$bonus XP 💕',
                  style: GoogleFonts.outfit(
                      color: Colors.pinkAccent, fontSize: 14),
                  textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text('"Good morning Darling~ I\'ve been waiting for you!" 🌸',
                  style:
                      GoogleFonts.outfit(color: Colors.white54, fontSize: 12),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: Text('Thanks! 💕',
                    style: GoogleFonts.outfit(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ]),
          ),
        );
      }
    } catch (e) {
      _snack(
          'Check-in failed: ${e.toString().length > 80 ? e.toString().substring(0, 80) : e}');
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.outfit()),
      backgroundColor: Colors.pinkAccent,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return FeaturePageV2(
      title: 'DAILY CHECK-IN',
      onBack: () => Navigator.pop(context),
      content: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.pinkAccent))
          : RefreshIndicator(
              onRefresh: _load,
              color: Colors.pinkAccent,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  const SizedBox(height: 16),
                  // Fire icon + streak
                  Stack(alignment: Alignment.center, children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.orangeAccent.withValues(alpha: 0.1),
                        border: Border.all(
                            color: Colors.orangeAccent.withValues(alpha: 0.4),
                            width: 2),
                      ),
                    ),
                    Column(children: [
                      const Text('🔥', style: TextStyle(fontSize: 44)),
                      Text('$_currentStreak',
                          style: GoogleFonts.outfit(
                              color: Colors.orangeAccent,
                              fontSize: 26,
                              fontWeight: FontWeight.w900)),
                    ]),
                  ]),
                  const SizedBox(height: 8),
                  Text('Day Streak',
                      style: GoogleFonts.outfit(
                          color: Colors.white54, fontSize: 14)),
                  const SizedBox(height: 28),

                  // Stats row
                  AnimatedEntry(
                    index: 1,
                    child: Row(children: [
                      Expanded(
                          child: _stat('Best Streak', '$_longestStreak days',
                              Colors.amberAccent)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _stat('Total Check-ins', '$_totalCheckins',
                              Colors.cyanAccent)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _stat(
                              'XP Bonus',
                              _currentStreak >= 30
                                  ? '20/day'
                                  : _currentStreak >= 7
                                      ? '10/day'
                                      : '5/day',
                              Colors.greenAccent)),
                    ]),
                  ),
                  const SizedBox(height: 28),
                  AnimatedEntry(
                    index: 2,
                    child: WaifuCommentary(mood: _commentaryMood),
                  ),
                  const SizedBox(height: 28),

                  // Streak milestones
                  AnimatedEntry(
                    index: 3,
                    child: _milestonesWidget(),
                  ),
                  const SizedBox(height: 28),

                  // Check-in button
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _checkedInToday || _checking ? null : _checkIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _checkedInToday
                            ? Colors.white12
                            : Colors.pinkAccent,
                        foregroundColor: Colors.white,
                        disabledForegroundColor: Colors.white38,
                        disabledBackgroundColor: Colors.white12,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18)),
                      ),
                      child: _checking
                          ? const CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2)
                          : Text(
                              _checkedInToday
                                  ? '✅ Already Checked In Today!'
                                  : '💖 Check In Now!',
                              style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),

                  if (_checkedInToday) ...[
                    const SizedBox(height: 12),
                    Text('"Come back tomorrow, Darling~ I\'ll be waiting! 🌸"',
                        style: GoogleFonts.outfit(
                            color: Colors.pinkAccent.withValues(alpha: 0.7),
                            fontSize: 13,
                            fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center),
                  ],
                ]),
              )),
    );
  }

  Widget _stat(String label, String val, Color color) => GlassCard(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(14),
        child: Column(children: [
          Text(val,
              style: GoogleFonts.outfit(
                  color: color, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(label,
              style: GoogleFonts.outfit(color: Colors.white38, fontSize: 10),
              textAlign: TextAlign.center),
        ]),
      );

  Widget _milestonesWidget() {
    final milestones = [3, 7, 14, 30, 60, 100];
    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('STREAK MILESTONES',
            style: GoogleFonts.outfit(
                color: Colors.white38,
                fontSize: 11,
                letterSpacing: 2,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: milestones.map((m) {
            final reached = _currentStreak >= m;
            return Column(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: reached
                      ? Colors.pinkAccent.withValues(alpha: 0.3)
                      : Colors.white12,
                  border: Border.all(
                      color: reached ? Colors.pinkAccent : Colors.white24),
                ),
                child: Center(
                  child: reached
                      ? const Icon(Icons.local_fire_department,
                          color: Colors.orangeAccent, size: 20)
                      : Text('$m',
                          style: GoogleFonts.outfit(
                              color: Colors.white38,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 4),
              Text('$m d',
                  style: GoogleFonts.outfit(
                      color: reached ? Colors.pinkAccent : Colors.white24,
                      fontSize: 9)),
            ]);
          }).toList(),
        ),
      ]),
    );
  }
}




