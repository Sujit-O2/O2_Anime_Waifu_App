import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:anime_waifu/services/user_profile/affection_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
          if (!mounted) return;
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
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        showSuccessSnackbar(context, 'Please sign in to save anniversary.');
        return;
      }
      await FirebaseFirestore.instance.collection('profiles').doc(user.uid).set(
          {'anniversaryDate': picked.toIso8601String()},
          SetOptions(merge: true));
      if (!mounted) return;
      setState(() => _startDate = picked);
      AffectionService.instance.addPoints(5);
      showSuccessSnackbar(context, 'Anniversary saved.');
    } catch (e) {
      showSuccessSnackbar(context, 'Failed to save anniversary.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
      backgroundColor: V2Theme.surfaceDark,
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
          : WaifuBackground(
              opacity: 0.08,
              tint: V2Theme.surfaceDark,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: Column(children: [
                  AnimatedEntry(
                    index: 0,
                    child: GlassCard(
                      margin: EdgeInsets.zero,
                      glow: _startDate != null,
                      child: Column(
                        children: <Widget>[
                          const Text(
                            'LOVE MILESTONE',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text('01',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 48,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 12),
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
                          const SizedBox(height: 8),
                          Text(
                            _startDate == null
                                ? 'Save your date so milestones and countdowns feel personal.'
                                : 'Your anniversary tracker now has a real start point for milestone cards.',
                            style: GoogleFonts.outfit(
                                color: Colors.white70,
                                fontSize: 13,
                                height: 1.45),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AnimatedEntry(
                    index: 1,
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: StatCard(
                            title: 'Days together',
                            value: days == null ? 'Unset' : '$days',
                            icon: Icons.favorite_rounded,
                            color: Colors.pinkAccent,
                          ),
                        ),
                        Expanded(
                          child: StatCard(
                            title: 'Current streak',
                            value: '${AffectionService.instance.streakDays}d',
                            icon: Icons.local_fire_department_rounded,
                            color: Colors.orangeAccent,
                          ),
                        ),
                        Expanded(
                          child: StatCard(
                            title: 'Next event',
                            value: daysUntil == null
                                ? '--'
                                : daysUntil == 0
                                    ? 'Today'
                                    : '$daysUntil d',
                            icon: Icons.celebration_rounded,
                            color: Colors.purpleAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  AnimatedEntry(
                    index: 2,
                    child: WaifuCommentary(
                      mood: days != null && days >= 100
                          ? 'achievement'
                          : days != null
                              ? 'motivated'
                              : 'neutral',
                    ),
                  ),
                  const SizedBox(height: 20),
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
                            ? 'Set Our Start Date'
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
                  _milestonesCard(days),
                ]),
              ),
            ),
    );
  }

  Widget _milestonesCard(int? days) {
    final milestones = [
      (7, '1 week together'),
      (30, '1 month together'),
      (100, '100 days'),
      (365, '1 year anniversary'),
      (730, '2 years'),
      (1000, '1000 days'),
    ];
    return GlassCard(
      margin: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('MILESTONES',
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
