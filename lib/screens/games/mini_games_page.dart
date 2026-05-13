import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:anime_waifu/main.dart';
import 'package:anime_waifu/services/games_gamification/game_sounds_service.dart';
import 'package:anime_waifu/services/games_gamification/game_progress_db.dart';
import 'package:anime_waifu/widgets/premium_page_route.dart';

const List<String> _o2GameBackgroundAssets = [
  'assets/img/z12.jpg',
  'assets/img/z2s.jpg',
  'assets/img/bg2.jpg',
  'assets/img/bg.jpg',
  'assets/img/bll.jpg',
];
const String _o2GameFallbackAsset = 'assets/img/z12.jpg';

String _randomO2GameBackground([Random? rng]) {
  final random = rng ?? Random();
  return _o2GameBackgroundAssets[random.nextInt(_o2GameBackgroundAssets.length)];
}

class _GameBackdrop extends StatelessWidget {
  final String asset;
  final Color glowColor;
  final Color surfaceTint;
  const _GameBackdrop({required this.asset, required this.glowColor, required this.surfaceTint});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(fit: StackFit.expand, children: [
          Image.asset(asset, fit: BoxFit.cover, opacity: const AlwaysStoppedAnimation(0.24),
              errorBuilder: (_, __, ___) => Image.asset(_o2GameFallbackAsset, fit: BoxFit.cover, opacity: const AlwaysStoppedAnimation(0.24))),
          DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [
            surfaceTint.withValues(alpha: 0.58), surfaceTint.withValues(alpha: 0.76), Colors.black.withValues(alpha: 0.90)]))),
          Positioned(top: -36, right: -24, child: _BackdropOrb(size: 170, color: glowColor.withValues(alpha: 0.22))),
          Positioned(bottom: 110, left: -34, child: _BackdropOrb(size: 140, color: Colors.white.withValues(alpha: 0.08))),
          Positioned(top: 180, right: 24, child: _BackdropOrb(size: 90, color: glowColor.withValues(alpha: 0.12))),
        ]),
      ),
    );
  }
}

class _BackdropOrb extends StatelessWidget {
  final double size;
  final Color color;
  const _BackdropOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0.0)]),
        boxShadow: [BoxShadow(color: color, blurRadius: size * 0.38, spreadRadius: size * 0.06)],
      ),
    );
  }
}

class _GameCardShimmer extends StatelessWidget {
  const _GameCardShimmer();
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[800]!, highlightColor: Colors.grey[700]!,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.grey[800]!, Colors.grey[700]!], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 50, height: 50, decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(14))),
          const Spacer(),
          Container(width: double.infinity, height: 17, color: Colors.grey[600]),
          const SizedBox(height: 4),
          Container(width: 100, height: 11, color: Colors.grey[600]),
        ])),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GAMES HUB
// ─────────────────────────────────────────────────────────────────────────────

class GamesHubPage extends StatefulWidget {
  const GamesHubPage({super.key});
  @override
  State<GamesHubPage> createState() => _GamesHubPageState();
}

class _GamesHubPageState extends State<GamesHubPage> {
  late final String _bannerAsset;
  bool _isLoading = true;
  String _selectedCategory = 'All';

  static const List<String> _categories = ['All', 'Puzzle', 'Action', 'Quiz', 'Arcade'];
  static const List<String> _gameIds = [
    'snake', 'memory_match', 'tap_reaction', 'number_guesser',
    'wordle', 'anime_quiz', 'block_blast', 'block_breaker'
  ];

  Map<String, Map<String, dynamic>> _dbStats = {};

  @override
  void initState() {
    super.initState();
    _bannerAsset = _randomO2GameBackground();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final all = await GameProgressDB.instance.loadAll(_gameIds);
    if (!mounted) return;
    setState(() {
      _dbStats = all;
      _isLoading = false;
    });
  }

