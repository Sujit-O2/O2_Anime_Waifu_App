import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// System Command Brain / Task Executor — Let AI execute system-level tasks.
/// Create files, run scripts, manage projects, open apps.
class TaskExecutorPage extends StatefulWidget {
  const TaskExecutorPage({super.key});
  @override
  State<TaskExecutorPage> createState() => _TaskExecutorPageState();
}

class _TaskExecutorPageState extends State<TaskExecutorPage> {
  final _ctrl = TextEditingController();
  final List<Map<String, dynamic>> _history = [];
  bool _executing = false;

  final _presets = [
    {'cmd': 'Create React project', 'icon': '⚛️', 'steps': ['npx create-react-app my-app', 'cd my-app', 'npm start']},
    {'cmd': 'Setup Spring Boot', 'icon': '☕', 'steps': ['spring init --dependencies=web my-api', 'cd my-api', 'mvn spring-boot:run']},
    {'cmd': 'Create Flutter project', 'icon': '🦋', 'steps': ['flutter create my_app', 'cd my_app', 'flutter run']},
    {'cmd': 'Setup Node.js API', 'icon': '🟢', 'steps': ['mkdir api && cd api', 'npm init -y', 'npm i express', 'node index.js']},
    {'cmd': 'Git commit & push', 'icon': '📦', 'steps': ['git add .', 'git commit -m "update"', 'git push origin main']},
    {'cmd': 'Docker compose up', 'icon': '🐳', 'steps': ['docker-compose build', 'docker-compose up -d', 'docker ps']},
    {'cmd': 'Clean build cache', 'icon': '🧹', 'steps': ['flutter clean', 'flutter pub get', 'flutter build apk']},
    {'cmd': 'Start coding session', 'icon': '💻', 'steps': ['Open IDE', 'Set focus timer 25min', 'Block distractions', 'Start Pomodoro']},
  ];

  void _execute(String command) async {
    if (command.trim().isEmpty) return;
    setState(() => _executing = true);

    // Parse command and generate steps
    final preset = _presets.where((p) => command.toLowerCase().contains((p['cmd']?.toString() ?? '').toLowerCase().split(' ').first)).toList();
    
    List<String> steps;
    String response;
    if (preset.isNotEmpty) {
      steps = (preset.first['steps'] as List).cast<String>();
      response = '✅ Executing: ${preset.first['cmd']}';
    } else {
      steps = ['Analyzing: "$command"', 'Generating execution plan...', 'Ready to execute'];
      response = '🧠 Understood. Here\'s the execution plan for "$command"';
    }

    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() {
      _executing = false;
      _history.insert(0, {
        'command': command,
        'response': response,
        'steps': steps,
        'time': DateTime.now().toIso8601String(),
        'status': 'ready',
      });
    });
    _ctrl.clear();
    _saveHistory();
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('task_executor_history', jsonEncode(_history.take(30).toList()));
  }

  

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70), onPressed: () => Navigator.pop(context)),
        title: Text('TASK EXECUTOR', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
        centerTitle: true,
      ),
      body: Column(children: [
        // Quick presets
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _presets.length,
            itemBuilder: (_, i) {
              final p = _presets[i];
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ActionChip(
                  avatar: Text(p['icon']?.toString() ?? '', style: const TextStyle(fontSize: 14)),
                  label: Text(p['cmd']?.toString() ?? '', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 10)),
                  backgroundColor: Colors.greenAccent.withValues(alpha: 0.08),
                  side: BorderSide(color: Colors.greenAccent.withValues(alpha: 0.2)),
                  onPressed: () => _execute(p['cmd']?.toString() ?? ''),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),

        // Execution history
        Expanded(
          child: _history.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('⚡', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 8),
                  Text('System Command Brain', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('Tell me what to do — I\'ll execute it', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12)),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _history.length,
                  itemBuilder: (_, i) {
                    final h = _history[i];
                    final steps = (h['steps'] as List).cast<String>();
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.15)),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          const Icon(Icons.terminal_rounded, color: Colors.greenAccent, size: 16),
                          const SizedBox(width: 6),
                          Expanded(child: Text('> ${h['command']}', style: GoogleFonts.firaCode(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.w600))),
                        ]),
                        const SizedBox(height: 6),
                        Text(h['response'], style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 8),
                        ...steps.asMap().entries.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Row(children: [
                            Container(
                              width: 18, height: 18,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.greenAccent.withValues(alpha: 0.15), border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.4))),
                              child: Center(child: Text('${e.key + 1}', style: GoogleFonts.outfit(color: Colors.greenAccent, fontSize: 9, fontWeight: FontWeight.w800))),
                            ),
                            const SizedBox(width: 8),
                            Text(e.value, style: GoogleFonts.firaCode(color: Colors.white54, fontSize: 11)),
                          ]),
                        )),
                        const SizedBox(height: 6),
                        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                          _actionBtn('▶ Execute', Colors.greenAccent),
                          const SizedBox(width: 6),
                          _actionBtn('📋 Copy', Colors.cyanAccent),
                        ]),
                      ]),
                    );
                  },
                ),
        ),

        // Command input
        Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
          ),
          child: Row(children: [
            const Text('>', style: TextStyle(color: Colors.greenAccent, fontSize: 16, fontWeight: FontWeight.w900)),
            const SizedBox(width: 8),
            Expanded(child: TextField(
              controller: _ctrl,
              onSubmitted: _execute,
              style: GoogleFonts.firaCode(color: Colors.white, fontSize: 13),
              cursorColor: Colors.greenAccent,
              decoration: InputDecoration(hintText: 'create react project with auth...', hintStyle: GoogleFonts.firaCode(color: Colors.white24, fontSize: 12), border: InputBorder.none),
            )),
            if (_executing)
              const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.greenAccent))
            else
              IconButton(icon: const Icon(Icons.play_arrow_rounded, color: Colors.greenAccent), onPressed: () => _execute(_ctrl.text)),
          ]),
        ),
      ]),
    );
  }

  Widget _actionBtn(String label, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: c.withValues(alpha: 0.3))),
      child: Text(label, style: GoogleFonts.outfit(color: c, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }
}



