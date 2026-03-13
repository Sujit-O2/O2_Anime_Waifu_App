import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/waifu_background.dart';

/// Bucket List — Firestore: bucket/{uid}
class BucketListPage extends StatefulWidget {
  const BucketListPage({super.key});
  @override
  State<BucketListPage> createState() => _BucketListPageState();
}

class _BucketListPageState extends State<BucketListPage>
    with SingleTickerProviderStateMixin {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _itemCtrl = TextEditingController();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  late AnimationController _fadeCtrl;
  String? get _uid => _auth.currentUser?.uid;

  static const _categories = [
    '🌍 Travel',
    '🎯 Achievement',
    '💪 Personal',
    '❤️ Relationship',
    '🎨 Creative',
    '📚 Learning',
    '🤩 Experience'
  ];
  int _selCat = 0;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _load();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _itemCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    if (_uid != null) {
      try {
        final doc = await _db.collection('bucket').doc(_uid).get();
        if (doc.exists) {
          final raw = doc.data()?['items'] as String?;
          if (raw != null) {
            _items = (jsonDecode(raw) as List)
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
            if (mounted) {
              setState(() => _loading = false);
              _fadeCtrl.forward();
              return;
            }
          }
        }
      } catch (_) {}
    }
    final p = await SharedPreferences.getInstance();
    try {
      _items = (jsonDecode(p.getString('bucket_list') ?? '[]') as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {}
    if (mounted) {
      setState(() => _loading = false);
      _fadeCtrl.forward();
    }
  }

  Future<void> _sync() async {
    final encoded = jsonEncode(_items);
    (await SharedPreferences.getInstance()).setString('bucket_list', encoded);
    if (_uid != null) {
      try {
        await _db
            .collection('bucket')
            .doc(_uid)
            .set({'items': encoded, 'updatedAt': FieldValue.serverTimestamp()});
      } catch (_) {}
    }
  }

  void _add() {
    if (_itemCtrl.text.trim().isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() => _items.add({
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'text': _itemCtrl.text.trim(),
          'cat': _categories[_selCat],
          'done': false,
          'time': DateTime.now().millisecondsSinceEpoch
        }));
    _itemCtrl.clear();
    _sync();
  }

  void _toggle(int i) {
    HapticFeedback.selectionClick();
    setState(() => _items[i]['done'] = !(_items[i]['done'] as bool));
    if (_items[i]['done'] as bool) HapticFeedback.heavyImpact();
    _sync();
  }

  int get _done => _items.where((x) => x['done'] == true).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A16),
      body: WaifuBackground(
        opacity: 0.09,
        tint: const Color(0xFF080E14),
        child: SafeArea(
            child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(children: [
              GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white12)),
                      child: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white60, size: 16))),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('BUCKET LIST',
                        style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5)),
                    Text('$_done/${_items.length} completed 🌟',
                        style: GoogleFonts.outfit(
                            color: Colors.amberAccent.withOpacity(0.6),
                            fontSize: 10)),
                  ])),
            ]),
          ),
          if (_items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _items.isEmpty ? 0 : _done / _items.length,
                  backgroundColor: Colors.white.withOpacity(0.07),
                  valueColor: const AlwaysStoppedAnimation(Colors.amberAccent),
                  minHeight: 4,
                ),
              ),
            ),
          // Add item
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                    children: List.generate(
                        _categories.length,
                        (i) => GestureDetector(
                              onTap: () => setState(() => _selCat = i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 130),
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: _selCat == i
                                        ? Colors.amberAccent.withOpacity(0.12)
                                        : Colors.white.withOpacity(0.04),
                                    border: Border.all(
                                        color: _selCat == i
                                            ? Colors.amberAccent
                                            : Colors.white12)),
                                child: Text(_categories[i],
                                    style: GoogleFonts.outfit(
                                        color: _selCat == i
                                            ? Colors.amberAccent
                                            : Colors.white38,
                                        fontSize: 10)),
                              ),
                            ))),
              ),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                    child: TextField(
                        controller: _itemCtrl,
                        style: GoogleFonts.outfit(
                            color: Colors.white, fontSize: 13),
                        cursorColor: Colors.amberAccent,
                        onSubmitted: (_) => _add(),
                        decoration: InputDecoration(
                            hintText: 'Add a bucket list item…',
                            hintStyle: GoogleFonts.outfit(
                                color: Colors.white30, fontSize: 12),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.04),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color:
                                        Colors.amberAccent.withOpacity(0.2))),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10)))),
                const SizedBox(width: 8),
                GestureDetector(
                    onTap: _add,
                    child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                            color: Colors.amberAccent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.amberAccent.withOpacity(0.4))),
                        child: const Icon(Icons.add_rounded,
                            color: Colors.amberAccent, size: 22))),
              ]),
            ]),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.amberAccent))
                : _items.isEmpty
                    ? Center(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                            const Text('🌟', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 12),
                            Text('Add things you want to do~',
                                style:
                                    GoogleFonts.outfit(color: Colors.white38))
                          ]))
                    : FadeTransition(
                        opacity: _fadeCtrl,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: _items.length,
                          itemBuilder: (ctx, i) {
                            final item = _items[i];
                            final done = item['done'] as bool;
                            return Dismissible(
                              key: ValueKey(item['id']),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 16),
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      color:
                                          Colors.redAccent.withOpacity(0.12)),
                                  child: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: Colors.redAccent)),
                              onDismissed: (_) {
                                setState(() => _items.removeAt(i));
                                _sync();
                              },
                              child: GestureDetector(
                                onTap: () => _toggle(i),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    color: done
                                        ? Colors.amberAccent.withOpacity(0.06)
                                        : Colors.white.withOpacity(0.04),
                                    border: Border.all(
                                        color: done
                                            ? Colors.amberAccent
                                                .withOpacity(0.3)
                                            : Colors.white.withOpacity(0.07)),
                                  ),
                                  child: Row(children: [
                                    Icon(
                                        done
                                            ? Icons.check_circle_rounded
                                            : Icons
                                                .radio_button_unchecked_rounded,
                                        color: done
                                            ? Colors.amberAccent
                                            : Colors.white24,
                                        size: 22),
                                    const SizedBox(width: 12),
                                    Expanded(
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                          Text(item['text'] as String,
                                              style: GoogleFonts.outfit(
                                                  color: done
                                                      ? Colors.white54
                                                      : Colors.white,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  decoration: done
                                                      ? TextDecoration
                                                          .lineThrough
                                                      : null)),
                                          Text(item['cat'] as String,
                                              style: GoogleFonts.outfit(
                                                  color: Colors.amberAccent
                                                      .withOpacity(0.5),
                                                  fontSize: 10)),
                                        ])),
                                  ]),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ])),
      ),
    );
  }
}
