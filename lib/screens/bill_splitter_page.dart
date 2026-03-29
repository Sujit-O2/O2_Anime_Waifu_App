import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

class BillSplitterPage extends StatefulWidget {
  const BillSplitterPage({super.key});
  @override
  State<BillSplitterPage> createState() => _BillSplitterPageState();
}

class _BillSplitterPageState extends State<BillSplitterPage> {
  final _totalCtrl = TextEditingController();
  List<String> _people = ['You'];
  double _tipPct = 0;
  bool _includeTax = false;
  double _taxPct = 18;
  final _personCtrl = TextEditingController();

  @override
  void dispose() { _totalCtrl.dispose(); _personCtrl.dispose(); super.dispose(); }

  double get _total => double.tryParse(_totalCtrl.text) ?? 0;
  double get _tip => _total * (_tipPct / 100);
  double get _tax => _includeTax ? _total * (_taxPct / 100) : 0;
  double get _grandTotal => _total + _tip + _tax;
  double get _perPerson => _people.isEmpty ? 0 : _grandTotal / _people.length;

  void _addPerson() {
    if (_personCtrl.text.trim().isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() => _people.add(_personCtrl.text.trim()));
    _personCtrl.clear();
  }

  void _removePerson(int i) {
    if (_people.length <= 1) return;
    HapticFeedback.lightImpact();
    setState(() => _people.removeAt(i));
  }

