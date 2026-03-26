import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// AI Manga Translator — Pick or capture manga panels, OCR + GPT translates.
class MangaTranslatorPage extends StatefulWidget {
  const MangaTranslatorPage({super.key});
  @override
  State<MangaTranslatorPage> createState() => _MangaTranslatorPageState();
}

class _MangaTranslatorPageState extends State<MangaTranslatorPage> {
  File? _image;
  bool _translating = false;
  String? _translation;
  String? _error;
  String _targetLang = 'English';

  static const _languages = ['English', 'Hindi', 'Spanish', 'French', 'German',
    'Portuguese', 'Korean', 'Chinese', 'Arabic', 'Russian'];

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(source: source, maxWidth: 1200);
      if (picked != null) {
        setState(() { _image = File(picked.path); _translation = null; _error = null; });
      }
    } catch (e) {
      setState(() => _error = 'Failed to pick image: $e');
    }
  }

  Future<void> _translate() async {
    if (_image == null) return;
    setState(() { _translating = true; _error = null; _translation = null; });
    HapticFeedback.mediumImpact();

    try {
      final prefs = await SharedPreferences.getInstance();
      // First check dev override, then fall back to dotenv
      String apiKey = prefs.getString('dev_api_key_override') ?? '';
      if (apiKey.isEmpty) {
        apiKey = dotenv.env['API_KEY'] ?? '';
      }
      if (apiKey.isEmpty) {
        setState(() { _error = 'No API key configured. Go to Dev Config in Settings.'; _translating = false; });
        return;
      }

      // Convert image to base64
      final bytes = await _image!.readAsBytes();
      final base64Img = base64Encode(bytes);

      // Use Groq API with vision-capable model
      final apiUrl = prefs.getString('dev_api_url_override')?.trim() ?? '';
      final endpoint = apiUrl.isNotEmpty
          ? apiUrl
          : 'https://api.groq.com/openai/v1/chat/completions';

      final resp = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama-3.2-90b-vision-preview',
          'messages': [{
            'role': 'user',
            'content': [
              {'type': 'text', 'text': 'This is a manga/anime panel. Please:\n'
                '1. Read ALL text in the image (Japanese, Korean, Chinese, or any language)\n'
                '2. Translate everything to $_targetLang\n'
                '3. Format as:\n'
                '   ORIGINAL: [original text]\n'
                '   TRANSLATION: [translated text]\n'
                '4. If there are speech bubbles, number them in reading order\n'
                '5. Include any sound effects (onomatopoeia) translations'},
              {'type': 'image_url',
                'image_url': {'url': 'data:image/jpeg;base64,$base64Img'}},
            ],
          }],
          'max_tokens': 1000,
        }),
      ).timeout(const Duration(seconds: 30));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final content = data['choices']?[0]?['message']?['content'] ?? '';
        setState(() => _translation = content);
        HapticFeedback.heavyImpact();
      } else {
        final body = jsonDecode(resp.body);
        setState(() => _error = body['error']?['message'] ?? 'Error ${resp.statusCode}');
      }
    } catch (e) {
      setState(() => _error = 'Translation failed: $e');
    }

    setState(() => _translating = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        title: const Text('📖 Manga Translator', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
        flexibleSpace: Container(decoration: BoxDecoration(gradient: LinearGradient(
          colors: [Colors.teal.withValues(alpha: 0.4), Colors.black.withValues(alpha: 0.95)]))),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Language selector
          Row(children: [
            Text('Translate to: ', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
            const SizedBox(width: 8),
            Expanded(child: SizedBox(height: 32,
              child: ListView.builder(
                scrollDirection: Axis.horizontal, itemCount: _languages.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => setState(() => _targetLang = _languages[i]),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: _targetLang == _languages[i]
                          ? Colors.teal.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05),
                        border: Border.all(color: _targetLang == _languages[i]
                          ? Colors.teal : Colors.transparent)),
                      child: Center(child: Text(_languages[i], style: TextStyle(
                        color: _targetLang == _languages[i] ? Colors.white : Colors.grey.shade500,
                        fontSize: 11, fontWeight: FontWeight.w600))),
                    ),
                  )),
              ),
            )),
          ]),
          const SizedBox(height: 16),

          // Image area
          if (_image != null)
            ClipRRect(borderRadius: BorderRadius.circular(16),
              child: Image.file(_image!, fit: BoxFit.contain, height: 300))
          else
            Container(height: 200, decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white.withValues(alpha: 0.04),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('📖', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 8),
                Text('Pick a manga panel to translate',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
              ])),
          const SizedBox(height: 12),

          // Action buttons
          Row(children: [
            Expanded(child: _actionBtn('📷 Camera', Colors.teal, () => _pickImage(ImageSource.camera))),
            const SizedBox(width: 8),
            Expanded(child: _actionBtn('🖼️ Gallery', Colors.indigo, () => _pickImage(ImageSource.gallery))),
            const SizedBox(width: 8),
            Expanded(child: _actionBtn(
              _translating ? '⏳...' : '🔤 Translate',
              Colors.deepPurple,
              _image != null && !_translating ? _translate : null)),
          ]),

          if (_error != null)
            Padding(padding: const EdgeInsets.only(top: 12),
              child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12))),

          if (_translating)
            const Padding(padding: EdgeInsets.only(top: 20),
              child: Center(child: CircularProgressIndicator(color: Colors.teal))),

          // Translation result
          if (_translation != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.teal.withValues(alpha: 0.08),
                border: Border.all(color: Colors.teal.withValues(alpha: 0.3))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.translate, color: Colors.teal, size: 16),
                  const SizedBox(width: 6),
                  Text('Translation', style: TextStyle(color: Colors.teal.shade300,
                    fontWeight: FontWeight.bold, fontSize: 13)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () { Clipboard.setData(ClipboardData(text: _translation!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied!'))); },
                    child: const Icon(Icons.copy, color: Colors.teal, size: 16)),
                ]),
                const SizedBox(height: 8),
                SelectableText(_translation!,
                  style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5)),
              ]),
            ),
          ],

          // Info
          Padding(padding: const EdgeInsets.only(top: 16),
            child: Text('Powered by GPT-4o Vision — OCR + Translation',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 10),
              textAlign: TextAlign.center)),
        ]),
      ),
    );
  }

  Widget _actionBtn(String label, Color color, VoidCallback? onTap) => GestureDetector(
    onTap: onTap,
    child: Container(height: 44,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14),
        color: onTap != null ? color.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.1),
        border: Border.all(color: onTap != null ? color.withValues(alpha: 0.5) : Colors.transparent)),
      child: Center(child: Text(label, style: TextStyle(
        color: onTap != null ? Colors.white : Colors.grey.shade700,
        fontSize: 12, fontWeight: FontWeight.w600)))));
}
