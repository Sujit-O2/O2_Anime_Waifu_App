import 'dart:async' show unawaited;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:anime_waifu/services/database_storage/app_db.dart';

class AutoWorkflowBuilderPage extends StatefulWidget {
  const AutoWorkflowBuilderPage({super.key});
  @override
  State<AutoWorkflowBuilderPage> createState() => _AutoWorkflowBuilderPageState();
}

class _AutoWorkflowBuilderPageState extends State<AutoWorkflowBuilderPage> {
  static const _accent = Color(0xFF00BCD4);
  static const _bg = Color(0xFF060C0D);

  final _nlCtrl = TextEditingController();
  List<Map<String, dynamic>> _workflows = [];
  Map<String, dynamic>? _preview;
  bool _building = false;

  static const _examples = [
    'Every morning send me news + tasks',
    'When I open YouTube, remind me to study',
    'Every Sunday summarize my week',
    'When battery < 20%, enable power saving',
    'Every night at 10pm, show mood check-in',
  ];

  static const _triggerIcons = {
    'Time': Icons.schedule,
    'App Open': Icons.apps,
    'Battery': Icons.battery_alert,
    'Location': Icons.location_on,
    'Manual': Icons.touch_app,
  };

  @override
  void initState() {
    super.initState();
    unawaited(AppDB.instance.recordUsage('auto_workflow'));
    _load();
  }

  @override
  void dispose() {
    _nlCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('workflows') ?? '[]';
    setState(() => _workflows = List<Map<String, dynamic>>.from(jsonDecode(raw)));
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('workflows', jsonEncode(_workflows));
  }

  Future<void> _buildWorkflow() async {
    final text = _nlCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() { _building = true; _preview = null; });
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    // Parse natural language into workflow structure
    final lower = text.toLowerCase();
    String trigger = 'Manual';
    String triggerDetail = 'On demand';
    List<String> actions = [];

    if (lower.contains('morning') || lower.contains('every day') || lower.contains('daily')) {
      trigger = 'Time'; triggerDetail = 'Every day at 8:00 AM';
    } else if (lower.contains('night') || lower.contains('pm')) {
      trigger = 'Time';
      final match = RegExp(r'(\d+)\s*pm').firstMatch(lower);
      triggerDetail = 'Every day at ${match?.group(1) ?? '10'}:00 PM';
    } else if (lower.contains('sunday') || lower.contains('weekly')) {
      trigger = 'Time'; triggerDetail = 'Every Sunday at 9:00 AM';
    } else if (lower.contains('open') || lower.contains('app')) {
      trigger = 'App Open'; triggerDetail = 'When target app opens';
    } else if (lower.contains('battery')) {
      trigger = 'Battery'; triggerDetail = 'When battery < 20%';
    }

    if (lower.contains('news')) actions.add('📰 Fetch top 5 news headlines');
    if (lower.contains('task') || lower.contains('todo')) actions.add('✅ Show today\'s task list');
    if (lower.contains('remind') || lower.contains('reminder')) actions.add('🔔 Send push notification');
    if (lower.contains('summar')) actions.add('📊 Generate weekly summary');
    if (lower.contains('mood')) actions.add('😊 Open mood check-in');
    if (lower.contains('power') || lower.contains('battery')) actions.add('🔋 Enable power saving mode');
    if (lower.contains('music')) actions.add('🎵 Play focus playlist');
    if (lower.contains('weather')) actions.add('🌤️ Fetch weather update');
    if (actions.isEmpty) actions.add('🤖 Execute AI-generated action');