  int _level(String id) => (_dbStats[id]?['level'] as int?) ?? 1;
  int _best(String id) => (_dbStats[id]?['bestScore'] as int?) ?? 0;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          Navigator.canPop(context)
              ? Navigator.pop(context)
              : Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const ChatHomePage()), (r) => false);
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Stack(children: [
          _GameBackdrop(asset: _bannerAsset, glowColor: Colors.pinkAccent, surfaceTint: Theme.of(context).scaffoldBackgroundColor),
          CustomScrollView(physics: const BouncingScrollPhysics(), slivers: [
            SliverAppBar(
              expandedHeight: 240, collapsedHeight: 240, toolbarHeight: 240,
              floating: false, pinned: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.95),
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8), size: 22),
                onPressed: () => Navigator.canPop(context)
                    ? Navigator.pop(context)
                    : Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const ChatHomePage()), (r) => false),
              ),
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: false,
                titlePadding: const EdgeInsets.fromLTRB(72, 0, 20, 20),
                title: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.pinkAccent.withValues(alpha: 0.2), Colors.purpleAccent.withValues(alpha: 0.15)]),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.3), width: 1),
                    ),
                    child: Text('🎮 ZERO TWO ARCADE', style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                  ),
                  const SizedBox(height: 12),
                  Text('GAME ZONE', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 28, color: Theme.of(context).colorScheme.onSurface, letterSpacing: 2, height: 1.1)),
                  const SizedBox(height: 6),
                  Text('Play with Zero Two, Darling~', style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.w500, height: 1.3)),
                ]),
                background: Stack(fit: StackFit.expand, children: [
                  Image.asset(_bannerAsset, fit: BoxFit.cover, alignment: Alignment.topCenter,
                      errorBuilder: (_, __, ___) => Image.asset(_o2GameFallbackAsset, fit: BoxFit.cover, alignment: Alignment.topCenter)),
                  Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [
                    Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.1),
                    Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8),
                    Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.95),
                  ]))),
                  Positioned(top: -20, right: -15, child: _BackdropOrb(size: 160, color: Colors.pinkAccent.withValues(alpha: 0.18))),
                  Positioned(bottom: -20, left: -15, child: _BackdropOrb(size: 120, color: Colors.cyanAccent.withValues(alpha: 0.12))),
                  Positioned(top: 80, right: 40, child: _BackdropOrb(size: 80, color: Colors.purpleAccent.withValues(alpha: 0.15))),
                ]),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
                        Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
                      ], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Theme.of(context).colorScheme.outline, width: 1),
                      boxShadow: [BoxShadow(color: Colors.pinkAccent.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 8))],
                    ),
                    child: Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          const Icon(Icons.auto_awesome_rounded, color: Colors.pinkAccent, size: 16),
                          const SizedBox(width: 8),
                          Text('ARCADE MOOD', style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2)),
                        ]),
                        const SizedBox(height: 10),
                        Text('Premium Game Hub', style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                        const SizedBox(height: 10),
                        Text('Jump between reflex, puzzle, and quiz modes without losing the Zero Two arcade vibe.',
                            style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface, fontSize: 14, height: 1.5, fontWeight: FontWeight.w500)),
                      ])),
                      const SizedBox(width: 24),
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [Colors.pinkAccent.withValues(alpha: 0.2), Colors.pinkAccent.withValues(alpha: 0.1)]),
                          border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.4), width: 2),
                        ),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.videogame_asset_rounded, color: Colors.pinkAccent, size: 24),
                          const SizedBox(height: 4),
                          Text('8', style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w900)),
                          Text('Games', style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface, fontSize: 10, fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 20),
                  const WaifuCommentary(mood: 'motivated'),
                  const SizedBox(height: 20),
                  Row(children: [
                    Expanded(child: _buildStatCard('Arcade', '4', Icons.flash_on_rounded, Colors.orangeAccent, 'Action Games')),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard('Brain', '2', Icons.psychology_rounded, Colors.cyanAccent, 'Puzzle Games')),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _buildStatCard('Quiz', '1', Icons.quiz_rounded, Colors.pinkAccent, 'Trivia Games')),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard('Classic', '1', Icons.stars_rounded, Colors.lightGreenAccent, 'Retro Games')),
                  ]),
                ]),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('GAME CATEGORIES', style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 2)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 44,
                    child: ListView(scrollDirection: Axis.horizontal, children: _categories.map((cat) {
                      final sel = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Material(color: Colors.transparent, child: InkWell(
                          borderRadius: BorderRadius.circular(22),
                          onTap: () => setState(() => _selectedCategory = cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: sel
                                  ? LinearGradient(colors: [Colors.purpleAccent.withValues(alpha: 0.25), Colors.purpleAccent.withValues(alpha: 0.15)])
                                  : LinearGradient(colors: [Theme.of(context).colorScheme.surface.withValues(alpha: 0.8), Theme.of(context).colorScheme.surface.withValues(alpha: 0.6)]),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: sel ? Colors.purpleAccent.withValues(alpha: 0.4) : Theme.of(context).colorScheme.outline, width: sel ? 1.5 : 1),
                              boxShadow: sel ? [BoxShadow(color: Colors.purpleAccent.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))] : null,
                            ),
                            child: Text(cat.toUpperCase(), style: GoogleFonts.outfit(
                              color: sel ? Colors.white : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                              fontSize: 13, fontWeight: sel ? FontWeight.w700 : FontWeight.w500, letterSpacing: 0.5)),
                          ),
                        )),
                      );
                    }).toList()),
                  ),
                ]),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: _isLoading
                  ? SliverGrid.count(crossAxisCount: 2, mainAxisSpacing: 18, crossAxisSpacing: 18, childAspectRatio: 0.82,
                      children: List.generate(8, (_) => const _GameCardShimmer()))
                  : SliverGrid.count(crossAxisCount: 2, mainAxisSpacing: 18, crossAxisSpacing: 18, childAspectRatio: 0.82, children: [
                      _GameCard(title: 'Snake', subtitle: 'Classic snake — eat, grow, survive',
                        icon: Icons.shuffle_rounded, gradient: const [Color(0xFF00E676), Color(0xFF00897B)],
                        level: _level('snake'), bestScore: _best('snake'),
                        onTap: () => Navigator.push(context, PremiumPageRoute(child: const SnakeGamePage(), style: RouteTransitionStyle.fadeScale))),
                      _GameCard(title: 'Memory Match', subtitle: 'Flip & match the anime pairs',
                        icon: Icons.grid_view_rounded, gradient: const [Color(0xFFFF4081), Color(0xFFAD1457)],
                        level: _level('memory_match'), bestScore: _best('memory_match'),
                        onTap: () => Navigator.push(context, PremiumPageRoute(child: const MemoryMatchPage(), style: RouteTransitionStyle.fadeSlide))),
                      _GameCard(title: 'Tap Reaction', subtitle: 'Test your reflexes!',
                        icon: Icons.touch_app_rounded, gradient: const [Color(0xFFFF9100), Color(0xFFE65100)],
                        level: _level('tap_reaction'), bestScore: _best('tap_reaction'),
                        onTap: () => Navigator.push(context, PremiumPageRoute(child: const TapReactionPage(), style: RouteTransitionStyle.fadeScale))),
                      _GameCard(title: 'Number Guess', subtitle: 'Guess Zero Two\'s secret number',
                        icon: Icons.casino_rounded, gradient: const [Color(0xFF7C4DFF), Color(0xFF4527A0)],
                        level: _level('number_guesser'), bestScore: _best('number_guesser'),
                        onTap: () => Navigator.push(context, PremiumPageRoute(child: const NumberGuesserPage(), style: RouteTransitionStyle.fadeSlide))),
                      _GameCard(title: 'Wordle', subtitle: 'Guess a hidden anime word. Green = right spot, Yellow = wrong spot',
                        icon: Icons.abc_rounded, gradient: const [Color(0xFF26C6DA), Color(0xFF00838F)],
                        level: _level('wordle'), bestScore: _best('wordle'),
                        onTap: () => Navigator.push(context, PremiumPageRoute(child: const WordleGamePage(), style: RouteTransitionStyle.fadeScale))),
                      _GameCard(title: 'Anime Quiz', subtitle: 'Test your anime knowledge!',
                        icon: Icons.quiz_rounded, gradient: const [Color(0xFFEC407A), Color(0xFF880E4F)],
                        level: _level('anime_quiz'), bestScore: _best('anime_quiz'),
                        onTap: () => Navigator.push(context, PremiumPageRoute(child: const AnimeQuizPage(), style: RouteTransitionStyle.fadeSlide))),
                      _GameCard(title: 'Block Blast', subtitle: 'Fill rows to clear the board!',
                        icon: Icons.view_quilt_rounded, gradient: const [Color(0xFFFF6F00), Color(0xFFE65100)],
                        level: _level('block_blast'), bestScore: _best('block_blast'),
                        onTap: () => Navigator.push(context, PremiumPageRoute(child: const BlockBlastPage(), style: RouteTransitionStyle.fadeScale))),
                      _GameCard(title: 'Block Breaker', subtitle: 'Break all bricks with the ball!',
                        icon: Icons.sports_tennis_rounded, gradient: const [Color(0xFF00B0FF), Color(0xFF0D47A1)],
                        level: _level('block_breaker'), bestScore: _best('block_breaker'),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BlockBreakerPage()))),
                    ]),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, String subtitle) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20)),
        const SizedBox(height: 8),
        Text(value, style: GoogleFonts.outfit(color: theme.colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(title, style: GoogleFonts.outfit(color: theme.colorScheme.onSurface, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        const SizedBox(height: 2),
        Text(subtitle, style: GoogleFonts.outfit(color: theme.colorScheme.onSurface, fontSize: 10, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GAME CARD WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class _GameCard extends StatefulWidget {
  final String title, subtitle;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;
  final int level;
  final int bestScore;

  const _GameCard({
    required this.title, required this.subtitle, required this.icon,
    required this.gradient, required this.onTap,
    this.level = 1, this.bestScore = 0,
  });

  @override
  State<_GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<_GameCard> with SingleTickerProviderStateMixin {
  late AnimationController _ac;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
  }

  @override
  void dispose() { _ac.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () { HapticFeedback.lightImpact(); widget.onTap(); },
        splashColor: widget.gradient.first.withValues(alpha: 0.1),
        highlightColor: widget.gradient.first.withValues(alpha: 0.05),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200), curve: Curves.easeOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: widget.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: widget.gradient.last.withValues(alpha: 0.3), width: 1.5),
            boxShadow: [
              BoxShadow(color: widget.gradient.last.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8), spreadRadius: -2),
              BoxShadow(color: widget.gradient.last.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4), spreadRadius: -1),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Stack(children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.white.withValues(alpha: 0.2), Colors.white.withValues(alpha: 0.1)]),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
                    boxShadow: [BoxShadow(color: Colors.white.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: Icon(widget.icon, color: Colors.white, size: 26),
                ),
                // LVL badge
                Positioned(
                  top: -4, right: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Colors.amber, Colors.orangeAccent]),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white, width: 1.5),
                      boxShadow: [BoxShadow(color: Colors.amber.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: Text('LVL ${widget.level}', style: GoogleFonts.outfit(color: Colors.black, fontSize: 8, fontWeight: FontWeight.w900)),
                  ),
                ),
              ]),
              const Spacer(),
              Text(widget.title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              const SizedBox(height: 4),
              Text(widget.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.85), fontSize: 12, height: 1.4, fontWeight: FontWeight.w500)),
              if (widget.bestScore > 0) ...[
                const SizedBox(height: 4),
                Text('🏆 ${widget.bestScore}', style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.75), fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SNAKE GAME — levels + lives + DB
// ─────────────────────────────────────────────────────────────────────────────

class SnakeGamePage extends StatefulWidget {
  const SnakeGamePage({super.key});
  @override
  State<SnakeGamePage> createState() => _SnakeGameState();
}

class _SnakeGameState extends State<SnakeGamePage> {
  static const int cols = 20, rows = 30;
  List<Point<int>> _snake = [];
  Point<int> _food = const Point(10, 15);
  Point<int> _dir = const Point(1, 0);
  Point<int>? _pendingDir;
  Timer? _timer;
  int _score = 0;
  int _lives = 3;
  int _level = 1;
  int _bestScore = 0;
  bool _running = false, _dead = false;
  bool _bgMusicEnabled = true;
  final Random _rng = Random();
  late final String _bgAsset;

  int get _tickMs => max(80, 160 - _level * 8);

  @override
  void initState() {
    super.initState();
    _bgAsset = _randomO2GameBackground();
    _loadDB();
    _resetSnake();
    // Initialize sound service before playing
    _initSound();
  }

  Future<void> _initSound() async {
    await GameSoundsService.instance.initialize();
    if (mounted) {
      await GameSoundsService.instance.playBackgroundMusic('sounds/game_arcade_bgm.ogg');
    }
  }

  Future<void> _loadDB() async {
    final rec = await GameProgressDB.instance.load('snake');
    if (!mounted) return;
    setState(() {
      _level = (rec['level'] as int?) ?? 1;
      _bestScore = (rec['bestScore'] as int?) ?? 0;
    });
  }

  void _resetSnake() {
    _snake = [const Point(10, 10), const Point(9, 10), const Point(8, 10)];
    _dir = const Point(1, 0);
    _pendingDir = null;
    _dead = false;
    _running = false;
    _placeFood();
  }

  void _newGame() {
    _score = 0;
    _lives = 3;
    _level = 1;
    _resetSnake();
  }

  void _startGame() {
    setState(() => _running = true);
    _timer?.cancel();
    _timer = Timer.periodic(Duration(milliseconds: _tickMs), (_) => _tick());
  }

  void _tick() {
    if (!mounted) return;
    if (_pendingDir != null) { _dir = _pendingDir!; _pendingDir = null; }
    if (_snake.isEmpty) return;
    final head = Point(_snake.first.x + _dir.x, _snake.first.y + _dir.y);
    if (head.x < 0 || head.x >= cols || head.y < 0 || head.y >= rows || _snake.any((s) => s == head)) {
      _timer?.cancel();
      _lives--;
      if (_lives <= 0) {
        _saveDB();
        setState(() { _dead = true; _running = false; });
      } else {
        setState(() { _dead = true; _running = false; });
      }
      return;
    }
    setState(() {
      _snake.insert(0, head);
      if (head == _food) {
        _score++;
        _level = max(1, _score ~/ 5 + 1);
        _placeFood();
        // Restart timer with new speed
        _timer?.cancel();
        _timer = Timer.periodic(Duration(milliseconds: _tickMs), (_) => _tick());
      } else {
        _snake.removeLast();
      }
    });
  }

  Future<void> _saveDB() async {
    if (_score > _bestScore) _bestScore = _score;
    await GameProgressDB.instance.save('snake', level: _level, bestScore: _bestScore, totalPlayed: (_bestScore > 0 ? 1 : 0));
  }

  void _placeFood() {
    Point<int> p;
    do { p = Point(_rng.nextInt(cols), _rng.nextInt(rows)); } while (_snake.any((s) => s == p));
    _food = p;
  }

  void _turn(Point<int> newDir) {
    if (newDir.x != -_dir.x || newDir.y != -_dir.y) _pendingDir = newDir;
  }

  @override
  void dispose() {
    _timer?.cancel();
    GameSoundsService.instance.stopBackgroundMusic();
    super.dispose();
  }

  Widget _livesRow() => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
    for (int i = 0; i < 3; i++) Text(i < _lives ? '❤️' : '🖤', style: const TextStyle(fontSize: 18)),
    const SizedBox(width: 12),
    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: Colors.greenAccent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
      child: Text('LVL $_level', style: GoogleFonts.outfit(color: Colors.greenAccent, fontSize: 13, fontWeight: FontWeight.w800))),
    const SizedBox(width: 8),
    Text('🏆 $_bestScore', style: GoogleFonts.outfit(color: Colors.amberAccent, fontSize: 13, fontWeight: FontWeight.w700)),
  ]);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        title: TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: _score), duration: const Duration(milliseconds: 300),
          builder: (_, v, __) => Text('Snake — $v pts', style: GoogleFonts.outfit(color: Colors.greenAccent, fontWeight: FontWeight.w800))),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(icon: const Icon(Icons.music_note_rounded, color: Colors.greenAccent), onPressed: () {
            if (_bgMusicEnabled) GameSoundsService.instance.pauseBackgroundMusic();
            else GameSoundsService.instance.resumeBackgroundMusic();
            setState(() => _bgMusicEnabled = !_bgMusicEnabled);
          }),
        ],
      ),
      body: Stack(children: [
        _GameBackdrop(asset: _bgAsset, glowColor: Colors.greenAccent, surfaceTint: const Color(0xFF060D12)),
        Column(children: [
          Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: _livesRow()),
          Expanded(
            child: GestureDetector(
              onHorizontalDragUpdate: (d) => _turn(d.delta.dx > 0 ? const Point(1, 0) : const Point(-1, 0)),
              onVerticalDragUpdate: (d) => _turn(d.delta.dy > 0 ? const Point(0, 1) : const Point(0, -1)),
              child: Padding(padding: const EdgeInsets.all(12), child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: LayoutBuilder(builder: (_, constraints) {
                  return SizedBox(width: constraints.maxWidth, height: constraints.maxHeight,
                    child: CustomPaint(
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                      painter: _SnakePainter(_snake, _food, cols, rows),
                      child: (_dead || !_running) ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                        if (_dead) Text(_lives <= 0 ? 'Game Over!' : 'Ouch! $_lives lives left', style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 28, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14)),
                          onPressed: () {
                            if (_lives <= 0) { setState(() => _newGame()); }
                            else { setState(() => _resetSnake()); }
                            _startGame();
                          },
                          child: Text(_lives <= 0 ? 'New Game' : (_dead ? 'Try Again' : 'Start'),
                              style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16)),
                        ),
                      ])) : const SizedBox.expand(),
                    ),
                  );
                }),
              )),
            ),
          ),
          Padding(padding: const EdgeInsets.only(bottom: 24), child: Column(children: [
            _dpadBtn(Icons.keyboard_arrow_up_rounded, const Point(0, -1)),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _dpadBtn(Icons.keyboard_arrow_left_rounded, const Point(-1, 0)),
              const SizedBox(width: 56),
              _dpadBtn(Icons.keyboard_arrow_right_rounded, const Point(1, 0)),
            ]),
            _dpadBtn(Icons.keyboard_arrow_down_rounded, const Point(0, 1)),
          ])),
        ]),
      ]),
    );
  }

  Widget _dpadBtn(IconData icon, Point<int> dir) {
    return IconButton(icon: Icon(icon, color: Colors.greenAccent, size: 40), onPressed: () {
      if (!_running && !_dead) _startGame();
      _turn(dir);
    });
  }
}

