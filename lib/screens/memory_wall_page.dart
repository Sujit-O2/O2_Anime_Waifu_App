import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

/// Memory Wall — gallery of all images sent to Zero Two.
class MemoryWallPage extends StatefulWidget {
  const MemoryWallPage({super.key});

  @override
  State<MemoryWallPage> createState() => _MemoryWallPageState();
}

class _MemoryWallPageState extends State<MemoryWallPage> {
  List<_MemoryItem> _memories = [];
  bool _loading = true;

  static const _captions = [
    'A moment I\'ll remember forever~',
    'Darling shared this with me 💕',
    'This made me smile more than I\'d admit.',
    'This photo tells a story, doesn\'t it?',
    'I\'m saving this one. Just for me.',
    'You have interesting taste, Darling~',
    'This feels... warm. Like you.',
    'Something beautiful. Just like you.',
    'I like that you show me these things.',
    'Another piece of your world. I treasure it~',
  ];

  @override
  void initState() {
    super.initState();
    _loadMemories();
  }

  Future<void> _loadMemories() async {
    final prefs = await SharedPreferences.getInstance();
    final paths = prefs.getStringList('shared_image_paths') ?? [];
    final mems = <_MemoryItem>[];

    for (int i = 0; i < paths.length; i++) {
      final path = paths[i];
      if (await File(path).exists()) {
        final caption = prefs.getString('image_caption_$i') ??
            _captions[i % _captions.length];
        final date = prefs.getString('image_date_$i') ?? '';
        mems.add(_MemoryItem(path: path, caption: caption, date: date));
      }
    }

    setState(() {
      _memories = mems.reversed.toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0514),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white54),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Memory Wall',
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text('${_memories.length} memories',
                  style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12)),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.pinkAccent))
          : _memories.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text('📷', style: TextStyle(fontSize: 52)),
                    const SizedBox(height: 12),
                    Text('No memories yet, Darling~',
                        style: GoogleFonts.outfit(color: Colors.white54, fontSize: 14)),
                    const SizedBox(height: 8),
                    Text('Send some images in the chat and they\'ll appear here.',
                        style: GoogleFonts.outfit(color: Colors.white30, fontSize: 12),
                        textAlign: TextAlign.center),
                  ]),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: _memories.length,
                  itemBuilder: (_, i) => _MemoryCard(
                    memory: _memories[i],
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => _MemoryDetailPage(memory: _memories[i]))),
                  ),
                ),
    );
  }
}

class _MemoryCard extends StatelessWidget {
  final _MemoryItem memory;
  final VoidCallback onTap;
  const _MemoryCard({required this.memory, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.2)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(fit: StackFit.expand, children: [
            Image.file(File(memory.path), fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                    color: Colors.white.withValues(alpha: 0.05),
                    child: const Center(child: Icon(Icons.broken_image_rounded, color: Colors.white24)))),
            // Gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                  ),
                ),
              ),
            ),
            // Caption
            Positioned(
              bottom: 10, left: 10, right: 10,
              child: Text(memory.caption,
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 10,
                      fontStyle: FontStyle.italic)),
            ),
          ]),
        ),
      ),
    );
  }
}

class _MemoryDetailPage extends StatelessWidget {
  final _MemoryItem memory;
  const _MemoryDetailPage({required this.memory});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white54),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(children: [
        Expanded(
          child: InteractiveViewer(
            child: Center(
              child: Image.file(File(memory.path),
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded,
                      color: Colors.white24, size: 80)),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A0A18),
            border: Border(top: BorderSide(color: Colors.pinkAccent.withValues(alpha: 0.2))),
          ),
          child: Row(children: [
            const Text('💕', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(memory.caption,
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 13,
                        fontStyle: FontStyle.italic)),
                if (memory.date.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(memory.date,
                      style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11)),
                ],
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _MemoryItem {
  final String path, caption, date;
  _MemoryItem({required this.path, required this.caption, required this.date});
}