    setState(() {
      _preview = {
        'name': text.length > 40 ? '${text.substring(0, 40)}...' : text,
        'trigger': trigger,
        'triggerDetail': triggerDetail,
        'actions': actions,
        'active': true,
        'runs': 0,
      };
      _building = false;
    });
  }

  void _saveWorkflow() {
    if (_preview == null) return;
    setState(() {
      _workflows.insert(0, Map<String, dynamic>.from(_preview!));
      _preview = null;
      _nlCtrl.clear();
    });
    _save();
  }

  void _toggleWorkflow(int i) {
    setState(() => _workflows[i]['active'] = !(_workflows[i]['active'] as bool));
    _save();
  }

  void _deleteWorkflow(int i) {
    setState(() => _workflows.removeAt(i));
    _save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        title: Text('🧩 Workflow Builder', style: GoogleFonts.orbitron(color: _accent, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: _accent),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _inputCard(),
          const SizedBox(height: 16),
          _examplesCard(),
          const SizedBox(height: 16),
          _buildButton(),
          if (_preview != null) ...[const SizedBox(height: 16), _previewCard()],
          if (_workflows.isNotEmpty) ...[const SizedBox(height: 16), _workflowList()],
        ]),
      ),
    );
  }

  Widget _inputCard() => _card(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label('DESCRIBE YOUR WORKFLOW'),
      const SizedBox(height: 10),
      TextField(
        controller: _nlCtrl,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        maxLines: 3,
        decoration: InputDecoration(
          hintText: 'e.g. "Every morning send me news + tasks"',
          hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
          filled: true, fillColor: Colors.white10,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.all(12),
        ),
      ),
    ]),
  );

  Widget _examplesCard() => _card(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label('QUICK EXAMPLES'),
      const SizedBox(height: 8),
      Wrap(
        spacing: 6, runSpacing: 6,
        children: _examples.map((e) => GestureDetector(
          onTap: () => setState(() => _nlCtrl.text = e),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white24)),
            child: Text(e, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ),
        )).toList(),
      ),
    ]),
  );

  Widget _buildButton() => SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: _building ? null : _buildWorkflow,
      icon: _building
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.auto_awesome),
      label: Text(_building ? 'Building...' : '🧩 Auto-Build Workflow', style: GoogleFonts.orbitron(fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: _accent, foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );

  Widget _previewCard() => _card(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        _label('WORKFLOW PREVIEW'),
        TextButton(onPressed: _saveWorkflow, child: const Text('SAVE', style: TextStyle(color: _accent, fontWeight: FontWeight.bold))),
      ]),
      const SizedBox(height: 10),
      _wfRow('Trigger', '${_preview!['trigger']} — ${_preview!['triggerDetail']}', _triggerIcons[_preview!['trigger']] ?? Icons.bolt),
      const Divider(color: Colors.white12, height: 16),
      _label('ACTIONS'),
      const SizedBox(height: 6),
      ...(_preview!['actions'] as List<String>).map((a) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(children: [
          const Icon(Icons.arrow_right, color: Colors.white38, size: 16),
          const SizedBox(width: 4),
          Text(a, style: const TextStyle(color: Colors.white, fontSize: 13)),
        ]),
      )),
    ]),
  );

  Widget _wfRow(String label, String value, IconData icon) => Row(children: [
    Icon(icon, color: _accent, size: 18),
    const SizedBox(width: 8),
    Text('$label: ', style: const TextStyle(color: Colors.white38, fontSize: 12)),
    Expanded(child: Text(value, style: const TextStyle(color: _accent, fontSize: 12, fontWeight: FontWeight.bold))),
  ]);

  Widget _workflowList() => _card(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label('MY WORKFLOWS (${_workflows.length})'),
      const SizedBox(height: 10),
      ...List.generate(_workflows.length, (i) {
        final w = _workflows[i];
        final active = w['active'] as bool;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: active ? _accent.withAlpha(15) : Colors.white10,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: active ? _accent.withAlpha(80) : Colors.white12),
            ),
            child: Row(children: [
              Icon(_triggerIcons[w['trigger']] ?? Icons.bolt, color: active ? _accent : Colors.white38, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(w['name'] as String, style: TextStyle(color: active ? Colors.white : Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
                Text(w['triggerDetail'] as String, style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ])),
              Switch(value: active, onChanged: (_) => _toggleWorkflow(i), activeColor: _accent),
              IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18), onPressed: () => _deleteWorkflow(i), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
            ]),
          ),
        );
      }),
    ]),
  );

  Widget _card({required Widget child}) => Container(
    width: double.infinity, padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF080E10), borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _accent.withAlpha(40)),
    ),
    child: child,
  );

  Widget _label(String t) => Text(t, style: GoogleFonts.orbitron(color: _accent, fontSize: 11, fontWeight: FontWeight.bold));
}
