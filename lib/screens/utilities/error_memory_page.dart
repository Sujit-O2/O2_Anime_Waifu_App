import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anime_waifu/core/v2_upgrade_kit.dart';

/// Error Memory v2 — Developer's bug journal with severity levels,
/// language tags, search, solution tracking, copy-to-clipboard, and stats.
class ErrorMemoryPage extends StatefulWidget {
  const ErrorMemoryPage({super.key});
  @override
  State<ErrorMemoryPage> createState() => _ErrorMemoryPageState();
}

class _ErrorMemoryPageState extends State<ErrorMemoryPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  final _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _errors = [];
  String _filterLang = 'all';
  String _searchQuery = '';

  static const _severities = {
    'critical': {'icon': '🔴', 'color': 0xFFFF1744, 'label': 'Critical'},
    'error': {'icon': '🟠', 'color': 0xFFFF5252, 'label': 'Error'},
    'warning': {'icon': '🟡', 'color': 0xFFFFD740, 'label': 'Warning'},
    'info': {'icon': '🔵', 'color': 0xFF40C4FF, 'label': 'Info'},
  };

  static const _defaultLangs = ['Dart', 'Python', 'JS', 'Kotlin', 'Swift', 'Rust', 'Go', 'C++'];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
    _searchCtrl.addListener(() => setState(() => _searchQuery = _searchCtrl.text.toLowerCase()));
    _load();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('error_memory_v2');
    if (data != null && mounted) {
      try { setState(() => _errors = (jsonDecode(data) as List).cast<Map<String, dynamic>>()); } catch (_) {}
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('error_memory_v2', jsonEncode(_errors));
  }

  Set<String> get _allLangs => _errors.map((e) => (e['lang']?.toString() ?? 'Unknown')).toSet();
  int get _solvedCount => _errors.where((e) => (e['solution']?.toString() ?? '').isNotEmpty).length;

  List<Map<String, dynamic>> get _filtered {
    var list = _errors.toList();
    if (_filterLang != 'all') list = list.where((e) => e['lang'] == _filterLang).toList();
    if (_searchQuery.isNotEmpty) {
      list = list.where((e) =>
        (e['error']?.toString() ?? '').toLowerCase().contains(_searchQuery) ||
        (e['solution']?.toString() ?? '').toLowerCase().contains(_searchQuery) ||
        (e['lang']?.toString() ?? '').toLowerCase().contains(_searchQuery)
      ).toList();
    }
    return list;
  }

  void _addError() {
    final errCtrl = TextEditingController();
    final solCtrl = TextEditingController();
    String lang = 'Dart';
    String severity = 'error';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A2E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text('Log Error 🐛', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),

            // Language selector
            SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _defaultLangs.map((l) => GestureDetector(
                  onTap: () => setSheetState(() => lang = l),
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: lang == l ? Colors.redAccent.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.04),
                      border: Border.all(color: lang == l ? Colors.redAccent : Colors.white12),
                    ),
                    child: Text(l, style: GoogleFonts.sourceCodePro(color: lang == l ? Colors.redAccent : Colors.white38, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                )).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // Severity
            Row(children: _severities.entries.map((e) {
              final active = severity == e.key;
              final c = Color(e.value['color'] as int);
              return Expanded(child: GestureDetector(
                onTap: () => setSheetState(() => severity = e.key),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: active ? c.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.03),
                    border: Border.all(color: active ? c : Colors.white12),
                  ),
                  child: Center(child: Text('${e.value['icon']} ${e.value['label']}', style: GoogleFonts.outfit(color: active ? c : Colors.white38, fontSize: 9, fontWeight: FontWeight.w700))),
                ),
              ));
            }).toList()),
            const SizedBox(height: 12),

            // Error field
            TextField(
              controller: errCtrl,
              maxLines: 4,
              style: GoogleFonts.sourceCodePro(color: Colors.redAccent.withValues(alpha: 0.9), fontSize: 12),
              cursorColor: Colors.redAccent,
              decoration: _inputDeco('Error message / stack trace', Icons.error_outline),
            ),
            const SizedBox(height: 10),

            // Solution field
            TextField(
              controller: solCtrl,
              maxLines: 3,
              style: GoogleFonts.sourceCodePro(color: Colors.greenAccent.withValues(alpha: 0.9), fontSize: 12),
              cursorColor: Colors.greenAccent,
              decoration: _inputDeco('Solution / fix', Icons.check_circle_outline),
            ),
            const SizedBox(height: 16),

            // Save button
            GestureDetector(
              onTap: () {
                if (errCtrl.text.isEmpty) return;
                HapticFeedback.mediumImpact();
                setState(() => _errors.insert(0, {
                  'error': errCtrl.text,
                  'solution': solCtrl.text,
                  'lang': lang,
                  'severity': severity,
                  'time': DateTime.now().toIso8601String(),
                }));
                _save();
                Navigator.pop(ctx);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFF5252), Color(0xFFFF1744)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(child: Text('LOG ERROR', style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800))),
              ),
            ),
          ])),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.outfit(color: Colors.white24),
    prefixIcon: Icon(icon, color: Colors.redAccent.withValues(alpha: 0.5), size: 18),
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.05),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return FeaturePageV2(
      title: 'ERROR MEMORY',
      subtitle: '${_errors.length} errors • $_solvedCount solved',
      onBack: () => Navigator.pop(context),
      actions: [
        GestureDetector(
          onTap: _addError,
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
            ),
            child: const Icon(Icons.add_rounded, color: Colors.redAccent, size: 20),
          ),
        ),
      ],
      content: FadeTransition(
        opacity: _fadeCtrl,
        child: Column(children: [

              // ── Search ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.redAccent.withValues(alpha: 0.15))),
                  child: TextField(
                    controller: _searchCtrl,
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
                    cursorColor: Colors.redAccent,
                    decoration: InputDecoration(hintText: 'Search errors & solutions...', hintStyle: GoogleFonts.outfit(color: Colors.white24), border: InputBorder.none, icon: const Icon(Icons.search, color: Colors.redAccent, size: 18)),
                  ),
                ),
              ),

              // ── Language Filters ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: SizedBox(
                  height: 30,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _langChip('all', 'All'),
                      ..._allLangs.map((l) => _langChip(l, l)),
                    ],
                  ),
                ),
              ),

              // ── Stats Row ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Row(children: [
                  _statChip('🐛', '${_errors.length}', 'Total', Colors.redAccent),
                  const SizedBox(width: 8),
                  _statChip('✅', '$_solvedCount', 'Solved', Colors.greenAccent),
                  const SizedBox(width: 8),
                  _statChip('⏳', '${_errors.length - _solvedCount}', 'Open', Colors.amberAccent),
                  const SizedBox(width: 8),
                  _statChip('📊', _allLangs.isEmpty ? '0' : '${_allLangs.length}', 'Langs', Colors.cyanAccent),
                ]),
              ),

              const SizedBox(height: 8),

              // ── Error Cards ──
              Expanded(
                child: filtered.isEmpty
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text('🐛', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 12),
                      Text('No bugs logged yet', style: GoogleFonts.outfit(color: Colors.white30, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('Tap + to log an error', style: GoogleFonts.outfit(color: Colors.white24, fontSize: 11)),
                    ]))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => _buildErrorCard(i, filtered[i]),
                    ),
              ),
        ]),
      ),
    );
  }

  Widget _langChip(String key, String label) {
    final active = _filterLang == key;
    final count = key == 'all' ? _errors.length : _errors.where((e) => e['lang'] == key).length;
    return GestureDetector(
      onTap: () => setState(() => _filterLang = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: active ? Colors.redAccent.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.04), border: Border.all(color: active ? Colors.redAccent : Colors.white12)),
        child: Text('$label ($count)', style: GoogleFonts.sourceCodePro(color: active ? Colors.redAccent : Colors.white38, fontSize: 10, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _statChip(String emoji, String value, String label, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: color.withValues(alpha: 0.05), border: Border.all(color: color.withValues(alpha: 0.15))),
      child: Column(children: [
        Text('$emoji $value', style: GoogleFonts.outfit(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
        Text(label, style: GoogleFonts.outfit(color: Colors.white30, fontSize: 8)),
      ]),
    ),
  );

  Widget _buildErrorCard(int index, Map<String, dynamic> error) {
    final severity = error['severity']?.toString() ?? 'error';
    final sevConfig = _severities[severity] ?? _severities['error']!;
    final sevColor = Color(sevConfig['color'] as int);
    final hasSolution = (error['solution']?.toString() ?? '').isNotEmpty;
    final time = DateTime.tryParse(error['time']?.toString() ?? '');
    final timeStr = time != null ? '${time.day}/${time.month}' : '';
    final realIndex = _errors.indexOf(error);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + index * 50),
      curve: Curves.easeOut,
      builder: (_, val, child) => Opacity(opacity: val, child: Transform.translate(offset: Offset(0, 12 * (1 - val)), child: child)),
      child: Dismissible(
        key: Key('${error['time']}_$index'),
        direction: DismissDirection.endToStart,
        onDismissed: (_) {
          final removed = _errors.removeAt(realIndex);
          _save();
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error deleted', style: GoogleFonts.outfit(color: Colors.white)),
            backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            action: SnackBarAction(label: 'UNDO', textColor: Colors.amberAccent, onPressed: () {
              setState(() => _errors.insert(realIndex, removed));
              _save();
            }),
          ));
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.delete_outline, color: Colors.redAccent),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: sevColor.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: sevColor.withValues(alpha: 0.15)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(sevConfig['icon'] as String, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: Colors.orangeAccent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                child: Text(error['lang']?.toString() ?? '', style: GoogleFonts.sourceCodePro(color: Colors.orangeAccent, fontSize: 9, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: sevColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                child: Text(sevConfig['label'] as String, style: GoogleFonts.outfit(color: sevColor, fontSize: 8, fontWeight: FontWeight.w700)),
              ),
              const Spacer(),
              Text(timeStr, style: GoogleFonts.outfit(color: Colors.white24, fontSize: 9)),
              const SizedBox(width: 4),
              if (hasSolution) const Icon(Icons.check_circle, color: Colors.greenAccent, size: 14),
            ]),
            const SizedBox(height: 8),
            // Error text
            GestureDetector(
              onTap: () { Clipboard.setData(ClipboardData(text: error['error']?.toString() ?? '')); HapticFeedback.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Copied to clipboard', style: GoogleFonts.outfit(color: Colors.white)), duration: const Duration(seconds: 1), backgroundColor: Colors.greenAccent.withValues(alpha: 0.8), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
              },
              child: Text(error['error']?.toString() ?? '', maxLines: 4, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.sourceCodePro(color: sevColor.withValues(alpha: 0.9), fontSize: 11, height: 1.4)),
            ),
            if (hasSolution) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.greenAccent.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.15))),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.check_circle, color: Colors.greenAccent, size: 14),
                  const SizedBox(width: 6),
                  Expanded(child: Text(error['solution'].toString(), style: GoogleFonts.sourceCodePro(color: Colors.greenAccent.withValues(alpha: 0.8), fontSize: 11, height: 1.4))),
                ]),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}



