import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MedicationReminderPage extends StatefulWidget {
  const MedicationReminderPage({super.key});
  @override
  State<MedicationReminderPage> createState() => _MedicationReminderPageState();
}

class _MedicationReminderPageState extends State<MedicationReminderPage>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _meds = [];
  int _waterGlasses = 0;
  int _waterGoal = 8;
  int _streak = 0;
  String _lastDate = '';
  late AnimationController _ringCtrl;
  final _nameCtrl = TextEditingController();
  final _doseCtrl = TextEditingController();
  int _selectedTime = 0;
  static const _times = ['🌅 Morning', '☀️ Afternoon', '🌆 Evening', '🌙 Night'];

  @override
  void initState() {
    super.initState();
    _ringCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _load();
  }

  @override
  void dispose() { _ringCtrl.dispose(); _nameCtrl.dispose(); _doseCtrl.dispose(); super.dispose(); }

  String get _today => '${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}';

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    try { _meds = (jsonDecode(p.getString('medication_data') ?? '[]') as List).cast<Map<String, dynamic>>(); } catch (_) {}
    _waterGlasses = p.getInt('water_intake_$_today') ?? 0;
    _waterGoal = p.getInt('water_goal') ?? 8;
    _streak = p.getInt('health_streak') ?? 0;
    _lastDate = p.getString('health_last_date') ?? '';
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yStr = '${yesterday.year}-${yesterday.month}-${yesterday.day}';
    if (_lastDate != _today && _lastDate != yStr) _streak = 0;
    setState(() {});
    _ringCtrl.forward();
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('medication_data', jsonEncode(_meds));
    await p.setInt('water_intake_$_today', _waterGlasses);
    await p.setInt('health_streak', _streak);
    await p.setString('health_last_date', _today);
  }

  void _addMed() {
    if (_nameCtrl.text.trim().isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() => _meds.add({
      'name': _nameCtrl.text.trim(),
      'dose': _doseCtrl.text.trim().isEmpty ? '1 tablet' : _doseCtrl.text.trim(),
      'time': _times[_selectedTime], 'taken': <String>[],
    }));
    _nameCtrl.clear(); _doseCtrl.clear(); _save();
  }

  void _toggleTaken(int i) {
    HapticFeedback.lightImpact();
    final taken = List<String>.from(_meds[i]['taken'] ?? []);
    taken.contains(_today) ? taken.remove(_today) : taken.add(_today);
    setState(() => _meds[i]['taken'] = taken);
    _save();
  }

  bool _isTakenToday(int i) => List<String>.from(_meds[i]['taken'] ?? []).contains(_today);

  void _addWater() { if (_waterGlasses >= _waterGoal) return; HapticFeedback.lightImpact(); setState(() => _waterGlasses++); _ringCtrl.reset(); _ringCtrl.forward(); _save(); }
  void _removeWater() { if (_waterGlasses <= 0) return; setState(() => _waterGlasses--); _save(); }
  void _deleteMed(int i) { HapticFeedback.mediumImpact(); setState(() => _meds.removeAt(i)); _save(); }

  @override
  Widget build(BuildContext context) {
    final waterPct = _waterGoal > 0 ? (_waterGlasses / _waterGoal).clamp(0.0, 1.0) : 0.0;
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A16),
      body: SafeArea(child: Column(children: [
        _buildHeader(),
        const SizedBox(height: 14),
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(children: [
            _buildWaterCard(waterPct),
            const SizedBox(height: 16),
            _buildAddMedCard(),
            const SizedBox(height: 14),
            if (_meds.isEmpty) _emptyState()
            else ...List.generate(_meds.length, (i) => _buildMedTile(i)),
          ]),
        )),
      ])),
    );
  }

  Widget _buildHeader() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
    child: Row(children: [
      GestureDetector(onTap: () => Navigator.pop(context), child: Container(
        width: 36, height: 36, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white12)),
        child: const Icon(Icons.arrow_back_ios_new, color: Colors.white60, size: 16),
      )),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('HEALTH REMINDERS', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        Text('🔥 $_streak day streak', style: GoogleFonts.outfit(color: Colors.orangeAccent, fontSize: 11)),
      ])),
    ]),
  );

  Widget _buildWaterCard(double waterPct) => Container(
    width: double.infinity, padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(18),
      gradient: LinearGradient(colors: [Colors.cyanAccent.withValues(alpha: 0.08), Colors.blueAccent.withValues(alpha: 0.05)]),
      border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.25)),
    ),
    child: Column(children: [
      Row(children: [
        const Text('💧', style: TextStyle(fontSize: 24)), const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Water Intake', style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
          Text('$_waterGlasses / $_waterGoal glasses', style: GoogleFonts.outfit(color: Colors.cyanAccent, fontSize: 12)),
        ])),
        GestureDetector(onTap: _removeWater, child: Container(width: 36, height: 36, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.06), border: Border.all(color: Colors.white12)), child: const Icon(Icons.remove, color: Colors.white38, size: 18))),
        const SizedBox(width: 8),
        GestureDetector(onTap: _addWater, child: Container(width: 44, height: 44, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.cyanAccent.withValues(alpha: 0.2), border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.6))), child: const Icon(Icons.add, color: Colors.cyanAccent, size: 22))),
      ]),
      const SizedBox(height: 14),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(_waterGoal, (i) {
        final filled = i < _waterGlasses;
        return AnimatedContainer(duration: const Duration(milliseconds: 300), width: 28, height: 36, margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), color: filled ? Colors.cyanAccent.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.04), border: Border.all(color: filled ? Colors.cyanAccent : Colors.white.withValues(alpha: 0.1))),
          child: Icon(Icons.local_drink_rounded, color: filled ? Colors.cyanAccent : Colors.white12, size: 16),
        );
      })),
      const SizedBox(height: 10),
      ClipRRect(borderRadius: BorderRadius.circular(4), child: AnimatedBuilder(animation: _ringCtrl, builder: (_, __) => LinearProgressIndicator(value: waterPct * _ringCtrl.value, backgroundColor: Colors.white.withValues(alpha: 0.06), valueColor: AlwaysStoppedAnimation(_waterGlasses >= _waterGoal ? Colors.greenAccent : Colors.cyanAccent), minHeight: 6))),
      if (_waterGlasses >= _waterGoal) ...[const SizedBox(height: 8), Text('✅ Daily water goal reached!', style: GoogleFonts.outfit(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.w700))],
    ]),
  );

  Widget _buildAddMedCard() => Container(
    width: double.infinity, padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: Colors.white.withValues(alpha: 0.03), border: Border.all(color: Colors.white.withValues(alpha: 0.08))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('ADD MEDICATION', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: TextField(controller: _nameCtrl, style: GoogleFonts.outfit(color: Colors.white, fontSize: 13), cursorColor: Colors.pinkAccent, decoration: InputDecoration(hintText: 'Medicine name', hintStyle: GoogleFonts.outfit(color: Colors.white30, fontSize: 12), filled: true, fillColor: Colors.white.withValues(alpha: 0.04), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none), isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10)))),
        const SizedBox(width: 8),
        SizedBox(width: 100, child: TextField(controller: _doseCtrl, style: GoogleFonts.outfit(color: Colors.white, fontSize: 13), cursorColor: Colors.pinkAccent, decoration: InputDecoration(hintText: 'Dosage', hintStyle: GoogleFonts.outfit(color: Colors.white30, fontSize: 12), filled: true, fillColor: Colors.white.withValues(alpha: 0.04), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none), isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10)))),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: SizedBox(height: 32, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: _times.length, itemBuilder: (c, i) => GestureDetector(onTap: () => setState(() => _selectedTime = i), child: AnimatedContainer(duration: const Duration(milliseconds: 150), margin: const EdgeInsets.only(right: 6), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: _selectedTime == i ? Colors.pinkAccent.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.04), border: Border.all(color: _selectedTime == i ? Colors.pinkAccent : Colors.white12)), child: Text(_times[i], style: GoogleFonts.outfit(color: _selectedTime == i ? Colors.pinkAccent : Colors.white38, fontSize: 11))))))),
        const SizedBox(width: 8),
        GestureDetector(onTap: _addMed, child: Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.pinkAccent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.4))), child: const Icon(Icons.add_rounded, color: Colors.pinkAccent, size: 20))),
      ]),
    ]),
  );

  Widget _buildMedTile(int i) {
    final med = _meds[i]; final taken = _isTakenToday(i);
    return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: taken ? Colors.greenAccent.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.03), border: Border.all(color: taken ? Colors.greenAccent.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.07))),
      child: Row(children: [
        GestureDetector(onTap: () => _toggleTaken(i), child: AnimatedContainer(duration: const Duration(milliseconds: 200), width: 36, height: 36, decoration: BoxDecoration(shape: BoxShape.circle, color: taken ? Colors.greenAccent.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05), border: Border.all(color: taken ? Colors.greenAccent : Colors.white24)), child: Icon(taken ? Icons.check_rounded : Icons.circle_outlined, color: taken ? Colors.greenAccent : Colors.white24, size: 20))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(med['name']?.toString() ?? '', style: GoogleFonts.outfit(color: taken ? Colors.greenAccent : Colors.white, fontSize: 14, fontWeight: FontWeight.w700, decoration: taken ? TextDecoration.lineThrough : null)),
          Text('${med['dose']} • ${med['time']}', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11)),
        ])),
        GestureDetector(onTap: () => _deleteMed(i), child: const Icon(Icons.close_rounded, color: Colors.white24, size: 18)),
      ]),
    );
  }

  Widget _emptyState() => Padding(padding: const EdgeInsets.only(top: 30), child: Column(children: [
    const Text('💊', style: TextStyle(fontSize: 40)), const SizedBox(height: 8),
    Text('No medications added', style: GoogleFonts.outfit(color: Colors.white38)),
  ]));
}



