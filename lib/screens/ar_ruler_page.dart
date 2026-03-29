import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class ArRulerPage extends StatefulWidget {
  const ArRulerPage({super.key});
  @override
  State<ArRulerPage> createState() => _ArRulerPageState();
}

class _ArRulerPageState extends State<ArRulerPage> {
  int _selectedCat = 0;
  final _inputCtrl = TextEditingController();
  String _result = '';
  int _selectedUnit = 0;

  static const _cats = ['📏 Length', '⚖️ Weight', '🌡️ Temperature', '🚗 Speed', '💧 Volume'];

  static const _units = <List<Map<String, dynamic>>>[
    // Length
    [{'name': 'cm', 'label': 'Centimeters', 'toCm': 1.0},
     {'name': 'in', 'label': 'Inches', 'toCm': 2.54},
     {'name': 'm', 'label': 'Meters', 'toCm': 100.0},
     {'name': 'ft', 'label': 'Feet', 'toCm': 30.48},
     {'name': 'km', 'label': 'Kilometers', 'toCm': 100000.0},
     {'name': 'mi', 'label': 'Miles', 'toCm': 160934.4}],
    // Weight
    [{'name': 'g', 'label': 'Grams', 'toG': 1.0},
     {'name': 'kg', 'label': 'Kilograms', 'toG': 1000.0},
     {'name': 'oz', 'label': 'Ounces', 'toG': 28.3495},
     {'name': 'lbs', 'label': 'Pounds', 'toG': 453.592}],
    // Temperature (special handling)
    [{'name': '°C', 'label': 'Celsius'}, {'name': '°F', 'label': 'Fahrenheit'}, {'name': 'K', 'label': 'Kelvin'}],
    // Speed
    [{'name': 'km/h', 'label': 'km/h', 'toKmh': 1.0},
     {'name': 'mph', 'label': 'mph', 'toKmh': 1.60934},
     {'name': 'm/s', 'label': 'm/s', 'toKmh': 3.6},
     {'name': 'knots', 'label': 'Knots', 'toKmh': 1.852}],
    // Volume
    [{'name': 'ml', 'label': 'Milliliters', 'toMl': 1.0},
     {'name': 'L', 'label': 'Liters', 'toMl': 1000.0},
     {'name': 'gal', 'label': 'Gallons (US)', 'toMl': 3785.41},
     {'name': 'oz', 'label': 'Fluid Oz', 'toMl': 29.5735},
     {'name': 'cup', 'label': 'Cups', 'toMl': 236.588}],
  ];

  @override
  void dispose() { _inputCtrl.dispose(); super.dispose(); }

  void _convert() {
    final val = double.tryParse(_inputCtrl.text);
    if (val == null) { setState(() => _result = ''); return; }
    final cat = _selectedCat;
    final unitList = _units[cat];
    final from = unitList[_selectedUnit];
    final sb = StringBuffer();

    if (cat == 2) {
      // Temperature
      for (int i = 0; i < unitList.length; i++) {
        if (i == _selectedUnit) continue;
        double converted;
        if (from['name'] == '°C') {
          converted = unitList[i]['name'] == '°F' ? val * 9 / 5 + 32 : val + 273.15;
        } else if (from['name'] == '°F') {
          final c = (val - 32) * 5 / 9;
          converted = unitList[i]['name'] == '°C' ? c : c + 273.15;
        } else {
          final c = val - 273.15;
          converted = unitList[i]['name'] == '°C' ? c : c * 9 / 5 + 32;
        }
        sb.writeln('${converted.toStringAsFixed(2)} ${unitList[i]['name']}');
      }
    } else {
      final baseKey = cat == 0 ? 'toCm' : cat == 1 ? 'toG' : cat == 3 ? 'toKmh' : 'toMl';
      final inBase = val * (from[baseKey] as num).toDouble();
      for (int i = 0; i < unitList.length; i++) {
        if (i == _selectedUnit) continue;
        final toFactor = (unitList[i][baseKey] as num).toDouble();
        final converted = inBase / toFactor;
        sb.writeln('${converted.toStringAsFixed(4)} ${unitList[i]['name']}');
      }
    }
    setState(() => _result = sb.toString().trim());
  }

