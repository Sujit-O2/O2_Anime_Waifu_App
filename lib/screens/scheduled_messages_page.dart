import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../api_call.dart';
import '../services/affection_service.dart';

class ScheduledMessagesPage extends StatefulWidget {
  const ScheduledMessagesPage({super.key});
  @override
  State<ScheduledMessagesPage> createState() => _ScheduledMessagesPageState();
}

class _ScheduledMsg {
  String id, prompt, message;
  TimeOfDay time;
  bool enabled;
  List<int> days; // 1-7 = Mon-Sun

  _ScheduledMsg({
    required this.id,
    required this.prompt,
    required this.message,
    required this.time,
    required this.enabled,
    required this.days,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'prompt': prompt,
        'message': message,
        'hour': time.hour,
        'minute': time.minute,
        'enabled': enabled,
        'days': days,
      };

  factory _ScheduledMsg.fromMap(Map<String, dynamic> m) => _ScheduledMsg(
        id: m['id'] as String,
        prompt: m['prompt'] as String? ?? '',
        message: m['message'] as String? ?? '',
        time: TimeOfDay(hour: m['hour'] as int, minute: m['minute'] as int),
        enabled: m['enabled'] as bool? ?? true,
        days: List<int>.from(m['days'] as List? ?? [1, 2, 3, 4, 5]),
      );
}

class _ScheduledMessagesPageState extends State<ScheduledMessagesPage> {
  List<_ScheduledMsg> _messages = [];
  bool _loading = true;
  static const _presets = [
    ('Good Morning 🌅', 'Good morning message from Zero Two'),
    ('Lunchtime 🍱', 'Sweet lunchtime check-in from Zero Two'),
    ('Good Night 🌙', 'Good night message from Zero Two'),
    ('Motivational 💪', 'Motivational boost from Zero Two'),
    ('I Miss You 💕', 'Zero Two says she misses you'),
  ];

  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final snap = await FirebaseFirestore.instance
          .collection('scheduled_messages')
          .doc(user.uid)
          .get();
      if (snap.exists) {
        final list = (snap.data()?['messages'] as List?) ?? [];
        setState(() => _messages = list
            .map((e) => _ScheduledMsg.fromMap(e as Map<String, dynamic>))
            .toList());
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection('scheduled_messages')
        .doc(user.uid)
        .set({
      'messages': _messages.map((m) => m.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _addPreset(String prompt, String label) async {
    if (_isCreating) return;
    
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Colors.pinkAccent,
            surface: Color(0xFF1A1A2E),
          ),
        ),
        child: child!,
      ),
    );
    if (time == null || !mounted) return;

    setState(() => _isCreating = true);

    // Generate message with AI
    try {
      final reply = await ApiService().sendConversation([
        {
          'role': 'user',
          'content':
              'You are Zero Two from DARLING in the FRANXX. Generate a sweet, short ($label) message for your Darling. Max 2 sentences. Be in character.',
        }
      ]);
      final msg = _ScheduledMsg(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        prompt: prompt,
        message: reply,
        time: time,
        enabled: true,
        days: [1, 2, 3, 4, 5, 6, 7],
      );
      setState(() {
        _messages.insert(0, msg);
        _isCreating = false;
      });
      AffectionService.instance.addPoints(2);
      await _save();
    } catch (_) {
      final msg = _ScheduledMsg(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        prompt: prompt,
        message: 'Good $label, Darling~ I\'m always thinking of you! 💕',
        time: time,
        enabled: true,
        days: [1, 2, 3, 4, 5, 6, 7],
      );
      setState(() {
        _messages.insert(0, msg);
        _isCreating = false;
      });
      await _save();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A16),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('SCHEDULED MESSAGES',
            style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 1)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.pinkAccent))
          : Column(children: [
              // Preset buttons
              Container(
                height: 100,
                padding: const EdgeInsets.fromLTRB(16, 12, 0, 8),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _presets.map((p) {
                    return GestureDetector(
                      onTap: () => _addPreset(p.$2, p.$1),
                      child: Container(
                        width: 90,
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: Colors.pinkAccent.withValues(alpha: 0.1),
                          border: Border.all(
                              color: Colors.pinkAccent.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(p.$1.split(' ').last,
                                style: const TextStyle(fontSize: 22)),
                            const SizedBox(height: 4),
                            Text(p.$1.split(' ').first,
                                style: GoogleFonts.outfit(
                                    color: Colors.white60, fontSize: 10),
                                textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const Divider(color: Colors.white12),
              Expanded(
                child: _messages.isEmpty
                    ? Center(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                            const Text('⏰', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 12),
                            Text('No scheduled messages yet',
                                style: GoogleFonts.outfit(
                                    color: Colors.white38, fontSize: 15)),
                            const SizedBox(height: 6),
                            Text('Tap a preset above to add one!',
                                style: GoogleFonts.outfit(
                                    color: Colors.white24, fontSize: 12)),
                          ]))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (ctx, index) {
                          final m = _messages[index];
                          return Dismissible(
                            key: Key(m.id),
                            direction: DismissDirection.endToStart,
                            onDismissed: (_) {
                              setState(() => _messages.removeAt(index));
                              _save();
                            },
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 16),
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: Colors.red.withValues(alpha: 0.2),
                              ),
                              child: const Icon(Icons.delete_outline,
                                  color: Colors.red),
                            ),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: Colors.white.withValues(alpha: 0.04),
                                border: Border.all(
                                    color: Colors.pinkAccent
                                        .withValues(alpha: 0.2)),
                              ),
                              child: Row(children: [
                                const Icon(Icons.schedule_outlined,
                                    color: Colors.pinkAccent, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(m.prompt,
                                            style: GoogleFonts.outfit(
                                                color: Colors.pinkAccent,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12)),
                                        Text(m.message,
                                            style: GoogleFonts.outfit(
                                                color: Colors.white70,
                                                fontSize: 12),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis),
                                      ]),
                                ),
                                Text(
                                  '${m.time.hour.toString().padLeft(2, '0')}:${m.time.minute.toString().padLeft(2, '0')}',
                                  style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                ),
                                const SizedBox(width: 8),
                                Switch(
                                  value: m.enabled,
                                  onChanged: (v) {
                                    setState(() => m.enabled = v);
                                    _save();
                                  },
                                  activeColor: Colors.pinkAccent,
                                  inactiveTrackColor: Colors.white12,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ]),
                            ),
                          );
                        },
                      ),
              ),
            ]),
    );
  }
}
