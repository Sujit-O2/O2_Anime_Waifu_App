import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:anime_waifu/api_call.dart';

class StoryModePage extends StatefulWidget {
  const StoryModePage({super.key});
  @override
  State<StoryModePage> createState() => _StorymodePageState();
}

class _StorymodePageState extends State<StoryModePage> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _chapters = [];
  bool _loading = false;
  late AnimationController _shimmerCtrl;
  final _scroll = ScrollController();

  static const _starters = [
    {'icon': '🌸', 'title': 'A Day in the FranXX', 'seed': 'A peaceful morning in the plantation where Zero Two finds Darling reading a book on the rooftop...'},
    {'icon': '🌊', 'title': 'Forbidden Shores', 'seed': 'Zero Two sneaks Darling away to a secret cove at the edge of the mesa, where the sea glitters...'},
    {'icon': '🌙', 'title': 'Moonlit Promise', 'seed': 'Under a silver moon, Zero Two traces a constellation with her finger and tells Darling about a wish she made...'},
    {'icon': '🎌', 'title': 'Ordinary Day', 'seed': 'What would it be like if Zero Two and Darling weren\'t pilots, but were just two ordinary students...'},
  ];

  Map<String, dynamic>? _activeStarter;
  String? _docId;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _loadLastStory();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? 'anon';

  Future<void> _loadLastStory() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('users').doc(_uid)
          .collection('storyChapters').orderBy('ts', descending: true).limit(1).get();
      if (snap.docs.isNotEmpty && mounted) {
        final doc = snap.docs.first;
        final data = doc.data();
        setState(() {
          _docId = doc.id;
          _activeStarter = {'title': data['title'], 'icon': data['icon']};
          _chapters = (data['chapters'] as List).cast<Map<String, dynamic>>();
        });
      }
    } catch (_) {}
  }

  Future<void> _startStory(Map<String, dynamic> starter) async {
    setState(() { _activeStarter = starter; _chapters = []; _loading = true; _docId = null; });
    await _continueStory(initial: starter['seed'] as String);
  }

  Future<void> _continueStory({String? initial}) async {
    if (_loading && initial == null) return;
    setState(() => _loading = true);
    try {
      final ctx = _chapters.map((c) => c['text']).join('\n\n');
      final prompt = initial != null
          ? 'You are a narrator continuing a romantic adventure story featuring Zero Two (from Darling in the FranXX) and Darling. Start the story from this scene: "$initial". Write the first chapter in ~100 words with vivid, poetic language. End with "What happens next?" '
          : 'Continue this story from where it left off:\n\n$ctx\n\nWrite the next chapter (~100 words), maintaining the romantic tone and flowing naturally. End with a choice for the reader.';
      final text = await ApiService().sendConversation([{'role': 'user', 'content': prompt}]);
      final chapter = {'text': text, 'idx': _chapters.length + 1};
      if (mounted) {
        setState(() { _chapters.add(chapter); _loading = false; });
        _saveStory();
        await Future.delayed(const Duration(milliseconds: 100));
        if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveStory() async {
    try {
      final data = {
        'title': _activeStarter!['title'],
        'icon': _activeStarter!['icon'],
        'chapters': _chapters,
        'ts': FieldValue.serverTimestamp(),
      };
      if (_docId != null) {
        await FirebaseFirestore.instance.collection('users').doc(_uid).collection('storyChapters').doc(_docId).update(data);
      } else {
        final ref = await FirebaseFirestore.instance.collection('users').doc(_uid).collection('storyChapters').add(data);
        _docId = ref.id;
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060A12),
      body: SafeArea(child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(children: [
            IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white54, size: 20), onPressed: () => Navigator.pop(context)),
            const Spacer(),
            Text('📖 Story Mode', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            const Spacer(),
            if (_activeStarter != null)
              GestureDetector(
                onTap: () => setState(() { _activeStarter = null; _chapters = []; }),
                child: Text('New', style: GoogleFonts.outfit(color: Colors.pinkAccent, fontSize: 13, fontWeight: FontWeight.w600)),
              )
            else const SizedBox(width: 44),
          ]),
        ),
        const SizedBox(height: 8),
        if (_activeStarter == null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text('Choose a story to begin~', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 14)),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _starters.map((s) => GestureDetector(
                onTap: () => _startStory(s),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.deepPurple.withValues(alpha: 0.3), Colors.indigo.withValues(alpha: 0.2)]),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.deepPurpleAccent.withValues(alpha: 0.4)),
                  ),
                  child: Row(children: [
                    Text(s['icon']!, style: const TextStyle(fontSize: 36)),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(s['title']!, style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(s['seed']!, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
                    ])),
                  ]),
                ),
              )).toList(),
            ),
          ),
        ] else ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(children: [
              Text('${_activeStarter!['icon']} ', style: const TextStyle(fontSize: 18)),
              Text(_activeStarter!['title'] as String, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('Chapter ${_chapters.length}', style: GoogleFonts.outfit(color: Colors.white30, fontSize: 12)),
            ]),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _chapters.length + (_loading ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == _chapters.length) {
                  return const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(color: Colors.pinkAccent)));
                }
                final chapter = _chapters[i];
                return TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 500),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (_, v, child) => Opacity(opacity: v, child: child),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Chapter ${chapter['idx']}', style: GoogleFonts.outfit(color: Colors.pinkAccent, fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text(chapter['text'] as String, style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, height: 1.7)),
                    ]),
                  ),
                );
              },
            ),
          ),
          if (!_loading && _chapters.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: GestureDetector(
                onTap: _continueStory,
                child: Container(
                  width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFFDB2777)]),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [BoxShadow(color: Colors.deepPurpleAccent.withValues(alpha: 0.4), blurRadius: 20)],
                  ),
                  child: Text('Continue the Story ✨', textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
        ],
      ])),
    );
  }
}
