import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:anime_waifu/utils/api_call.dart';
import 'package:anime_waifu/core/v2_upgrade_kit.dart';

/// File Intelligence System — Read files, summarize code, analyze project structures.
class FileIntelligencePage extends StatefulWidget {
  const FileIntelligencePage({super.key});
  @override
  State<FileIntelligencePage> createState() => _FileIntelligencePageState();
}

class _FileIntelligencePageState extends State<FileIntelligencePage> {
  bool _analyzing = false;
  Map<String, dynamic>? _analysis;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final d = prefs.getString('file_intel_history');
    if (d != null) {
      if (!mounted) return;
      setState(() =>
          _history = (jsonDecode(d) as List).cast<Map<String, dynamic>>());
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'file_intel_history', jsonEncode(_history.take(20).toList()));
  }

  void _pickAndAnalyze() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);
      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.single.path!);
      final path = file.path;
      final sizeMb = file.lengthSync() / (1024 * 1024);

      // Limit to 2MB to prevent API crash
      if (sizeMb > 2) {
        if (!mounted) return;
        setState(() {
          _analysis = {
            'type': 'error',
            'path': path,
            'summary': 'File is too large (>2MB)',
            'techStack': <String>[]
          };
        });
        return;
      }

      setState(() => _analyzing = true);

      final content = await file.readAsString();
      final ext = path.split('.').last;

      // Generate summary via API
      final api = ApiService();
      final preview = content.substring(0, content.length.clamp(0, 3000));
      final aiResponse = await api.sendConversation([
        {
          'role': 'system',
          'content':
              'You are zero two. You are given the raw text of a file. Briefly summarize what this file is about, what language/format it uses, and list 3 key takeaways. Keep it under 4 sentences.'
        },
        {
          'role': 'user',
          'content': 'File extension: .$ext\n\nContent preview:\n$preview'
        }
      ]);

      final lines = content.split('\n').length;
      final res = {
        'type': 'file',
        'path': path,
        'extension': ext,
        'lines': lines,
        'size': '${(file.lengthSync() / 1024).toStringAsFixed(1)} KB',
        'preview': content.substring(0, content.length.clamp(0, 500)),
        'summary': aiResponse,
        'techStack': ['📄 .$ext file'],
      };

      if (!mounted) return;
      setState(() {
        _analyzing = false;
        _analysis = res;
        _history.insert(0, {...res, 'time': DateTime.now().toIso8601String()});
      });
      _save();
    } catch (e) {
      setState(() {
        _analyzing = false;
        _analysis = {
          'type': 'error',
          'path': 'Unknown',
          'summary': 'Could not read file (Is it binary/image?): $e',
          'techStack': <String>[]
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FeaturePageV2(
      title: 'FILE INTELLIGENCE',
      subtitle: 'Contextual Document Search',
      onBack: () => Navigator.pop(context),
      content: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            const Text('📂', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 6),
            Text('File Intelligence System',
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900)),
            Text('Analyze files, folders & project structures',
                style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12)),
            const SizedBox(height: 14),

            GestureDetector(
              onTap: _analyzing ? null : _pickAndAnalyze,
              child: GlassCard(
                padding: const EdgeInsets.symmetric(vertical: 16),
                glow: !_analyzing,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_analyzing)
                      const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.amberAccent))
                    else
                      const Icon(Icons.upload_file_rounded,
                          color: Colors.amberAccent),
                    const SizedBox(width: 10),
                    Text(
                      _analyzing
                          ? 'AI ANALYZING FILE...'
                          : 'PICK FILE TO ANALYZE',
                      style: GoogleFonts.outfit(
                          color: Colors.amberAccent,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Analysis results
            if (_analysis != null) ...[
              GlassCard(
                padding: const EdgeInsets.all(14),
                glow: false,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(
                            _analysis!['type'] == 'directory'
                                ? Icons.folder_rounded
                                : Icons.insert_drive_file_rounded,
                            color: Colors.amberAccent,
                            size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(_analysis!['summary'] ?? '',
                                style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700))),
                      ]),
                      const SizedBox(height: 8),
                      Text(_analysis!['path'] ?? '',
                          style: GoogleFonts.firaCode(
                              color: Colors.amberAccent.withValues(alpha: 0.7),
                              fontSize: 10)),
                      const SizedBox(height: 8),

                      if (_analysis!['type'] == 'directory') ...[
                        _statRow('Total Files', '${_analysis!['totalFiles']}',
                            Colors.cyanAccent),
                        _statRow('Directories', '${_analysis!['totalDirs']}',
                            Colors.greenAccent),
                      ],
                      if (_analysis!['type'] == 'file') ...[
                        _statRow('Lines', '${_analysis!['lines']}',
                            Colors.cyanAccent),
                        _statRow('Size', '${_analysis!['size']}',
                            Colors.greenAccent),
                        _statRow('Extension', '.${_analysis!['extension']}',
                            Colors.pinkAccent),
                      ],
                      const SizedBox(height: 8),

                      // Tech stack
                      if ((_analysis!['techStack'] as List?)?.isNotEmpty ??
                          false) ...[
                        Text('TECH STACK',
                            style: GoogleFonts.outfit(
                                color: Colors.white54,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1)),
                        const SizedBox(height: 4),
                        ...(_analysis!['techStack'] as List).map((t) => Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Text(t.toString(),
                                  style: GoogleFonts.outfit(
                                      color: Colors.amberAccent
                                          .withValues(alpha: 0.8),
                                      fontSize: 11)),
                            )),
                      ],

                      // File preview
                      if (_analysis!['preview'] != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: const Color(0xFF0D1117),
                              borderRadius: BorderRadius.circular(8)),
                          child: Text(_analysis!['preview'],
                              style: GoogleFonts.firaCode(
                                  color: Colors.white38, fontSize: 10),
                              maxLines: 12,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ]),
              ),
            ],

            // History
            if (_history.isNotEmpty) ...[
              const SizedBox(height: 14),
              Align(
                  alignment: Alignment.centerLeft,
                  child: Text('RECENT ANALYSES',
                      style: GoogleFonts.outfit(
                          color: Colors.white38,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1))),
              const SizedBox(height: 6),
              ...(_history.take(5).map((h) => Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(8)),
                    child: Row(children: [
                      Icon(
                          h['type'] == 'directory'
                              ? Icons.folder_rounded
                              : Icons.insert_drive_file_rounded,
                          color: Colors.white30,
                          size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(h['path'] ?? '',
                              style: GoogleFonts.firaCode(
                                  color: Colors.white54, fontSize: 10),
                              overflow: TextOverflow.ellipsis)),
                    ]),
                  ))),
            ],
          ])),
    );
  }

  Widget _statRow(String label, String value, Color c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        Text(label,
            style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11)),
        const Spacer(),
        Text(value,
            style: GoogleFonts.outfit(
                color: c, fontSize: 11, fontWeight: FontWeight.w800)),
      ]),
    );
  }
}



