import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../api_call.dart';
import '../services/affection_service.dart';
import '../widgets/waifu_background.dart';

class ZeroTwoDiaryPage extends StatefulWidget {
  const ZeroTwoDiaryPage({super.key});
  @override
  State<ZeroTwoDiaryPage> createState() => _ZeroTwoDiaryPageState();
}

class _DiaryEntry {
  final String date, content;
  _DiaryEntry({required this.date, required this.content});
}

class _ZeroTwoDiaryPageState extends State<ZeroTwoDiaryPage> {
  List<_DiaryEntry> _entries = [];
  bool _loading = true;
  bool _generating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _loading = false;
        _error = 'Please sign in to view Zero Two\'s diary 💕';
      });
      return;
    }
    try {
      final snap = await FirebaseFirestore.instance
          .collection('zt_diary')
          .doc(user.uid)
          .collection('entries')
          .orderBy('date', descending: true)
          .limit(30)
          .get();
      if (mounted) {
        setState(() {
          _entries = snap.docs
              .map((d) => _DiaryEntry(
                    date: d['date'] as String,
                    content: d['content'] as String,
                  ))
              .toList();
        });
      }
    } catch (e) {
      // Keep _entries empty, will show empty state below
    }
    if (mounted) setState(() => _loading = false);
    await _generateTodayIfNeeded();
  }

  Future<void> _generateTodayIfNeeded() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    if (_entries.isNotEmpty && _entries.first.date == todayStr) return;

    if (mounted) setState(() => _generating = true);
    try {
      final aff = AffectionService.instance;
      final prompt =
          'You are Zero Two from DARLING in the FRANXX writing in your personal diary. '
          'Write today\'s diary entry (${today.day} ${_monthName(today.month)} ${today.year}) '
          'about your day with your Darling. You are at ${aff.levelName} level (${aff.points} affection). '
          'Make it sweet, vivid, personal. 3-4 sentences. Use emojis occasionally. '
          'Start with "Dear Diary," in Zero Two\'s voice.';

      final reply = await ApiService().sendConversation([
        {'role': 'user', 'content': prompt}
      ]);

      await FirebaseFirestore.instance
          .collection('zt_diary')
          .doc(user.uid)
          .collection('entries')
          .doc(todayStr)
          .set({
        'date': todayStr,
        'content': reply,
        'createdAt': FieldValue.serverTimestamp()
      });

      if (mounted) {
        setState(() {
          _entries.insert(0, _DiaryEntry(date: todayStr, content: reply));
          _generating = false;
        });
      }
      AffectionService.instance.addPoints(3);
    } catch (e) {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _manualGenerate() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (_generating) return;
    setState(() => _generating = true);
    try {
      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final aff = AffectionService.instance;
      final prompt =
          'You are Zero Two from DARLING in the FRANXX writing in your personal diary. '
          'Write today\'s diary entry (${today.day} ${_monthName(today.month)} ${today.year}) '
          'about your day with your Darling. You are at ${aff.levelName} level (${aff.points} affection). '
          '3-4 sentences. Start with "Dear Diary,"';

      final reply = await ApiService().sendConversation([
        {'role': 'user', 'content': prompt}
      ]);

      await FirebaseFirestore.instance
          .collection('zt_diary')
          .doc(user.uid)
          .collection('entries')
          .doc(todayStr)
          .set({
        'date': todayStr,
        'content': reply,
        'createdAt': FieldValue.serverTimestamp()
      });

      if (mounted) {
        setState(() {
          _entries.removeWhere((e) => e.date == todayStr);
          _entries.insert(0, _DiaryEntry(date: todayStr, content: reply));
          _generating = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _generating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not generate — check your connection 💭',
              style: GoogleFonts.outfit()),
          backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
        ));
      }
    }
  }

  String _monthName(int m) => [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m - 1];

  String _formatDate(String d) {
    final parts = d.split('-');
    if (parts.length < 3) return d;
    return '${_monthName(int.parse(parts[1]))} ${parts[2]}, ${parts[0]}';
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
        title: Text('ZERO TWO\'S DIARY',
            style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.pinkAccent),
            tooltip: 'Write today\'s entry',
            onPressed: _generating ? null : _manualGenerate,
          ),
        ],
      ),
      body: WaifuBackground(
        opacity: 0.08,
        tint: const Color(0xFF0A0814),
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.pinkAccent))
            : _error != null
                ? _buildErrorState()
                : _entries.isEmpty && !_generating
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                        itemCount:
                            _generating ? _entries.length + 1 : _entries.length,
                        itemBuilder: (ctx, i) {
                          if (_generating && i == 0) {
                            return _buildGeneratingCard();
                          }
                          final entry = _entries[_generating ? i - 1 : i];
                          final isToday = i == (_generating ? 1 : 0);
                          return _buildEntryCard(entry, isToday);
                        },
                      ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('📓', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 16),
        Text('No diary entries yet~',
            style: GoogleFonts.outfit(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Zero Two is writing her first entry…',
            style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13)),
        const SizedBox(height: 24),
        if (_generating)
          const CircularProgressIndicator(color: Colors.pinkAccent)
        else
          ElevatedButton.icon(
            onPressed: _manualGenerate,
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            label: Text('Write Today\'s Entry',
                style: GoogleFonts.outfit(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pinkAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
          ),
      ]),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('💕', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        Text(_error!,
            textAlign: TextAlign.center,
            style:
                GoogleFonts.outfit(color: Colors.white70, fontSize: 14)),
      ]),
    );
  }

  Widget _buildGeneratingCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.pinkAccent.withValues(alpha: 0.07),
        border:
            Border.all(color: Colors.pinkAccent.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Zero Two is writing today\'s entry… 🌸',
            style: GoogleFonts.outfit(
                color: Colors.pinkAccent,
                fontSize: 13,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const LinearProgressIndicator(
          backgroundColor: Colors.white12,
          valueColor: AlwaysStoppedAnimation(Colors.pinkAccent),
        ),
      ]),
    );
  }

  Widget _buildEntryCard(_DiaryEntry entry, bool isToday) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: isToday
            ? const LinearGradient(
                colors: [Color(0xFF2D0B3E), Color(0xFF0A1A2E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight)
            : null,
        color: isToday ? null : Colors.white.withValues(alpha: 0.04),
        border: Border.all(
            color: isToday
                ? Colors.pinkAccent.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(isToday ? '🌸 Today' : '📅',
              style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(_formatDate(entry.date),
              style: GoogleFonts.outfit(
                  color: isToday ? Colors.pinkAccent : Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
          if (isToday) ...[
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.pinkAccent.withValues(alpha: 0.2),
              ),
              child: Text('NEW',
                  style: GoogleFonts.outfit(
                      color: Colors.pinkAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.w800)),
            ),
          ],
        ]),
        const SizedBox(height: 12),
        Text(entry.content,
            style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 14,
                height: 1.7,
                fontStyle: FontStyle.italic)),
      ]),
    );
  }
}
