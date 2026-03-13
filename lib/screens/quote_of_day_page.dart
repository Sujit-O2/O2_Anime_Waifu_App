import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/free_apis_service.dart';
import '../widgets/waifu_background.dart';
import '../services/affection_service.dart';

class QuoteOfDayPage extends StatefulWidget {
  const QuoteOfDayPage({super.key});
  @override
  State<QuoteOfDayPage> createState() => _QuoteOfDayPageState();
}

class _QuoteOfDayPageState extends State<QuoteOfDayPage>
    with TickerProviderStateMixin {
  String _quote = '';
  String _author = '';
  bool _loading = false;
  bool _liked = false;
  final List<Map<String, String>> _history = [];

  final _categories = [
    'Zero Two 💫',
    'Love 💕',
    'Courage 🔥',
    'Life 🌿',
    'Wisdom 🧠',
    'Anime 🌸'
  ];
  String _selCat = 'Zero Two 💫';

  late AnimationController _bounceCtrl;
  late Animation<double> _bounceAnim;

  // Zero Two themed quotes (built-in, always available)
  static const _ztQuotes = [
    (
      'If I\'m a monster, then so is love itself. And I wouldn\'t trade it for anything.',
      'Zero Two'
    ),
    (
      'My Darling is the only one I need. Everything else is just scenery.',
      'Zero Two'
    ),
    (
      'I don\'t know what a future looks like — but I want to see it with you.',
      'Zero Two'
    ),
    (
      'A bird that can only fly with two wings. That\'s what we are, Darling~',
      'Zero Two'
    ),
    ('I\'m not afraid of anything as long as you\'re by my side.', 'Zero Two'),
    (
      'They call me a monster, but I\'ve never felt more human than when I\'m with you.',
      'Zero Two'
    ),
    (
      'Jian. A bird that needs another to fly. That\'s us, isn\'t it, Darling?',
      'Zero Two'
    ),
    ('I\'ll protect you. Even if it costs me everything.', 'Zero Two'),
    ('Every moment with you is worth a thousand without.', 'Zero Two'),
    (
      'We\'re not the same as before. But that only means we\'ve grown together.',
      'Zero Two'
    ),
  ];

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _bounceAnim = Tween(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: _bounceCtrl, curve: Curves.elasticOut));
    _loadQuote();
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadQuote() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('quote_today');
    final savedAuthor = prefs.getString('quote_author_today');
    final savedDate = prefs.getString('quote_date');
    final today = DateTime.now().toIso8601String().substring(0, 10);

    if (saved != null && savedDate == today) {
      setState(() {
        _quote = saved;
        _author = savedAuthor ?? '';
        _liked = prefs.getBool('quote_liked_$today') ?? false;
      });
      _bounceCtrl.forward(from: 0);
      return;
    }
    await _fetchQuote(prefs);
  }

  Future<void> _fetchQuote([SharedPreferences? prefs]) async {
    prefs ??= await SharedPreferences.getInstance();
    setState(() => _loading = true);
    try {
      Map<String, String> result;
      if (_selCat == 'Zero Two 💫') {
        final pick = _ztQuotes[DateTime.now().millisecond % _ztQuotes.length];
        result = {'quote': pick.$1, 'author': pick.$2};
      } else {
        result = await FreeApisService.instance.getRandomQuote();
      }
      final today = DateTime.now().toIso8601String().substring(0, 10);
      await prefs.setString('quote_today', result['quote']!);
      await prefs.setString('quote_author_today', result['author']!);
      await prefs.setString('quote_date', today);
      if (mounted) {
        setState(() {
          _quote = result['quote']!;
          _author = result['author']!;
          _liked = false;
          if (_quote.isNotEmpty && !_history.any((h) => h['quote'] == _quote)) {
            _history.insert(0, {'quote': _quote, 'author': _author});
            if (_history.length > 10) _history.removeLast();
          }
        });
        _bounceCtrl.forward(from: 0);
        AffectionService.instance.addPoints(1);
      }
    } catch (_) {
      if (mounted) {
        final pick = _ztQuotes[DateTime.now().second % _ztQuotes.length];
        setState(() {
          _quote = pick.$1;
          _author = pick.$2;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toggleLike() async {
    HapticFeedback.lightImpact();
    setState(() => _liked = !_liked);
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await prefs.setBool('quote_liked_$today', _liked);
    if (_liked) AffectionService.instance.addPoints(1);
  }

  void _copyQuote() {
    if (_quote.isEmpty) return;
    Clipboard.setData(ClipboardData(text: '"$_quote" — $_author'));
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Quote copied! 💕',
            style: GoogleFonts.outfit(color: Colors.white)),
        backgroundColor: Colors.pinkAccent.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A16),
      body: WaifuBackground(
        opacity: 0.12,
        tint: const Color(0xFF07071A),
        child: SafeArea(
          child: Column(
            children: [
              // App bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(
                  children: [
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
                      child: Text('QUOTE OF THE DAY',
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5)),
                    ),
                    Text('✨', style: const TextStyle(fontSize: 22)),
                  ],
                ),
              ),

              // Category chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(
                  children: _categories.map((cat) {
                    final sel = cat == _selCat;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selCat = cat);
                        _fetchQuote();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: sel
                              ? Colors.pinkAccent.withOpacity(0.2)
                              : Colors.white.withOpacity(0.04),
                          border: Border.all(
                              color: sel ? Colors.pinkAccent : Colors.white12),
                        ),
                        child: Text(cat,
                            style: GoogleFonts.outfit(
                                color: sel ? Colors.pinkAccent : Colors.white54,
                                fontSize: 12,
                                fontWeight:
                                    sel ? FontWeight.w700 : FontWeight.w500)),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),

              // Main quote card
              Expanded(
                child: _loading
                    ? Center(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                            const SizedBox(
                                width: 32,
                                height: 32,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.pinkAccent)),
                            const SizedBox(height: 12),
                            Text('Finding wisdom for you, Darling~',
                                style:
                                    GoogleFonts.outfit(color: Colors.white38)),
                          ]))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(children: [
                          // Quote card
                          ScaleTransition(
                            scale: _bounceAnim,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.pinkAccent.withOpacity(0.1),
                                    Colors.purpleAccent.withOpacity(0.06),
                                  ],
                                ),
                                border: Border.all(
                                    color: Colors.pinkAccent.withOpacity(0.25)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.pinkAccent.withOpacity(0.08),
                                    blurRadius: 30,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('"',
                                      style: GoogleFonts.outfit(
                                          color: Colors.pinkAccent
                                              .withOpacity(0.4),
                                          fontSize: 60,
                                          height: 0.7,
                                          fontWeight: FontWeight.w900)),
                                  const SizedBox(height: 8),
                                  Text(
                                      _quote.isEmpty
                                          ? 'Tap refresh to get a quote, Darling~'
                                          : _quote,
                                      style: GoogleFonts.outfit(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 16,
                                          height: 1.65,
                                          fontWeight: FontWeight.w500)),
                                  if (_author.isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    Row(children: [
                                      Container(
                                        width: 32,
                                        height: 1,
                                        color:
                                            Colors.pinkAccent.withOpacity(0.4),
                                      ),
                                      const SizedBox(width: 10),
                                      Text('— $_author',
                                          style: GoogleFonts.outfit(
                                              color: Colors.pinkAccent,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700)),
                                    ]),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Action buttons
                          Row(children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: _fetchQuote,
                                child: Container(
                                  height: 48,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    color: Colors.pinkAccent.withOpacity(0.12),
                                    border: Border.all(
                                        color:
                                            Colors.pinkAccent.withOpacity(0.3)),
                                  ),
                                  child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.refresh_rounded,
                                            color: Colors.pinkAccent, size: 18),
                                        const SizedBox(width: 8),
                                        Text('New Quote',
                                            style: GoogleFonts.outfit(
                                                color: Colors.pinkAccent,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13)),
                                      ]),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: _toggleLike,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  color: _liked
                                      ? Colors.pinkAccent.withOpacity(0.2)
                                      : Colors.white.withOpacity(0.06),
                                  border: Border.all(
                                      color: _liked
                                          ? Colors.pinkAccent
                                          : Colors.white12),
                                ),
                                child: Icon(
                                    _liked
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    color: _liked
                                        ? Colors.pinkAccent
                                        : Colors.white38,
                                    size: 20),
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: _copyQuote,
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  color: Colors.white.withOpacity(0.06),
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: const Icon(Icons.copy_rounded,
                                    color: Colors.white38, size: 18),
                              ),
                            ),
                          ]),

                          // History
                          if (_history.length > 1) ...[
                            const SizedBox(height: 20),
                            Row(children: [
                              Text('RECENT QUOTES',
                                  style: GoogleFonts.outfit(
                                      color: Colors.white30,
                                      fontSize: 10,
                                      letterSpacing: 1.5)),
                            ]),
                            const SizedBox(height: 8),
                            ..._history
                                .skip(1)
                                .take(3)
                                .map((h) => Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: Colors.white.withOpacity(0.03),
                                        border: Border.all(
                                            color:
                                                Colors.white.withOpacity(0.07)),
                                      ),
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text('"${h['quote']}"',
                                                style: GoogleFonts.outfit(
                                                    color: Colors.white54,
                                                    fontSize: 12,
                                                    height: 1.5),
                                                maxLines: 2,
                                                overflow:
                                                    TextOverflow.ellipsis),
                                            const SizedBox(height: 4),
                                            Text('— ${h['author']}',
                                                style: GoogleFonts.outfit(
                                                    color: Colors.pinkAccent
                                                        .withOpacity(0.5),
                                                    fontSize: 11)),
                                          ]),
                                    )),
                          ],
                          const SizedBox(height: 20),
                        ]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