class _SnakePainter extends CustomPainter {
  final List<Point<int>> snake;
  final Point<int> food;
  final int cols, rows;
  _SnakePainter(this.snake, this.food, this.cols, this.rows);

  @override
  void paint(Canvas canvas, Size size) {
    final cw = size.width / cols, ch = size.height / rows;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = const Color(0xFF0D1F1A));
    canvas.drawCircle(Offset((food.x + 0.5) * cw, (food.y + 0.5) * ch), min(cw, ch) * 0.42, Paint()..color = Colors.redAccent);
    for (int i = 0; i < snake.length; i++) {
      final s = snake[i];
      final t = 1 - (i / snake.length * 0.6);
      final p = Paint()..color = Color.lerp(Colors.greenAccent, Colors.green[900]!, 1 - t)!;
      final r = RRect.fromRectAndRadius(Rect.fromLTWH(s.x * cw + 1, s.y * ch + 1, cw - 2, ch - 2), Radius.circular(min(cw, ch) * 0.3));
      canvas.drawRRect(r, p);
    }
  }

  @override
  bool shouldRepaint(_SnakePainter old) => true;
}

// ─────────────────────────────────────────────────────────────────────────────
// MEMORY MATCH — levels + lives + DB
// ─────────────────────────────────────────────────────────────────────────────

class MemoryMatchPage extends StatefulWidget {
  const MemoryMatchPage({super.key});
  @override
  State<MemoryMatchPage> createState() => _MemoryMatchState();
}

class _MemoryMatchState extends State<MemoryMatchPage> {
  static const _emojis = ['🌸','⚔️','🎌','🦊','🐉','💮','🎴','🌙','⭐','🔥','💎','🎭','🌊','🎵','🍡','🦋'];

  int _level = 1;
  int _lives = 3;
  int _score = 0;
  int _bestScore = 0;
  int _totalPlayed = 0;
  late List<String> _cards;
  late List<bool> _flipped;
  late List<bool> _matched;
  int? _firstIdx;
  bool _locked = false;
  bool _won = false;
  late final String _bgAsset;

  int get _pairCount => min(4 + _level, _emojis.length);

  @override
  void initState() {
    super.initState();
    _bgAsset = _randomO2GameBackground();
    _loadDB();
    _buildBoard();
    GameSoundsService.instance.playBackgroundMusic('sounds/game_puzzle_bgm.ogg');
  }

  Future<void> _loadDB() async {
    final rec = await GameProgressDB.instance.load('memory_match');
    if (!mounted) return;
    setState(() {
      _level = (rec['level'] as int?) ?? 1;
      _bestScore = (rec['bestScore'] as int?) ?? 0;
      _totalPlayed = (rec['totalPlayed'] as int?) ?? 0;
    });
    _buildBoard();
  }

  void _buildBoard() {
    final pool = _emojis.sublist(0, _pairCount);
    _cards = [...pool, ...pool]..shuffle(Random());
    _flipped = List.filled(_cards.length, false);
    _matched = List.filled(_cards.length, false);
    _firstIdx = null;
    _locked = false;
    _won = false;
  }

  void _onTap(int idx) {
    if (_locked || _flipped[idx] || _matched[idx]) return;
    setState(() => _flipped[idx] = true);
    if (_firstIdx == null) {
      _firstIdx = idx;
    } else {
      final a = _firstIdx!;
      _firstIdx = null;
      if (_cards[a] == _cards[idx]) {
        setState(() {
          _matched[a] = true;
          _matched[idx] = true;
          _score += 10 + _level * 2;
        });
        if (_matched.every((m) => m)) {
          _level++;
          _won = true;
          _saveDB();
          setState(() {});
        }
      } else {
        _locked = true;
        Future.delayed(const Duration(milliseconds: 900), () {
          if (!mounted) return;
          setState(() {
            _flipped[a] = false;
            _flipped[idx] = false;
            _locked = false;
            _lives--;
          });
          if (_lives <= 0) { _saveDB(); setState(() {}); }
        });
      }
    }
  }

  Future<void> _saveDB() async {
    _totalPlayed++;
    if (_score > _bestScore) _bestScore = _score;
    await GameProgressDB.instance.save('memory_match', level: _level, bestScore: _bestScore, totalPlayed: _totalPlayed);
  }

  void _restart() {
    setState(() {
      _lives = 3;
      _score = 0;
      _level = 1;
      _buildBoard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cols = _pairCount <= 6 ? 3 : 4;
    final gameOver = _lives <= 0;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: Text('Memory Match — $_score pts', style: GoogleFonts.outfit(color: Colors.pinkAccent, fontWeight: FontWeight.w800)),
      ),
      body: Stack(children: [
        _GameBackdrop(asset: _bgAsset, glowColor: Colors.pinkAccent, surfaceTint: const Color(0xFF120810)),
        Column(children: [
          Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (int i = 0; i < 3; i++) Text(i < _lives ? '❤️' : '🖤', style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 12),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(color: Colors.pinkAccent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
              child: Text('LVL $_level', style: GoogleFonts.outfit(color: Colors.pinkAccent, fontSize: 13, fontWeight: FontWeight.w800))),
            const SizedBox(width: 8),
            Text('🏆 $_bestScore', style: GoogleFonts.outfit(color: Colors.amberAccent, fontSize: 13, fontWeight: FontWeight.w700)),
          ])),
          Expanded(child: (gameOver || _won)
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(_won ? '🎉 Level Complete!' : '💔 Game Over!',
                    style: GoogleFonts.outfit(color: _won ? Colors.greenAccent : Colors.redAccent, fontSize: 28, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text('Score: $_score', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent, foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14)),
                  onPressed: () { if (_won) { setState(() { _lives = 3; _buildBoard(); }); } else { _restart(); } },
                  child: Text(_won ? 'Next Level' : 'Play Again', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16)),
                ),
              ]))
            : Padding(padding: const EdgeInsets.all(16), child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols, mainAxisSpacing: 10, crossAxisSpacing: 10),
                itemCount: _cards.length,
                itemBuilder: (_, i) {
                  final show = _flipped[i] || _matched[i];
                  return GestureDetector(
                    onTap: () => _onTap(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: _matched[i] ? Colors.pinkAccent.withValues(alpha: 0.3)
                            : show ? Colors.white.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _matched[i] ? Colors.pinkAccent : Colors.white.withValues(alpha: 0.2), width: 1.5),
                      ),
                      child: Center(child: Text(show ? _cards[i] : '❓', style: const TextStyle(fontSize: 28))),
                    ),
                  );
                },
              ))),
        ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAP REACTION — levels + lives + DB
