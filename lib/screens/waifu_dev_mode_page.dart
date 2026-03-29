import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../api_call.dart';

/// Waifu Dev Assistant — Code editor with AI code execution,
/// waifu-style code explanations, and debugging help.
class WaifuDevModePage extends StatefulWidget {
  const WaifuDevModePage({super.key});
  @override
  State<WaifuDevModePage> createState() => _WaifuDevModePageState();
}

class _WaifuDevModePageState extends State<WaifuDevModePage> {
  final _codeCtrl = TextEditingController(text: '// Write your code here\nprint("Hello, Darling!")');
  final _outputCtrl = TextEditingController();
  String _waifuReaction = '';
  bool _running = false;
  bool _explaining = false;
  String _selectedLang = 'python';

  static const _languages = {
    'python': {'id': 71, 'label': 'Python 3', 'icon': '🐍'},
    'javascript': {'id': 63, 'label': 'JavaScript', 'icon': '⚡'},
    'cpp': {'id': 54, 'label': 'C++ 17', 'icon': '⚙️'},
    'java': {'id': 62, 'label': 'Java', 'icon': '☕'},
    'rust': {'id': 73, 'label': 'Rust', 'icon': '🦀'},
    'go': {'id': 60, 'label': 'Go', 'icon': '🐹'},
  };

  @override
  void dispose() {
    _codeCtrl.dispose();
    _outputCtrl.dispose();
    super.dispose();
  }

