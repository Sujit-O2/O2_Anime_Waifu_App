import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../widgets/waifu_background.dart';

class LanguageTranslatorPage extends StatefulWidget {
  const LanguageTranslatorPage({super.key});
  @override
  State<LanguageTranslatorPage> createState() => _LanguageTranslatorPageState();
}

class _LanguageTranslatorPageState extends State<LanguageTranslatorPage>
    with SingleTickerProviderStateMixin {
  final _textCtrl = TextEditingController();
  String _translated = '';
  String _fromLang = 'en';
  String _toLang = 'ja';
  bool _loading = false;
  String? _error;
  late AnimationController _fadeCtrl;

  static const _languages = {
    'en': '🇬🇧 English',
    'ja': '🇯🇵 Japanese',
    'ko': '🇰🇷 Korean',
    'zh': '🇨🇳 Chinese',
    'fr': '🇫🇷 French',
    'es': '🇪🇸 Spanish',
    'de': '🇩🇪 German',
    'it': '🇮🇹 Italian',
    'ru': '🇷🇺 Russian',
    'ar': '🇸🇦 Arabic',
    'hi': '🇮🇳 Hindi',
    'pt': '🇧🇷 Portuguese',
  };

  // Popular anime translations built-in (no network needed)
  static const _builtIn = {
    'darling': '「ダーリン」— Dārin (Zero Two\'s trademark~)',
    'i love you':
        '愛してる (Ai shiteru) — Japanese\n나는 당신을 사랑합니다 — Korean\n我爱你 — Chinese',
    'zero two': 'ゼロツー — Zerō Tsū (Japanese)',
    'strawberry': 'イチゴ — Ichigo (also Ichigo\'s name! 🍓)',
    'franxx': 'フランクス — Furankusu',
    'cherry blossom': '桜 — Sakura 🌸',
    'thank you': 'ありがとう — Arigatou (Japanese)\n감사합니다 — Gamsahamnida (Korean)',
  };

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _translate() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;

    // Check built-in first
    final lower = text.toLowerCase();
    if (_builtIn.containsKey(lower)) {
      _fadeCtrl.reset();
      setState(() {
        _translated = _builtIn[lower]!;
        _error = null;
      });
      _fadeCtrl.forward();
      return;
    }

    setState(() {
      _loading = true;
      _translated = '';
      _error = null;
    });
    try {
      // Try LibreTranslate (free, no key)
      final res = await http
          .post(
            Uri.parse('https://libretranslate.de/translate'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'q': text,
              'source': _fromLang,
              'target': _toLang,
              'format': 'text',
            }),
          )
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final result = data['translatedText'] as String? ?? '';
        _fadeCtrl.reset();
        setState(() {
          _translated = result;
        });
        _fadeCtrl.forward();
      } else {
        // Fallback: MyMemory API (free)
        final encoded = Uri.encodeComponent(text);
        final mmRes = await http
            .get(
              Uri.parse(
                  'https://api.mymemory.translated.net/get?q=$encoded&langpair=$_fromLang|$_toLang'),
            )
            .timeout(const Duration(seconds: 8));
        if (mmRes.statusCode == 200) {
          final data = jsonDecode(mmRes.body);
          final result =
              data['responseData']?['translatedText'] as String? ?? '';
          _fadeCtrl.reset();
          setState(() {
            _translated = result;
          });
          _fadeCtrl.forward();
        } else {
          setState(() => _error =
              'Translation service unavailable. Try a different language pair or check your internet connection.');
        }
      }
    } catch (e) {
      // Try MyMemory as absolute fallback
      try {
        final encoded = Uri.encodeComponent(text);
        final mmRes = await http
            .get(
              Uri.parse(
                  'https://api.mymemory.translated.net/get?q=$encoded&langpair=$_fromLang|$_toLang'),
            )
            .timeout(const Duration(seconds: 8));
        if (mmRes.statusCode == 200) {
          final data = jsonDecode(mmRes.body);
          final result =
              data['responseData']?['translatedText'] as String? ?? '';
          _fadeCtrl.reset();
          setState(() {
            _translated = result;
          });
          _fadeCtrl.forward();
        }
      } catch (_) {
        setState(() => _error = 'Network error. Please check your connection~');
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  void _swap() {
    setState(() {
      final tmp = _fromLang;
      _fromLang = _toLang;
      _toLang = tmp;
      _translated = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A16),
      resizeToAvoidBottomInset: true,
      body: WaifuBackground(
        opacity: 0.09,
        tint: const Color(0xFF080A14),
        child: SafeArea(
          child: Column(children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white60, size: 16),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TRANSLATOR',
                            style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5)),
                        Text('Free translation — no API key',
                            style: GoogleFonts.outfit(
                                color: Colors.blueAccent.withOpacity(0.6),
                                fontSize: 10)),
                      ]),
                ),
              ]),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Language selectors
                      Row(children: [
                        Expanded(
                            child: _langDropdown(
                                _fromLang,
                                (v) => setState(() {
                                      _fromLang = v!;
                                      _translated = '';
                                    }))),
                        GestureDetector(
                          onTap: _swap,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: Colors.blueAccent.withOpacity(0.3)),
                            ),
                            child: const Icon(Icons.swap_horiz_rounded,
                                color: Colors.blueAccent, size: 20),
                          ),
                        ),
                        Expanded(
                            child: _langDropdown(
                                _toLang,
                                (v) => setState(() {
                                      _toLang = v!;
                                      _translated = '';
                                    }))),
                      ]),
                      const SizedBox(height: 14),

                      // Input
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.white.withOpacity(0.04),
                          border: Border.all(
                              color: Colors.blueAccent.withOpacity(0.25)),
                        ),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              TextField(
                                controller: _textCtrl,
                                style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 15,
                                    height: 1.5),
                                cursorColor: Colors.blueAccent,
                                maxLines: 5,
                                minLines: 3,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Type something to translate…',
                                  hintStyle: GoogleFonts.outfit(
                                      color: Colors.white30, fontSize: 14),
                                  contentPadding: const EdgeInsets.all(14),
                                ),
                              ),
                              if (_textCtrl.text.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(
                                      right: 8, bottom: 8),
                                  child: GestureDetector(
                                    onTap: () {
                                      _textCtrl.clear();
                                      setState(() => _translated = '');
                                    },
                                    child: const Icon(Icons.close_rounded,
                                        color: Colors.white24, size: 16),
                                  ),
                                ),
                            ]),
                      ),
                      const SizedBox(height: 12),

                      // Translate button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _translate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                Colors.blueAccent.withOpacity(0.3),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : Text('Translate 🌐',
                                  style: GoogleFonts.outfit(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800)),
                        ),
                      ),

                      // Error
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.redAccent.withOpacity(0.08),
                            border: Border.all(
                                color: Colors.redAccent.withOpacity(0.2)),
                          ),
                          child: Text(_error!,
                              style: GoogleFonts.outfit(
                                  color: Colors.redAccent,
                                  fontSize: 12,
                                  height: 1.5)),
                        ),
                      ],

                      // Result
                      if (_translated.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        FadeTransition(
                          opacity: _fadeCtrl,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Colors.blueAccent.withOpacity(0.06),
                              border: Border.all(
                                  color: Colors.blueAccent.withOpacity(0.25)),
                            ),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Text(_languages[_toLang] ?? _toLang,
                                        style: GoogleFonts.outfit(
                                            color: Colors.blueAccent,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700)),
                                    const Spacer(),
                                    GestureDetector(
                                      onTap: () {
                                        Clipboard.setData(
                                            ClipboardData(text: _translated));
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                          content: Text('Copied!',
                                              style: GoogleFonts.outfit()),
                                          backgroundColor: Colors.blueAccent,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12)),
                                          duration: const Duration(seconds: 2),
                                        ));
                                      },
                                      child: const Icon(Icons.copy_outlined,
                                          color: Colors.blueAccent, size: 16),
                                    ),
                                  ]),
                                  const SizedBox(height: 10),
                                  Text(_translated,
                                      style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontSize: 18,
                                          height: 1.6)),
                                ]),
                          ),
                        ),
                      ],

                      // Quick phrases
                      const SizedBox(height: 20),
                      Text('Quick phrases 💬',
                          style: GoogleFonts.outfit(
                              color: Colors.white38,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: _builtIn.keys
                            .take(6)
                            .map((k) => GestureDetector(
                                  onTap: () {
                                    _textCtrl.text = k;
                                    _translate();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      color:
                                          Colors.blueAccent.withOpacity(0.08),
                                      border: Border.all(
                                          color: Colors.blueAccent
                                              .withOpacity(0.25)),
                                    ),
                                    child: Text(k,
                                        style: GoogleFonts.outfit(
                                            color: Colors.blueAccent,
                                            fontSize: 12)),
                                  ),
                                ))
                            .toList(),
                      ),
                    ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _langDropdown(String value, void Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.04),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.25)),
      ),
      child: DropdownButton<String>(
        value: value,
        dropdownColor: const Color(0xFF12121E),
        underline: const SizedBox.shrink(),
        isExpanded: true,
        style: GoogleFonts.outfit(color: Colors.white, fontSize: 12),
        onChanged: onChanged,
        items: _languages.entries
            .map((e) => DropdownMenuItem(
                  value: e.key,
                  child: Text(e.value, style: GoogleFonts.outfit(fontSize: 12)),
                ))
            .toList(),
      ),
    );
  }
}