// Tap the target as fast as possible. Window shrinks each level.
// ─────────────────────────────────────────────────────────────────────────────

class TapReactionPage extends StatefulWidget {
  const TapReactionPage({super.key});
  @override
  State<TapReactionPage> createState() => _TapReactionState();
}

class _TapReactionState extends State<TapReactionPage> {
  int _level = 1;
  int _lives = 3;
  int _score = 0;
  int _bestScore = 0;
  int _totalPlayed = 0;
  int _round = 0;
  static const int _roundsPerLevel = 5;

  // window in ms: starts 1200ms, shrinks 80ms per level, floor 300ms
  int get _windowMs => max(300, 1200 - (_level - 1) * 80);

  bool _waiting = true;   // waiting for the target to appear
  bool _targetVisible = false;
  bool _tooEarly = false;
  bool _missed = false;
  bool _gameOver = false;
  DateTime? _shownAt;
  int? _lastReactionMs;
  Timer? _waitTimer;
  Timer? _hideTimer;
  late final String _bgAsset;

  @override
  void initState() {
    super.initState();
    _bgAsset = _randomO2GameBackground();
    _loadDB();
    GameSoundsService.instance.playBackgroundMusic('sounds/game_reaction_bgm.ogg');
  }

  Future<void> _loadDB() async {
    final rec = await GameProgressDB.instance.load('tap_reaction');
    if (!mounted) return;
    setState(() {
      _level = (rec['level'] as int?) ?? 1;
      _bestScore = (rec['bestScore'] as int?) ?? 0;
      _totalPlayed = (rec['totalPlayed'] as int?) ?? 0;
    });
  }

  Future<void> _saveDB() async {
    _totalPlayed++;
    if (_score > _bestScore) _bestScore = _score;
    await GameProgressDB.instance.save('tap_reaction', level: _level, bestScore: _bestScore, totalPlayed: _totalPlayed);
  }

  void _startRound() {
    _waitTimer?.cancel();
    _hideTimer?.cancel();
    setState(() { _waiting = true; _targetVisible = false; _tooEarly = false; _missed = false; _lastReactionMs = null; });
    final delay = 1000 + Random().nextInt(2000);
    _waitTimer = Timer(Duration(milliseconds: delay), () {
      if (!mounted) return;
      setState(() { _targetVisible = true; _waiting = false; _shownAt = DateTime.now(); });
      _hideTimer = Timer(Duration(milliseconds: _windowMs), () {
        if (!mounted || !_targetVisible) return;
        setState(() { _targetVisible = false; _missed = true; _lives--; });
        if (_lives <= 0) { _saveDB(); setState(() => _gameOver = true); }
      });
    });
  }

  void _onTap() {
    if (_gameOver) return;
    if (_waiting) {
      _waitTimer?.cancel();
      setState(() { _tooEarly = true; _lives--; });
      if (_lives <= 0) { _saveDB(); setState(() => _gameOver = true); return; }
      Future.delayed(const Duration(milliseconds: 800), _startRound);
      return;
    }
    if (!_targetVisible) return;
    _hideTimer?.cancel();
    final ms = DateTime.now().difference(_shownAt!).inMilliseconds;
    final pts = max(10, 200 - ms ~/ 5 + _level * 5);
    _score += pts;
    _lastReactionMs = ms;
    _round++;
    setState(() { _targetVisible = false; });
    if (_round >= _roundsPerLevel) {
      _level++;
      _round = 0;
      _saveDB();
      Future.delayed(const Duration(milliseconds: 600), _startRound);
    } else {
      Future.delayed(const Duration(milliseconds: 400), _startRound);
    }
  }

  void _restart() {
    _waitTimer?.cancel(); _hideTimer?.cancel();
    setState(() { _level = 1; _lives = 3; _score = 0; _round = 0; _gameOver = false; _targetVisible = false; _waiting = true; _tooEarly = false; _missed = false; _lastReactionMs = null; });
  }

  @override
  void dispose() {
    _waitTimer?.cancel();
    _hideTimer?.cancel();
    GameSoundsService.instance.stopBackgroundMusic();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: Text('Tap Reaction — $_score pts', style: GoogleFonts.outfit(color: Colors.orangeAccent, fontWeight: FontWeight.w800)),
      ),
      body: Stack(children: [
        _GameBackdrop(asset: _bgAsset, glowColor: Colors.orangeAccent, surfaceTint: const Color(0xFF120A00)),
        Column(children: [
          Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (int i = 0; i < 3; i++) Text(i < _lives ? '❤️' : '🖤', style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 12),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(color: Colors.orangeAccent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
              child: Text('LVL $_level  •  ${_windowMs}ms', style: GoogleFonts.outfit(color: Colors.orangeAccent, fontSize: 13, fontWeight: FontWeight.w800))),
            const SizedBox(width: 8),
            Text('🏆 $_bestScore', style: GoogleFonts.outfit(color: Colors.amberAccent, fontSize: 13, fontWeight: FontWeight.w700)),
          ])),
          Expanded(child: _gameOver
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('Game Over!', style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 28, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text('Score: $_score', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14)),
                  onPressed: _restart,
                  child: Text('Play Again', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16)),
                ),
              ]))
            : GestureDetector(
                onTap: _onTap,
                behavior: HitTestBehavior.opaque,
                child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  if (!_targetVisible && _waiting && !_tooEarly && !_missed)
                    Text('Get ready…', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 22, fontWeight: FontWeight.w600)),
                  if (_tooEarly)
                    Text('Too early! 😬', style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 22, fontWeight: FontWeight.w700)),
                  if (_missed)
                    Text('Too slow! 🐢', style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 22, fontWeight: FontWeight.w700)),
                  if (_lastReactionMs != null && !_tooEarly && !_missed)
                    Text('${_lastReactionMs}ms ⚡', style: GoogleFonts.outfit(color: Colors.greenAccent, fontSize: 22, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 40),
                  AnimatedScale(
                    scale: _targetVisible ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 150),
                    child: GestureDetector(
                      onTap: _onTap,
                      child: Container(
                        width: 140, height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const RadialGradient(colors: [Colors.orangeAccent, Colors.deepOrange]),
                          boxShadow: [BoxShadow(color: Colors.orangeAccent.withValues(alpha: 0.6), blurRadius: 40, spreadRadius: 8)],
                        ),
                        child: const Center(child: Text('TAP!', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900))),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  if (!_targetVisible && _waiting && !_tooEarly && !_missed)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14)),
                      onPressed: _startRound,
                      child: Text('Start Round', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16)),
                    ),
                  Text('Round ${_round + 1} / $_roundsPerLevel', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13)),
                ])),
              )),
        ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NUMBER GUESSER — levels + lives + DB
// Range grows with level: level 1 = 1-50, level N = 1-(50+N*50)
// ─────────────────────────────────────────────────────────────────────────────

class NumberGuesserPage extends StatefulWidget {
  const NumberGuesserPage({super.key});
  @override
  State<NumberGuesserPage> createState() => _NumberGuesserState();
}

class _NumberGuesserState extends State<NumberGuesserPage> {
  int _level = 1;
  int _lives = 3;
  int _score = 0;
  int _bestScore = 0;
  int _totalPlayed = 0;
  late int _secret;
  late int _maxNum;
  int _guessesLeft = 0;
  final _ctrl = TextEditingController();
  String _hint = '';
  bool _won = false;
  bool _gameOver = false;
  late final String _bgAsset;

  int get _maxGuesses => max(3, 8 - _level ~/ 2);

  @override
  void initState() {
    super.initState();
    _bgAsset = _randomO2GameBackground();
    _loadDB();
    GameSoundsService.instance.playBackgroundMusic('sounds/game_brain_bgm.ogg');
  }

  Future<void> _loadDB() async {
    final rec = await GameProgressDB.instance.load('number_guesser');
    if (!mounted) return;
    setState(() {
      _level = (rec['level'] as int?) ?? 1;
      _bestScore = (rec['bestScore'] as int?) ?? 0;
      _totalPlayed = (rec['totalPlayed'] as int?) ?? 0;
    });
    _newRound();
  }

  void _newRound() {
    _maxNum = 50 + _level * 50;
    _secret = Random().nextInt(_maxNum) + 1;
    _guessesLeft = _maxGuesses;
    _hint = 'Guess a number between 1 and $_maxNum';
    _won = false;
    _gameOver = false;
    _ctrl.clear();
  }

  Future<void> _saveDB() async {
    _totalPlayed++;
    if (_score > _bestScore) _bestScore = _score;
    await GameProgressDB.instance.save('number_guesser', level: _level, bestScore: _bestScore, totalPlayed: _totalPlayed);
  }

