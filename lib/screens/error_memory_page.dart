import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Error Memory — Stores coding errors + solutions so you never solve the same bug twice.
class ErrorMemoryPage extends StatefulWidget {
  const ErrorMemoryPage({super.key});
  @override
  State<ErrorMemoryPage> createState() => _ErrorMemoryPageState();
}

class _ErrorMemoryPageState extends State<ErrorMemoryPage> {
  List<Map<String, dynamic>> _errors = [];
  final _searchCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('error_memory');
    if (data != null && mounted) {
      try {
        setState(() => _errors = (jsonDecode(data) as List).cast<Map<String, dynamic>>());
      } catch (_) {}
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('error_memory', jsonEncode(_errors));
  }

  void _addError() {
    final errCtrl = TextEditingController();
    final solCtrl = TextEditingController();
    final langCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.95), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Log Error', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800)),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        _field(errCtrl, 'Error message / stack trace', Icons.error_outline),
        const SizedBox(height: 10),
        _field(solCtrl, 'Solution / fix', Icons.check_circle_outline),
        const SizedBox(height: 10),
        _field(langCtrl, 'Language / framework', Icons.code),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.white54))),
        TextButton(onPressed: () {
          if (errCtrl.text.isNotEmpty) {
            setState(() => _errors.insert(0, {'error': errCtrl.text, 'solution': solCtrl.text, 'lang': langCtrl.text, 'time': DateTime.now().toIso8601String()}));
            _save(); Navigator.pop(ctx);
          }
        }, child: Text('SAVE', style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.w700))),
      ],
    ));
  }

  Widget _field(TextEditingController c, String hint, IconData icon) => TextField(controller: c, maxLines: 3, style: GoogleFonts.sourceCodePro(color: Colors.white, fontSize: 12), cursorColor: Colors.redAccent, decoration: InputDecoration(hintText: hint, hintStyle: GoogleFonts.outfit(color: Colors.white24), prefixIcon: Icon(icon, color: Colors.redAccent.withValues(alpha: 0.6), size: 18), filled: true, fillColor: Colors.white.withValues(alpha: 0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)));

  @override
  Widget build(BuildContext context) {
    final q = _searchCtrl.text.toLowerCase();
    final filtered = q.isEmpty ? _errors : _errors.where((e) => (e['error']?.toString() ?? '').toLowerCase().contains(q) || (e['solution']?.toString() ?? '').toLowerCase().contains(q)).toList();
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70), onPressed: () => Navigator.pop(context)),
        title: Text('ERROR MEMORY', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.5)), centerTitle: true),
      floatingActionButton: FloatingActionButton(onPressed: _addError, backgroundColor: Colors.redAccent, child: const Icon(Icons.add, color: Colors.white)),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(12), child: TextField(controller: _searchCtrl, onChanged: (_) => setState(() {}), style: GoogleFonts.outfit(color: Colors.white), cursorColor: Colors.redAccent, decoration: InputDecoration(hintText: 'Search errors...', hintStyle: GoogleFonts.outfit(color: Colors.white24), prefixIcon: const Icon(Icons.search, color: Colors.redAccent), filled: true, fillColor: Colors.white.withValues(alpha: 0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)))),
        Expanded(child: filtered.isEmpty
          ? Center(child: Text('No errors logged yet 🐛', style: GoogleFonts.outfit(color: Colors.white30)))
          : ListView.builder(padding: const EdgeInsets.all(12), itemCount: filtered.length, itemBuilder: (_, i) {
            final e = filtered[i];
            return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [const Icon(Icons.error_outline, color: Colors.redAccent, size: 16), const SizedBox(width: 6), if ((e['lang']?.toString() ?? '').isNotEmpty) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.orangeAccent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)), child: Text(e['lang'].toString(), style: GoogleFonts.outfit(color: Colors.orangeAccent, fontSize: 9, fontWeight: FontWeight.w700)))]),
                const SizedBox(height: 6),
                Text(e['error']?.toString() ?? '', maxLines: 3, overflow: TextOverflow.ellipsis, style: GoogleFonts.sourceCodePro(color: Colors.redAccent.withValues(alpha: 0.9), fontSize: 11)),
                if ((e['solution']?.toString() ?? '').isNotEmpty) ...[const SizedBox(height: 8), Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.check_circle, color: Colors.greenAccent, size: 14), const SizedBox(width: 6), Expanded(child: Text(e['solution'].toString(), style: GoogleFonts.outfit(color: Colors.greenAccent.withValues(alpha: 0.8), fontSize: 11)))])],
              ]));
          })),
      ]),
    );
  }
}
