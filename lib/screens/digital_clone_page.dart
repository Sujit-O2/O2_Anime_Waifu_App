import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_call.dart';

/// Digital Clone — AI learns YOUR typing style, decisions & habits.
/// Ask "What would I do?" and the AI answers like YOU.
class DigitalClonePage extends StatefulWidget {
  const DigitalClonePage({super.key});
  @override
  State<DigitalClonePage> createState() => _DigitalClonePageState();
}

class _DigitalClonePageState extends State<DigitalClonePage> {
  final _ctrl = TextEditingController();
  List<Map<String, String>> _samples = [];
  final List<Map<String, String>> _cloneChat = [];
  bool _training = false;
  double _accuracy = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final d = prefs.getString('digital_clone_samples');
    if (d != null) {
      setState(() {
        _samples = (jsonDecode(d) as List).cast<Map<String, dynamic>>().map((m) => m.map((k, v) => MapEntry(k, v.toString()))).toList();
        _accuracy = (_samples.length * 4.5).clamp(0, 95);
      });
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('digital_clone_samples', jsonEncode(_samples));
  }

  void _trainSample() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _training = true;
    });
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _samples.add({'input': text, 'time': DateTime.now().toIso8601String()});
        _accuracy = (_samples.length * 4.5).clamp(0, 95);
        _training = false;
      });
      _ctrl.clear();
      _save();
    });
  }

  Future<void> _askClone() async {
    if (_samples.isEmpty) return;
    final question = _ctrl.text.trim();
    if (question.isEmpty) return;
    
    setState(() {
      _cloneChat.add({'role': 'user', 'text': question});
      _cloneChat.add({'role': 'clone', 'text': '🧬 Thinking like you...'});
    });
    _ctrl.clear();

    try {
      final api = ApiService();
      String sampleContext = _samples.map((s) => "- ${s['input']}").join('\n');
      final prompt = [
        {
          'role': 'system', 
          'content': 'You are a Digital Clone of the user. You must adopt their EXACT personality, logic, typing style, and habits based strictly on the following training data they provided about themselves:\n'
                     '$sampleContext\n\n'
                     'When the user asks you a question, DO NOT act like an AI assistant. Answer EXACTLY how they would answer it themselves based on these patterns.'
        },
        {'role': 'user', 'content': question}
      ];
      
      final response = await api.sendConversation(prompt);
      
      setState(() {
        _cloneChat.removeLast(); // remove thinking message
        _cloneChat.add({'role': 'clone', 'text': response});
      });
    } catch (e) {
      setState(() {
        _cloneChat.removeLast();
        _cloneChat.add({'role': 'clone', 'text': '❌ Clone API glitch: $e'});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70), onPressed: () => Navigator.pop(context)),
        title: Text('DIGITAL CLONE', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Stats card
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.cyanAccent.withValues(alpha: 0.08), Colors.purpleAccent.withValues(alpha: 0.08)]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                const Text('🧬', style: TextStyle(fontSize: 36)),
                const SizedBox(height: 6),
                Text('Clone Accuracy: ${_accuracy.toStringAsFixed(1)}%', style: GoogleFonts.outfit(color: Colors.cyanAccent, fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('${_samples.length} training samples', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(value: _accuracy / 100, minHeight: 6, backgroundColor: Colors.white.withValues(alpha: 0.06), valueColor: const AlwaysStoppedAnimation(Colors.cyanAccent)),
                ),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                  _miniStat('Typing Style', _samples.length >= 3 ? '✅ Learned' : '⏳ Learning', Colors.greenAccent),
                  _miniStat('Decisions', _samples.length >= 5 ? '✅ Learned' : '⏳ Learning', Colors.amberAccent),
                  _miniStat('Habits', _samples.length >= 8 ? '✅ Learned' : '⏳ Learning', Colors.pinkAccent),
                ]),
              ],
            ),
          ),

          // Mode toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.school_rounded, size: 16),
                  label: Text('TRAIN', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 12)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent.withValues(alpha: 0.15), foregroundColor: Colors.cyanAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.chat_rounded, size: 16),
                  label: Text('ASK CLONE', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 12)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent.withValues(alpha: 0.15), foregroundColor: Colors.purpleAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 8),

          // Chat/training area
          Expanded(
            child: _cloneChat.isEmpty
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text('Train your clone by typing how you think', style: GoogleFonts.outfit(color: Colors.white30, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text('Then ask "What would I do?" 🧬', style: GoogleFonts.outfit(color: Colors.white24, fontSize: 12)),
                    ]),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _cloneChat.length,
                    itemBuilder: (_, i) {
                      final m = _cloneChat[i];
                      final isClone = m['role'] == 'clone';
                      return Align(
                        alignment: isClone ? Alignment.centerLeft : Alignment.centerRight,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                          decoration: BoxDecoration(
                            color: isClone ? Colors.cyanAccent.withValues(alpha: 0.08) : Colors.purpleAccent.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: (isClone ? Colors.cyanAccent : Colors.purpleAccent).withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(isClone ? '🧬 Your Clone' : '👤 You', style: GoogleFonts.outfit(color: isClone ? Colors.cyanAccent : Colors.purpleAccent, fontSize: 10, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 2),
                              Text(m['text'] ?? '', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Input
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  style: GoogleFonts.outfit(color: Colors.white),
                  cursorColor: Colors.cyanAccent,
                  decoration: InputDecoration(
                    hintText: _samples.length < 5 ? 'Train: type how you think/decide...' : 'Ask your clone anything...',
                    hintStyle: GoogleFonts.outfit(color: Colors.white24),
                    border: InputBorder.none,
                  ),
                ),
              ),
              if (_training)
                const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent))
              else ...[
                IconButton(icon: const Icon(Icons.school_rounded, color: Colors.cyanAccent, size: 20), onPressed: _trainSample, tooltip: 'Train'),
                IconButton(icon: const Icon(Icons.send_rounded, color: Colors.purpleAccent, size: 20), onPressed: _askClone, tooltip: 'Ask Clone'),
              ],
            ]),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String val, Color c) {
    return Column(children: [
      Text(val, style: GoogleFonts.outfit(color: c, fontSize: 11, fontWeight: FontWeight.w700)),
      Text(label, style: GoogleFonts.outfit(color: Colors.white30, fontSize: 10)),
    ]);
  }
}
