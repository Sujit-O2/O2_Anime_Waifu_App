import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Goal Tracker — Set goals, track progress, get AI reminders.
class GoalTrackerPage extends StatefulWidget {
  const GoalTrackerPage({super.key});
  @override
  State<GoalTrackerPage> createState() => _GoalTrackerPageState();
}

class _GoalTrackerPageState extends State<GoalTrackerPage> {
  List<Map<String, dynamic>> _goals = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('goals_data');
    if (data != null) setState(() => _goals = (jsonDecode(data) as List).cast<Map<String, dynamic>>());
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('goals_data', jsonEncode(_goals));
  }

  void _addGoal() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('New Goal', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: titleCtrl, style: GoogleFonts.outfit(color: Colors.white), cursorColor: Colors.greenAccent, decoration: InputDecoration(hintText: 'Goal title', hintStyle: GoogleFonts.outfit(color: Colors.white24), filled: true, fillColor: Colors.white.withValues(alpha: 0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
        const SizedBox(height: 10),
        TextField(controller: descCtrl, maxLines: 3, style: GoogleFonts.outfit(color: Colors.white), cursorColor: Colors.greenAccent, decoration: InputDecoration(hintText: 'Steps...', hintStyle: GoogleFonts.outfit(color: Colors.white24), filled: true, fillColor: Colors.white.withValues(alpha: 0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.white54))),
        TextButton(onPressed: () {
          if (titleCtrl.text.isNotEmpty) { setState(() => _goals.add({'title': titleCtrl.text, 'desc': descCtrl.text, 'progress': 0.0, 'time': DateTime.now().toIso8601String()})); _save(); Navigator.pop(ctx); }
        }, child: Text('ADD', style: GoogleFonts.outfit(color: Colors.greenAccent, fontWeight: FontWeight.w700))),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70), onPressed: () => Navigator.pop(context)),
        title: Text('GOALS', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.5)), centerTitle: true),
      floatingActionButton: FloatingActionButton(onPressed: _addGoal, backgroundColor: Colors.greenAccent, child: const Icon(Icons.add, color: Colors.black)),
      body: _goals.isEmpty
        ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Text('🎯', style: TextStyle(fontSize: 48)), const SizedBox(height: 12), Text('No goals yet', style: GoogleFonts.outfit(color: Colors.white30, fontSize: 16))]))
        : ListView.builder(padding: const EdgeInsets.all(12), itemCount: _goals.length, itemBuilder: (_, i) {
            final g = _goals[i]; final prog = (g['progress'] as num).toDouble();
            return Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.greenAccent.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.2))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Expanded(child: Text(g['title'], style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700))), Text('${(prog * 100).toInt()}%', style: GoogleFonts.outfit(color: Colors.greenAccent, fontSize: 13, fontWeight: FontWeight.w800))]),
                const SizedBox(height: 10),
                ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: prog, minHeight: 8, backgroundColor: Colors.white.withValues(alpha: 0.06), valueColor: AlwaysStoppedAnimation(prog >= 1 ? Colors.amberAccent : Colors.greenAccent))),
                const SizedBox(height: 8),
                Row(children: [
                  _btn('-10%', () { setState(() => _goals[i]['progress'] = (prog - 0.1).clamp(0.0, 1.0)); _save(); }),
                  const SizedBox(width: 6),
                  _btn('+10%', () { setState(() => _goals[i]['progress'] = (prog + 0.1).clamp(0.0, 1.0)); _save(); }),
                  const Spacer(),
                  GestureDetector(onTap: () { setState(() => _goals.removeAt(i)); _save(); }, child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18)),
                ]),
              ]));
          }),
    );
  }

  Widget _btn(String l, VoidCallback t) => GestureDetector(onTap: t, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.greenAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Text(l, style: GoogleFonts.outfit(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.w700))));
}
