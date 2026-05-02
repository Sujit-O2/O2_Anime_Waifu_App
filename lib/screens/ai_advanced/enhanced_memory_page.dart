import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:anime_waifu/services/memory_context/enhanced_memory_service.dart';
import 'package:flutter/material.dart';
import 'package:anime_waifu/config/app_themes.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class EnhancedMemoryPage extends StatefulWidget {
  const EnhancedMemoryPage({super.key});
  @override
  State<EnhancedMemoryPage> createState() => _EnhancedMemoryPageState();
}

class _EnhancedMemoryPageState extends State<EnhancedMemoryPage> {
  final _service = EnhancedMemoryService.instance;
  final _keyCtrl = TextEditingController();
  final _valCtrl = TextEditingController();
  Map<String, String> _facts = {};
  bool _loading = true;
  bool _saving = false;

  static const _quickFacts = [
    {'key': 'Name', 'value': 'Sujit'},
    {'key': 'Favorite anime', 'value': 'Darling in the FranXX'},
    {'key': 'Hobby', 'value': 'Coding'},
    {'key': 'Goal', 'value': 'Build something amazing'},
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _keyCtrl.dispose();
    _valCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final facts = await _service.recallAll();
    if (mounted) setState(() { _facts = facts; _loading = false; });
  }

  Future<void> _save() async {
    final k = _keyCtrl.text.trim();
    final v = _valCtrl.text.trim();
    if (k.isEmpty || v.isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() => _saving = true);
    await _service.saveFact(k, v);
    _keyCtrl.clear();
    _valCtrl.clear();
    await _load();
    if (mounted) {
      setState(() => _saving = false);
      showSuccessSnackbar(context, 'Memory saved');
    }
  }

  Future<void> _delete(String key) async {
    HapticFeedback.mediumImpact();
    await _service.deleteFact(key);
    await _load();
  }

  Future<void> _clearAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Clear all memories?', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Text('This permanently deletes all stored facts.', style: GoogleFonts.outfit()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Clear', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (ok == true) { await _service.clearAll(); await _load(); }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.appTokens;
    final primary = theme.colorScheme.primary;