  void _guess() {
    final n = int.tryParse(_ctrl.text.trim());
    if (n == null || n < 1 || n > _maxNum) {
      setState(() => _hint = 'Enter a number between 1 and $_maxNum!');
      return;
    }
    _ctrl.clear();
    _guessesLeft--;
    if (n == _secret) {
      final pts = (_guessesLeft + 1) * 10 + _level * 5;
      _score += pts;
      _level++;
      _won = true;
      _saveDB();
      setState(() => _hint = '🎉 Correct! +$pts pts');
    } else if (_guessesLeft <= 0) {
      _lives--;
      _gameOver = _lives <= 0;
      _saveDB();
      setState(() => _hint = '💔 It was $_secret. ${_gameOver ? "Game Over!" : "$_lives lives left."}');
    } else {
      final diff = (n - _secret).abs();
      final temp = diff < 5 ? '🔥 Burning hot!' : diff < 15 ? '♨️ Warm' : diff < 30 ? '❄️ Cold' : '🧊 Freezing!';
      setState(() => _hint = n < _secret ? '⬆️ Higher! $temp ($_guessesLeft guesses left)' : '⬇️ Lower! $temp ($_guessesLeft guesses left)');
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    GameSoundsService.instance.stopBackgroundMusic();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: Text('Number Guess — $_score pts', style: GoogleFonts.outfit(color: Colors.purpleAccent, fontWeight: FontWeight.w800)),
      ),
      body: Stack(children: [
        _GameBackdrop(asset: _bgAsset, glowColor: Colors.purpleAccent, surfaceTint: const Color(0xFF0D0818)),
        Padding(padding: const EdgeInsets.all(24), child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (int i = 0; i < 3; i++) Text(i < _lives ? '❤️' : '🖤', style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 12),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(color: Colors.purpleAccent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
              child: Text('LVL $_level  •  1–$_maxNum', style: GoogleFonts.outfit(color: Colors.purpleAccent, fontSize: 13, fontWeight: FontWeight.w800))),
            const SizedBox(width: 8),
            Text('🏆 $_bestScore', style: GoogleFonts.outfit(color: Colors.amberAccent, fontSize: 13, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3)),
            ),
            child: Column(children: [
              Text('🎯 Guesses left: $_guessesLeft / $_maxGuesses',
                  style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              Text(_hint, textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, height: 1.4)),
            ]),
          ),
          const SizedBox(height: 32),
          if (!_won && !_gameOver) ...[
            TextField(
              controller: _ctrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
              decoration: InputDecoration(
                hintText: 'Your guess…',
                hintStyle: GoogleFonts.outfit(color: Colors.white38),
                filled: true, fillColor: Colors.white.withValues(alpha: 0.08),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.purpleAccent, width: 2)),
              ),
              onSubmitted: (_) => _guess(),
            ),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 16)),
              onPressed: _guess,
              child: Text('GUESS', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
            )),
          ],
          if (_won || _gameOver) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14)),
              onPressed: () {
                if (_gameOver) setState(() { _lives = 3; _score = 0; _level = 1; _newRound(); });
                else setState(() => _newRound());
              },
              child: Text(_gameOver ? 'New Game' : 'Next Level', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ],
        ])),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WORDLE GAME — levels + lives + DB
// 5-letter anime words. Higher levels = rarer words, fewer guesses.
// ─────────────────────────────────────────────────────────────────────────────

class WordleGamePage extends StatefulWidget {
  const WordleGamePage({super.key});
  @override
  State<WordleGamePage> createState() => _WordleGameState();
}

class _WordleGameState extends State<WordleGamePage> {
  // Tiered word lists: tier 0 = easy, tier 1 = medium, tier 2 = hard
  static const _wordTiers = [
    ['NARUT','GOKUU','LUFFY','ICHIG','MIKAN','SAKUR','HINAB','KAKSH','ITACH','GAARA'],
    ['ZEROT','ASUNA','KIRIT','MIKSA','ERENS','LEVIS','REMUS','EMILI','YUMIS','ARMIN'],
    ['STREL','FRANX','KLAXO','DARLI','SQUAD','PISTL','STAMI','GENST','CHLOR','ARGNT'],
  ];

  int _level = 1;
  int _lives = 3;
  int _score = 0;
  int _bestScore = 0;
  int _totalPlayed = 0;
  late String _secret;
  late List<String> _guesses;
  late List<List<int>> _colors; // 0=grey,1=yellow,2=green
  String _current = '';
  bool _won = false;
  bool _gameOver = false;
  String _msg = '';
  late final String _bgAsset;

  int get _maxGuesses => max(3, 6 - _level ~/ 3);
  int get _tier => min(2, (_level - 1) ~/ 3);

  @override
  void initState() {
    super.initState();
    _bgAsset = _randomO2GameBackground();
    _loadDB();
    GameSoundsService.instance.playBackgroundMusic('sounds/game_brain_bgm.ogg');
  }

  @override
  void dispose() {
    GameSoundsService.instance.stopBackgroundMusic();
    super.dispose();
  }

  Future<void> _loadDB() async {
    final rec = await GameProgressDB.instance.load('wordle');
    if (!mounted) return;
    setState(() {
      _level = (rec['level'] as int?) ?? 1;
      _bestScore = (rec['bestScore'] as int?) ?? 0;
      _totalPlayed = (rec['totalPlayed'] as int?) ?? 0;
    });
    _newRound();
  }

  void _newRound() {
    final pool = _wordTiers[_tier];
    _secret = pool[Random().nextInt(pool.length)];
    _guesses = [];
    _colors = [];
    _current = '';
    _won = false;
    _gameOver = false;
    _msg = '';
  }

  Future<void> _saveDB() async {
    _totalPlayed++;
    if (_score > _bestScore) _bestScore = _score;
    await GameProgressDB.instance.save('wordle', level: _level, bestScore: _bestScore, totalPlayed: _totalPlayed);
  }

  void _key(String ch) {
    if (_won || _gameOver || _current.length >= 5) return;
    setState(() => _current += ch);
  }

  void _del() {
    if (_current.isEmpty) return;
    setState(() => _current = _current.substring(0, _current.length - 1));
  }

  void _submit() {
    if (_current.length < 5) { setState(() => _msg = 'Need 5 letters!'); return; }
    final guess = _current;
    final row = List.filled(5, 0);
    final secretChars = _secret.split('');
    final used = List.filled(5, false);
    // greens
    for (int i = 0; i < 5; i++) {
      if (guess[i] == secretChars[i]) { row[i] = 2; used[i] = true; }
    }
    // yellows
    for (int i = 0; i < 5; i++) {
      if (row[i] == 2) continue;
      for (int j = 0; j < 5; j++) {
        if (!used[j] && guess[i] == secretChars[j]) { row[i] = 1; used[j] = true; break; }
      }
    }
    setState(() {
      _guesses.add(guess);
      _colors.add(row);
      _current = '';
      _msg = '';
    });
    if (guess == _secret) {
      final pts = (_maxGuesses - _guesses.length + 1) * 20 + _level * 10;
      _score += pts;
      _level++;
      _won = true;
      _saveDB();
      setState(() => _msg = '🎉 Correct! +$pts pts');
    } else if (_guesses.length >= _maxGuesses) {
      _lives--;
      _gameOver = _lives <= 0;
      _saveDB();
      setState(() => _msg = '💔 It was $_secret');
    }
  }

  static const _rows = ['QWERTYUIOP', 'ASDFGHJKL', 'ZXCVBNM'];

  Color _tileColor(int c) => c == 2 ? Colors.green : c == 1 ? Colors.amber : Colors.white24;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: Text('Wordle — $_score pts', style: GoogleFonts.outfit(color: Colors.cyanAccent, fontWeight: FontWeight.w800)),
      ),
      body: Stack(children: [
        _GameBackdrop(asset: _bgAsset, glowColor: Colors.cyanAccent, surfaceTint: const Color(0xFF001418)),
        Column(children: [
          Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (int i = 0; i < 3; i++) Text(i < _lives ? '❤️' : '🖤', style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 12),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(color: Colors.cyanAccent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
              child: Text('LVL $_level  •  $_maxGuesses tries', style: GoogleFonts.outfit(color: Colors.cyanAccent, fontSize: 13, fontWeight: FontWeight.w800))),
            const SizedBox(width: 8),
            Text('🏆 $_bestScore', style: GoogleFonts.outfit(color: Colors.amberAccent, fontSize: 13, fontWeight: FontWeight.w700)),
          ])),
          if (_msg.isNotEmpty)
            Padding(padding: const EdgeInsets.only(bottom: 4),
              child: Text(_msg, style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700))),
          // Grid
          Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            for (int r = 0; r < _maxGuesses; r++)
              Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(mainAxisSize: MainAxisSize.min, children: [
                for (int c = 0; c < 5; c++) ...[
                  Container(
                    width: 48, height: 48,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: r < _guesses.length ? _tileColor(_colors[r][c]) : Colors.white.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: r == _guesses.length && c < _current.length
                          ? Colors.cyanAccent : Colors.white24, width: 1.5),
                    ),
                    child: Center(child: Text(
                      r < _guesses.length ? _guesses[r][c]
                          : (r == _guesses.length && c < _current.length ? _current[c] : ''),
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                    )),
                  ),
                ],
              ])),
          ]))),
          // Keyboard
          if (!_won && !_gameOver)
            Padding(padding: const EdgeInsets.fromLTRB(8, 0, 8, 16), child: Column(children: [
              for (final row in _rows)
                Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  for (final ch in row.split(''))
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: SizedBox(
                      width: 30, height: 40,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.12), foregroundColor: Colors.white,
                          padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                        onPressed: () => _key(ch),
                        child: Text(ch, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700)),
                      ),
                    )),
                  if (row == 'ZXCVBNM') ...[
                    const SizedBox(width: 4),
                    SizedBox(width: 44, height: 40, child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.withValues(alpha: 0.3), foregroundColor: Colors.white,
                          padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                      onPressed: _del,
                      child: const Icon(Icons.backspace_rounded, size: 16),
                    )),
                    const SizedBox(width: 4),
                    SizedBox(width: 52, height: 40, child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent.withValues(alpha: 0.3), foregroundColor: Colors.white,
                          padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                      onPressed: _submit,
                      child: Text('GO', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w900)),
                    )),
                  ],
                ])),
            ])),
          if (_won || _gameOver)
            Padding(padding: const EdgeInsets.only(bottom: 24), child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14)),
              onPressed: () {
                if (_gameOver) setState(() { _lives = 3; _score = 0; _level = 1; _newRound(); });
                else setState(() => _newRound());
              },
              child: Text(_gameOver ? 'New Game' : 'Next Level', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16)),
            )),
        ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ANIME QUIZ — levels + lives + DB
