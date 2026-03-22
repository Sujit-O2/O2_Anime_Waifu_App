import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PinnedMessagesPage extends StatefulWidget {
  const PinnedMessagesPage({super.key});
  @override
  State<PinnedMessagesPage> createState() => _PinnedMessagesPageState();
}

class _PinnedMessagesPageState extends State<PinnedMessagesPage> {
  List<Map<String, dynamic>> _pins = [];
  bool _loading = true;

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
          .collection('pinned_messages')
          .doc(user.uid)
          .get();
      if (snap.exists) {
        final list = ((snap.data() ?? {})['pins'] as List?) ?? [];
        setState(() => _pins = list.cast<Map<String, dynamic>>());
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _unpin(int idx) async {
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
        title: Text('PINNED MESSAGES',
            style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.pinkAccent))
          : _pins.isEmpty
              ? Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                      const Text('📌', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 12),
                      Text('No pinned messages yet',
                          style: GoogleFonts.outfit(
                              color: Colors.white38, fontSize: 15)),
                      const SizedBox(height: 6),
                      Text('Long-press any message in chat to pin it!',
                          style: GoogleFonts.outfit(
                              color: Colors.white24, fontSize: 12)),
                    ]))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _pins.length,
                  itemBuilder: (ctx, i) {
                    final p = _pins[i];
                    final isUser = p['role'] == 'user';
                    final ts = p['pinnedAt'] as String?;
                    return Dismissible(
                      key: Key('$i${p['content']}'),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) => _unpin(i),
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: Colors.red.withValues(alpha: 0.15),
                        ),
                        child: const Icon(Icons.push_pin_outlined,
                            color: Colors.red),
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: isUser
                              ? Colors.pinkAccent.withValues(alpha: 0.07)
                              : Colors.deepPurple.withValues(alpha: 0.1),
                          border: Border.all(
                              color: isUser
                                  ? Colors.pinkAccent.withValues(alpha: 0.3)
                                  : Colors.deepPurpleAccent
                                      .withValues(alpha: 0.3)),
                        ),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Icon(Icons.push_pin_rounded,
                                    size: 14,
                                    color: isUser
                                        ? Colors.pinkAccent
                                        : Colors.deepPurpleAccent),
                                const SizedBox(width: 6),
                                Text(isUser ? 'You' : 'Zero Two 🌸',
                                    style: GoogleFonts.outfit(
                                        color: isUser
                                            ? Colors.pinkAccent
                                            : Colors.deepPurpleAccent,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold)),
                                const Spacer(),
                                if (ts != null)
                                  Text(ts.substring(0, 10),
                                      style: GoogleFonts.outfit(
                                          color: Colors.white24, fontSize: 10)),
                              ]),
                              const SizedBox(height: 8),
                              Text(p['content'] as String? ?? '',
                                  style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 14,
                                      height: 1.5)),
                            ]),
                      ),
                    );
                  },
                ),
    );
  }
}
