import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/achievements_service.dart';
import '../services/affection_service.dart';

class AchievementsGalleryPage extends StatefulWidget {
  const AchievementsGalleryPage({super.key});
  @override
  State<AchievementsGalleryPage> createState() =>
      _AchievementsGalleryPageState();
}

class _AchievementsGalleryPageState extends State<AchievementsGalleryPage> {
  String _filter = 'All';
  final _filters = ['All', 'Unlocked', 'Locked'];

  @override
  void initState() {
    super.initState();
    _syncToCloud();
  }

  Future<void> _syncToCloud() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final unlocked = AchievementsService.instance.unlocked;
      await FirebaseFirestore.instance
          .collection('achievements')
          .doc(user.uid)
          .set({
        'unlocked': unlocked,
        'total': AchievementsService.all.length,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final aff = AffectionService.instance;
    final all = AchievementsService.all;
    final unlocked = AchievementsService.instance.unlocked;
    final pct = (unlocked.length / all.length * 100).round();

    final filtered = all.where((a) {
      if (_filter == 'Unlocked') return unlocked.contains(a.id);
      if (_filter == 'Locked') return !unlocked.contains(a.id);
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A16),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('ACHIEVEMENTS',
            style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5)),
        centerTitle: true,
      ),
      body: Column(children: [
        // Progress header
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [Color(0xFF2D0B3E), Color(0xFF0A1A2E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.3)),
          ),
          child: Row(children: [
            const Text('🏆', style: TextStyle(fontSize: 38)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${unlocked.length} / ${all.length} Unlocked',
                        style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: unlocked.length / all.length,
                      backgroundColor: Colors.white12,
                      valueColor:
                          const AlwaysStoppedAnimation(Colors.pinkAccent),
                      borderRadius: BorderRadius.circular(4),
                      minHeight: 6,
                    ),
                    const SizedBox(height: 4),
                    Text('$pct% • ${aff.points} total XP',
                        style: GoogleFonts.outfit(
                            color: Colors.white38, fontSize: 11)),
                  ]),
            ),
          ]),
        ),

        // Filter chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: _filters.map((f) {
              final sel = f == _filter;
              return GestureDetector(
                onTap: () => setState(() => _filter = f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: sel
                        ? Colors.pinkAccent.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.05),
                    border: Border.all(
                        color: sel ? Colors.pinkAccent : Colors.white12),
                  ),
                  child: Text(f,
                      style: GoogleFonts.outfit(
                          color: sel ? Colors.pinkAccent : Colors.white54,
                          fontSize: 12,
                          fontWeight:
                              sel ? FontWeight.bold : FontWeight.normal)),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),

        // Grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemCount: filtered.length,
            itemBuilder: (ctx, i) {
              final ach = filtered[i];
              final isUnlocked = unlocked.contains(ach.id);
              return _achCard(ach, isUnlocked);
            },
          ),
        ),
      ]),
    );
  }

  Widget _achCard(AchievementDef ach, bool unlocked) {
    final color = unlocked ? Colors.pinkAccent : Colors.white24;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: unlocked
            ? Colors.pinkAccent.withValues(alpha: 0.07)
            : Colors.white.withValues(alpha: 0.03),
        border: Border.all(
            color: unlocked
                ? Colors.pinkAccent.withValues(alpha: 0.35)
                : Colors.white12),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Stack(alignment: Alignment.topRight, children: [
          Text(ach.emoji,
              style: TextStyle(
                  fontSize: 36,
                  color: unlocked ? null : const Color(0x44FFFFFF))),
          if (unlocked)
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.greenAccent.withValues(alpha: 0.9),
              ),
              child: const Icon(Icons.check, size: 10, color: Colors.black),
            ),
        ]),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(ach.title,
              style: GoogleFonts.outfit(
                  color: unlocked ? Colors.white : Colors.white38,
                  fontSize: 12,
                  fontWeight: unlocked ? FontWeight.bold : FontWeight.normal),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(height: 4),
        Text('+XP',
            style: GoogleFonts.outfit(
                color: color, fontSize: 10, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}