// Timed MCQ. Timer shrinks per level. Harder questions at higher levels.
// ─────────────────────────────────────────────────────────────────────────────

class AnimeQuizPage extends StatefulWidget {
  const AnimeQuizPage({super.key});
  @override
  State<AnimeQuizPage> createState() => _AnimeQuizState();
}

class _AnimeQuizState extends State<AnimeQuizPage> {
  int _level = 1;
  int _lives = 3;
  int _score = 0;
  int _bestScore = 0;
  int _totalPlayed = 0;
  int _timeLeft = 0;
  Timer? _timer;
  int? _selected;
  bool _answered = false;
  bool _gameOver = false;
  bool _loading = false;
  String _error = '';
  late final String _bgAsset;

  // Current question from API
  String _question = '';
  List<String> _opts = [];
  int _correctIdx = 0;

  int get _timerSecs => max(5, 15 - _level);
  String get _difficulty => _level <= 4 ? 'easy' : _level <= 8 ? 'medium' : 'hard';

  @override
  void initState() {
    super.initState();
    _bgAsset = _randomO2GameBackground();
    _loadDB();
    GameSoundsService.instance.playBackgroundMusic('sounds/game_brain_bgm.ogg');
  }

  Future<void> _loadDB() async {
    final rec = await GameProgressDB.instance.load('anime_quiz');
    if (!mounted) return;
    setState(() {
      _level = (rec['level'] as int?) ?? 1;
      _bestScore = (rec['bestScore'] as int?) ?? 0;
      _totalPlayed = (rec['totalPlayed'] as int?) ?? 0;
    });
    _fetchQuestion();
  }

  Future<void> _saveDB() async {
    _totalPlayed++;
    if (_score > _bestScore) _bestScore = _score;
    await GameProgressDB.instance.save('anime_quiz', level: _level, bestScore: _bestScore, totalPlayed: _totalPlayed);
  }

  /// Calls the LLM to generate a fresh anime trivia question.
  Future<void> _fetchQuestion() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = ''; _answered = false; _selected = null; });
    _timer?.cancel();

    try {
      final apiKey = dotenv.env['API_KEY'] ?? '';
      if (apiKey.isEmpty) throw Exception('No API key');

      final prompt = '''Generate one anime trivia question at $_difficulty difficulty (level $_level).
Respond with ONLY valid JSON, no markdown, no extra text:
{"q":"question text","a":"correct answer","opts":["opt1","opt2","opt3","opt4"]}
Rules: exactly 4 options, correct answer must be one of the options, no duplicate options.''';

      final res = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {'Authorization': 'Bearer $apiKey', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': 'meta-llama/llama-4-scout-17b-16e-instruct',
          'messages': [{'role': 'user', 'content': prompt}],
          'max_tokens': 200,
          'temperature': 0.9,
        }),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final raw = (data['choices'][0]['message']['content'] as String).trim();
      // Strip any accidental markdown fences
      final clean = raw.replaceAll(RegExp(r'```[a-z]*\n?'), '').replaceAll('```', '').trim();
      final q = jsonDecode(clean) as Map<String, dynamic>;

      final opts = List<String>.from(q['opts'] as List);
      final correct = q['a'] as String;
      final ci = opts.indexOf(correct);
      if (ci == -1) throw Exception('Answer not in options');

      if (!mounted) return;
      setState(() {
        _question = q['q'] as String;
        _opts = opts;
        _correctIdx = ci;
        _loading = false;
      });
      _startTimer();
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Failed to load question. Tap retry.'; });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timeLeft = _timerSecs;
    setState(() {});
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _timeLeft--;
      if (_timeLeft <= 0) {
        _timer?.cancel();
        _lives--;
        _answered = true;
        if (_lives <= 0) { _saveDB(); setState(() => _gameOver = true); return; }
        setState(() {});
        Future.delayed(const Duration(milliseconds: 1200), _fetchQuestion);
      } else {
        setState(() {});
      }
    });
  }

  void _answer(int idx) {
    if (_answered || _loading) return;
    _timer?.cancel();
    _selected = idx;
    _answered = true;
    if (idx == _correctIdx) {
      final pts = _timeLeft * 5 + _level * 10;
      _score += pts;
      _level++;
      _saveDB();
    } else {
      _lives--;
      if (_lives <= 0) { _saveDB(); setState(() => _gameOver = true); return; }
    }
    setState(() {});
    Future.delayed(const Duration(milliseconds: 1200), _fetchQuestion);
  }

  void _restart() {
    _timer?.cancel();
    setState(() { _level = 1; _lives = 3; _score = 0; _gameOver = false; });
    _fetchQuestion();
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white), onPressed: () { _timer?.cancel(); Navigator.pop(context); }),
        title: Text('Anime Quiz — $_score pts', style: GoogleFonts.outfit(color: Colors.pinkAccent, fontWeight: FontWeight.w800)),
      ),
      body: Stack(children: [
        _GameBackdrop(asset: _bgAsset, glowColor: Colors.pinkAccent, surfaceTint: const Color(0xFF120010)),
        _gameOver
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('Game Over!', style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 28, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text('Score: $_score', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14)),
                onPressed: _restart,
                child: Text('Play Again', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ]))
          : Padding(padding: const EdgeInsets.all(20), child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (int i = 0; i < 3; i++) Text(i < _lives ? '❤️' : '🖤', style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 12),
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(color: Colors.pinkAccent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                  child: Text('LVL $_level • $_difficulty', style: GoogleFonts.outfit(color: Colors.pinkAccent, fontSize: 13, fontWeight: FontWeight.w800))),
                const SizedBox(width: 8),
                Text('🏆 $_bestScore', style: GoogleFonts.outfit(color: Colors.amberAccent, fontSize: 13, fontWeight: FontWeight.w700)),
                const Spacer(),
                if (!_loading && _error.isEmpty)
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _timeLeft <= 5 ? Colors.redAccent.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.1),
                      border: Border.all(color: _timeLeft <= 5 ? Colors.redAccent : Colors.white38, width: 2),
                    ),
                    child: Center(child: Text('$_timeLeft', style: GoogleFonts.outfit(color: _timeLeft <= 5 ? Colors.redAccent : Colors.white, fontSize: 16, fontWeight: FontWeight.w900))),
                  ),
              ]),
              const SizedBox(height: 24),
              if (_loading)
                Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const CircularProgressIndicator(color: Colors.pinkAccent),
                  const SizedBox(height: 16),
                  Text('Zero Two is thinking of a question…', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14)),
                ])))
              else if (_error.isNotEmpty)
                Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_error, textAlign: TextAlign.center, style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 15)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent, foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    onPressed: _fetchQuestion,
                    child: Text('Retry', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
                  ),
                ])))
              else ...[
                Container(
                  width: double.infinity, padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.3)),
                  ),
                  child: Text(_question, textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, height: 1.4)),
                ),
                const SizedBox(height: 24),
                ...List.generate(_opts.length, (i) {
                  Color bg = Colors.white.withValues(alpha: 0.08);
                  Color border = Colors.white24;
                  if (_answered) {
                    if (i == _correctIdx) { bg = Colors.green.withValues(alpha: 0.3); border = Colors.greenAccent; }
                    else if (i == _selected) { bg = Colors.red.withValues(alpha: 0.3); border = Colors.redAccent; }
                  }
                  return Padding(padding: const EdgeInsets.only(bottom: 12), child: GestureDetector(
                    onTap: () => _answer(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: double.infinity, padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: border, width: 1.5)),
                      child: Text(_opts[i], style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ));
                }),
              ],
            ])),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BLOCK BLAST — drag-and-drop with ghost preview, levels + lives + DB
// ─────────────────────────────────────────────────────────────────────────────

class BlockBlastPage extends StatefulWidget {
  const BlockBlastPage({super.key});
  @override
  State<BlockBlastPage> createState() => _BlockBlastState();
}

class _BlockBlastState extends State<BlockBlastPage> {
  static const int _cols = 8, _rows = 8;
  static const double _cellSize = 38.0;

  static const _shapes = [
    [[0,0],[0,1],[0,2]],
    [[0,0],[1,0],[2,0]],
    [[0,0],[0,1],[1,0],[1,1]],
    [[0,0],[0,1],[0,2],[1,0]],
    [[0,0],[0,1],[0,2],[1,2]],
    [[0,0],[1,0],[1,1],[2,1]],
    [[0,1],[1,0],[1,1],[2,0]],
    [[0,0],[0,1]],
    [[0,0],[1,0]],
    [[0,0]],
  ];

  static const _pieceColors = [
    Color(0xFFFF6F00), Color(0xFF00B0FF), Color(0xFFAB47BC),
    Color(0xFF26C6DA), Color(0xFFEC407A), Color(0xFF66BB6A),
    Color(0xFFFFCA28), Color(0xFFEF5350),
  ];

  int _level = 1, _lives = 3, _score = 0, _bestScore = 0, _totalPlayed = 0;
  bool _gameOver = false;
  late final String _bgAsset;
  late List<List<int>> _grid;
  late List<List<List<int>>> _pieces;
  late List<Color> _pieceColorList;

  // Ghost preview state
  int? _hoverPiece;
  int _ghostRow = 0, _ghostCol = 0;
  bool _ghostValid = false;

