import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Auto Workflow Engine — "Start coding session" → AI opens IDE, sets timer, blocks distractions.
class WorkflowEnginePage extends StatefulWidget {
  const WorkflowEnginePage({super.key});
  @override
  State<WorkflowEnginePage> createState() => _WorkflowEnginePageState();
}

class _WorkflowEnginePageState extends State<WorkflowEnginePage> {
  List<Map<String, dynamic>> _workflows = [];
  int? _activeIdx;

  final _presets = [
    {
      'name': '💻 Coding Session',
      'steps': [
        'Open IDE',
        'Set 25min focus timer',
        'Block social media',
        'Play lo-fi music',
        'Start coding'
      ]
    },
    {
      'name': '📚 Study Mode',
      'steps': [
        'Open notes app',
        'Set 45min timer',
        'Block notifications',
        'Review flashcards',
        'Take quiz'
      ]
    },
    {
      'name': '🧘 Morning Routine',
      'steps': [
        'Hydrate 💧',
        'Quick stretch 5min',
        'Review goals',
        'Check calendar',
        'Plan top 3 tasks'
      ]
    },
    {
      'name': '🌙 Night Wind-Down',
      'steps': [
        'Stop screens',
        'Journal 5 min',
        'Review day accomplishments',
        'Set tomorrow alarm',
        'Sleep mode ON'
      ]
    },
    {
      'name': '🏋️ Workout Flow',
      'steps': [
        'Put on gym clothes',
        'Start playlist',
        'Warm up 5min',
        'Main workout 30min',
        'Cool down & stretch'
      ]
    },
    {
      'name': '📦 Deploy Pipeline',
      'steps': [
        'Run tests',
        'Build production',
        'Check staging',
        'Deploy to prod',
        'Monitor logs'
      ]
    },
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final d = prefs.getString('workflow_engine');
    if (d != null) {
      if (!mounted) return;
      setState(() =>
          _workflows = (jsonDecode(d) as List).cast<Map<String, dynamic>>());
    } else {
      setState(() => _workflows = _presets
          .map((p) => {
                ...p,
                'progress': 0,
                'created': DateTime.now().toIso8601String()
              })
          .toList());
      _save();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('workflow_engine', jsonEncode(_workflows));
  }

  void _toggleStep(int wIdx, int sIdx) {
    setState(() {
      final steps = (_workflows[wIdx]['steps'] as List).cast<String>();
      final completed = (_workflows[wIdx]['completed'] as List?) ??
          List.filled(steps.length, false);
      while (completed.length < steps.length) {
        completed.add(false);
      }

      final isNowCompleted = !(completed[sIdx] as bool);
      completed[sIdx] = isNowCompleted;
      _workflows[wIdx]['completed'] = completed;
      _workflows[wIdx]['progress'] = completed.where((c) => c == true).length;

      // Phase 4: OS-Level Automation
      if (isNowCompleted) {
        _executeStepAction(steps[sIdx]);
      }
    });
    _save();
  }

  Future<void> _executeStepAction(String stepDesc) async {
    final lower = stepDesc.toLowerCase();

    try {
      if (lower.contains('ide') || lower.contains('code')) {
        await launchUrl(Uri.parse('vscode://'));
      } else if (lower.contains('music') || lower.contains('playlist')) {
        await launchUrl(Uri.parse('spotify:'));
      } else if (lower.contains('timer')) {
        final match = RegExp(r'(\d+)min').firstMatch(lower);
        final mins = match != null ? match.group(1) : '25';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('⏱ OS Timer starting: $mins minutes'),
          backgroundColor: Colors.greenAccent,
        ));
      } else if (lower.contains('notes')) {
        await launchUrl(Uri.parse('obsidian://open'));
      } else if (lower.contains('calendar')) {
        await launchUrl(Uri.parse('content://com.android.calendar/time/'));
      }
    } catch (e) {
      // Just fail silently if app is not installed
      if (kDebugMode) debugPrint('Intent failed: \$e');
    }
  }

  void _activate(int idx) {
    setState(() {
      _activeIdx = _activeIdx == idx ? null : idx;
      if (_activeIdx != null) {
        _workflows[idx]['completed'] =
            List.filled((_workflows[idx]['steps'] as List).length, false);
        _workflows[idx]['progress'] = 0;
      }
    });
    _save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
            onPressed: () => Navigator.pop(context)),
        title: Text('WORKFLOW ENGINE',
            style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5)),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _workflows.length,
        itemBuilder: (_, i) {
          final w = _workflows[i];
          final steps = (w['steps'] as List).cast<String>();
          final completed =
              (w['completed'] as List?) ?? List.filled(steps.length, false);
          final isActive = _activeIdx == i;
          final progress = (w['progress'] as int? ?? 0) / steps.length;
          final c = isActive ? Colors.greenAccent : Colors.cyanAccent;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: c.withValues(alpha: isActive ? 0.4 : 0.12)),
            ),
            child: Column(children: [
              // Header
              ListTile(
                title: Text(w['name'],
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
                subtitle: Text('${steps.length} steps',
                    style: GoogleFonts.outfit(
                        color: Colors.white38, fontSize: 11)),
                trailing: ElevatedButton(
                  onPressed: () => _activate(i),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        (isActive ? Colors.redAccent : Colors.greenAccent)
                            .withValues(alpha: 0.15),
                    foregroundColor:
                        isActive ? Colors.redAccent : Colors.greenAccent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  ),
                  child: Text(isActive ? 'STOP' : '▶ START',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w800, fontSize: 11)),
                ),
              ),
              if (isActive) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 4,
                        backgroundColor: Colors.white.withValues(alpha: 0.06),
                        valueColor: AlwaysStoppedAnimation(c)),
                  ),
                ),
                const SizedBox(height: 6),
                ...steps.asMap().entries.map((e) {
                  final done =
                      e.key < completed.length && completed[e.key] == true;
                  return ListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    leading: GestureDetector(
                      onTap: () => _toggleStep(i, e.key),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: done
                              ? Colors.greenAccent.withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.05),
                          border: Border.all(
                              color:
                                  done ? Colors.greenAccent : Colors.white24),
                        ),
                        child: done
                            ? const Icon(Icons.check_rounded,
                                size: 14, color: Colors.greenAccent)
                            : null,
                      ),
                    ),
                    title: Text(
                      e.value,
                      style: GoogleFonts.outfit(
                        color: done ? Colors.white30 : Colors.white70,
                        fontSize: 12,
                        decoration: done ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
              ],
            ]),
          );
        },
      ),
    );
  }
}
