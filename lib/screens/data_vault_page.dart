import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/waifu_background.dart';

/// 🔐 DATA VAULT — Secret panel (tap version label 7 times in About page)
/// All Firestore paths are in sync with FirestoreService:
///   chats/{uid}         — chat messages array
///   vault/{uid}         — secret notes + PIN
///   profiles/{uid}      — persona, custom rules, waifu name
///   affection/{uid}     — XP, streak, relationship level
///   memory/{uid}        — AI memory facts
///   quests/{uid}        — daily quests progress
///   mood/{uid}          — mood journal entries
///   scores/{uid}        — mini-game high scores
///   achievements/{uid}  — unlocked badges
///   settings/{uid}      — app settings/prefs
class DataVaultPage extends StatefulWidget {
  const DataVaultPage({super.key});
  @override
  State<DataVaultPage> createState() => _DataVaultPageState();
}

class _DataVaultPageState extends State<DataVaultPage>
    with SingleTickerProviderStateMixin {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  late final AnimationController _glowCtrl;
  late final Animation<double> _glowAnim;
  bool _loading = true;
  final Map<String, _VaultCategory> _categories = {};
  String? _deletingKey;

  User? get _user => _auth.currentUser;
  String? get _uid => _user?.uid;

  @override
  void initState() {
    super.initState();
    _glowCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.3, end: 1.0)
        .animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
    _loadStats();
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  // ── Correct Firestore paths matching FirestoreService ─────────────────────
  static const _defs = [
    _VaultDef(
      key: 'chat',
      label: '💬 Chat History',
      subtitle: 'All stored messages',
      icon: Icons.chat_bubble_outline,
      color: Colors.cyanAccent,
      // chats/{uid} — single doc with 'messages' array
      collection: 'chats',
      isSingleDoc: true,
      countField: 'messages',
    ),
    _VaultDef(
      key: 'vault',
      label: '🔐 Secret Notes',
      subtitle: 'PIN-protected private notes',
      icon: Icons.lock_outline,
      color: Colors.pinkAccent,
      collection: 'vault',
      isSingleDoc: true,
      countField: 'notes',
    ),
    _VaultDef(
      key: 'profile',
      label: '👤 Profile & Persona',
      subtitle: 'Custom persona, rules, name',
      icon: Icons.person_outline,
      color: Colors.blueAccent,
      collection: 'profiles',
      isSingleDoc: true,
    ),
    _VaultDef(
      key: 'affection',
      label: '💖 Affection / XP',
      subtitle: 'Relationship XP, streak, level',
      icon: Icons.favorite_outline,
      color: Colors.pinkAccent,
      collection: 'affection',
      isSingleDoc: true,
      isXp: true,
    ),
    _VaultDef(
      key: 'memory',
      label: '🧠 AI Memory',
      subtitle: 'Facts Zero Two remembers about you',
      icon: Icons.psychology_outlined,
      color: Colors.deepPurpleAccent,
      collection: 'memory',
      isSingleDoc: true,
      countField: 'facts',
    ),
    _VaultDef(
      key: 'quests',
      label: '⚡ Daily Quests',
      subtitle: 'Quest progress & completions',
      icon: Icons.flag_circle_outlined,
      color: Colors.lightGreenAccent,
      collection: 'quests',
      isSingleDoc: true,
    ),
    _VaultDef(
      key: 'mood',
      label: '😊 Mood Journal',
      subtitle: 'Mood entries & history',
      icon: Icons.mood_outlined,
      color: Colors.orangeAccent,
      collection: 'mood',
      isSingleDoc: true,
      countField: 'entries',
    ),
    _VaultDef(
      key: 'scores',
      label: '🎮 Game High Scores',
      subtitle: 'Best scores across all 8 games',
      icon: Icons.sports_esports_outlined,
      color: Colors.amberAccent,
      collection: 'scores',
      isSingleDoc: true,
    ),
    _VaultDef(
      key: 'achievements',
      label: '🏆 Achievements',
      subtitle: 'Unlocked badges & milestones',
      icon: Icons.emoji_events_outlined,
      color: Colors.yellow,
      collection: 'achievements',
      isSingleDoc: true,
      countField: 'badges',
    ),
    _VaultDef(
      key: 'settings',
      label: '⚙️ App Settings',
      subtitle: 'Synced preferences & config',
      icon: Icons.settings_outlined,
      color: Colors.tealAccent,
      collection: 'settings',
      isSingleDoc: true,
    ),
  ];

  Future<void> _loadStats() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final uid = _uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }

    final cats = <String, _VaultCategory>{};
    for (final def in _defs) {
      int count = 0;
      String? lastUpdated;
      String? preview;
      try {
        final doc = await _db.collection(def.collection).doc(uid).get();
        if (doc.exists) {
          final data = doc.data() ?? {};

          // Get count
          if (def.countField != null) {
            final field = data[def.countField!];
            if (field is List) {
              count = field.length;
            } else if (field is String && field.isNotEmpty) {
              // JSON-encoded string, estimate count
              count = 1;
              try {
                final decoded = jsonDecode(field);
                if (decoded is List) count = decoded.length;
                if (decoded is Map) count = decoded.length;
              } catch (_) {}
            } else if (field != null) {
              count = 1;
            }
          } else {
            count = doc.exists ? 1 : 0;
          }

          // Get last updated
          final ts = data['updatedAt'];
          if (ts is Timestamp) lastUpdated = _fmtDate(ts.toDate());

          // Count for chat (messages array)
          if (def.key == 'chat') {
            final msgs = data['messages'] as List?;
            if (msgs != null) {
              count = msgs.length;
              if (msgs.isNotEmpty) {
                final last = msgs.last as Map<String, dynamic>;
                final text = last['text']?.toString() ?? '';
                preview = text.length > 40 ? text.substring(0, 40) : text;
              }
            }
          }

          // Count for memory (JSON map)
          if (def.key == 'memory') {
            try {
              final raw = data['facts'] as String?;
              if (raw != null && raw.isNotEmpty) {
                final m = jsonDecode(raw) as Map;
                count = m.length;
              }
            } catch (_) {}
          }

          // Count for mood (JSON list)
          if (def.key == 'mood') {
            try {
              final raw = data['entries'] as String?;
              if (raw != null && raw.isNotEmpty) {
                final list = jsonDecode(raw) as List;
                count = list.length;
              }
            } catch (_) {}
          }
        }
      } catch (_) {}
      cats[def.key] = _VaultCategory(
          def: def, count: count, lastUpdated: lastUpdated, preview: preview);
    }
    if (mounted) {
      setState(() {
        _categories.addAll(cats);
        _loading = false;
      });
    }
  }

  String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  Future<void> _deleteCategory(_VaultCategory cat) async {
    final uid = _uid;
    if (uid == null) return;
    final confirmed = await _showConfirm(cat.def.label);
    if (!confirmed) return;
    HapticFeedback.heavyImpact();
    setState(() => _deletingKey = cat.def.key);
    try {
      await _db.collection(cat.def.collection).doc(uid).delete();
      _snack('✅ ${cat.def.label} deleted!', cat.def.color);
      await _loadStats();
    } catch (e) {
      _snack('❌ Error: $e', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _deletingKey = null);
    }
  }

  Future<void> _deleteAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF12121E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('⚠️ Delete ALL Data?',
            style: GoogleFonts.outfit(
                color: Colors.redAccent, fontWeight: FontWeight.w800)),
        content: Text(
          'This will permanently delete ALL your data from the cloud database — chat history, notes, XP, achievements, everything.\n\nThis cannot be undone.',
          style: GoogleFonts.outfit(color: Colors.white70, height: 1.5),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel',
                  style: GoogleFonts.outfit(color: Colors.white38))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: Text('Delete Everything',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final uid = _uid;
    if (uid == null) return;

    HapticFeedback.heavyImpact();
    setState(() => _loading = true);
    try {
      final collections = _defs.map((d) => d.collection).toSet();
      for (final col in collections) {
        try {
          await _db.collection(col).doc(uid).delete();
        } catch (_) {}
      }
      _snack('✅ All data deleted from cloud', Colors.pinkAccent);
      await _loadStats();
    } catch (e) {
      _snack('❌ Error: $e', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: GoogleFonts.outfit(
              color: Colors.black87, fontWeight: FontWeight.w700)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
    ));
  }

  Future<bool> _showConfirm(String label) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF12121E),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Text('Delete $label?',
                style: GoogleFonts.outfit(
                    color: Colors.white, fontWeight: FontWeight.w800)),
            content: Text(
                'This will permanently delete this data from the cloud. Are you sure?',
                style: GoogleFonts.outfit(color: Colors.white60, height: 1.5)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel',
                    style: GoogleFonts.outfit(color: Colors.white38)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('Delete',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final uid = _uid;
    return Scaffold(
      backgroundColor: const Color(0xFF050510),
      body: WaifuBackground(
        opacity: 0.06,
        tint: const Color(0xFF050510),
        child: SafeArea(
          child: Column(children: [
            // Header
            AnimatedBuilder(
              animation: _glowAnim,
              builder: (ctx, _) => Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color:
                          Colors.redAccent.withOpacity(_glowAnim.value * 0.3),
                    ),
                  ),
                ),
                child: Row(children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white60, size: 16),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Text('🔐', style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Text('DATA VAULT',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                  shadows: [
                                    Shadow(
                                        color: Colors.redAccent
                                            .withOpacity(_glowAnim.value * 0.6),
                                        blurRadius: 12)
                                  ],
                                )),
                          ]),
                          Text(
                              'All cloud data • ${uid != null ? '${uid.substring(0, 8)}…' : 'Not signed in'}',
                              style: GoogleFonts.outfit(
                                  color: Colors.white24, fontSize: 10)),
                        ]),
                  ),
                  if (!_loading)
                    GestureDetector(
                      onTap: _loadStats,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: const Icon(Icons.refresh_rounded,
                            color: Colors.white38, size: 18),
                      ),
                    ),
                ]),
              ),
            ),

            // Warning banner
            Container(
              margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent.withOpacity(0.25)),
              ),
              child: Row(children: [
                const Text('⚠️', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Deleting data here removes it permanently from the cloud. Local cached data may remain until app restart.',
                    style: GoogleFonts.outfit(
                        color: Colors.white54, fontSize: 11, height: 1.4),
                  ),
                ),
              ]),
            ),

            const SizedBox(height: 6),

            // Categories list
            Expanded(
              child: _loading
                  ? Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                          const CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.redAccent),
                          const SizedBox(height: 14),
                          Text('Reading cloud data…',
                              style: GoogleFonts.outfit(color: Colors.white38)),
                        ]))
                  : uid == null
                      ? Center(
                          child: Text('Please sign in to view your data vault.',
                              style: GoogleFonts.outfit(color: Colors.white38)))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                          itemCount: _defs.length,
                          itemBuilder: (ctx, i) {
                            final key = _defs[i].key;
                            final cat = _categories[key];
                            if (cat == null) return const SizedBox.shrink();
                            return _buildCategoryCard(cat);
                          },
                        ),
            ),
          ]),
        ),
      ),
      // Delete All FAB
      floatingActionButton: uid != null && !_loading
          ? FloatingActionButton.extended(
              onPressed: _deleteAll,
              backgroundColor: Colors.redAccent,
              icon:
                  const Icon(Icons.delete_forever_rounded, color: Colors.white),
              label: Text('Delete All',
                  style: GoogleFonts.outfit(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            )
          : null,
    );
  }

  Widget _buildCategoryCard(_VaultCategory cat) {
    final isDeleting = _deletingKey == cat.def.key;
    final hasData = cat.count > 0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: hasData
            ? cat.def.color.withOpacity(0.06)
            : Colors.white.withOpacity(0.02),
        border: Border.all(
          color: hasData
              ? cat.def.color.withOpacity(0.25)
              : Colors.white.withOpacity(0.06),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cat.def.color.withOpacity(hasData ? 0.15 : 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: cat.def.color.withOpacity(hasData ? 0.3 : 0.1)),
            ),
            child: Icon(cat.def.icon,
                color: hasData ? cat.def.color : Colors.white24, size: 22),
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(cat.def.label,
                  style: GoogleFonts.outfit(
                      color: hasData ? Colors.white : Colors.white38,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(cat.def.subtitle,
                  style:
                      GoogleFonts.outfit(color: Colors.white30, fontSize: 11)),
              if (hasData) ...[
                const SizedBox(height: 4),
                Row(children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: cat.def.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      cat.def.key == 'chat'
                          ? '${cat.count} messages'
                          : '${cat.count} ${cat.count == 1 ? "item" : "items"}',
                      style: GoogleFonts.outfit(
                          color: cat.def.color,
                          fontSize: 10,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (cat.lastUpdated != null) ...[
                    const SizedBox(width: 8),
                    Text('Updated ${cat.lastUpdated}',
                        style: GoogleFonts.outfit(
                            color: Colors.white24, fontSize: 10)),
                  ],
                ]),
              ] else ...[
                const SizedBox(height: 4),
                Text('No data stored',
                    style: GoogleFonts.outfit(
                        color: Colors.white24, fontSize: 11)),
              ],
            ]),
          ),

          // Delete button
          if (isDeleting)
            const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.redAccent))
          else if (hasData)
            GestureDetector(
              onTap: () => _deleteCategory(cat),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                ),
                child: const Icon(Icons.delete_outlined,
                    color: Colors.redAccent, size: 18),
              ),
            )
          else
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: const Icon(Icons.check_rounded,
                  color: Colors.white12, size: 18),
            ),
        ]),
      ),
    );
  }
}

// ── Models ────────────────────────────────────────────────────────────────────

class _VaultDef {
  final String key, label, subtitle, collection;
  final IconData icon;
  final Color color;
  final bool isSingleDoc;
  final bool isXp;
  final String? countField;

  const _VaultDef({
    required this.key,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.collection,
    this.isSingleDoc = false,
    this.isXp = false,
    this.countField,
  });
}

class _VaultCategory {
  final _VaultDef def;
  final int count;
  final String? lastUpdated;
  final String? preview;

  const _VaultCategory({
    required this.def,
    required this.count,
    this.lastUpdated,
    this.preview,
  });
}
