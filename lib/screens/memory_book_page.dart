import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/affection_service.dart';
import '../widgets/waifu_background.dart';

class MemoryBookPage extends StatefulWidget {
  const MemoryBookPage({super.key});
  @override
  State<MemoryBookPage> createState() => _MemoryBookPageState();
}

class _Memory {
  String id, title, note;
  DateTime date;
  String? imagePath;

  _Memory({
    required this.id,
    required this.title,
    required this.note,
    required this.date,
    this.imagePath,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'note': note,
        'date': date.toIso8601String(),
        'imagePath': imagePath,
      };

  factory _Memory.fromJson(Map<String, dynamic> j) => _Memory(
        id: j['id'] as String,
        title: j['title'] as String,
        note: j['note'] as String,
        date: DateTime.parse(j['date'] as String),
        imagePath: j['imagePath'] as String?,
      );
}

class _MemoryBookPageState extends State<MemoryBookPage> {
  List<_Memory> _memories = [];
  final _titleCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String? _tempImagePath;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('memory_book');
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        setState(() => _memories = list
            .map((e) => _Memory.fromJson(e as Map<String, dynamic>))
            .toList());
      } catch (_) {}
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'memory_book', jsonEncode(_memories.map((m) => m.toJson()).toList()));
  }

  void _showAddDialog() {
    _titleCtrl.clear();
    _noteCtrl.clear();
    _tempImagePath = null;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setBS) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Add Memory',
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            const SizedBox(height: 16),
            _inputField(_titleCtrl, 'Title (e.g. "First 100 XP day!")'),
            const SizedBox(height: 8),
            _inputField(_noteCtrl, 'Write a note…', lines: 3),
            const SizedBox(height: 10),
            // Photo
            GestureDetector(
              onTap: () async {
                final p = await _picker.pickImage(
                    source: ImageSource.gallery, imageQuality: 70);
                if (p != null) setBS(() => _tempImagePath = p.path);
              },
              child: Container(
                width: double.infinity,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white.withValues(alpha: 0.04),
                  border: Border.all(color: Colors.white12),
                ),
                child: _tempImagePath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(File(_tempImagePath!),
                            fit: BoxFit.cover))
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_photo_alternate_outlined,
                              color: Colors.white38, size: 28),
                          const SizedBox(height: 4),
                          Text('Add photo',
                              style: GoogleFonts.outfit(
                                  color: Colors.white38, fontSize: 12)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_titleCtrl.text.trim().isEmpty) return;
                  _memories.insert(
                      0,
                      _Memory(
                        id: 'mem_${DateTime.now().millisecondsSinceEpoch}',
                        title: _titleCtrl.text.trim(),
                        note: _noteCtrl.text.trim(),
                        date: DateTime.now(),
                        imagePath: _tempImagePath,
                      ));
                  _save();
                  setState(() {});
                  AffectionService.instance.addPoints(3);
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text('Save Memory',
                    style: GoogleFonts.outfit(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        );
      }),
    );
  }

  Widget _inputField(TextEditingController ctrl, String hint,
          {int lines = 1}) =>
      Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: TextField(
          controller: ctrl,
          maxLines: lines,
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
          cursorColor: Colors.pinkAccent,
          decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(12),
              hintText: hint,
              hintStyle: GoogleFonts.outfit(color: Colors.white24)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('MEMORY BOOK',
            style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate_outlined,
                color: Colors.pinkAccent),
            onPressed: _showAddDialog,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: Colors.pinkAccent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Memory', style: GoogleFonts.outfit(color: Colors.white)),
      ),
      body: WaifuBackground(
        opacity: 0.09,
        tint: const Color(0xFF0A0814),
        child: _memories.isEmpty
            ? Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                    const Text('📷', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 12),
                    Text('No memories yet, Darling~',
                        style: GoogleFonts.outfit(
                            color: Colors.white38, fontSize: 16)),
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: _showAddDialog,
                      child: Text('Add first memory →',
                          style: GoogleFonts.outfit(color: Colors.pinkAccent)),
                    ),
                  ]))
            : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.8),
                itemCount: _memories.length,
                itemBuilder: (ctx, i) {
                  final m = _memories[i];
                  final months = [
                    'Jan',
                    'Feb',
                    'Mar',
                    'Apr',
                    'May',
                    'Jun',
                    'Jul',
                    'Aug',
                    'Sep',
                    'Oct',
                    'Nov',
                    'Dec'
                  ];
                  final date =
                      '${months[m.date.month - 1]} ${m.date.day}, ${m.date.year}';
                  return GestureDetector(
                    onLongPress: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          backgroundColor: const Color(0xFF1A1A2E),
                          title: Text('Delete?',
                              style: GoogleFonts.outfit(color: Colors.white)),
                          content: Text('Remove "${m.title}"?',
                              style: GoogleFonts.outfit(color: Colors.white54)),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('Cancel',
                                    style: GoogleFonts.outfit(
                                        color: Colors.white38))),
                            TextButton(
                              onPressed: () {
                                _memories.removeAt(i);
                                _save();
                                setState(() {});
                                Navigator.pop(context);
                              },
                              child: Text('Delete',
                                  style: GoogleFonts.outfit(
                                      color: Colors.redAccent)),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white.withValues(alpha: 0.04),
                        border: Border.all(
                            color: Colors.pinkAccent.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Image or placeholder
                            Expanded(
                              child: m.imagePath != null &&
                                      File(m.imagePath!).existsSync()
                                  ? ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(16)),
                                      child: Image.file(File(m.imagePath!),
                                          fit: BoxFit.cover,
                                          width: double.infinity))
                                  : Container(
                                      decoration: const BoxDecoration(
                                        borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(16)),
                                        gradient: LinearGradient(
                                          colors: [
                                            Color(0xFF2D0B3E),
                                            Color(0xFF0A1A2E)
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                      child: const Center(
                                          child: Text('📷',
                                              style: TextStyle(fontSize: 32))),
                                    ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(m.title,
                                      style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  if (m.note.isNotEmpty)
                                    Text(m.note,
                                        style: GoogleFonts.outfit(
                                            color: Colors.white38,
                                            fontSize: 10),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 2),
                                  Text(date,
                                      style: GoogleFonts.outfit(
                                          color: Colors.white24, fontSize: 9)),
                                ],
                              ),
                            ),
                          ]),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