    return FeaturePageV2(
      title: 'ENHANCED MEMORY',
      subtitle: '${_facts.length}/30 facts stored',
      onBack: () => Navigator.pop(context),
      actions: [
        if (_facts.isNotEmpty)
          GestureDetector(
            onTap: _clearAll,
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3))),
              child: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 18),
            ),
          ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _load,
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: tokens.panelMuted, borderRadius: BorderRadius.circular(10), border: Border.all(color: tokens.outlineStrong)),
            child: Icon(Icons.refresh_rounded, color: tokens.textMuted, size: 18),
          ),
        ),
      ],
      content: _loading
          ? const PremiumLoadingState(label: 'Loading memories…', icon: Icons.memory_rounded)
          : Column(children: [
              // ── Stats + hero ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(children: [
                  AnimatedEntry(
                    index: 0,
                    child: GlassCard(
                      margin: EdgeInsets.zero,
                      glow: true,
                      child: Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Memory vault', style: GoogleFonts.outfit(color: tokens.textSoft, fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Text(_facts.isEmpty ? 'No facts stored yet' : '${_facts.length} facts in memory', style: GoogleFonts.outfit(color: theme.colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          Text('Facts are injected into every AI conversation so Zero Two remembers you.', style: GoogleFonts.outfit(color: tokens.textMuted, fontSize: 12, height: 1.35)),
                        ])),
                        const SizedBox(width: 16),
                        ProgressRing(
                          progress: _facts.length / 30,
                          foreground: primary,
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.memory_rounded, size: 26),
                            const SizedBox(height: 4),
                            Text('${_facts.length}', style: GoogleFonts.outfit(color: theme.colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w800)),
                            Text('Facts', style: GoogleFonts.outfit(color: tokens.textMuted, fontSize: 10)),
                          ]),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AnimatedEntry(
                    index: 1,
                    child: Row(children: [
                      Expanded(child: StatCard(title: 'Stored', value: '${_facts.length}', icon: Icons.storage_rounded, color: primary)),
                      const Expanded(child: StatCard(title: 'Capacity', value: '30', icon: Icons.data_usage_rounded, color: Colors.amberAccent)),
                      Expanded(child: StatCard(title: 'Status', value: _facts.isEmpty ? 'Empty' : 'Active', icon: Icons.check_circle_rounded, color: _facts.isEmpty ? tokens.textMuted : Colors.lightGreenAccent)),
                    ]),
                  ),
                  const SizedBox(height: 12),

                  // ── Add form ─────────────────────────────────────────────
                  AnimatedEntry(
                    index: 2,
                    child: GlassCard(
                      margin: EdgeInsets.zero,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('ADD MEMORY FACT', style: GoogleFonts.outfit(color: tokens.textSoft, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                        const SizedBox(height: 10),
                        Row(children: [
                          Expanded(flex: 2, child: TextField(
                            controller: _keyCtrl,
                            style: GoogleFonts.outfit(color: theme.colorScheme.onSurface, fontSize: 13),
                            cursorColor: primary,
                            decoration: InputDecoration(hintText: 'Key (e.g. Name)', hintStyle: GoogleFonts.outfit(color: tokens.textSoft, fontSize: 12), isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                          )),
                          const SizedBox(width: 8),
                          Expanded(flex: 3, child: TextField(
                            controller: _valCtrl,
                            style: GoogleFonts.outfit(color: theme.colorScheme.onSurface, fontSize: 13),
                            cursorColor: primary,
                            onSubmitted: (_) => _save(),
                            decoration: InputDecoration(hintText: 'Value (e.g. Sujit)', hintStyle: GoogleFonts.outfit(color: tokens.textSoft, fontSize: 12), isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                          )),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _saving ? null : _save,
                            child: Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(color: primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: primary.withValues(alpha: 0.4))),
                              child: _saving
                                  ? Padding(padding: const EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2, color: primary))
                                  : Icon(Icons.add_rounded, color: primary, size: 22),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 10),
                        // Quick add chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(children: _quickFacts.map((f) => GestureDetector(
                            onTap: () { _keyCtrl.text = f['key']!; _valCtrl.text = f['value']!; },
                            child: Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: tokens.panelMuted, borderRadius: BorderRadius.circular(20), border: Border.all(color: tokens.outline)),
                              child: Text('+ ${f['key']}', style: GoogleFonts.outfit(color: tokens.textMuted, fontSize: 11)),
                            ),
                          )).toList()),
                        ),
                      ]),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 8),

              // ── Facts list ───────────────────────────────────────────────
              Expanded(
                child: _facts.isEmpty
                    ? const EmptyState(icon: Icons.memory_rounded, title: 'No facts stored', subtitle: 'Add facts above so Zero Two can remember things about you in every conversation.')
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: _facts.length,
                        itemBuilder: (ctx, i) {
                          final key = _facts.keys.elementAt(i);
                          final val = _facts[key]!;
                          return AnimatedEntry(
                            index: i,
                            child: Dismissible(
                              key: ValueKey(key),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 16),
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: Colors.redAccent.withValues(alpha: 0.12)),
                                child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                              ),
                              onDismissed: (_) => _delete(key),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  color: tokens.panelMuted,
                                  border: Border.all(color: tokens.outline),
                                ),
                                child: Row(children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                    child: Icon(Icons.memory_rounded, color: primary, size: 16),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(key, style: GoogleFonts.outfit(color: primary, fontWeight: FontWeight.w600, fontSize: 12)),
                                    Text(val, style: GoogleFonts.outfit(color: theme.colorScheme.onSurface, fontSize: 14)),
                                  ])),
                                  GestureDetector(
                                    onTap: () => _delete(key),
                                    child: Icon(Icons.close_rounded, color: tokens.textSoft, size: 18),
                                  ),
                                ]),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ]),
    );
  }
}
