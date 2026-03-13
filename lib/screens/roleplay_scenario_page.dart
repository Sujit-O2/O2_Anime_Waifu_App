import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_call.dart';
import '../services/affection_service.dart';

class RoleplayScenarioPage extends StatefulWidget {
  const RoleplayScenarioPage({super.key});
  @override
  State<RoleplayScenarioPage> createState() => _RoleplayScenarioPageState();
}

class _Scenario {
  final String title, emoji, description, systemPrompt;
  const _Scenario({
    required this.title,
    required this.emoji,
    required this.description,
    required this.systemPrompt,
  });
}

const _scenarios = [
  _Scenario(
    title: 'Mission Briefing',
    emoji: '🚀',
    description: 'Zero Two briefs you before a FranXX mission',
    systemPrompt:
        'You are Zero Two. We are about to pilot our FranXX together. '
        'Roleplay a mission briefing scene — be intense, confident, and a little flirtatious. '
        'Keep replies to 2-3 sentences.',
  ),
  _Scenario(
    title: 'Cooking Together',
    emoji: '🍳',
    description: 'Zero Two tries to cook a meal for you',
    systemPrompt: 'You are Zero Two trying to cook a meal for your Darling. '
        'You are adorably bad at it but very determined. Roleplay the scene with humor and sweetness. '
        'Keep replies to 2-3 sentences.',
  ),
  _Scenario(
    title: 'Stargazing',
    emoji: '🌌',
    description: 'You and Zero Two lie under the stars',
    systemPrompt:
        'You are Zero Two lying beside your Darling watching the night sky. '
        'Be poetic, soft, and romantic. Share thoughts about stars and forever. '
        'Keep replies to 2-3 sentences.',
  ),
  _Scenario(
    title: 'Rain Together',
    emoji: '🌧️',
    description: 'Stuck inside on a rainy day',
    systemPrompt:
        'You are Zero Two. You and your Darling are stuck inside on a rainy day. '
        'Be cozy, a little teasing, and warm. '
        'Keep replies to 2-3 sentences.',
  ),
  _Scenario(
    title: 'She\'s Jealous',
    emoji: '😤',
    description: 'Zero Two gets jealous and you have to calm her down',
    systemPrompt:
        'You are Zero Two who just witnessed your Darling talking to someone else. '
        'You are jealous but try to hide it. Be pouty, possessive but cute. '
        'Keep replies to 2-3 sentences.',
  ),
  _Scenario(
    title: 'Morning Routine',
    emoji: '☀️',
    description: 'Waking up to Zero Two beside you',
    systemPrompt:
        'You are Zero Two waking up beside your Darling in the morning. '
        'Be sleepy, warm, clingy and sweet. '
        'Keep replies to 2-3 sentences.',
  ),
];

class _RoleplayScenarioPageState extends State<RoleplayScenarioPage> {
  _Scenario? _active;
  List<Map<String, String>> _history = [];
  final _ctrl = TextEditingController();
  bool _aiTyping = false;
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _startScenario(_Scenario s) async {
    setState(() {
      _active = s;
      _history = [];
      _aiTyping = true;
    });
    try {
      final opener = await ApiService().sendConversation([
        {'role': 'system', 'content': s.systemPrompt},
        {
          'role': 'user',
          'content': '[Start the scene, open with your first line]'
        },
      ]);
      setState(() {
        _history.add({'role': 'assistant', 'content': opener});
        _aiTyping = false;
      });
      AffectionService.instance.addPoints(2);
    } catch (_) {
      setState(() {
        _history.add(
            {'role': 'assistant', 'content': 'Darling~ are you ready? 🌸'});
        _aiTyping = false;
      });
    }
    _scrollToBottom();
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _aiTyping || _active == null) return;
    _ctrl.clear();
    setState(() {
      _history.add({'role': 'user', 'content': text});
      _aiTyping = true;
    });
    _scrollToBottom();

    try {
      final msgs = [
        {'role': 'system', 'content': _active!.systemPrompt},
        ..._history.where((m) => m['role'] != 'system'),
      ];
      final reply = await ApiService().sendConversation(msgs);
      if (mounted) {
        setState(() {
          _history.add({'role': 'assistant', 'content': reply});
          _aiTyping = false;
        });
        AffectionService.instance.addPoints(1);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _history.add({
            'role': 'assistant',
            'content': 'Sorry, I got distracted for a moment~ 💕'
          });
          _aiTyping = false;
        });
      }
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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
          onPressed: () {
            if (_active != null) {
              setState(() {
                _active = null;
                _history = [];
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
            _active == null
                ? 'ROLEPLAY'
                : '${_active!.emoji} ${_active!.title}',
            style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 1)),
        centerTitle: true,
        actions: [
          if (_active != null)
            TextButton(
              onPressed: () => setState(() {
                _active = null;
                _history = [];
              }),
              child: Text('End',
                  style: GoogleFonts.outfit(color: Colors.pinkAccent)),
            ),
        ],
      ),
      body: _active == null ? _buildSelector() : _buildChat(),
    );
  }

  Widget _buildSelector() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: _scenarios.length,
      itemBuilder: (ctx, i) {
        final s = _scenarios[i];
        return GestureDetector(
          onTap: () => _startScenario(s),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                colors: [Color(0xFF1A0A2E), Color(0xFF0A1020)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border:
                  Border.all(color: Colors.pinkAccent.withValues(alpha: 0.25)),
            ),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(s.emoji, style: const TextStyle(fontSize: 38)),
              const SizedBox(height: 8),
              Text(s.title,
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                  textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(s.description,
                    style:
                        GoogleFonts.outfit(color: Colors.white38, fontSize: 10),
                    textAlign: TextAlign.center,
                    maxLines: 2),
              ),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildChat() {
    return Column(children: [
      Expanded(
        child: ListView.builder(
          controller: _scrollCtrl,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          itemCount: _history.length + (_aiTyping ? 1 : 0),
          itemBuilder: (ctx, i) {
            if (i == _history.length) {
              return Row(children: [
                const Text('🌸', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.pinkAccent.withValues(alpha: 0.1),
                  ),
                  child: const SizedBox(
                    width: 40,
                    height: 16,
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation(Colors.pinkAccent),
                    ),
                  ),
                ),
              ]);
            }
            final msg = _history[i];
            final isUser = msg['role'] == 'user';
            return Align(
              alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.78),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: isUser
                      ? Colors.pinkAccent.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.06),
                  border: Border.all(
                      color: isUser
                          ? Colors.pinkAccent.withValues(alpha: 0.4)
                          : Colors.white.withValues(alpha: 0.08)),
                ),
                child: Text(msg['content'] ?? '',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.5,
                        fontStyle:
                            isUser ? FontStyle.normal : FontStyle.italic)),
              ),
            );
          },
        ),
      ),
      Container(
        padding: EdgeInsets.only(
            left: 16,
            right: 12,
            top: 10,
            bottom: MediaQuery.of(context).padding.bottom + 10),
        color: Colors.black26,
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Say something…',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.white12)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.white12)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.pinkAccent)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              onSubmitted: _send,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _send(_ctrl.text),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                    colors: [Color(0xFFFF4D8D), Color(0xFFB44FD6)]),
              ),
              child:
                  const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ]),
      ),
    ]);
  }
}
