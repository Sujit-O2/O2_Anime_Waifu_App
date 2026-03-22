import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/ai_content_service.dart';
import '../services/affection_service.dart';
import '../widgets/waifu_background.dart';

class WorkoutPlannerPage extends StatefulWidget {
  const WorkoutPlannerPage({super.key});
  @override
  State<WorkoutPlannerPage> createState() => _WorkoutPlannerPageState();
}

class _WorkoutPlannerPageState extends State<WorkoutPlannerPage>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _exercises = [];
  bool _loading = true;
  final Set<int> _completed = {};
  late AnimationController _fadeCtrl;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _loadExercises();
  }

  @override
  void dispose() { _fadeCtrl.dispose(); super.dispose(); }

  Future<void> _loadExercises() async {
    setState(() { _loading = true; _exercises = []; _completed.clear(); });
    _fadeCtrl.reset();
    try {
      final ex = await AiContentService.getWorkouts();
      if (mounted) { setState(() { _exercises = ex; _loading = false; }); _fadeCtrl.forward(); }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toggleComplete(int idx) {
    HapticFeedback.mediumImpact();
    setState(() {
      if (_completed.contains(idx)) { _completed.remove(idx); }
      else {
        _completed.add(idx);
        if (_completed.length == _exercises.length) {
          AffectionService.instance.addPoints(5);
          _showCompletionSnack();
        }
      }
    });
  }

  void _showCompletionSnack() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Text('🎉', style: TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Expanded(child: Text('Workout complete! +5 XP, Darling~',
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600))),
      ]),
      backgroundColor: Colors.greenAccent.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final progress = _exercises.isEmpty ? 0.0 : _completed.length / _exercises.length;
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A16),
      body: WaifuBackground(
        opacity: 0.10, tint: const Color(0xFF070A0F),
        child: SafeArea(child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white12)),
                  child: const Icon(Icons.arrow_back_ios_new, color: Colors.white60, size: 16)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('WORKOUT PLANNER', style: GoogleFonts.outfit(
                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                Text(_loading ? 'AI generating your workout…' : 'Zero Two-approved training 💪',
                    style: GoogleFonts.outfit(color: Colors.redAccent.withOpacity(0.7), fontSize: 10)),
              ])),
              if (_exercises.isNotEmpty) Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.3))),
                child: Text('${_completed.length}/${_exercises.length}',
                    style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
          if (_exercises.isNotEmpty) Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Progress', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11)),
                Text('${(progress * 100).toInt()}%', style: GoogleFonts.outfit(
                    color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 6),
              ClipRRect(borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: progress,
                    backgroundColor: Colors.white.withOpacity(0.07),
                    valueColor: const AlwaysStoppedAnimation(Colors.redAccent), minHeight: 4)),
            ]),
          ),
          const SizedBox(height: 10),
          Expanded(child: _loading
              ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent),
                  SizedBox(height: 16),
                  Text('Generating exercises with AI…', style: TextStyle(color: Colors.white54)),
                ]))
              : _exercises.isEmpty
                  ? Center(child: Text('No exercises available.', style: GoogleFonts.outfit(color: Colors.white54)))
                  : FadeTransition(opacity: _fadeCtrl,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: _exercises.length,
                        itemBuilder: (ctx, i) => _buildExerciseCard(_exercises[i], i)))),
        ])),
      ),
    );
  }

  Widget _buildExerciseCard(Map<String, dynamic> ex, int idx) {
    final done = _completed.contains(idx);
    final name = ex['name']?.toString() ?? 'Exercise';
    final sets = ex['sets']?.toString() ?? '';
    final reps = ex['reps']?.toString() ?? '';
    final desc = ex['desc']?.toString() ?? '';
    final muscle = ex['muscle']?.toString() ?? '';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: done ? Colors.greenAccent.withOpacity(0.07) : Colors.white.withOpacity(0.04),
        border: Border.all(color: done ? Colors.greenAccent.withOpacity(0.3) : Colors.white.withOpacity(0.07))),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: GestureDetector(
          onTap: () => _toggleComplete(idx),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 40, height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? Colors.greenAccent.withOpacity(0.2) : Colors.redAccent.withOpacity(0.1),
              border: Border.all(color: done ? Colors.greenAccent : Colors.redAccent.withOpacity(0.4))),
            child: Icon(done ? Icons.check_rounded : Icons.fitness_center_outlined,
                color: done ? Colors.greenAccent : Colors.redAccent, size: 20)),
        ),
        title: Text(name, style: GoogleFonts.outfit(
            color: done ? Colors.greenAccent : Colors.white,
            fontSize: 14, fontWeight: FontWeight.w700,
            decoration: done ? TextDecoration.lineThrough : null)),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (sets.isNotEmpty || reps.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text('${sets.isNotEmpty ? "Sets: $sets" : ""}${reps.isNotEmpty ? " · Reps: $reps" : ""}',
                style: GoogleFonts.outfit(color: Colors.redAccent.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w600)),
          ],
          if (muscle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text('🎯 $muscle', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11)),
          ],
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text('💡 $desc', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11)),
          ],
        ]),
        trailing: Icon(done ? Icons.star_rounded : Icons.star_border_rounded,
            color: done ? Colors.amberAccent : Colors.white24, size: 20),
        onTap: () => _toggleComplete(idx),
      ),
    );
  }
}
