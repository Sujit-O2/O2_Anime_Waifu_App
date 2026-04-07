import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../api_call.dart';

class SmartScannerPage extends StatefulWidget {
  const SmartScannerPage({super.key});
  @override
  State<SmartScannerPage> createState() => _SmartScannerPageState();
}

class _SmartScannerPageState extends State<SmartScannerPage> {
  bool _scanning = false;
  String? _extractedText;
  String? _imagePath;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('smart_scanner_history') ?? '[]';
    try {
      setState(() =>
          _history = (jsonDecode(raw) as List).cast<Map<String, dynamic>>());
    } catch (_) {}
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
        'smart_scanner_history', jsonEncode(_history.take(20).toList()));
  }

  Future<void> _scanImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final img = await picker.pickImage(source: source, imageQuality: 85);
      if (img == null) return;

      setState(() {
        _scanning = true;
        _imagePath = img.path;
        _extractedText = null;
      });

      final file = File(img.path);
      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);

      final api = ApiService();
      final result = await api.sendConversation([
        {
          'role': 'system',
          'content':
              'You are an OCR text extraction tool. Extract ALL text visible in the image. Return only the extracted text, preserving line breaks and formatting. If no text is found, say "No text detected in this image."'
        },
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text': 'Extract all text from this image:'
            },
            {
              'type': 'image_url',
              'image_url': {
                'url': 'data:image/jpeg;base64,$base64Image'
              }
            }
          ]
        }
      ]);

      final entry = {
        'text': result,
        'path': img.path,
        'time': DateTime.now().millisecondsSinceEpoch,
        'source': source == ImageSource.camera ? 'camera' : 'gallery',
      };

      setState(() {
        _scanning = false;
        _extractedText = result;
        _history.insert(0, entry);
      });
      _save();
    } catch (e) {
      setState(() {
        _scanning = false;
        _extractedText = 'Error scanning: $e';
      });
    }
  }

  void _copyText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.mediumImpact();
    _snack('📋 Copied to clipboard!', Colors.tealAccent);
  }

  void _snack(String msg, Color c) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: GoogleFonts.outfit(
              color: Colors.black87, fontWeight: FontWeight.w700)),
      backgroundColor: c,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  String _timeAgo(int ms) {
    final diff =
        DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ms));
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white12)),
                  child: const Icon(Icons.arrow_back_ios_new,
                      color: Colors.white60, size: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SMART SCANNER',
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5)),
                      Text('OCR • Extract text from images',
                          style: GoogleFonts.outfit(
                              color: Colors.tealAccent, fontSize: 11)),
                    ]),
              ),
            ]),
          ),

          const SizedBox(height: 16),

          // Scan buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Expanded(
                child: _scanButton(
                  '📸 Camera',
                  Icons.camera_alt_rounded,
                  Colors.tealAccent,
                  () => _scanImage(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _scanButton(
                  '🖼️ Gallery',
                  Icons.photo_library_rounded,
                  Colors.purpleAccent,
                  () => _scanImage(ImageSource.gallery),
                ),
              ),
            ]),
          ),

          const SizedBox(height: 14),

          // Results
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(children: [
                if (_scanning) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.tealAccent.withValues(alpha: 0.05),
                      border: Border.all(
                          color: Colors.tealAccent.withValues(alpha: 0.2)),
                    ),
                    child: Column(children: [
                      const SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.tealAccent)),
                      const SizedBox(height: 14),
                      Text('AI is scanning your image...',
                          style: GoogleFonts.outfit(
                              color: Colors.tealAccent, fontSize: 13)),
                      Text('Extracting all visible text',
                          style: GoogleFonts.outfit(
                              color: Colors.white30, fontSize: 11)),
                    ]),
                  ),
                ],

                // Image preview
                if (_imagePath != null && !_scanning) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(
                      File(_imagePath!),
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // Extracted text
                if (_extractedText != null && !_scanning) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: Colors.tealAccent.withValues(alpha: 0.05),
                      border: Border.all(
                          color: Colors.tealAccent.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Icon(Icons.text_snippet_rounded,
                                color: Colors.tealAccent, size: 18),
                            const SizedBox(width: 8),
                            Text('EXTRACTED TEXT',
                                style: GoogleFonts.outfit(
                                    color: Colors.tealAccent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1)),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => _copyText(_extractedText!),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.tealAccent
                                      .withValues(alpha: 0.15),
                                ),
                                child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.copy_rounded,
                                          color: Colors.tealAccent, size: 14),
                                      const SizedBox(width: 4),
                                      Text('Copy',
                                          style: GoogleFonts.outfit(
                                              color: Colors.tealAccent,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700)),
                                    ]),
                              ),
                            ),
                          ]),
                          const SizedBox(height: 10),
                          SelectableText(
                            _extractedText!,
                            style: GoogleFonts.outfit(
                                color: Colors.white, fontSize: 13, height: 1.5),
                          ),
                        ]),
                  ),
                ],

                // History
                if (_history.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('SCAN HISTORY',
                        style: GoogleFonts.outfit(
                            color: Colors.white38,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1)),
                  ),
                  const SizedBox(height: 8),
                  ..._history.take(10).map((h) => GestureDetector(
                        onTap: () {
                          setState(() {
                            _extractedText = h['text'] as String?;
                            _imagePath = h['path'] as String?;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(children: [
                            Icon(
                                h['source'] == 'camera'
                                    ? Icons.camera_alt_rounded
                                    : Icons.photo_library_rounded,
                                color: Colors.white30,
                                size: 16),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                (h['text'] as String? ?? '')
                                    .replaceAll('\n', ' ')
                                    .substring(
                                        0,
                                        ((h['text'] as String?)?.length ?? 0)
                                            .clamp(0, 60)),
                                style: GoogleFonts.outfit(
                                    color: Colors.white54, fontSize: 11),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(_timeAgo(h['time'] as int),
                                style: GoogleFonts.outfit(
                                    color: Colors.white24, fontSize: 10)),
                          ]),
                        ),
                      )),
                ],

                if (_extractedText == null && !_scanning && _history.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: Column(children: [
                      const Text('📸', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 12),
                      Text('Scan documents, receipts, or whiteboards',
                          style: GoogleFonts.outfit(color: Colors.white38)),
                      Text('AI will extract all text for you',
                          style: GoogleFonts.outfit(
                              color: Colors.white24, fontSize: 12)),
                    ]),
                  ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _scanButton(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: _scanning ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 8),
          Text(label,
              style: GoogleFonts.outfit(
                  color: color, fontSize: 13, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}