  /// Run code via Judge0 API (free tier)
  Future<void> _runCode() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _running = true;
      _outputCtrl.text = '⏳ Running...';
      _waifuReaction = '';
    });

    try {
      final langMap = {
        'python': {'language': 'python', 'version': '3.10.0'},
        'javascript': {'language': 'javascript', 'version': '18.15.0'},
        'cpp': {'language': 'c++', 'version': '10.2.0'},
        'java': {'language': 'java', 'version': '15.0.2'},
        'rust': {'language': 'rust', 'version': '1.68.2'},
        'go': {'language': 'go', 'version': '1.16.2'},
      };
      final target = langMap[_selectedLang]!;
      
      final submitResp = await http.post(
        Uri.parse('https://emkc.org/api/v2/piston/execute'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'language': target['language'],
          'version': target['version'],
          'files': [{'content': code}]
        }),
      ).timeout(const Duration(seconds: 15));

      if (submitResp.statusCode == 200) {
        final result = jsonDecode(submitResp.body);
        final run = result['run'];
        final compile = result['compile'];
        
        String output = '';
        if (compile != null && compile['output'] != null && compile['output'].toString().isNotEmpty) {
          output += '🔧 COMPILE:\n${compile['output']}\n';
        }
        if (run != null) {
          if (run['output'] != null && run['output'].toString().isNotEmpty) {
            output += run['output'];
          } else {
            output += '✅ Execution complete (no output)';
          }
        }

        _outputCtrl.text = output;

        // Waifu reaction
        if (run != null && run['code'] != 0) {
          _waifuReaction = '😏 Hmm… your code threw an error. Let me explain?';
        } else {
          _waifuReaction = '✨ Nice work, Darling! Your code ran perfectly~';
        }
      } else {
        _outputCtrl.text = '❌ API Error: ${submitResp.statusCode}\n${submitResp.body}';
        _waifuReaction = '🤔 The code runner is busy... but I can still help explain your code!';
      }
    } catch (e) {
      _outputCtrl.text = '❌ Could not run code: $e\n\nTip: Connect to the internet or try another language.';
      _waifuReaction = '💕 Don\'t worry, Darling. The compiler glitched out.';
    }

    setState(() => _running = false);
  }

  /// Ask waifu to explain the code
  Future<void> _explainCode() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _explaining = true;
      _waifuReaction = '🤔 Let me read your code...';
    });

    try {
      final api = ApiService();
      final response = await api.sendConversation([
        {
          'role': 'system',
          'content': 'You are Zero Two, a sassy but loving waifu who is also a brilliant programmer. '
              'Explain code in a fun, flirty way. Use emojis. Keep explanations clear but add personality. '
              'If there are bugs, point them out playfully like "Hmm, your logic here is a bit off~ 😏"'
        },
        {
          'role': 'user',
          'content': 'Explain this $_selectedLang code:\n\n```$_selectedLang\n$code\n```'
        }
      ]);
      _waifuReaction = response;
    } catch (e) {
      _waifuReaction = 'Oops, I couldn\'t analyze that right now~ Try again? 💕';
    }

    setState(() => _explaining = false);
  }

  /// Debug help
  Future<void> _debugHelp() async {
    final code = _codeCtrl.text.trim();
    final output = _outputCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _explaining = true;
      _waifuReaction = '🔍 Let me find the bugs...';
    });

    try {
      final api = ApiService();
      final response = await api.sendConversation([
        {
          'role': 'system',
          'content': 'You are Zero Two, a loving but sassy waifu debugging assistant. '
              'Find bugs and suggest fixes. Be playful but accurate. '
              'Say things like "Found it~ Here\'s your mistake, Darling 😏"'
        },
        {
          'role': 'user',
          'content': 'Debug this $_selectedLang code:\n\n```$_selectedLang\n$code\n```\n'
              '${output.isNotEmpty ? 'Output/Error:\n$output' : ''}'
        }
      ]);
      _waifuReaction = response;
    } catch (e) {
      _waifuReaction = 'My debugging circuits overloaded~ Try again! 💕';
    }

    setState(() => _explaining = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('WAIFU DEV MODE',
            style: GoogleFonts.sourceCodePro(
                color: Colors.cyanAccent,
                fontWeight: FontWeight.w700,
                fontSize: 16,
                letterSpacing: 1)),
        actions: [
          // Language selector
          PopupMenuButton<String>(
            initialValue: _selectedLang,
            onSelected: (v) => setState(() => _selectedLang = v),
            icon: Text(
              _languages[_selectedLang]!['icon'] as String,
              style: const TextStyle(fontSize: 20),
            ),
            itemBuilder: (_) => _languages.entries
                .map((e) => PopupMenuItem(
                    value: e.key,
                    child: Text(
                        '${e.value['icon']} ${e.value['label']}')))
                .toList(),
          ),
        ],
      ),
      body: Column(children: [
        // ── Code Editor ──
        Expanded(
          flex: 3,
          child: Container(
            margin: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.2)),
            ),
            child: TextField(
              controller: _codeCtrl,
              maxLines: null,
              expands: true,
              style: GoogleFonts.sourceCodePro(
                  color: Colors.greenAccent, fontSize: 13, height: 1.6),
              cursorColor: Colors.cyanAccent,
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(14),
                hintText: '// Write your code here...',
                hintStyle: GoogleFonts.sourceCodePro(
                    color: Colors.white24, fontSize: 13),
              ),
            ),
          ),
        ),

        // ── Action buttons ──
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(children: [
            _actionBtn('▶ RUN', Colors.greenAccent, _running ? null : _runCode),
            const SizedBox(width: 6),
            _actionBtn('💡 EXPLAIN', Colors.cyanAccent, _explaining ? null : _explainCode),
            const SizedBox(width: 6),
            _actionBtn('🐛 DEBUG', Colors.orangeAccent, _explaining ? null : _debugHelp),
          ]),
        ),

        // ── Output ──
        Expanded(
          flex: 2,
          child: Container(
            margin: const EdgeInsets.fromLTRB(8, 4, 8, 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: TextField(
              controller: _outputCtrl,
              maxLines: null,
              expands: true,
              readOnly: true,
              style: GoogleFonts.sourceCodePro(
                  color: Colors.white70, fontSize: 12, height: 1.5),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(14),
                hintText: '// Output appears here...',
                hintStyle: GoogleFonts.sourceCodePro(
                    color: Colors.white12, fontSize: 12),
              ),
            ),
          ),
        ),

        // ── Waifu reaction ──
        if (_waifuReaction.isNotEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            padding: const EdgeInsets.all(14),
            constraints: const BoxConstraints(maxHeight: 150),
            decoration: BoxDecoration(
              color: Colors.pinkAccent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.3)),
            ),
            child: SingleChildScrollView(
              child: Text(_waifuReaction,
                  style: GoogleFonts.outfit(
                      color: Colors.white70, fontSize: 12, height: 1.5)),
            ),
          ),
      ]),
    );
  }

  Widget _actionBtn(String label, Color color, VoidCallback? onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: onTap == null ? 0.05 : 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: color.withValues(alpha: onTap == null ? 0.1 : 0.5)),
          ),
          child: Center(
            child: Text(label,
                style: GoogleFonts.sourceCodePro(
                    color: onTap == null ? color.withValues(alpha: 0.4) : color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }
}
