import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:anime_waifu/widgets/waifu_background.dart';

/// Pinned Messages v2 — Saved chat pins with search, staggered animations,
/// swipe-to-unpin, role-based styling, and WaifuBackground.
class PinnedMessagesPage extends StatefulWidget {
  const PinnedMessagesPage({super.key});
  @override
  State<PinnedMessagesPage> createState() => _PinnedMessagesPageState();
}

class _PinnedMessagesPageState extends State<PinnedMessagesPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  List<Map<String, dynamic>> _pins = [];
  bool _loading = true;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..forward();
    _searchCtrl.addListener(
        () => setState(() => _searchQuery = _searchCtrl.text.toLowerCase()));
    _load();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final snap = await FirebaseFirestore.instance
          .collection('pinned_messages')
          .doc(user.uid)
          .get();
      if (snap.exists) {
        final list = ((snap.data() ?? {})['pins'] as List?) ?? [];
        setState(() => _pins =
            list.map((e) => Map<String, dynamic>.from(e as Map)).toList());
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _unpin(int idx) async {
    HapticFeedback.mediumImpact();
    final removed = _pins[idx];
    setState(() => _pins.removeAt(idx));
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection('pinned_messages')
        .doc(user.uid)
        .set(
      {'pins': _pins, 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Message unpinned',
            style: GoogleFonts.outfit(color: Colors.white)),
        backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.amberAccent,
          onPressed: () {
            setState(() => _pins.insert(idx, removed));
            FirebaseFirestore.instance
                .collection('pinned_messages')
                .doc(user.uid)
                .set({'pins': _pins, 'updatedAt': FieldValue.serverTimestamp()},
                    SetOptions(merge: true));
          },
        ),
      ));
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_searchQuery.isEmpty) return _pins;
    return _pins
        .where((p) => (p['content']?.toString() ?? '')
            .toLowerCase()
            .contains(_searchQuery))
        .toList();
  }

  int get _userCount => _pins.where((p) => p['role'] == 'user').length;
  int get _waifuCount => _pins.where((p) => p['role'] != 'user').length;

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: WaifuBackground(
        opacity: 0.07,
        tint: const Color(0xFF0A0612),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeCtrl,
            child: Column(children: [
// ── Header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.08),
                              Colors.white.withValues(alpha: 0.03),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.white60, size: 16)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('PINNED MESSAGES',
                            style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5)),
                        Text(
                            '${_pins.length} pinned • $_userCount you • $_waifuCount Zero Two',
                            style: GoogleFonts.outfit(
                                color: Colors.deepPurpleAccent
                                    .withValues(alpha: 0.7),
                                fontSize: 10)),
                      ])),
                ]),
              ),

              // ── Search ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.07),
                        Colors.white.withValues(alpha: 0.02),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.deepPurpleAccent.withValues(alpha: 0.25)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurpleAccent.withValues(alpha: 0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    style:
                        GoogleFonts.outfit(color: Colors.white, fontSize: 13),
                    cursorColor: Colors.deepPurpleAccent,
                    decoration: InputDecoration(
                        hintText: 'Search pinned messages...',
                        hintStyle: GoogleFonts.outfit(color: Colors.white24),
                        border: InputBorder.none,
                        icon: const Icon(Icons.search,
                            color: Colors.white30, size: 18)),
                  ),
                ),
              ),

              // ── Stats ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Row(children: [
                  _statCard('📌', '${_pins.length}', 'Total',
                      Colors.deepPurpleAccent),
                  const SizedBox(width: 8),
                  _statCard('👤', '$_userCount', 'You', Colors.pinkAccent),
                  const SizedBox(width: 8),
                  _statCard(
                      '🌸', '$_waifuCount', 'Zero Two', Colors.cyanAccent),
                ]),
              ),

              const SizedBox(height: 10),

              // ── Messages ──
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: Colors.deepPurpleAccent))
                    : filtered.isEmpty
                        ? Center(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                const Text('📌',
                                    style: TextStyle(fontSize: 48)),
                                const SizedBox(height: 12),
                                Text(
                                    _searchQuery.isNotEmpty
                                        ? 'No matching pins'
                                        : 'No pinned messages yet',
                                    style: GoogleFonts.outfit(
                                        color: Colors.white30, fontSize: 14)),
                                const SizedBox(height: 4),
                                Text(
                                    'Long-press any message in chat to pin it!',
                                    style: GoogleFonts.outfit(
                                        color: Colors.white24, fontSize: 11)),
                              ]))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            itemBuilder: (_, i) =>
                                _buildPinCard(i, filtered[i]),
                          ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _statCard(String emoji, String value, String label, Color color) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.08),
                color.withValues(alpha: 0.03),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.25)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: [
            Text('$emoji $value',
                style: GoogleFonts.outfit(
                    color: color, fontSize: 12, fontWeight: FontWeight.w700)),
            Text(label,
                style: GoogleFonts.outfit(color: Colors.white30, fontSize: 8)),
          ]),
        ),
      );

  Widget _buildPinCard(int index, Map<String, dynamic> p) {
    final isUser = p['role'] == 'user';
    final color = isUser ? Colors.pinkAccent : Colors.deepPurpleAccent;
    final ts = p['pinnedAt'] as String?;
    final realIndex = _pins.indexOf(p);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + index * 60),
      curve: Curves.easeOut,
      builder: (_, val, child) => Opacity(
          opacity: val,
          child: Transform.translate(
              offset: Offset(0, 12 * (1 - val)), child: child)),
      child: Dismissible(
        key: Key('$index${p['content']}'),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => _unpin(realIndex),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.redAccent.withValues(alpha: 0.15)),
          child: const Icon(Icons.push_pin_outlined, color: Colors.redAccent),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: color.withValues(alpha: 0.06),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.push_pin_rounded, size: 14, color: color),
              const SizedBox(width: 6),
              Text(isUser ? 'You' : 'Zero Two 🌸',
                  style: GoogleFonts.outfit(
                      color: color, fontSize: 12, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (ts != null)
                Text(ts.substring(0, 10),
                    style: GoogleFonts.outfit(
                        color: Colors.white24, fontSize: 10)),
            ]),
            const SizedBox(height: 8),
            Text(p['content'] as String? ?? '',
                style: GoogleFonts.outfit(
                    color: Colors.white, fontSize: 14, height: 1.5)),
          ]),
        ),
      ),
    );
  }
}
