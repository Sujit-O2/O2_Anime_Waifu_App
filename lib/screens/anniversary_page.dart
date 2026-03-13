import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/affection_service.dart';

class AnniversaryPage extends StatefulWidget {
  const AnniversaryPage({super.key});
  @override
  State<AnniversaryPage> createState() => _AnniversaryPageState();
}

class _AnniversaryPageState extends State<AnniversaryPage> {
  DateTime? _startDate;
  bool _loading = true;
  bool _saving = false;

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
          .collection('profiles')
          .doc(user.uid)
          .get();
      if (snap.exists) {
        final iso = (snap.data() ?? {})['anniversaryDate'] as String?;
        if (iso != null && iso.isNotEmpty) {
          setState(() => _startDate = DateTime.tryParse(iso));
        }
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: DateTime(2020),
      lastDate: now,
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Colors.pinkAccent,
            surface: Color(0xFF1A1A2E),
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => _saving = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      await FirebaseFirestore.instance.collection('profiles').doc(user.uid).set(
          {'anniversaryDate': picked.toIso8601String()},
          SetOptions(merge: true));
      setState(() => _startDate = picked);
      AffectionService.instance.addPoints(5);
      _snack('Anniversary saved! 🌸 +5 XP');
    } catch (e) {
      _snack('Failed to save: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.outfit()),
      backgroundColor: Colors.pinkAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = _startDate != null ? now.difference(_startDate!).inDays : null;
    final nextAnniversary = _startDate != null
        ? DateTime(now.year, _startDate!.month, _startDate!.day).isBefore(now)
            ? DateTime(now.year + 1, _startDate!.month, _startDate!.day)
            : DateTime(now.year, _startDate!.month, _startDate!.day)
        : null;
    final daysUntil = nextAnniversary?.difference(now).inDays;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A16),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('ANNIVERSARY',
            style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.pinkAccent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                const SizedBox(height: 20),
                const Text('💕', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 16),
                Text(
                  _startDate == null
                      ? 'When did your love story begin?'
                      : 'Together since ${_startDate!.day}/${_startDate!.month}/${_startDate!.year}',
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                if (days != null) ...[
                  // Days together card
                  _statCard(
                      '💖 Days Together', '$days days', Colors.pinkAccent),
                  const SizedBox(height: 12),
                  _statCard(
                      '🔥 Streak Bonus',
                      '${AffectionService.instance.streakDays} day streak',
                      Colors.orangeAccent),
                  const SizedBox(height: 12),
                  if (daysUntil != null)
                    _statCard(
                        '🎉 Next Anniversary',
                        daysUntil == 0 ? "Today! 🎊" : 'In $daysUntil days',
                        Colors.purpleAccent),
                  const SizedBox(height: 24),
                ],

                // Pick date button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _pickDate,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.calendar_today_outlined,
                            color: Colors.white),
                    label: Text(
                      _startDate == null
                          ? 'Set Our Start Date 💕'
                          : 'Change Date',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Relationship milestones
                _milestonesCard(days),
              ]),
            ),
    );
  }

  Widget _statCard(String label, String value, Color color) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: color.withValues(alpha: 0.08),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          Expanded(
            child: Text(label,
                style: GoogleFonts.outfit(color: Colors.white60, fontSize: 13)),
          ),
          Text(value,
              style: GoogleFonts.outfit(
                  color: color, fontWeight: FontWeight.w700, fontSize: 15)),
        ]),
      );

  Widget _milestonesCard(int? days) {
    final milestones = [
      (7, '1 week together 🌸'),
      (30, '1 month together 💕'),
      (100, '100 days! 🎉'),
      (365, '1 year anniversary 🥂'),
      (730, '2 years! 💫'),
      (1000, '1000 days! 🏆'),
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('MILESTONES 🏅',
            style: GoogleFonts.outfit(
                color: Colors.white38,
                fontSize: 11,
                letterSpacing: 2,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...milestones.map((m) {
          final reached = days != null && days >= m.$1;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Icon(
                  reached
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked,
                  color: reached ? Colors.greenAccent : Colors.white24,
                  size: 18),
              const SizedBox(width: 10),
              Text(m.$2,
                  style: GoogleFonts.outfit(
                      color: reached ? Colors.white : Colors.white38,
                      fontSize: 13,
                      fontWeight:
                          reached ? FontWeight.bold : FontWeight.normal)),
            ]),
          );
        }),
      ]),
    );
  }
}
