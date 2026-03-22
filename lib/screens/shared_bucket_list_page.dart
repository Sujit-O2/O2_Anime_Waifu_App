import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SharedBucketListPage extends StatefulWidget {
  const SharedBucketListPage({super.key});
  @override
  State<SharedBucketListPage> createState() => _SharedBucketListPageState();
}

class _SharedBucketListPageState extends State<SharedBucketListPage> {
  final _ctrl = TextEditingController();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  final _suggestions = [
    '🌸 Watch the sunrise together',
    '🎌 Visit Japan someday',
    '🌊 Dance in the rain',
    '🌹 Write love letters',
    '⭐ Learn to cook together',
    '🎡 Go to a theme park',
  ];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? 'anon';
  CollectionReference get _col =>
      FirebaseFirestore.instance.collection('users').doc(_uid).collection('bucketList');

  Future<void> _loadItems() async {
    try {
      final snap = await _col.orderBy('ts').get();
      if (mounted) {
        setState(() {
          _items = snap.docs
              .map((d) => {'id': d.id, 'text': d['text'] as String, 'done': d['done'] as bool})
              .toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addItem(String text) async {
    if (text.trim().isEmpty) return;
    final doc = _col.doc();
    final item = {'id': doc.id, 'text': text.trim(), 'done': false};
    setState(() => _items.add(item));
    _ctrl.clear();
    HapticFeedback.lightImpact();
    try {
      await doc.set({'text': text.trim(), 'done': false, 'ts': FieldValue.serverTimestamp()});
    } catch (_) {}
  }

  Future<void> _toggle(int i) async {
    HapticFeedback.lightImpact();
    final item = _items[i];
    final newDone = !(item['done'] as bool);
    setState(() => _items[i] = {...item, 'done': newDone});
    try {
      await _col.doc(item['id'] as String).update({'done': newDone});
    } catch (_) {}
  }

  Future<void> _delete(int i) async {
    final item = _items[i];
    setState(() => _items.removeAt(i));
    try {
      await _col.doc(item['id'] as String).delete();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final done = _items.where((e) => e['done'] == true).length;
    final total = _items.length;

    return Scaffold(
      backgroundColor: const Color(0xFF060B12),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white54, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              const Spacer(),
              Text('📝 Bucket List',
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('$done/$total',
                  style: GoogleFonts.outfit(color: Colors.pinkAccent, fontSize: 16, fontWeight: FontWeight.w700)),
            ]),
          ),
          if (total > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: total == 0 ? 0 : done / total,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation(Colors.pinkAccent),
                  minHeight: 6,
                ),
              ),
            ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  style: GoogleFonts.outfit(color: Colors.white),
                  onSubmitted: _addItem,
                  decoration: InputDecoration(
                    hintText: 'Add a dream to our list~',
                    hintStyle: GoogleFonts.outfit(color: Colors.white30, fontSize: 13),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.06),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => _addItem(_ctrl.text),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFDB2777), Color(0xFF7C3AED)]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Colors.pinkAccent))
                : _items.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Center(child: Text('Start with one of these~',
                              style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13))),
                          const SizedBox(height: 12),
                          ..._suggestions.map((s) => GestureDetector(
                                onTap: () => _addItem(s),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.2)),
                                  ),
                                  child: Text(s,
                                      style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14)),
                                ),
                              )),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _items.length,
                        itemBuilder: (_, i) {
                          final item = _items[i];
                          final isDone = item['done'] as bool;
                          return Dismissible(
                            key: Key(item['id'] as String),
                            direction: DismissDirection.endToStart,
                            onDismissed: (_) => _delete(i),
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(16)),
                              child: const Icon(Icons.delete_rounded, color: Colors.redAccent),
                            ),
                            child: GestureDetector(
                              onTap: () => _toggle(i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: isDone
                                      ? Colors.pinkAccent.withValues(alpha: 0.1)
                                      : Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: isDone
                                          ? Colors.pinkAccent.withValues(alpha: 0.4)
                                          : Colors.white12),
                                ),
                                child: Row(children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    width: 24, height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isDone ? Colors.pinkAccent : Colors.transparent,
                                      border: Border.all(
                                          color: isDone ? Colors.pinkAccent : Colors.white38,
                                          width: 2),
                                    ),
                                    child: isDone
                                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(item['text'] as String,
                                        style: GoogleFonts.outfit(
                                          color: isDone ? Colors.white54 : Colors.white,
                                          fontSize: 14,
                                          decoration: isDone ? TextDecoration.lineThrough : null,
                                        )),
                                  ),
                                ]),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ]),
      ),
    );
  }
}
