import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ClipboardManagerPage extends StatefulWidget {
  const ClipboardManagerPage({super.key});
  @override
  State<ClipboardManagerPage> createState() => _ClipboardManagerPageState();
}

class _ClipboardManagerPageState extends State<ClipboardManagerPage> {
  List<Map<String, dynamic>> _clips = [];
  String _search = '';
  final _addCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _addCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    try {
      _clips =
          (jsonDecode(p.getString('clipboard_history_data') ?? '[]') as List)
              .cast<Map<String, dynamic>>();
    } catch (_) {}
    setState(() {});
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
        'clipboard_history_data', jsonEncode(_clips.take(50).toList()));
  }

  String _detectType(String text) {
    if (RegExp(r'https?://').hasMatch(text)) return 'url';
    if (RegExp(r'[\w.]+@[\w.]+\.\w+').hasMatch(text)) return 'email';
    if (RegExp(r'^\+?[\d\s-]{7,15}$').hasMatch(text.trim())) return 'phone';
    return 'text';
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'url':
        return Icons.link_rounded;
      case 'email':
        return Icons.email_rounded;
      case 'phone':
        return Icons.phone_rounded;
      default:
        return Icons.text_snippet_rounded;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'url':
        return Colors.lightBlueAccent;
      case 'email':
        return Colors.orangeAccent;
      case 'phone':
        return Colors.greenAccent;
      default:
        return Colors.white54;
    }
  }

  void _addFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text == null || data!.text!.isEmpty) {
      _snack('📋 Clipboard is empty', Colors.white38);
      return;
    }
    _addClip(data.text!);
  }

  void _addManual() {
    if (_addCtrl.text.trim().isEmpty) return;
    _addClip(_addCtrl.text.trim());
    _addCtrl.clear();
  }

  void _addClip(String text) {
    if (_clips.any((c) => c['text'] == text)) {
      _snack('Already saved', Colors.white38);
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _clips.insert(0, {
          'text': text,
          'type': _detectType(text),
          'time': DateTime.now().millisecondsSinceEpoch,
          'pinned': false,
        }));
    _save();
    _snack('✅ Clip saved!', Colors.tealAccent);
  }

  void _copyClip(String text) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    _snack('📋 Copied!', Colors.tealAccent);
  }

  void _togglePin(int i) {
    HapticFeedback.lightImpact();
    setState(() => _clips[i]['pinned'] = !(_clips[i]['pinned'] as bool));
    _save();
  }

  void _deleteClip(int i) {
    HapticFeedback.mediumImpact();
    setState(() => _clips.removeAt(i));
    _save();
  }

  String _timeAgo(int ms) {
    final diff =
        DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ms));
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    return '${diff.inMinutes}m';
  }

  void _snack(String msg, Color c) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg,
            style: GoogleFonts.outfit(
                color: Colors.black87, fontWeight: FontWeight.w700)),
        backgroundColor: c,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
  }

  List<Map<String, dynamic>> get _filtered {
    var list = List<Map<String, dynamic>>.from(_clips);
    if (_search.isNotEmpty)
      list = list
          .where((c) => (c['text']?.toString() ?? '')
              .toLowerCase()
              .contains(_search.toLowerCase()))
          .toList();
    list.sort((a, b) {
      if (a['pinned'] == true && b['pinned'] != true) return -1;
      if (b['pinned'] == true && a['pinned'] != true) return 1;
      return 0;
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
          child: Column(children: [
        Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(children: [
              GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white12)),
                      child: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white60, size: 16))),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('CLIPBOARD',
                        style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5)),
                    Text('${_clips.length} saved clips',
                        style: GoogleFonts.outfit(
                            color: Colors.tealAccent, fontSize: 11)),
                  ])),
              GestureDetector(
                  onTap: _addFromClipboard,
                  child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.tealAccent.withValues(alpha: 0.15),
                          border: Border.all(
                              color: Colors.tealAccent.withValues(alpha: 0.4))),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.content_paste_rounded,
                            color: Colors.tealAccent, size: 16),
                        const SizedBox(width: 4),
                        Text('Paste',
                            style: GoogleFonts.outfit(
                                color: Colors.tealAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.w700))
                      ]))),
            ])),
        const SizedBox(height: 12),
        // Search + add
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Expanded(
                  child: TextField(
                      onChanged: (v) => setState(() => _search = v),
                      style:
                          GoogleFonts.outfit(color: Colors.white, fontSize: 13),
                      cursorColor: Colors.tealAccent,
                      decoration: InputDecoration(
                          hintText: '🔍 Search clips...',
                          hintStyle: GoogleFonts.outfit(
                              color: Colors.white30, fontSize: 12),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.04),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10)))),
            ])),
        const SizedBox(height: 8),
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Expanded(
                  child: TextField(
                      controller: _addCtrl,
                      style:
                          GoogleFonts.outfit(color: Colors.white, fontSize: 13),
                      cursorColor: Colors.tealAccent,
                      decoration: InputDecoration(
                          hintText: 'Type to add clip...',
                          hintStyle: GoogleFonts.outfit(
                              color: Colors.white30, fontSize: 12),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.04),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10)))),
              const SizedBox(width: 8),
              GestureDetector(
                  onTap: _addManual,
                  child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                          color: Colors.tealAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: Colors.tealAccent.withValues(alpha: 0.4))),
                      child: const Icon(Icons.add_rounded,
                          color: Colors.tealAccent, size: 20))),
            ])),
        const Divider(color: Colors.white12, height: 16),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                      const Text('📋', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 12),
                      Text('No clips saved',
                          style: GoogleFonts.outfit(color: Colors.white38))
                    ]))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final clip = filtered[i];
                    final realIdx = _clips.indexOf(clip);
                    final type = clip['type']?.toString() ?? '';
                    final pinned = clip['pinned'] == true;
                    return Dismissible(
                      key: ValueKey(clip['time']),
                      direction: DismissDirection.endToStart,
                      background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.redAccent.withValues(alpha: 0.15)),
                          child: const Icon(Icons.delete_outline_rounded,
                              color: Colors.redAccent)),
                      onDismissed: (_) => _deleteClip(realIdx),
                      child: GestureDetector(
                        onTap: () => _copyClip(clip['text']?.toString() ?? ''),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: pinned
                                  ? Colors.amberAccent.withValues(alpha: 0.06)
                                  : Colors.white.withValues(alpha: 0.03),
                              border: Border.all(
                                  color: pinned
                                      ? Colors.amberAccent
                                          .withValues(alpha: 0.25)
                                      : Colors.white.withValues(alpha: 0.07))),
                          child: Row(children: [
                            Icon(_typeIcon(type),
                                color: _typeColor(type), size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(clip['text']?.toString() ?? '',
                                      style: GoogleFonts.outfit(
                                          color: Colors.white, fontSize: 12),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 2),
                                  Text(
                                      '${type.toUpperCase()} • ${_timeAgo(clip['time'] as int)}',
                                      style: GoogleFonts.outfit(
                                          color: Colors.white24, fontSize: 9)),
                                ])),
                            GestureDetector(
                                onTap: () => _togglePin(realIdx),
                                child: Icon(
                                    pinned
                                        ? Icons.push_pin
                                        : Icons.push_pin_outlined,
                                    color: pinned
                                        ? Colors.amberAccent
                                        : Colors.white24,
                                    size: 16)),
                          ]),
                        ),
                      ),
                    );
                  }),
        ),
      ])),
    );
  }
}
