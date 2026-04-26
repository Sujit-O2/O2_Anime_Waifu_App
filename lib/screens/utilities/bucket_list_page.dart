import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:anime_waifu/core/v2_upgrade_kit.dart';

class BucketListPage extends StatefulWidget {
  const BucketListPage({super.key});

  @override
  State<BucketListPage> createState() => _BucketListPageState();
}

class _BucketListPageState extends State<BucketListPage>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _itemCtrl = TextEditingController();
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _items = <Map<String, dynamic>>[];
  bool _loading = true;
  late AnimationController _fadeCtrl;
  int _selCat = 0;
  String _searchQuery = '';

  static const List<String> _categories = <String>[
    'Travel',
    'Achievement',
    'Personal',
    'Relationship',
    'Creative',
    'Learning',
    'Experience',
  ];

  String? get _uid => _auth.currentUser?.uid;
  int get _done => _items.where((item) => item['done'] == true).length;
  int get _activeItems => _items.where((item) => item['done'] != true).length;

  String get _commentaryMood {
    if (_done == _items.length && _items.isNotEmpty) {
      return 'achievement';
    }
    if (_done > 0) {
      return 'motivated';
    }
    return 'neutral';
  }

  List<Map<String, dynamic>> get _filteredItems {
    if (_searchQuery.trim().isEmpty) {
      return _items;
    }
    final query = _searchQuery.toLowerCase();
    return _items.where((item) {
      final text = item['text']?.toString().toLowerCase() ?? '';
      final cat = item['cat']?.toString().toLowerCase() ?? '';
      return text.contains(query) || cat.contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _load();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _itemCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() => _loading = true);
    }
    if (_uid != null) {
      try {
        final doc = await _db.collection('bucket').doc(_uid).get();
        if (doc.exists) {
          final raw = doc.data()?['items'] as String?;
          if (raw != null && raw.isNotEmpty) {
            _items = _decode(raw);
            if (mounted) {
              setState(() => _loading = false);
              _fadeCtrl
                ..reset()
                ..forward();
            }
            return;
          }
        }
      } catch (_) {}
    }

    final prefs = await SharedPreferences.getInstance();
    _items = _decode(prefs.getString('bucket_list') ?? '[]');
    if (mounted) {
      setState(() => _loading = false);
      _fadeCtrl
        ..reset()
        ..forward();
    }
  }

  List<Map<String, dynamic>> _decode(String raw) {
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((entry) => Map<String, dynamic>.from(entry as Map))
          .toList();
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  Future<void> _sync() async {
    final encoded = jsonEncode(_items);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bucket_list', encoded);
    if (_uid != null) {
      try {
        await _db.collection('bucket').doc(_uid).set(<String, dynamic>{
          'items': encoded,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }
  }

  Future<void> _refresh() => _load();

  Future<void> _add() async {
    if (_itemCtrl.text.trim().isEmpty) {
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() {
      _items.add(<String, dynamic>{
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'text': _itemCtrl.text.trim(),
        'cat': _categories[_selCat],
        'done': false,
        'time': DateTime.now().millisecondsSinceEpoch,
      });
      _itemCtrl.clear();
    });
    await _sync();
    if (mounted) {
      showSuccessSnackbar(context, 'Bucket list item added.');
    }
  }

  Future<void> _toggle(int index) async {
    HapticFeedback.selectionClick();
    final item = Map<String, dynamic>.from(_items[index]);
    item['done'] = !(item['done'] as bool? ?? false);
    if (item['done'] == true) {
      HapticFeedback.heavyImpact();
    }
    setState(() => _items[index] = item);
    await _sync();
  }

  Future<void> _deleteAt(int index) async {
    final removed = _items[index];
    setState(() => _items.removeAt(index));
    await _sync();
    if (!mounted) {
      return;
    }
    showUndoSnackbar(
      context,
      'Bucket list item removed.',
      () async {
        if (!mounted) return;
        setState(() => _items.insert(index, removed));
        await _sync();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleItems = _filteredItems;

    return Scaffold(
      backgroundColor: V2Theme.surfaceDark,
      body: WaifuBackground(
        opacity: 0.09,
        tint: const Color(0xFF080E14),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white70,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BUCKET LIST',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Text(
                            '$_done/${_items.length} completed goals',
                            style: GoogleFonts.outfit(
                              color: Colors.amberAccent.withValues(alpha: 0.7),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _refresh,
                      icon: const Icon(
                        Icons.refresh_rounded,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: V2Theme.primaryColor),
                      )
                    : RefreshIndicator(
                        onRefresh: _refresh,
                        color: V2Theme.primaryColor,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          children: [
                            GlassCard(
                              margin: EdgeInsets.zero,
                              glow: true,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Dream board',
                                          style: GoogleFonts.outfit(
                                            color: Colors.white70,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          _items.isEmpty
                                              ? 'Start your first big goal'
                                              : '$_activeItems dreams still ahead',
                                          style: GoogleFonts.outfit(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _items.isEmpty
                                              ? 'Capture places to go, things to build, or memories you want to make.'
                                              : 'You have $_done completed milestones and ${visibleItems.length} items in the current view.',
                                          style: GoogleFonts.outfit(
                                            color: Colors.white60,
                                            fontSize: 12,
                                            height: 1.35,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  ProgressRing(
                                    progress: _items.isEmpty
                                        ? 0
                                        : _done / _items.length,
                                    foreground: Colors.amberAccent,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.flag_circle_rounded,
                                          color: Colors.amberAccent,
                                          size: 28,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '$_done',
                                          style: GoogleFonts.outfit(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        Text(
                                          'Done',
                                          style: GoogleFonts.outfit(
                                            color: Colors.white54,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            WaifuCommentary(mood: _commentaryMood),
                            Row(
                              children: [
                                Expanded(
                                  child: StatCard(
                                    title: 'Total',
                                    value: '${_items.length}',
                                    icon: Icons.list_alt_rounded,
                                    color: Colors.amberAccent,
                                  ),
                                ),
                                Expanded(
                                  child: StatCard(
                                    title: 'Done',
                                    value: '$_done',
                                    icon: Icons.check_circle_rounded,
                                    color: V2Theme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: StatCard(
                                    title: 'Active',
                                    value: '$_activeItems',
                                    icon: Icons.flight_takeoff_rounded,
                                    color: V2Theme.secondaryColor,
                                  ),
                                ),
                                Expanded(
                                  child: StatCard(
                                    title: 'Visible',
                                    value: '${visibleItems.length}',
                                    icon: Icons.visibility_rounded,
                                    color: Colors.lightGreenAccent,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            V2SearchBar(
                              controller: _searchCtrl,
                              hintText: 'Search by goal or category...',
                              onChanged: (value) {
                                if (!mounted) return;
                                setState(() => _searchQuery = value.trim());
                              },
                            ),
                            const SizedBox(height: 12),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: List<Widget>.generate(
                                  _categories.length,
                                  (i) => Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      label: Text(_categories[i]),
                                      selected: _selCat == i,
                                      onSelected: (_) =>
                                          setState(() => _selCat = i),
                                      labelStyle: GoogleFonts.outfit(
                                        color: _selCat == i
                                            ? Colors.white
                                            : Colors.white70,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      selectedColor: Colors.amberAccent
                                          .withValues(alpha: 0.24),
                                      backgroundColor:
                                          Colors.white.withValues(alpha: 0.06),
                                      side: BorderSide(
                                        color: _selCat == i
                                            ? Colors.amberAccent
                                            : Colors.white12,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            GlassCard(
                              margin: EdgeInsets.zero,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _itemCtrl,
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 13,
                                      ),
                                      cursorColor: Colors.amberAccent,
                                      onSubmitted: (_) => _add(),
                                      decoration: InputDecoration(
                                        hintText:
                                            'Add a new bucket list item...',
                                        hintStyle: GoogleFonts.outfit(
                                          color: Colors.white30,
                                          fontSize: 12,
                                        ),
                                        border: InputBorder.none,
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  FilledButton(
                                    onPressed: _add,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.amberAccent,
                                      foregroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: const Icon(Icons.add_rounded),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (visibleItems.isEmpty)
                              EmptyState(
                                icon: Icons.flag_outlined,
                                title: _items.isEmpty
                                    ? 'Add your first dream'
                                    : 'No bucket list items found',
                                subtitle: _items.isEmpty
                                    ? 'Capture something you want to do, build, or experience and start collecting milestones here.'
                                    : 'Try a different search term or clear the filter to see everything again.',
                                buttonText:
                                    _items.isEmpty ? null : 'Clear Search',
                                onButtonPressed: _items.isEmpty
                                    ? null
                                    : () {
                                        _searchCtrl.clear();
                                        setState(() => _searchQuery = '');
                                      },
                              )
                            else
                              FadeTransition(
                                opacity: _fadeCtrl,
                                child: Column(
                                  children: List<Widget>.generate(
                                    visibleItems.length,
                                    (index) {
                                      final item = visibleItems[index];
                                      final realIndex = _items.indexOf(item);
                                      final done =
                                          item['done'] as bool? ?? false;
                                      return AnimatedEntry(
                                        index: index,
                                        child: Dismissible(
                                          key: ValueKey(item['id']),
                                          direction:
                                              DismissDirection.endToStart,
                                          background: Container(
                                            margin: const EdgeInsets.only(
                                                bottom: 10),
                                            alignment: Alignment.centerRight,
                                            padding: const EdgeInsets.only(
                                                right: 20),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                              color: Colors.redAccent
                                                  .withValues(alpha: 0.18),
                                            ),
                                            child: const Icon(
                                              Icons.delete_outline_rounded,
                                              color: Colors.redAccent,
                                            ),
                                          ),
                                          onDismissed: (_) =>
                                              _deleteAt(realIndex),
                                          child: GlassCard(
                                            margin: const EdgeInsets.only(
                                                bottom: 10),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 12,
                                            ),
                                            onTap: () => _toggle(realIndex),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  done
                                                      ? Icons
                                                          .check_circle_rounded
                                                      : Icons
                                                          .radio_button_unchecked_rounded,
                                                  color: done
                                                      ? Colors.amberAccent
                                                      : Colors.white24,
                                                  size: 22,
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        item['text']
                                                                ?.toString() ??
                                                            '',
                                                        style:
                                                            GoogleFonts.outfit(
                                                          color: done
                                                              ? Colors.white54
                                                              : Colors.white,
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          decoration: done
                                                              ? TextDecoration
                                                                  .lineThrough
                                                              : null,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        item['cat']
                                                                ?.toString() ??
                                                            '',
                                                        style:
                                                            GoogleFonts.outfit(
                                                          color: Colors
                                                              .amberAccent
                                                              .withValues(
                                                                  alpha: 0.65),
                                                          fontSize: 10,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