  void _shareResult() {
    if (_total <= 0) return;
    final sb = StringBuffer('💰 Bill Split Summary\n');
    sb.writeln('━━━━━━━━━━━━━━━━━');
    sb.writeln('Subtotal: ₹${_total.toStringAsFixed(2)}');
    if (_tipPct > 0) sb.writeln('Tip (${_tipPct.round()}%): ₹${_tip.toStringAsFixed(2)}');
    if (_includeTax) sb.writeln('Tax (${_taxPct.round()}%): ₹${_tax.toStringAsFixed(2)}');
    sb.writeln('Total: ₹${_grandTotal.toStringAsFixed(2)}');
    sb.writeln('━━━━━━━━━━━━━━━━━');
    sb.writeln('Split between ${_people.length} people:');
    for (final p in _people) sb.writeln('  • $p: ₹${_perPerson.toStringAsFixed(2)}');
    sb.writeln('\n— Sent from O2-WAIFU 🌸');
    SharePlus.instance.share(ShareParams(text: sb.toString()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A16),
      body: SafeArea(child: Column(children: [
        // Header
        Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 0), child: Row(children: [
          GestureDetector(onTap: () => Navigator.pop(context), child: Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white12)), child: const Icon(Icons.arrow_back_ios_new, color: Colors.white60, size: 16))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('BILL SPLITTER', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            Text('Split bills with friends', style: GoogleFonts.outfit(color: Colors.amberAccent, fontSize: 11)),
          ])),
          GestureDetector(onTap: _shareResult, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.amberAccent.withValues(alpha: 0.15), border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.4))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.share_rounded, color: Colors.amberAccent, size: 16), const SizedBox(width: 4), Text('Share', style: GoogleFonts.outfit(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.w700))]))),
        ])),
        const SizedBox(height: 16),
        Expanded(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), child: Column(children: [
          // Total input
          TextField(controller: _totalCtrl, keyboardType: TextInputType.number, onChanged: (_) => setState(() {}),
            style: GoogleFonts.outfit(color: Colors.amberAccent, fontSize: 28, fontWeight: FontWeight.w900), cursorColor: Colors.amberAccent, textAlign: TextAlign.center,
            decoration: InputDecoration(hintText: '₹ 0.00', hintStyle: GoogleFonts.outfit(color: Colors.white24, fontSize: 28, fontWeight: FontWeight.w900),
              filled: true, fillColor: Colors.amberAccent.withValues(alpha: 0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: Colors.amberAccent.withValues(alpha: 0.2))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: Colors.amberAccent.withValues(alpha: 0.5))),
              prefixText: '₹ ', prefixStyle: GoogleFonts.outfit(color: Colors.amberAccent.withValues(alpha: 0.5), fontSize: 28), contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18))),
          const SizedBox(height: 16),

          // Tip selector
          Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: Colors.white.withValues(alpha: 0.03), border: Border.all(color: Colors.white.withValues(alpha: 0.08))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('TIP', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
              const SizedBox(height: 8),
              Row(children: [0.0, 5.0, 10.0, 15.0, 20.0].map((t) => Expanded(child: GestureDetector(onTap: () => setState(() => _tipPct = t),
                child: AnimatedContainer(duration: const Duration(milliseconds: 150), margin: const EdgeInsets.symmetric(horizontal: 3), padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: _tipPct == t ? Colors.amberAccent.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.04), border: Border.all(color: _tipPct == t ? Colors.amberAccent : Colors.white12)),
                  child: Center(child: Text('${t.round()}%', style: GoogleFonts.outfit(color: _tipPct == t ? Colors.amberAccent : Colors.white38, fontSize: 12, fontWeight: FontWeight.w700))))))).toList()),
              const SizedBox(height: 10),
              // Tax toggle
              Row(children: [
                GestureDetector(onTap: () => setState(() => _includeTax = !_includeTax),
                  child: Row(children: [Icon(_includeTax ? Icons.check_box : Icons.check_box_outline_blank, color: _includeTax ? Colors.amberAccent : Colors.white24, size: 20), const SizedBox(width: 6), Text('Include Tax (${_taxPct.round()}%)', style: GoogleFonts.outfit(color: _includeTax ? Colors.amberAccent : Colors.white38, fontSize: 12))])),
              ]),
            ]),
          ),
          const SizedBox(height: 14),

          // People
          Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: Colors.white.withValues(alpha: 0.03), border: Border.all(color: Colors.white.withValues(alpha: 0.08))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('PEOPLE (${_people.length})', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextField(controller: _personCtrl, style: GoogleFonts.outfit(color: Colors.white, fontSize: 13), cursorColor: Colors.amberAccent, decoration: InputDecoration(hintText: 'Add person', hintStyle: GoogleFonts.outfit(color: Colors.white30, fontSize: 12), filled: true, fillColor: Colors.white.withValues(alpha: 0.04), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none), isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10)))),
                const SizedBox(width: 8),
                GestureDetector(onTap: _addPerson, child: Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.amberAccent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.4))), child: const Icon(Icons.person_add_rounded, color: Colors.amberAccent, size: 18))),
              ]),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6, children: _people.asMap().entries.map((e) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: Colors.amberAccent.withValues(alpha: 0.1), border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.3))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(e.value, style: GoogleFonts.outfit(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.w600)),
                  if (_people.length > 1) ...[const SizedBox(width: 4), GestureDetector(onTap: () => _removePerson(e.key), child: const Icon(Icons.close, color: Colors.amberAccent, size: 14))],
                ]),
              )).toList()),
            ]),
          ),
          const SizedBox(height: 16),

          // Summary
          if (_total > 0) Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(colors: [Colors.amberAccent.withValues(alpha: 0.1), Colors.orangeAccent.withValues(alpha: 0.06)]),
            border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.3))),
            child: Column(children: [
              _summaryRow('Subtotal', '₹${_total.toStringAsFixed(2)}', Colors.white54),
              if (_tipPct > 0) _summaryRow('Tip (${_tipPct.round()}%)', '₹${_tip.toStringAsFixed(2)}', Colors.white54),
              if (_includeTax) _summaryRow('Tax (${_taxPct.round()}%)', '₹${_tax.toStringAsFixed(2)}', Colors.white54),
              const Divider(color: Colors.white12, height: 16),
              _summaryRow('TOTAL', '₹${_grandTotal.toStringAsFixed(2)}', Colors.amberAccent),
              const SizedBox(height: 10),
              Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.amberAccent.withValues(alpha: 0.1)),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.people_rounded, color: Colors.amberAccent, size: 20), const SizedBox(width: 10),
                  Text('₹${_perPerson.toStringAsFixed(2)}', style: GoogleFonts.outfit(color: Colors.amberAccent, fontSize: 24, fontWeight: FontWeight.w900)),
                  Text(' / person', style: GoogleFonts.outfit(color: Colors.amberAccent.withValues(alpha: 0.6), fontSize: 13)),
                ]),
              ),
            ]),
          ),
        ]))),
      ])),
    );
  }

  Widget _summaryRow(String l, String v, Color c) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Text(l, style: GoogleFonts.outfit(color: c, fontSize: 13)), Text(v, style: GoogleFonts.outfit(color: c, fontSize: 13, fontWeight: FontWeight.w800)),
  ]));
}