  // Board GlobalKey to convert drag offsets to grid coords
  final _boardKey = GlobalKey();

  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _bgAsset = _randomO2GameBackground();
    _loadDB();
    GameSoundsService.instance.playBackgroundMusic('sounds/game_puzzle_bgm.ogg');
  }

  @override
  void dispose() {
    GameSoundsService.instance.stopBackgroundMusic();
    super.dispose();
  }

  Future<void> _loadDB() async {
    final rec = await GameProgressDB.instance.load('block_blast');
    if (!mounted) return;
    setState(() {
      _level = (rec['level'] as int?) ?? 1;
      _bestScore = (rec['bestScore'] as int?) ?? 0;
      _totalPlayed = (rec['totalPlayed'] as int?) ?? 0;
    });
    _newGame();
  }

  Future<void> _saveDB() async {
    _totalPlayed++;
    if (_score > _bestScore) _bestScore = _score;
    await GameProgressDB.instance.save('block_blast', level: _level, bestScore: _bestScore, totalPlayed: _totalPlayed);
  }

  void _newGame() {
    _grid = List.generate(_rows, (_) => List.filled(_cols, -1));
    final prefill = min((_level - 1) * 3, 20);
    for (int i = 0; i < prefill; i++) {
      _grid[_rng.nextInt(_rows)][_rng.nextInt(_cols)] = _rng.nextInt(_pieceColors.length);
    }
    _spawnPieces();
    _gameOver = false;
  }

  void _spawnPieces() {
    _pieces = List.generate(3, (_) => _shapes[_rng.nextInt(_shapes.length)].map((r) => List<int>.from(r)).toList());
    _pieceColorList = List.generate(3, (_) => _pieceColors[_rng.nextInt(_pieceColors.length)]);
    _hoverPiece = null;
    if (!_canPlaceAny()) {
      _lives--;
      if (_lives <= 0) { _saveDB(); setState(() => _gameOver = true); return; }
      _spawnPieces();
    }
  }

  bool _canPlaceAny() {
    for (int p = 0; p < _pieces.length; p++) {
      if (_pieces[p].isEmpty) continue;
      for (int r = 0; r < _rows; r++) {
        for (int c = 0; c < _cols; c++) {
          if (_fits(_pieces[p], r, c)) return true;
        }
      }
    }
    return false;
  }

  bool _fits(List<List<int>> shape, int row, int col) {
    for (final cell in shape) {
      final r = row + cell[0], c = col + cell[1];
      if (r < 0 || r >= _rows || c < 0 || c >= _cols || _grid[r][c] != -1) return false;
    }
    return true;
  }

  void _place(int pieceIdx, int row, int col) {
    if (!_fits(_pieces[pieceIdx], row, col)) return;
    final colorIdx = _pieceColors.indexOf(_pieceColorList[pieceIdx]);
    for (final cell in _pieces[pieceIdx]) {
      _grid[row + cell[0]][col + cell[1]] = colorIdx;
    }
    _pieces[pieceIdx] = [];
    _clearLines();
    _score += 10 + _level * 2;
    if (_pieces.every((p) => p.isEmpty)) {
      _level++;
      _saveDB();
      _spawnPieces();
    }
    setState(() {});
  }

  void _clearLines() {
    int cleared = 0;
    for (int r = 0; r < _rows; r++) {
      if (_grid[r].every((c) => c != -1)) { _grid[r] = List.filled(_cols, -1); cleared++; }
    }
    for (int c = 0; c < _cols; c++) {
      if (List.generate(_rows, (r) => _grid[r][c]).every((v) => v != -1)) {
        for (int r = 0; r < _rows; r++) { _grid[r][c] = -1; }
        cleared++;
      }
    }
    if (cleared > 0) _score += cleared * 50 + cleared * cleared * 10;
  }

  /// Convert a global drag position to grid [row, col], anchored to piece top-left.
  (int, int) _globalToGrid(Offset global) {
    final box = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return (0, 0);
    final local = box.globalToLocal(global);
    final col = (local.dx / _cellSize).floor();
    final row = (local.dy / _cellSize).floor();
    return (row, col);
  }

  void _onDragUpdate(int pieceIdx, Offset global) {
    final (row, col) = _globalToGrid(global);
    final valid = _fits(_pieces[pieceIdx], row, col);
    setState(() { _hoverPiece = pieceIdx; _ghostRow = row; _ghostCol = col; _ghostValid = valid; });
  }

  void _onDragEnd(int pieceIdx, Offset global) {
    final (row, col) = _globalToGrid(global);
    if (_fits(_pieces[pieceIdx], row, col)) {
      _place(pieceIdx, row, col);
    }
    setState(() { _hoverPiece = null; });
  }

  Widget _buildPieceWidget(int pi, {double cellSize = 28.0}) {
    if (_pieces[pi].isEmpty) return const SizedBox(width: 80, height: 80);
    final shape = _pieces[pi];
    final maxR = shape.map((c) => c[0]).reduce(max) + 1;
    final maxC = shape.map((c) => c[1]).reduce(max) + 1;
    return SizedBox(
      width: maxC * cellSize,
      height: maxR * cellSize,
      child: Stack(children: shape.map((cell) => Positioned(
        left: cell[1] * cellSize,
        top: cell[0] * cellSize,
        child: Container(
          width: cellSize - 2, height: cellSize - 2,
          decoration: BoxDecoration(
            color: _pieceColorList[pi],
            borderRadius: BorderRadius.circular(4),
            boxShadow: [BoxShadow(color: _pieceColorList[pi].withValues(alpha: 0.5), blurRadius: 6, offset: const Offset(0, 2))],
          ),
        ),
      )).toList()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const boardSize = _cellSize * _cols;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: Text('Block Blast — $_score pts', style: GoogleFonts.outfit(color: Colors.orangeAccent, fontWeight: FontWeight.w800)),
      ),
      body: Stack(children: [
        _GameBackdrop(asset: _bgAsset, glowColor: Colors.orangeAccent, surfaceTint: const Color(0xFF120800)),
        _gameOver
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('Game Over!', style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 28, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text('Score: $_score', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14)),
                onPressed: () => setState(() { _lives = 3; _score = 0; _level = 1; _newGame(); }),
                child: Text('Play Again', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ]))
          : Column(children: [
              Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (int i = 0; i < 3; i++) Text(i < _lives ? '❤️' : '🖤', style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 12),
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(color: Colors.orangeAccent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                  child: Text('LVL $_level', style: GoogleFonts.outfit(color: Colors.orangeAccent, fontSize: 13, fontWeight: FontWeight.w800))),
                const SizedBox(width: 8),
                Text('🏆 $_bestScore', style: GoogleFonts.outfit(color: Colors.amberAccent, fontSize: 13, fontWeight: FontWeight.w700)),
              ])),
              // Board
              Center(child: Container(
                key: _boardKey,
                width: boardSize, height: boardSize,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: Stack(children: [
                  // Grid cells
                  Column(mainAxisSize: MainAxisSize.min, children: List.generate(_rows, (r) =>
                    Row(mainAxisSize: MainAxisSize.min, children: List.generate(_cols, (c) {
                      final colorIdx = _grid[r][c];
                      // Ghost preview
                      bool isGhost = false;
                      bool ghostOk = false;
                      if (_hoverPiece != null) {
                        for (final cell in _pieces[_hoverPiece!]) {
                          if (_ghostRow + cell[0] == r && _ghostCol + cell[1] == c) {
                            isGhost = true;
                            ghostOk = _ghostValid;
                            break;
                          }
                        }
                      }
                      return Container(
                        width: _cellSize, height: _cellSize,
                        margin: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color: isGhost
                              ? (ghostOk ? _pieceColorList[_hoverPiece!].withValues(alpha: 0.55) : Colors.redAccent.withValues(alpha: 0.35))
                              : colorIdx >= 0 ? _pieceColors[colorIdx] : Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isGhost ? (ghostOk ? _pieceColorList[_hoverPiece!] : Colors.redAccent) : Colors.white.withValues(alpha: 0.08),
                            width: isGhost ? 1.5 : 0.5,
                          ),
                        ),
                      );
                    })),
                  )),
                ]),
              )),
              const SizedBox(height: 20),
              // Piece tray — each piece is a Draggable
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: List.generate(3, (pi) {
                if (_pieces[pi].isEmpty) return const SizedBox(width: 80, height: 80);
                return Draggable<int>(
                  data: pi,
                  onDragUpdate: (d) => _onDragUpdate(pi, d.globalPosition),
                  onDragEnd: (d) => _onDragEnd(pi, d.offset),
                  onDraggableCanceled: (_, __) => setState(() => _hoverPiece = null),
                  feedback: Opacity(opacity: 0.85, child: _buildPieceWidget(pi, cellSize: _cellSize)),
                  childWhenDragging: Opacity(opacity: 0.25, child: _buildPieceWidget(pi)),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _pieceColorList[pi].withValues(alpha: 0.4), width: 1.5),
                    ),
                    child: _buildPieceWidget(pi),
                  ),
                );
              })),
              const SizedBox(height: 12),
              Text('Drag pieces onto the board', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11)),
              const SizedBox(height: 16),
            ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BLOCK BREAKER — levels + lives + DB
// Classic Breakout. Ball speed and brick rows increase with level.
// ─────────────────────────────────────────────────────────────────────────────

class BlockBreakerPage extends StatefulWidget {
  const BlockBreakerPage({super.key});
  @override
  State<BlockBreakerPage> createState() => _BlockBreakerState();
}

class _BlockBreakerState extends State<BlockBreakerPage> with SingleTickerProviderStateMixin {
  static const int _brickCols = 7;
  static const double _paddleW = 80, _paddleH = 12, _ballR = 8;