  @override
  Widget build(BuildContext context) {
    final unitList = _units[_selectedCat];
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A16),
      body: SafeArea(child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 0), child: Row(children: [
          GestureDetector(onTap: () => Navigator.pop(context), child: Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white12)), child: const Icon(Icons.arrow_back_ios_new, color: Colors.white60, size: 16))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('RULER & CONVERTER', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            Text('Measure & convert units', style: GoogleFonts.outfit(color: Colors.orangeAccent, fontSize: 11)),
          ])),
        ])),
        const SizedBox(height: 14),
        // Category selector
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: SizedBox(height: 36, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: _cats.length, itemBuilder: (c, i) => GestureDetector(onTap: () { setState(() { _selectedCat = i; _selectedUnit = 0; _result = ''; }); _convert(); },
          child: AnimatedContainer(duration: const Duration(milliseconds: 150), margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: _selectedCat == i ? Colors.orangeAccent.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.04), border: Border.all(color: _selectedCat == i ? Colors.orangeAccent : Colors.white12)),
            child: Text(_cats[i], style: GoogleFonts.outfit(color: _selectedCat == i ? Colors.orangeAccent : Colors.white38, fontSize: 12, fontWeight: FontWeight.w600))))))),
        const SizedBox(height: 16),
        Expanded(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), child: Column(children: [
          // Input
          TextField(controller: _inputCtrl, keyboardType: TextInputType.number, onChanged: (_) => _convert(),
            style: GoogleFonts.outfit(color: Colors.orangeAccent, fontSize: 32, fontWeight: FontWeight.w900), cursorColor: Colors.orangeAccent, textAlign: TextAlign.center,
            decoration: InputDecoration(hintText: '0', hintStyle: GoogleFonts.outfit(color: Colors.white24, fontSize: 32, fontWeight: FontWeight.w900),
              filled: true, fillColor: Colors.orangeAccent.withValues(alpha: 0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: Colors.orangeAccent.withValues(alpha: 0.2))),
              contentPadding: const EdgeInsets.symmetric(vertical: 18))),
          const SizedBox(height: 12),
          // Unit selector
          Wrap(spacing: 6, runSpacing: 6, children: unitList.asMap().entries.map((e) => GestureDetector(onTap: () { setState(() => _selectedUnit = e.key); _convert(); },
            child: AnimatedContainer(duration: const Duration(milliseconds: 150), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: _selectedUnit == e.key ? Colors.orangeAccent.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.04), border: Border.all(color: _selectedUnit == e.key ? Colors.orangeAccent : Colors.white12)),
              child: Text(e.value['label'] as String, style: GoogleFonts.outfit(color: _selectedUnit == e.key ? Colors.orangeAccent : Colors.white54, fontSize: 12, fontWeight: FontWeight.w600))))).toList()),
          const SizedBox(height: 20),
          // Results
          if (_result.isNotEmpty) Container(width: double.infinity, padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: Colors.orangeAccent.withValues(alpha: 0.06), border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.2))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('CONVERSIONS', style: GoogleFonts.outfit(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
              const SizedBox(height: 10),
              ..._result.split('\n').map((line) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
                const Icon(Icons.arrow_forward_rounded, color: Colors.orangeAccent, size: 16), const SizedBox(width: 10),
                Expanded(child: Text(line, style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700))),
                GestureDetector(onTap: () { Clipboard.setData(ClipboardData(text: line)); HapticFeedback.lightImpact(); },
                  child: const Icon(Icons.copy_rounded, color: Colors.white24, size: 16)),
              ]))),
            ]),
          ),

          const SizedBox(height: 24),
          // Quick reference
          Container(width: double.infinity, padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: Colors.white.withValues(alpha: 0.03), border: Border.all(color: Colors.white.withValues(alpha: 0.08))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('📐 QUICK REFERENCE', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
              const SizedBox(height: 8),
              _refRow('1 inch', '2.54 cm'), _refRow('1 foot', '30.48 cm'), _refRow('1 mile', '1.609 km'),
              _refRow('1 kg', '2.205 lbs'), _refRow('1 gallon', '3.785 L'),
              _refRow('0°C', '32°F'), _refRow('100°C', '212°F'),
            ]),
          ),
        ]))),
      ])),
    );
  }

  Widget _refRow(String l, String r) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Text(l, style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11)),
    Text(r, style: GoogleFonts.outfit(color: Colors.orangeAccent, fontSize: 11, fontWeight: FontWeight.w700)),
  ]));
}
