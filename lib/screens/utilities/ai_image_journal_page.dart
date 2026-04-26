import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:anime_waifu/services/utilities_core/image_gen_service.dart';

class AiImageJournalPage extends StatefulWidget {
  const AiImageJournalPage({super.key});

  @override
  State<AiImageJournalPage> createState() => _AiImageJournalPageState();
}

class _AiImageJournalPageState extends State<AiImageJournalPage> {
  final _promptCtrl = TextEditingController();
  final List<Map<String, dynamic>> _entries = [];
  bool _generating = false;
  Database? _db;
  String _selectedMood = 'creative';
  final List<String> _moods = [
    'creative',
    'dreamy',
    'mystical',
    'joyful',
    'melancholic',
    'adventurous',
    'romantic',
    'surreal'
  ];

  @override
  void initState() {
    super.initState();
    _initDb();
  }

  Future<void> _initDb() async {
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      path.join(dbPath, 'ai_image_journal.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE entries(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            prompt TEXT,
            imagePath TEXT,
            mood TEXT,
            timestamp INTEGER
          )
        ''');
      },
    );
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    if (_db == null) return;
    final data = await _db!.query('entries', orderBy: 'timestamp DESC');
    if (mounted)
      setState(() => _entries
        ..clear()
        ..addAll(data));
  }

  Future<void> _generate() async {
    final prompt = _promptCtrl.text.trim();
    if (prompt.isEmpty || _generating) return;
    setState(() => _generating = true);
    try {
      final result = await ImageGenService.generateImage(prompt);
      if (result == null) throw Exception('Generation failed');
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/img_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(result.bytes);
      await _db?.insert('entries', {
        'prompt': prompt,
        'imagePath': file.path,
        'mood': _selectedMood,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      _promptCtrl.clear();
      _loadEntries();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Generation failed')),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  void dispose() {
    _promptCtrl.dispose();
    _db?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Image Journal', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Mood picker
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _moods.map((mood) => GestureDetector(
                    onTap: () => setState(() => _selectedMood = mood),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _selectedMood == mood
                            ? Colors.purpleAccent.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _selectedMood == mood
                              ? Colors.purpleAccent
                              : Colors.white12,
                        ),
                      ),
                      child: Text(
                        mood,
                        style: GoogleFonts.outfit(
                          color: _selectedMood == mood ? Colors.purpleAccent : Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _promptCtrl,
                        decoration: InputDecoration(
                          hintText: 'Describe your vision...',
                          filled: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onSubmitted: (_) => _generate(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _generating ? null : _generate,
                      icon: _generating
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.auto_awesome),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _entries.isEmpty
                ? Center(
                    child: Text('No entries yet',
                        style: GoogleFonts.outfit(color: Colors.white54)))
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _entries.length,
                    itemBuilder: (_, i) {
                      final e = _entries[i];
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(File(e['imagePath']), fit: BoxFit.cover),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.8)
                                    ],
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      e['mood']?.toString().toUpperCase() ?? '',
                                      style: GoogleFonts.outfit(
                                          color: Colors.purpleAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      e['prompt'],
                                      style: GoogleFonts.outfit(
                                          color: Colors.white, fontSize: 11),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