  int _level = 1;
  int _lives = 3;
  int _score = 0;
  int _bestScore = 0;
  int _totalPlayed = 0;
  bool _running = false;
  bool _gameOver = false;
  bool _won = false;
  late final String _bgAsset;

  // Game state (in logical units, mapped to screen in paint)
  double _pw = 300, _ph = 500; // play area size, set in layout
  double _paddleX = 110;
  double _ballX = 150, _ballY = 400;
  double _vx = 3, _vy = -4;
  late List<List<bool>> _bricks;
  late List<List<Color>> _brickColors;
  int _brickRows = 3;

  late AnimationController _ac;

  static const _rowColors = [
    Color(0xFFEF5350), Color(0xFFFF9800), Color(0xFFFFEB3B),
    Color(0xFF66BB6A), Color(0xFF42A5F5), Color(0xFFAB47BC),
  ];

  double get _ballSpeed => 3.5 + _level * 0.4;

  @override
  void initState() {
    super.initState();
    _bgAsset = _randomO2GameBackground();
    _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 16))
      ..addListener(_tick)
      ..repeat();
    _loadDB();
    GameSoundsService.instance.playBackgroundMusic('sounds/game_arcade_bgm.ogg');
  }

  Future<void> _loadDB() async {
    final rec = await GameProgressDB.instance.load('block_breaker');
    if (!mounted) return;
    setState(() {
      _level = (rec['level'] as int?) ?? 1;
      _bestScore = (rec['bestScore'] as int?) ?? 0;
      _totalPlayed = (rec['totalPlayed'] as int?) ?? 0;
    });
    _buildLevel();
  }

  Future<void> _saveDB() async {
    _totalPlayed++;
    if (_score > _bestScore) _bestScore = _score;
    await GameProgressDB.instance.save('block_breaker', level: _level, bestScore: _bestScore, totalPlayed: _totalPlayed);
  }

  void _buildLevel() {
    _brickRows = min(2 + _level, 6);
    _bricks = List.generate(_brickRows, (_) => List.filled(_brickCols, true));
    _brickColors = List.generate(_brickRows, (r) => List.filled(_brickCols, _rowColors[r % _rowColors.length]));
    _resetBall();
    _won = false;
    _running = false;
  }

  void _resetBall() {
    _ballX = _pw / 2;
    _ballY = _ph * 0.75;
    _paddleX = _pw / 2 - _paddleW / 2;
    final angle = (Random().nextDouble() * 60 - 30) * (pi / 180);
    _vx = _ballSpeed * sin(angle);
    _vy = -_ballSpeed * cos(angle).abs();
  }

  void _tick() {
    if (!_running || _gameOver || _won) return;
    setState(() {
      _ballX += _vx;
      _ballY += _vy;

      // Wall bounces
      if (_ballX - _ballR <= 0) { _ballX = _ballR; _vx = _vx.abs(); }
      if (_ballX + _ballR >= _pw) { _ballX = _pw - _ballR; _vx = -_vx.abs(); }
      if (_ballY - _ballR <= 0) { _ballY = _ballR; _vy = _vy.abs(); }

      // Paddle bounce
      if (_ballY + _ballR >= _ph - _paddleH - 10 &&
          _ballX >= _paddleX && _ballX <= _paddleX + _paddleW &&
          _vy > 0) {
        final rel = (_ballX - (_paddleX + _paddleW / 2)) / (_paddleW / 2);
        _vx = rel * _ballSpeed * 1.2;
        _vy = -_ballSpeed;
        _ballY = _ph - _paddleH - 10 - _ballR;
      }

      // Ball lost
      if (_ballY - _ballR > _ph) {
        _lives--;
        if (_lives <= 0) { _saveDB(); _gameOver = true; _running = false; return; }
        _resetBall();
        _running = false;
      }

      // Brick collision
      final brickW = _pw / _brickCols;
      const brickH = 22.0, brickTop = 60.0;
      for (int r = 0; r < _brickRows; r++) {
        for (int c = 0; c < _brickCols; c++) {
          if (!_bricks[r][c]) continue;
          final bx = c * brickW, by = brickTop + r * (brickH + 4);
          if (_ballX + _ballR > bx && _ballX - _ballR < bx + brickW &&
              _ballY + _ballR > by && _ballY - _ballR < by + brickH) {
            _bricks[r][c] = false;
            _score += 10 + _level * 3;
            // Determine bounce direction
            final overlapLeft = (_ballX + _ballR) - bx;
            final overlapRight = (bx + brickW) - (_ballX - _ballR);
            final overlapTop = (_ballY + _ballR) - by;
            final overlapBottom = (by + brickH) - (_ballY - _ballR);
            final minH = min(overlapLeft, overlapRight);
            final minV = min(overlapTop, overlapBottom);
            if (minH < minV) _vx = -_vx; else _vy = -_vy;
          }
        }
      }

      // Check win
      if (_bricks.every((row) => row.every((b) => !b))) {
        _level++;
        _won = true;
        _running = false;
        _saveDB();
      }
    });
  }

  void _movePaddle(double dx) {
    setState(() {
      _paddleX = (_paddleX + dx).clamp(0, _pw - _paddleW);
    });
  }

  @override
  void dispose() {
    _ac.dispose();
    GameSoundsService.instance.stopBackgroundMusic();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: Text('Block Breaker — $_score pts', style: GoogleFonts.outfit(color: Colors.cyanAccent, fontWeight: FontWeight.w800)),
      ),
      body: Stack(children: [
        _GameBackdrop(asset: _bgAsset, glowColor: Colors.cyanAccent, surfaceTint: const Color(0xFF001420)),
        Column(children: [
          Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (int i = 0; i < 3; i++) Text(i < _lives ? '❤️' : '🖤', style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 12),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(color: Colors.cyanAccent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
              child: Text('LVL $_level', style: GoogleFonts.outfit(color: Colors.cyanAccent, fontSize: 13, fontWeight: FontWeight.w800))),
            const SizedBox(width: 8),
            Text('🏆 $_bestScore', style: GoogleFonts.outfit(color: Colors.amberAccent, fontSize: 13, fontWeight: FontWeight.w700)),
          ])),
          Expanded(child: LayoutBuilder(builder: (_, constraints) {
            _pw = constraints.maxWidth;
            _ph = constraints.maxHeight;
            return GestureDetector(
              onHorizontalDragUpdate: (d) { _movePaddle(d.delta.dx); if (!_running && !_gameOver && !_won) { _running = true; } },
              onTapDown: (_) { if (!_running && !_gameOver && !_won) setState(() => _running = true); },
              child: CustomPaint(
                size: Size(_pw, _ph),
                painter: _BreakerPainter(
                  pw: _pw, ph: _ph,
                  paddleX: _paddleX, paddleW: _paddleW, paddleH: _paddleH,
                  ballX: _ballX, ballY: _ballY, ballR: _ballR,
                  bricks: _bricks, brickColors: _brickColors,
                  brickCols: _brickCols, brickRows: _brickRows,
                ),
                child: (_gameOver || _won || !_running)
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      if (_gameOver) Text('Game Over!', style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 28, fontWeight: FontWeight.w900)),
                      if (_won) Text('Level Clear! 🎉', style: GoogleFonts.outfit(color: Colors.greenAccent, fontSize: 28, fontWeight: FontWeight.w900)),
                      if (!_running && !_gameOver && !_won) Text('Tap to Start', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 22, fontWeight: FontWeight.w700)),
                      if (_gameOver || _won) ...[
                        const SizedBox(height: 8),
                        Text('Score: $_score', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14)),
                          onPressed: () {
                            if (_gameOver) setState(() { _lives = 3; _score = 0; _level = 1; _buildLevel(); });
                            else setState(() => _buildLevel());
                          },
                          child: Text(_gameOver ? 'New Game' : 'Next Level', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16)),
                        ),
                      ],
                    ]))
                  : const SizedBox.expand(),
              ),
            );
          })),
        ]),
      ]),
    );
  }
}

class _BreakerPainter extends CustomPainter {
  final double pw, ph, paddleX, paddleW, paddleH, ballX, ballY, ballR;
  final List<List<bool>> bricks;
  final List<List<Color>> brickColors;
  final int brickCols, brickRows;

  const _BreakerPainter({
    required this.pw, required this.ph,
    required this.paddleX, required this.paddleW, required this.paddleH,
    required this.ballX, required this.ballY, required this.ballR,
    required this.bricks, required this.brickColors,
    required this.brickCols, required this.brickRows,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final brickW = pw / brickCols;
    const brickH = 22.0, brickTop = 60.0;

    // Bricks
    for (int r = 0; r < brickRows; r++) {
      for (int c = 0; c < brickCols; c++) {
        if (!bricks[r][c]) continue;
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(c * brickW + 2, brickTop + r * (brickH + 4), brickW - 4, brickH),
          const Radius.circular(6),
        );
        canvas.drawRRect(rect, Paint()..color = brickColors[r][c]);
        canvas.drawRRect(rect, Paint()..color = Colors.white.withValues(alpha: 0.15)..style = PaintingStyle.stroke..strokeWidth = 1);
      }
    }

    // Paddle
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(paddleX, ph - paddleH - 10, paddleW, paddleH), const Radius.circular(8)),
      Paint()..shader = const LinearGradient(colors: [Colors.cyanAccent, Colors.blueAccent])
          .createShader(Rect.fromLTWH(paddleX, ph - paddleH - 10, paddleW, paddleH)),
    );

    // Ball
    canvas.drawCircle(Offset(ballX, ballY), ballR,
        Paint()..color = Colors.white..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    canvas.drawCircle(Offset(ballX, ballY), ballR, Paint()..color = Colors.cyanAccent);
  }

  @override
  bool shouldRepaint(_BreakerPainter old) => true;
}
