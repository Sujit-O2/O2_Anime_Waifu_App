import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VoiceNotesPage extends StatefulWidget {
  const VoiceNotesPage({super.key});
  @override
  State<VoiceNotesPage> createState() => _VoiceNotesPageState();
}

class _VoiceNotesPageState extends State<VoiceNotesPage> with SingleTickerProviderStateMixin {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  List<Map<String, dynamic>> _notes = [];
  bool _loading = true;
  bool _adding = false;
  late AnimationController _floatCtrl;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _loadNotes();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? 'anon';
  CollectionReference get _col => FirebaseFirestore.instance.collection('users').doc(_uid).collection('voiceNotes');

  Future<void> _loadNotes() async {
    try {
      final snap = await _col.orderBy('ts', descending: true).get();
      if (mounted) {
        setState(() {
          _notes = snap.docs.map((d) => {'id': d.id, 'title': d['title'] as String, 'content': d['content'] as String, 'ts': (d['ts'] as Timestamp?)?.toDate()}).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveNote() async {
    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();
    if (title.isEmpty || content.isEmpty) return;
    HapticFeedback.lightImpact();
    final doc = _col.doc();
    final note = {'id': doc.id, 'title': title, 'content': content, 'ts': DateTime.now()};
    setState(() { _notes.insert(0, note); _adding = false; _titleCtrl.clear(); _contentCtrl.clear(); });
    try {
      await doc.set({'title': title, 'content': content, 'ts': FieldValue.serverTimestamp()});
    } catch (_) {}
  }

  Future<void> _deleteNote(int i) async {
    final note = _notes[i];
    setState(() => _notes.removeAt(i));
    try {
      await _col.doc(note['id'] as String).delete();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080610),
      body: SafeArea(child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(children: [
            IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white54, size: 20), onPressed: () => Navigator.pop(context)),
            const Spacer(),
            Text('📓 Voice Notes', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => _adding = !_adding),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _adding ? Colors.white12 : Colors.pinkAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_adding ? Icons.close : Icons.add, color: Colors.pinkAccent, size: 20),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 8),
        // Add form
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          child: _adding
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.3)),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      TextField(
                        controller: _titleCtrl,
                        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700),
                        decoration: InputDecoration(
                          hintText: 'Note title...',
                          hintStyle: GoogleFonts.outfit(color: Colors.white30),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const Divider(color: Colors.white12, height: 16),
                      TextField(
                        controller: _contentCtrl,
                        style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14),
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'What\'s on your mind, Darling?',
                          hintStyle: GoogleFonts.outfit(color: Colors.white24, fontSize: 13),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: _saveNote,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFFDB2777), Color(0xFF7C3AED)]),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text('Save Note', style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ),
                    ]),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Colors.pinkAccent))
              : _notes.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      AnimatedBuilder(animation: _floatCtrl, builder: (_, __) => Transform.translate(
                        offset: Offset(0, -8 * _floatCtrl.value),
                        child: const Text('📓', style: TextStyle(fontSize: 64)),
                      )),
                      const SizedBox(height: 16),
                      Text('No notes yet, Darling~', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 16)),
                      const SizedBox(height: 6),
                      Text('Tap + to write your first one', style: GoogleFonts.outfit(color: Colors.white24, fontSize: 13)),
                    ]))
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.85),
                      itemCount: _notes.length,
                      itemBuilder: (_, i) {
                        final note = _notes[i];
                        final colors = [
                          [const Color(0xFF3B0764), const Color(0xFF6D28D9)],
                          [const Color(0xFF831843), const Color(0xFFDB2777)],
                          [const Color(0xFF134E4A), const Color(0xFF0D9488)],
                          [const Color(0xFF1E3A5F), const Color(0xFF3B82F6)],
                        ];
                        final pair = colors[i % colors.length];
                        final ts = note['ts'] as DateTime?;
                        return TweenAnimationBuilder<double>(
                          duration: Duration(milliseconds: 400 + i * 80),
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (_, v, child) => Opacity(opacity: v, child: Transform.scale(scale: 0.85 + 0.15 * v, child: child)),
                          child: GestureDetector(
                            onLongPress: () { HapticFeedback.mediumImpact(); _deleteNote(i); },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: pair, begin: Alignment.topLeft, end: Alignment.bottomRight),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(note['title'] as String,
                                    maxLines: 2, overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 8),
                                Expanded(child: Text(note['content'] as String,
                                    overflow: TextOverflow.fade,
                                    style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12, height: 1.5))),
                                if (ts != null)
                                  Text('${ts.day}/${ts.month}', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 10)),
                              ]),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ])),
    );
  }
}
