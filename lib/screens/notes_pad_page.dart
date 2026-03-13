import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotesPadPage extends StatefulWidget {
  const NotesPadPage({super.key});
  @override
  State<NotesPadPage> createState() => _NotesPadPageState();
}

class _Note {
  String id, title, body, color;
  DateTime date;
  _Note(
      {required this.id,
      required this.title,
      required this.body,
      required this.color,
      required this.date});
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'color': color,
        'date': date.toIso8601String()
      };
  factory _Note.fromJson(Map<String, dynamic> j) => _Note(
      id: j['id'] as String,
      title: j['title'] as String,
      body: j['body'] as String,
      color: j['color'] as String,
      date: DateTime.parse(j['date'] as String));
}

class _NotesPadPageState extends State<NotesPadPage> {
  List<_Note> _notes = [];
  String _search = '';
  static const _noteColors = [
    '#1A1A2E',
    '#2D0B3E',
    '#0A1A2E',
    '#1A2E0A',
    '#2E1A0A',
    '#2E0A1A'
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('notespad');
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        setState(() => _notes = list
            .map((e) => _Note.fromJson(e as Map<String, dynamic>))
            .toList());
      } catch (_) {}
    }
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
        'notespad', jsonEncode(_notes.map((n) => n.toJson()).toList()));
  }

  Color _parseColor(String hex) =>
      Color(int.parse(hex.replaceFirst('#', '0xFF')));

  void _openNote(_Note? note) {
    final titleCtrl = TextEditingController(text: note?.title ?? '');
    final bodyCtrl = TextEditingController(text: note?.body ?? '');
    String color = note?.color ?? _noteColors[0];
    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, setBS) => Container(
                height: MediaQuery.of(ctx).size.height * 0.85,
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(ctx).viewInsets.bottom),
                decoration: BoxDecoration(
                    color: _parseColor(color),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24))),
                child: Column(children: [
                  Row(children: [
                    IconButton(
                        icon: const Icon(Icons.close, color: Colors.white38),
                        onPressed: () => Navigator.pop(ctx)),
                    Expanded(
                        child: Text(note == null ? 'New Note' : 'Edit Note',
                            style: GoogleFonts.outfit(
                                color: Colors.white54, fontSize: 13),
                            textAlign: TextAlign.center)),
                    IconButton(
                        icon: const Icon(Icons.check_rounded,
                            color: Colors.pinkAccent),
                        onPressed: () {
                          if (titleCtrl.text.trim().isEmpty &&
                              bodyCtrl.text.trim().isEmpty) {
                            return;
                          }

                          if (note != null) {
                            note.title = titleCtrl.text.trim();
                            note.body = bodyCtrl.text.trim();
                            note.color = color;
                            note.date = DateTime.now();
                          } else {
                            _notes.insert(
                                0,
                                _Note(
                                    id: 'n_${DateTime.now().millisecondsSinceEpoch}',
                                    title: titleCtrl.text.trim(),
                                    body: bodyCtrl.text.trim(),
                                    color: color,
                                    date: DateTime.now()));
                          }
                          _save();
                          setState(() {});
                          Navigator.pop(ctx);
                        }),
                  ]),
                  // Color picker
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                          children: _noteColors
                              .map((c) => GestureDetector(
                                  onTap: () => setBS(() => color = c),
                                  child: Container(
                                      width: 28,
                                      height: 28,
                                      margin: const EdgeInsets.only(right: 6),
                                      decoration: BoxDecoration(
                                          color: _parseColor(c),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: c == color
                                                  ? Colors.white
                                                  : Colors.white12,
                                              width: c == color ? 2.5 : 1)))))
                              .toList())),
                  Divider(
                      color: Colors.white.withValues(alpha: 0.07), height: 20),
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextField(
                          controller: titleCtrl,
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                          cursorColor: Colors.pinkAccent,
                          decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Title…',
                              hintStyle: GoogleFonts.outfit(
                                  color: Colors.white24, fontSize: 18)))),
                  Expanded(
                      child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: TextField(
                              controller: bodyCtrl,
                              maxLines: null,
                              expands: true,
                              style: GoogleFonts.outfit(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  height: 1.6),
                              cursorColor: Colors.pinkAccent,
                              keyboardType: TextInputType.multiline,
                              decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Write your note here…',
                                  hintStyle: GoogleFonts.outfit(
                                      color: Colors.white24))))),
                ]))));
  }

  @override
  Widget build(BuildContext context) {
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
    final filtered = _notes
        .where((n) =>
            n.title.toLowerCase().contains(_search.toLowerCase()) ||
            n.body.toLowerCase().contains(_search.toLowerCase()))
        .toList();
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
              onPressed: () => Navigator.pop(context)),
          title: Text('NOTES',
              style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2)),
          centerTitle: true,
          actions: [
            IconButton(
                icon: const Icon(Icons.add_circle_outline,
                    color: Colors.pinkAccent),
                onPressed: () => _openNote(null))
          ]),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openNote(null),
          backgroundColor: Colors.pinkAccent,
          icon: const Icon(Icons.edit_outlined, color: Colors.white),
          label: Text('Note', style: GoogleFonts.outfit(color: Colors.white))),
      body: Column(children: [
        Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white.withValues(alpha: 0.05),
                    border: Border.all(color: Colors.white12)),
                child: TextField(
                    onChanged: (v) => setState(() => _search = v),
                    style:
                        GoogleFonts.outfit(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: Colors.white38, size: 20),
                        hintText: 'Search notes…',
                        hintStyle:
                            GoogleFonts.outfit(color: Colors.white24))))),
        Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                        const Text('📝', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text(
                            _notes.isEmpty
                                ? 'No notes yet, Darling~'
                                : 'No notes match your search',
                            style: GoogleFonts.outfit(
                                color: Colors.white38, fontSize: 16))
                      ]))
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 0.85),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final n = filtered[i];
                      return GestureDetector(
                          onTap: () {
                            _openNote(n);
                          },
                          onLongPress: () {
                            Clipboard.setData(
                                ClipboardData(text: '${n.title}\n${n.body}'));
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('Copied!',
                                    style: GoogleFonts.outfit()),
                                backgroundColor: Colors.pinkAccent,
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 1),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10))));
                          },
                          child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: _parseColor(n.color),
                                  border: Border.all(
                                      color: Colors.white
                                          .withValues(alpha: 0.07))),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (n.title.isNotEmpty)
                                      Text(n.title,
                                          style: GoogleFonts.outfit(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis),
                                    if (n.title.isNotEmpty && n.body.isNotEmpty)
                                      const SizedBox(height: 6),
                                    Expanded(
                                        child: Text(n.body,
                                            style: GoogleFonts.outfit(
                                                color: Colors.white54,
                                                fontSize: 12,
                                                height: 1.5),
                                            overflow: TextOverflow.fade)),
                                    const SizedBox(height: 6),
                                    Text(
                                        '${months[n.date.month - 1]} ${n.date.day}',
                                        style: GoogleFonts.outfit(
                                            color: Colors.white24,
                                            fontSize: 10)),
                                  ])));
                    })),
      ]),
    );
  }
}
