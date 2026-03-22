import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../main.dart';

const List<String> _o2GameBackgroundAssets = [
  'assets/img/z12.jpg',
  'assets/img/z2s.jpg',
  'assets/img/bg2.png',
  'assets/img/bg.png',
  'assets/img/bll.jpg',
];
const String _o2GameFallbackAsset = 'assets/img/z12.jpg';

String _randomO2GameBackground([Random? rng]) {
  final random = rng ?? Random();
  return _o2GameBackgroundAssets[
      random.nextInt(_o2GameBackgroundAssets.length)];
}

class _GameBackdrop extends StatelessWidget {
  final String asset;
  final Color glowColor;
  final Color surfaceTint;

  const _GameBackdrop({
    required this.asset,
    required this.glowColor,
    required this.surfaceTint,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              asset,
              fit: BoxFit.cover,
              opacity: const AlwaysStoppedAnimation(0.24),
              errorBuilder: (_, __, ___) => Image.asset(
                _o2GameFallbackAsset,
                fit: BoxFit.cover,
                opacity: const AlwaysStoppedAnimation(0.24),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    surfaceTint.withValues(alpha: 0.58),
                    surfaceTint.withValues(alpha: 0.76),
                    Colors.black.withValues(alpha: 0.90),
                  ],
                ),
              ),
            ),
            Positioned(
              top: -36,
              right: -24,
              child: _BackdropOrb(
                size: 170,
                color: glowColor.withValues(alpha: 0.22),
              ),
            ),
            Positioned(
              bottom: 110,
              left: -34,
              child: _BackdropOrb(
                size: 140,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            Positioned(
              top: 180,
              right: 24,
              child: _BackdropOrb(
                size: 90,
                color: glowColor.withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackdropOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _BackdropOrb({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withValues(alpha: 0.0),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: size * 0.38,
            spreadRadius: size * 0.06,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GAMES HUB – lists all playable animated games
// ─────────────────────────────────────────────────────────────────────────────

class GamesHubPage extends StatefulWidget {
  const GamesHubPage({super.key});

  @override
  State<GamesHubPage> createState() => _GamesHubPageState();
}

class _GamesHubPageState extends State<GamesHubPage> {
  late final String _bannerAsset;

  @override
  void initState() {
    super.initState();
    _bannerAsset = _randomO2GameBackground();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          Navigator.canPop(context)
              ? Navigator.pop(context)
              : Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const ChatHomePage()),
                  (r) => false);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A1A),
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                _bannerAsset,
                fit: BoxFit.cover,
                opacity: const AlwaysStoppedAnimation(0.25),
                errorBuilder: (_, __, ___) => Image.asset(
                  _o2GameFallbackAsset,
                  fit: BoxFit.cover,
                  opacity: const AlwaysStoppedAnimation(0.25),
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: 214,
                  collapsedHeight: 214,
                  toolbarHeight: 214,
                  floating: false,
                  pinned: true,
                  backgroundColor:
                      const Color(0xFF0A0A1A).withValues(alpha: 0.82),
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 22),
                    onPressed: () => Navigator.canPop(context)
                        ? Navigator.pop(context)
                        : Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ChatHomePage()),
                            (r) => false),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    centerTitle: false,
                    titlePadding: const EdgeInsets.fromLTRB(72, 0, 18, 18),
                    title: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.18),
                            ),
                          ),
                          child: Text(
                            'Zero Two Arcade',
                            style: GoogleFonts.outfit(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'GAME ZONE',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w900,
                            fontSize: 24,
                            color: Colors.white,
                            letterSpacing: 3,
                            shadows: const [
                              Shadow(
                                color: Colors.pinkAccent,
                                blurRadius: 16,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Fixed banner with O2 glow effects',
                          style: GoogleFonts.outfit(
                            color: Colors.white70,
                            fontSize: 11,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          _bannerAsset,
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                          errorBuilder: (_, __, ___) => Image.asset(
                            _o2GameFallbackAsset,
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                          ),
                        ),
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0x22000000), Color(0xCC0A0A1A)],
                            ),
                          ),
                        ),
                        Positioned(
                          top: -30,
                          right: -18,
                          child: _BackdropOrb(
                            size: 150,
                            color: Colors.pinkAccent.withValues(alpha: 0.24),
                          ),
                        ),
                        Positioned(
                          bottom: -24,
                          left: -18,
                          child: _BackdropOrb(
                            size: 110,
                            color: Colors.cyanAccent.withValues(alpha: 0.10),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverGrid.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 18,
                    crossAxisSpacing: 18,
                    childAspectRatio: 0.82,
                    children: [
                      _GameCard(
                        title: 'Snake',
                        subtitle: 'Classic snake — eat, grow, survive',
                        icon: Icons.shuffle_rounded,
                        gradient: const [Color(0xFF00E676), Color(0xFF00897B)],
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SnakeGamePage())),
                      ),
                      _GameCard(
                        title: 'Memory Match',
                        subtitle: 'Flip & match the anime pairs',
                        icon: Icons.grid_view_rounded,
                        gradient: const [Color(0xFFFF4081), Color(0xFFAD1457)],
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const MemoryMatchPage())),
                      ),
                      _GameCard(
                        title: 'Tap Reaction',
                        subtitle: 'Test your reflexes!',
                        icon: Icons.touch_app_rounded,
                        gradient: const [Color(0xFFFF9100), Color(0xFFE65100)],
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const TapReactionPage())),
                      ),
                      _GameCard(
                        title: 'Number Guess',
                        subtitle: 'Guess Zero Two\'s secret number',
                        icon: Icons.casino_rounded,
                        gradient: const [Color(0xFF7C4DFF), Color(0xFF4527A0)],
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const NumberGuesserPage())),
                      ),
                      _GameCard(
                        title: 'Wordle',
                        subtitle:
                            'Guess a hidden 5-letter anime word. Green = right spot, Yellow = wrong spot',
                        icon: Icons.abc_rounded,
                        gradient: const [Color(0xFF26C6DA), Color(0xFF00838F)],
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const WordleGamePage())),
                      ),
                      _GameCard(
                        title: 'Anime Quiz',
                        subtitle: 'Test your anime knowledge!',
                        icon: Icons.quiz_rounded,
                        gradient: const [Color(0xFFEC407A), Color(0xFF880E4F)],
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AnimeQuizPage())),
                      ),
                      _GameCard(
                        title: 'Block Blast',
                        subtitle: 'Fill rows to clear the board!',
                        icon: Icons.view_quilt_rounded,
                        gradient: const [Color(0xFFFF6F00), Color(0xFFE65100)],
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const BlockBlastPage())),
                      ),
                      _GameCard(
                        title: 'Block Breaker',
                        subtitle: 'Break all bricks with the ball!',
                        icon: Icons.sports_tennis_rounded,
                        gradient: const [Color(0xFF00B0FF), Color(0xFF0D47A1)],
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const BlockBreakerPage())),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
  const _GameCard(
      {required this.title,
      required this.subtitle,
      required this.icon,
      required this.gradient,
      required this.onTap});

  @override
  State<_GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<_GameCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ac;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween(begin: 1.0, end: 0.94)
        .animate(CurvedAnimation(parent: _ac, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ac.forward(),
      onTapUp: (_) {
        _ac.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ac.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: widget.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                  color: widget.gradient.last.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6))
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(widget.icon, color: Colors.white, size: 30),
                ),
                const Spacer(),
                Text(widget.title,
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(widget.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                        color: Colors.white70, fontSize: 11, height: 1.3)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SNAKE GAME
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
  bool _running = false, _dead = false;
  final Random _rng = Random();
  late final String _bgAsset;

  @override
  void initState() {
    super.initState();
    _bgAsset = _randomO2GameBackground();
    _resetGame();
  }

  void _resetGame() {
    _snake = [const Point(10, 10), const Point(9, 10), const Point(8, 10)];
    _dir = const Point(1, 0);
    _pendingDir = null;
    _score = 0;
    _dead = false;
    _running = false;
    _placeFood();
  }

  void _startGame() {
    setState(() => _running = true);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 160), (_) => _tick());
  }

  void _tick() {
    if (!mounted) return;
    if (_pendingDir != null) {
      _dir = _pendingDir!;
      _pendingDir = null;
    }
    final head = Point(_snake.first.x + _dir.x, _snake.first.y + _dir.y);
    if (head.x < 0 ||
        head.x >= cols ||
        head.y < 0 ||
        head.y >= rows ||
        _snake.any((s) => s == head)) {
      _timer?.cancel();
      setState(() {
        _dead = true;
        _running = false;
      });
      return;
    }
    setState(() {
      _snake.insert(0, head);
      if (head == _food) {
        _score++;
        _placeFood();
      } else {
        _snake.removeLast();
      }
    });
  }

  void _placeFood() {
    Point<int> p;
    do {
      p = Point(_rng.nextInt(cols), _rng.nextInt(rows));
    } while (_snake.any((s) => s == p));
    _food = p;
  }

  void _turn(Point<int> newDir) {
    if (newDir.x != -_dir.x || newDir.y != -_dir.y) _pendingDir = newDir;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060D12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Snake — $_score pts',
            style: GoogleFonts.outfit(
                color: Colors.greenAccent, fontWeight: FontWeight.w800)),
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          _GameBackdrop(
            asset: _bgAsset,
            glowColor: Colors.greenAccent,
            surfaceTint: const Color(0xFF060D12),
          ),
          Column(
            children: [
              Expanded(
                child: GestureDetector(
                  onHorizontalDragUpdate: (d) {
                    if (d.delta.dx > 0) {
                      _turn(const Point(1, 0));
                    } else {
                      _turn(const Point(-1, 0));
                    }
                  },
                  onVerticalDragUpdate: (d) {
                    if (d.delta.dy > 0) {
                      _turn(const Point(0, 1));
                    } else {
                      _turn(const Point(0, -1));
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SizedBox(
                            width: constraints.maxWidth,
                            height: constraints.maxHeight,
                            child: CustomPaint(
                              size: Size(
                                constraints.maxWidth,
                                constraints.maxHeight,
                              ),
                              painter: _SnakePainter(_snake, _food, cols, rows),
                              child: _dead || !_running
                                  ? Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (_dead)
                                            Text('Game Over!',
                                                style: GoogleFonts.outfit(
                                                    color: Colors.redAccent,
                                                    fontSize: 32,
                                                    fontWeight:
                                                        FontWeight.w900)),
                                          const SizedBox(height: 16),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.greenAccent,
                                                foregroundColor: Colors.black,
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20)),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 36,
                                                        vertical: 14)),
                                            onPressed: () {
                                              setState(() => _resetGame());
                                              _startGame();
                                            },
                                            child: Text(
                                                _dead ? 'Play Again' : 'Start',
                                                style: GoogleFonts.outfit(
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 16)),
                                          ),
                                        ],
                                      ),
                                    )
                                  : const SizedBox.expand(),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(children: [
                  _dpadBtn(Icons.keyboard_arrow_up_rounded, const Point(0, -1)),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    _dpadBtn(
                        Icons.keyboard_arrow_left_rounded, const Point(-1, 0)),
                    const SizedBox(width: 56),
                    _dpadBtn(
                        Icons.keyboard_arrow_right_rounded, const Point(1, 0)),
                  ]),
                  _dpadBtn(
                      Icons.keyboard_arrow_down_rounded, const Point(0, 1)),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dpadBtn(IconData icon, Point<int> dir) {
    return IconButton(
      icon: Icon(icon, color: Colors.greenAccent, size: 40),
      onPressed: () {
        if (!_running && !_dead) _startGame();
        _turn(dir);
      },
    );
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
    // Background grid
    final bgPaint = Paint()..color = const Color(0xFF0D1F1A);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);
    // Food
    final foodPaint = Paint()..color = Colors.redAccent;
    canvas.drawCircle(Offset((food.x + 0.5) * cw, (food.y + 0.5) * ch),
        min(cw, ch) * 0.42, foodPaint);
    // Snake
    for (int i = 0; i < snake.length; i++) {
      final s = snake[i];
      final t = 1 - (i / snake.length * 0.6);
      final p = Paint()
        ..color = Color.lerp(Colors.greenAccent, Colors.green[900]!, 1 - t)!;
      final r = RRect.fromRectAndRadius(
          Rect.fromLTWH(s.x * cw + 1, s.y * ch + 1, cw - 2, ch - 2),
          Radius.circular(min(cw, ch) * 0.3));
      canvas.drawRRect(r, p);
    }
  }

  @override
  bool shouldRepaint(_SnakePainter old) => true;
}

// ─────────────────────────────────────────────────────────────────────────────
// MEMORY MATCH GAME
// ─────────────────────────────────────────────────────────────────────────────

class MemoryMatchPage extends StatefulWidget {
  const MemoryMatchPage({super.key});
  @override
  State<MemoryMatchPage> createState() => _MemoryMatchState();
}

class _MemoryMatchState extends State<MemoryMatchPage> {
  static const _emojis = ['🌸', '⚔️', '🦋', '💮', '🎴', '🌺', '🍡', '🎎'];
  late List<String> _cards;
  List<bool> _flipped = [];
  List<bool> _matched = [];
  int? _first, _second;
  bool _busy = false;
  int _moves = 0, _matches = 0;
  late final String _bgAsset;

  @override
  void initState() {
    super.initState();
    _bgAsset = _randomO2GameBackground();
    _init();
  }

  void _init() {
    _cards = [..._emojis, ..._emojis]..shuffle();
    _flipped = List.filled(16, false);
    _matched = List.filled(16, false);
    _moves = 0;
    _matches = 0;
    _first = null;
    _second = null;
    _busy = false;
  }

  Future<void> _tap(int i) async {
    if (_busy || _flipped[i] || _matched[i]) return;
    setState(() => _flipped[i] = true);
    if (_first == null) {
      _first = i;
    } else {
      _second = i;
      _moves++;
      _busy = true;
      await Future.delayed(const Duration(milliseconds: 700));
      if (_cards[_first!] == _cards[_second!]) {
        _matched[_first!] = _matched[_second!] = true;
        _matches++;
      } else {
        _flipped[_first!] = _flipped[_second!] = false;
      }
      _first = _second = null;
      _busy = false;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final won = _matches == _emojis.length;
    return Scaffold(
      backgroundColor: const Color(0xFF110018),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Memory Match — $_moves moves',
            style: GoogleFonts.outfit(
                color: Colors.pinkAccent, fontWeight: FontWeight.w800)),
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.pinkAccent),
            onPressed: () => setState(() => _init()),
          )
        ],
      ),
      body: Stack(
        children: [
          _GameBackdrop(
            asset: _bgAsset,
            glowColor: Colors.pinkAccent,
            surfaceTint: const Color(0xFF110018),
          ),
          Column(
            children: [
              if (won)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFFFF4081), Color(0xFFAD1457)]),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text('🎉 You won in $_moves moves!',
                        style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16)),
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10),
                    itemCount: 16,
                    itemBuilder: (_, i) => _CardTile(
                      emoji: _cards[i],
                      flipped: _flipped[i],
                      matched: _matched[i],
                      onTap: () => _tap(i),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardTile extends StatefulWidget {
  final String emoji;
  final bool flipped, matched;
  final VoidCallback onTap;
  const _CardTile(
      {required this.emoji,
      required this.flipped,
      required this.matched,
      required this.onTap});
  @override
  State<_CardTile> createState() => _CardTileState();
}

class _CardTileState extends State<_CardTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _ac;
  late Animation<double> _flip;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _flip = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ac, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(_CardTile old) {
    super.didUpdateWidget(old);
    if (widget.flipped != old.flipped) {
      widget.flipped ? _ac.forward() : _ac.reverse();
    }
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _flip,
        builder: (_, __) {
          final angle = _flip.value * pi;
          final showFront = angle <= pi / 2;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.rotationY(angle),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.matched
                      ? [const Color(0xFF00E676), const Color(0xFF00897B)]
                      : showFront
                          ? [const Color(0xFFFF4081), const Color(0xFFAD1457)]
                          : [const Color(0xFF2D0845), const Color(0xFF1A0030)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  showFront ? '' : widget.emoji,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAP REACTION GAME
// ─────────────────────────────────────────────────────────────────────────────

// Reaction game phases — top-level (Dart doesn't allow enums inside classes)
enum _Phase { idle, waiting, ready, result }

class TapReactionPage extends StatefulWidget {
  const TapReactionPage({super.key});
  @override
  State<TapReactionPage> createState() => _TapReactionState();
}

class _TapReactionState extends State<TapReactionPage>
    with SingleTickerProviderStateMixin {
  _Phase _phase = _Phase.idle;
  int _round = 0, _totalMs = 0;
  DateTime? _showTime;
  Timer? _timer;
  late AnimationController _pulse;
  late Animation<double> _pulseAnim;
  final Random _rng = Random();
  final List<int> _times = [];
  late final String _bgAsset;

  @override
  void initState() {
    super.initState();
    _bgAsset = _randomO2GameBackground();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _pulseAnim = Tween(begin: 0.95, end: 1.05)
        .animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
    _pulse.repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  void _start() {
    setState(() {
      _phase = _Phase.waiting;
      _round++;
    });
    final delay = 1500 + _rng.nextInt(3000);
    _timer = Timer(Duration(milliseconds: delay), () {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.ready;
        _showTime = DateTime.now();
      });
    });
  }

  void _tap() {
    if (_phase == _Phase.waiting) {
      _timer?.cancel();
      setState(() => _phase = _Phase.idle);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Too early! Wait for green.')));
      return;
    }
    if (_phase == _Phase.ready) {
      final ms = DateTime.now().difference(_showTime!).inMilliseconds;
      _times.add(ms);
      _totalMs += ms;
      setState(() => _phase = _Phase.result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final avg = _times.isEmpty ? 0 : _totalMs ~/ _times.length;
    return Scaffold(
      backgroundColor: const Color(0xFF0D0A00),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Tap Reaction',
            style: GoogleFonts.outfit(
                color: Colors.orangeAccent, fontWeight: FontWeight.w800)),
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          _GameBackdrop(
            asset: _bgAsset,
            glowColor: Colors.orangeAccent,
            surfaceTint: const Color(0xFF0D0A00),
          ),
          GestureDetector(
            onTap: _phase == _Phase.idle || _phase == _Phase.result
                ? _start
                : _tap,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: _phase == _Phase.ready
                  ? Colors.green.withValues(alpha: 0.3)
                  : _phase == _Phase.waiting
                      ? Colors.red.withValues(alpha: 0.2)
                      : Colors.transparent,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _pulseAnim,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: _phase == _Phase.ready
                              ? [Colors.greenAccent, Colors.green]
                              : _phase == _Phase.waiting
                                  ? [Colors.redAccent, Colors.red[900]!]
                                  : [Colors.orangeAccent, Colors.deepOrange],
                        ),
                        boxShadow: [
                          BoxShadow(
                              color: (_phase == _Phase.ready
                                      ? Colors.green
                                      : Colors.orange)
                                  .withValues(alpha: 0.5),
                              blurRadius: 30,
                              spreadRadius: 5)
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _phase == _Phase.idle
                              ? '▶ TAP TO\nSTART'
                              : _phase == _Phase.waiting
                                  ? 'WAIT...'
                                  : _phase == _Phase.ready
                                      ? 'TAP!'
                                      : '${_times.last} ms',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: _phase == _Phase.result ? 28 : 22,
                              fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  if (_times.isNotEmpty) ...[
                    Text('Round $_round  •  Avg: $avg ms',
                        style: GoogleFonts.outfit(
                            color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 8),
                    Text(
                        _phase == _Phase.result
                            ? 'Tap anywhere to try again'
                            : '',
                        style: GoogleFonts.outfit(
                            color: Colors.white38, fontSize: 13)),
                  ] else
                    Text('Tap the circle when it turns green!',
                        style: GoogleFonts.outfit(
                            color: Colors.white38, fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NUMBER GUESSER GAME
// ─────────────────────────────────────────────────────────────────────────────

class NumberGuesserPage extends StatefulWidget {
  const NumberGuesserPage({super.key});
  @override
  State<NumberGuesserPage> createState() => _NumberGuesserState();
}

class _NumberGuesserState extends State<NumberGuesserPage>
    with SingleTickerProviderStateMixin {
  final Random _rng = Random();
  late int _secret;
  final _ctrl = TextEditingController();
  String _hint = '';
  int _attempts = 0;
  bool _won = false;
  late AnimationController _shake;
  late Animation<double> _shakeAnim;
  late final String _bgAsset;

  @override
  void initState() {
    super.initState();
    _bgAsset = _randomO2GameBackground();
    _secret = _rng.nextInt(100) + 1;
    _shake = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnim = Tween(begin: -8.0, end: 8.0)
        .animate(CurvedAnimation(parent: _shake, curve: Curves.elasticIn));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _shake.dispose();
    super.dispose();
  }

  void _guess() {
    final n = int.tryParse(_ctrl.text.trim());
    if (n == null || n < 1 || n > 100) {
      _shake.forward(from: 0);
      setState(() => _hint = 'Enter a number between 1 and 100');
      return;
    }
    _attempts++;
    if (n == _secret) {
      setState(() {
        _hint = '🎉 Correct! The number was $_secret!';
        _won = true;
      });
    } else if (n < _secret) {
      _shake.forward(from: 0);
      setState(() => _hint = 'Too low! Try higher, darling~');
    } else {
      _shake.forward(from: 0);
      setState(() => _hint = 'Too high! Go lower, honey~');
    }
    _ctrl.clear();
  }

  void _reset() {
    setState(() {
      _secret = _rng.nextInt(100) + 1;
      _hint = '';
      _attempts = 0;
      _won = false;
    });
    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0018),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Number Guess',
            style: GoogleFonts.outfit(
                color: Colors.deepPurpleAccent, fontWeight: FontWeight.w800)),
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: Colors.deepPurpleAccent),
            onPressed: _reset,
          )
        ],
      ),
      body: Stack(
        children: [
          _GameBackdrop(
            asset: _bgAsset,
            glowColor: Colors.deepPurpleAccent,
            surfaceTint: const Color(0xFF0C0018),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF7C4DFF), Color(0xFF4527A0)]),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.deepPurple.withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 4)
                    ],
                  ),
                  child: Column(
                    children: [
                      Text('?',
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 64,
                              fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      Text("I'm thinking of a number\nbetween 1 and 100",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                              color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('Attempt $_attempts',
                          style: GoogleFonts.outfit(
                              color: Colors.white38, fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                if (_hint.isNotEmpty)
                  AnimatedBuilder(
                    animation: _shakeAnim,
                    builder: (_, child) => Transform.translate(
                        offset: Offset(_shakeAnim.value, 0), child: child),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _won
                            ? Colors.green.withValues(alpha: 0.2)
                            : Colors.pinkAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: _won
                                ? Colors.greenAccent.withValues(alpha: 0.5)
                                : Colors.pinkAccent.withValues(alpha: 0.3)),
                      ),
                      child: Text(_hint,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                              color:
                                  _won ? Colors.greenAccent : Colors.pinkAccent,
                              fontSize: 15,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                const SizedBox(height: 24),
                if (!_won) ...[
                  TextField(
                    controller: _ctrl,
                    keyboardType: TextInputType.number,
                    style:
                        GoogleFonts.outfit(color: Colors.white, fontSize: 20),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: 'Your guess...',
                      hintStyle: GoogleFonts.outfit(color: Colors.white30),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.07),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    onSubmitted: (_) => _guess(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurpleAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(vertical: 16)),
                      onPressed: _guess,
                      child: Text('GUESS',
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w800, fontSize: 16)),
                    ),
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(vertical: 16)),
                      onPressed: _reset,
                      child: Text('Play Again',
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w800, fontSize: 16)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// WORDLE GAME
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

class WordleGamePage extends StatefulWidget {
  const WordleGamePage({super.key});
  @override
  State<WordleGamePage> createState() => _WordleGamePageState();
}

class _WordleGamePageState extends State<WordleGamePage> {
  final List<String> _easyWords = ['ANIME', 'OTAKU', 'MANGA', 'WAIFU', 'KAWAI'];
  final List<String> _mediumWords = [
    'NARUTO',
    'SAKURA',
    'SHONEN',
    'SENPAI',
    'ISEKAI'
  ];
  final List<String> _hardWords = [
    'SAMURAI',
    'TSUNDERE',
    'SHINIGAMI',
    'HOKAGE',
    'HENTOSHI'
  ];

  late String _targetWord;
  final List<String> _guesses = [];
  String _currentGuess = '';
  late int _maxGuesses;
  bool _gameOver = false;
  bool _won = false;
  late final String _bgAsset;

  String _phase = 'difficulty';

  @override
  void initState() {
    super.initState();
    _bgAsset = _randomO2GameBackground();
  }

  void _startGame(String diff) {
    setState(() {
      _phase = 'game';
      _guesses.clear();
      _currentGuess = '';
      _gameOver = false;
      _won = false;

      final rng = Random();
      if (diff == 'Easy') {
        _targetWord = _easyWords[rng.nextInt(_easyWords.length)];
        _maxGuesses = 8;
      } else if (diff == 'Hard') {
        _targetWord = _hardWords[rng.nextInt(_hardWords.length)];
        _maxGuesses = 5;
      } else {
        _targetWord = _mediumWords[rng.nextInt(_mediumWords.length)];
        _maxGuesses = 6;
      }
    });
  }

  void _reset() {
    setState(() {
      _phase = 'difficulty';
    });
  }

  void _verifyGuess() {
    if (_currentGuess.length != _targetWord.length) return;
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.lightImpact();
    setState(() {
      _guesses.add(_currentGuess);
      if (_currentGuess == _targetWord) {
        _won = true;
        _gameOver = true;
        SystemSound.play(SystemSoundType.alert);
      } else if (_guesses.length >= _maxGuesses) {
        _gameOver = true;
      }
      _currentGuess = '';
    });
  }

  void _addLetter(String letter) {
    if (_currentGuess.length < 5 && !_gameOver) {
      setState(() => _currentGuess += letter);
    }
  }

  void _removeLetter() {
    if (_currentGuess.isNotEmpty && !_gameOver) {
      setState(() =>
          _currentGuess = _currentGuess.substring(0, _currentGuess.length - 1));
    }
  }

  Widget _buildGridRow(String word, bool isSubmitted) {
    List<Widget> boxes = [];
    for (int i = 0; i < 5; i++) {
      String char = i < word.length ? word[i] : '';
      Color bgColor = Colors.black45;
      Color borderColor = Colors.white24;
      if (isSubmitted && char.isNotEmpty) {
        if (_targetWord[i] == char) {
          bgColor = Colors.green.shade600;
          borderColor = Colors.green.shade600;
        } else if (_targetWord.contains(char)) {
          bgColor = Colors.orange.shade600;
          borderColor = Colors.orange.shade600;
        } else {
          bgColor = Colors.grey.shade800;
          borderColor = Colors.grey.shade800;
        }
      } else if (char.isNotEmpty) {
        borderColor = Colors.white60;
      }

      boxes.add(Container(
        width: 50,
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          char,
          style: GoogleFonts.outfit(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ));
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: boxes.expand((b) => [b, const SizedBox(width: 8)]).toList()
        ..removeLast(),
    );
  }

  Widget _buildKeyboard() {
    const rows = [
      ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
      ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
      ['ENTER', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', 'DEL']
    ];
    return Column(
      children: rows
          .map((row) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: row.map((key) {
                    final isAction = key == 'ENTER' || key == 'DEL';
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                      child: Material(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(4),
                        child: InkWell(
                          onTap: () {
                            if (key == 'ENTER') {
                              _verifyGuess();
                            } else if (key == 'DEL') {
                              _removeLetter();
                            } else {
                              _addLetter(key);
                            }
                          },
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isAction ? 12 : 10,
                              vertical: 14,
                            ),
                            child: Text(
                              key,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: isAction ? 12 : 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ))
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A24),
      appBar: AppBar(
        title: Text('Anime Wordle',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          _GameBackdrop(
            asset: _bgAsset,
            glowColor: Colors.cyanAccent,
            surfaceTint: const Color(0xFF1A1A24),
          ),
          SafeArea(
            child: _phase == 'difficulty'
                ? _buildDifficultySelector()
                : _buildGameUI(),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultySelector() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.abc_rounded, size: 64, color: Colors.cyanAccent),
          const SizedBox(height: 24),
          _difficultyBtn(
              'Easy (5 Letters, 8 Guesses)', 'Easy', Colors.greenAccent),
          const SizedBox(height: 16),
          _difficultyBtn(
              'Medium (6 Letters, 6 Guesses)', 'Medium', Colors.orangeAccent),
          const SizedBox(height: 16),
          _difficultyBtn(
              'Hard (7+ Letters, 5 Guesses)', 'Hard', Colors.redAccent),
        ],
      ),
    );
  }

  Widget _difficultyBtn(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: InkWell(
        onTap: () => _startGame(value),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            border: Border.all(color: color.withValues(alpha: 0.6), width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(label,
              style: GoogleFonts.outfit(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1)),
        ),
      ),
    );
  }

  Widget _buildGameUI() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            children: [
              for (int i = 0; i < _maxGuesses; i++) ...[
                if (i < _guesses.length)
                  _buildGridRow(_guesses[i], true)
                else if (i == _guesses.length)
                  _buildGridRow(_currentGuess, false)
                else
                  _buildGridRow('', false),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
        if (_gameOver) ...[
          Text(
            _won ? 'Sugoi! You got it!' : 'Game Over! Word was $_targetWord',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _won ? Colors.greenAccent : Colors.redAccent,
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _reset,
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                foregroundColor: Colors.black),
            child: const Text('Play Again'),
          ),
          const SizedBox(height: 20),
        ],
        if (!_gameOver) _buildKeyboard(),
        const SizedBox(height: 20),
      ],
    );
  }
}

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// ANIME QUIZ GAME — Unlimited rounds, 10 questions per round
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

// ── Master question bank (80+ questions) ─────────────────────────────────────
const List<Map<String, dynamic>> _kAnimeQuestions = [
  // ── One Piece ─────────────────────────────────────────────────
  {
    'q': 'What fruit gives Luffy his rubber powers?',
    'opts': [
      'Mera Mera no Mi',
      'Gomu Gomu no Mi',
      'Ope Ope no Mi',
      'Hana Hana no Mi'
    ],
    'ans': 1
  },
  {
    'q': 'Who is the first mate of the Straw Hat Pirates?',
    'opts': ['Sanji', 'Usopp', 'Zoro', 'Nami'],
    'ans': 2
  },
  {
    'q': "What is Nami's main weapon?",
    'opts': ['Clima-Tact', 'Sword', 'Slingshot', 'Trident'],
    'ans': 0
  },
  {
    'q': 'Which island is the home of the Whitebeard Pirates?',
    'opts': ['Impel Down', 'Marineford', 'Punk Hazard', 'Moby Dick'],
    'ans': 3
  },
  {
    'q': "What is Trafalgar Law's Devil Fruit?",
    'opts': [
      'Hana Hana no Mi',
      'Ope Ope no Mi',
      'Bara Bara no Mi',
      'Mori Mori no Mi'
    ],
    'ans': 1
  },
  {
    'q': 'What is the name of Zoro\'s ultimate sword technique?',
    'opts': ['Rashomon', 'Oni Giri', 'Tora Gari', 'Asura'],
    'ans': 3
  },
  // ── Naruto ────────────────────────────────────────────────────
  {
    'q': 'Who is the Nine-Tails Jinchuriki?',
    'opts': ['Gaara', 'Killer B', 'Naruto', 'Minato'],
    'ans': 2
  },
  {
    'q': "What is Sasuke Uchiha's signature technique?",
    'opts': ['Rasengan', 'Chidori', 'Shadow Clone', 'Amaterasu'],
    'ans': 1
  },
  {
    'q': 'Who trained Naruto to use Sage Mode?',
    'opts': ['Jiraiya', 'Fukasaku', 'Tsunade', 'Kakashi'],
    'ans': 1
  },
  {
    'q': "What is Rock Lee's specialty?",
    'opts': ['Genjutsu', 'Ninjutsu', 'Taijutsu', 'Kenjutsu'],
    'ans': 2
  },
  {
    'q': 'What village is Naruto from?',
    'opts': ['Sand Village', 'Mist Village', 'Leaf Village', 'Cloud Village'],
    'ans': 2
  },
  {
    'q': 'Who is the first Hokage?',
    'opts': ['Tobirama Senju', 'Hashirama Senju', 'Sarutobi', 'Minato'],
    'ans': 1
  },
  // ── Attack on Titan ───────────────────────────────────────────
  {
    'q': 'Who holds the Founding Titan at the start of AOT?',
    'opts': ['Reiner', 'Eren', 'Zeke', 'Historia'],
    'ans': 1
  },
  {
    'q': 'What is the Scout Regiment\'s symbol?',
    'opts': ['Wings of Freedom', 'Crossed Swords', 'Eagle Crest', 'Titan Mark'],
    'ans': 0
  },
  {
    'q': "What is Levi's last name?",
    'opts': ['Ackerman', 'Yeager', 'Braun', 'Springer'],
    'ans': 0
  },
  {
    'q': 'What kills titans most efficiently?',
    'opts': ['Arrows', 'Cannons', 'Nape slash', 'Fire'],
    'ans': 2
  },
  {
    'q': 'Who is the Armored Titan?',
    'opts': ['Bertholdt', 'Reiner', 'Annie', 'Zeke'],
    'ans': 1
  },
  // ── Death Note ────────────────────────────────────────────────
  {
    'q': 'What is the name of the shinigami who drops the Death Note?',
    'opts': ['Rem', 'Ryuk', 'Gelus', 'Sidoh'],
    'ans': 1
  },
  {
    'q': "What is Light Yagami's alias?",
    'opts': ['Beyond Birthday', 'Kira', 'L', 'N'],
    'ans': 1
  },
  {
    'q': 'What do you need to kill someone using the Death Note?',
    'opts': [
      'Full name & age',
      'Full name & face',
      'Full name & birthdate',
      'Just a name'
    ],
    'ans': 1
  },
  {
    'q': "What is L's real name?",
    'opts': ['Lawliet', 'Ryuzaki', 'L. Lowe', 'L. Watari'],
    'ans': 0
  },
  // ── Dragon Ball ───────────────────────────────────────────────
  {
    'q': 'Who is the first character to become a Super Saiyan in DBZ?',
    'opts': ['Vegeta', 'Gohan', 'Goku', 'Trunks'],
    'ans': 2
  },
  {
    'q': 'What are the 7 dragon balls used to summon?',
    'opts': ['A Genie', 'Shenron', 'Energy', 'A Portal'],
    'ans': 1
  },
  {
    'q': "What is Vegeta's home planet?",
    'opts': ['Namek', 'Earth', 'Planet Vegeta', 'New Vegeta'],
    'ans': 2
  },
  {
    'q': "What is Piccolo's species?",
    'opts': ['Saiyan', 'Android', 'Namekian', 'Human'],
    'ans': 2
  },
  {
    'q': 'What fusion dance produces Gogeta?',
    'opts': [
      'Goku + Vegeta',
      'Gohan + Goten',
      'Gohan + Piccolo',
      'Goku + Gohan'
    ],
    'ans': 0
  },
  // ── Fullmetal Alchemist ───────────────────────────────────────
  {
    'q': "Who is Edward Elric's brother?",
    'opts': ['Roy Mustang', 'Alphonse Elric', 'Hughes', 'Envy'],
    'ans': 1
  },
  {
    'q': 'What is the ultimate taboo in alchemy?',
    'opts': [
      'Transmuting gold',
      'Human transmutation',
      'Making weapons',
      'Splitting atoms'
    ],
    'ans': 1
  },
  {
    'q': "What is Roy Mustang's alchemy specialty?",
    'opts': ['Earth', 'Water', 'Fire', 'Lightning'],
    'ans': 2
  },
  {
    'q': "What body part does Ed sacrifice to restore Al's soul?",
    'opts': ['Right arm', 'Left leg', 'Left arm', 'Right leg'],
    'ans': 0
  },
  // ── One Punch Man ─────────────────────────────────────────────
  {
    'q': 'Who is known as the One Punch Man?',
    'opts': ['Genos', 'King', 'Saitama', 'Garou'],
    'ans': 2
  },
  {
    'q': "What is Genos's nickname for Saitama?",
    'opts': ['Master', 'Teacher', 'Sensei', 'Boss'],
    'ans': 2
  },
  {
    'q': 'What rank is Saitama in the Hero Association?',
    'opts': ['S-Class', 'A-Class', 'B-Class', 'C-Class'],
    'ans': 3
  },
  {
    'q': "What is Saitama's daily training routine (partially)?",
    'opts': [
      '200 km run',
      '100 push-ups, sit-ups, squats + 10 km run',
      '500 punches',
      'Meditation'
    ],
    'ans': 1
  },
  // ── Demon Slayer ──────────────────────────────────────────────
  {
    'q': "What is Tanjiro Kamado's breathing style?",
    'opts': [
      'Thunder Breathing',
      'Water Breathing',
      'Flame Breathing',
      'Sun Breathing'
    ],
    'ans': 1
  },
  {
    'q': "Who poisoned Tanjiro's family?",
    'opts': ['Muzan Kibutsuji', 'Doma', 'Rui', 'Akaza'],
    'ans': 0
  },
  {
    'q': 'What makes Tanjiro\'s final form unique?',
    'opts': [
      'Flame Breathing',
      'Breath of the Sun (Hinokami Kagura)',
      'Mist Breathing',
      'Love Breathing'
    ],
    'ans': 1
  },
  {
    'q': "What is Zenitsu's only technique?",
    'opts': [
      'Water Wheel',
      'Thunderclap and Flash',
      'Whirlwind',
      'Dance of the Fire God'
    ],
    'ans': 1
  },
  // ── My Hero Academia ──────────────────────────────────────────
  {
    'q': "What is Deku's Quirk called?",
    'opts': ['Half-Cold Half-Hot', 'Explosion', 'One For All', 'Zero Gravity'],
    'ans': 2
  },
  {
    'q': "Who is the Symbol of Peace?",
    'opts': ['Endeavor', 'All For One', 'Best Jeanist', 'All Might'],
    'ans': 3
  },
  {
    'q': "What is Bakugo's Quirk?",
    'opts': ['Fire', 'Explosion', 'Hardening', 'Black Whip'],
    'ans': 1
  },
  {
    'q': 'What school do U.A. heroes attend?',
    'opts': ['Shiketsu', 'Ketsubutsu', 'Seiai', 'U.A. High'],
    'ans': 3
  },
  {
    'q': "What class is Deku in?",
    'opts': ['Class 1-B', 'Class 2-A', 'Class 1-A', 'Class 3-C'],
    'ans': 2
  },
  // ── Hunter x Hunter ───────────────────────────────────────────
  {
    'q': "What is Gon Freecss's father?",
    'opts': ['Netero', 'Ging Freecss', 'Killua', 'Leorio'],
    'ans': 1
  },
  {
    'q': "What is Killua Zoldyck's special technique?",
    'opts': ['Nen', 'Godspeed', 'Jajanken', 'Bungee Gum'],
    'ans': 1
  },
  {
    'q': "What is Hisoka's Nen type?",
    'opts': ['Emitter', 'Transmuter', 'Enhancer', 'Specialist'],
    'ans': 1
  },
  {
    'q': 'What animal can Gon transform into with Nen?',
    'opts': ['None — he has Enhancer Nen', 'Dragon', 'Wolf', 'Eagle'],
    'ans': 0
  },
  // ── Sword Art Online ──────────────────────────────────────────
  {
    'q': "What is Kirito's real name?",
    'opts': [
      'Kazuto Kirigaya',
      'Ryoutarou Tsuboi',
      'Kouhei Izaki',
      'Keita Nakamura'
    ],
    'ans': 0
  },
  {
    'q': "What is Asuna's rapier named?",
    'opts': ['Lambent Light', 'Dark Repulser', 'Elucidator', 'Night Sky Sword'],
    'ans': 0
  },
  {
    'q': 'What is the final boss of Sword Art Online game?',
    'opts': [
      'Akihiko Kayaba / Heathcliff',
      'Oberon',
      'Death Gun',
      'Administrator'
    ],
    'ans': 0
  },
  // ── Darling in the FranXX ─────────────────────────────────────
  {
    'q': "What is Zero Two's code?",
    'opts': ['016', '002', '326', '666'],
    'ans': 1
  },
  {
    'q': "What is Hiro's codename after piloting with Zero Two?",
    'opts': ['Code 016', 'Code 002', 'Darling', 'Code 015'],
    'ans': 0
  },
  {
    'q': "What are the mechs in Darling in the FranXX called?",
    'opts': ['Knightmares', 'Gundams', 'Titans', 'FranXX'],
    'ans': 3
  },
  {
    'q': "What is the enemy organism in DitF?",
    'opts': ['Klaxosaurs', 'Titans', 'Apostles', 'Shadows'],
    'ans': 0
  },
  // ── Bleach ────────────────────────────────────────────────────
  {
    'q': "What is Ichigo Kurosaki's sword called?",
    'opts': ['Zanpakuto: Zangetsu', 'Byakuya', 'Renji', 'Senbonzakura'],
    'ans': 0
  },
  {
    'q': "What are the hollows hunted by Soul Reapers?",
    'opts': ['Quincies', 'Arrancars', 'Hollows', 'Fullbringers'],
    'ans': 2
  },
  {
    'q': "What is Byakuya Kuchiki's Bankai?",
    'opts': [
      'Senbonzakura Kageyoshi',
      'Daiguren Hyōrinmaru',
      'Tenken',
      'Ittō Kasō'
    ],
    'ans': 0
  },
  // ── Tokyo Ghoul ───────────────────────────────────────────────
  {
    'q': "What is Ken Kaneki's ghoul kagune type?",
    'opts': ['Rinkaku', 'Ukaku', 'Koukaku', 'Bikaku'],
    'ans': 0
  },
  {
    'q': 'What coffee shop does Kaneki frequent?',
    'opts': [':re', 'Anteiku', 'Ghoul House', 'Cochlea'],
    'ans': 1
  },
  // ── Black Clover ──────────────────────────────────────────────
  {
    'q': "What magic does Asta use?",
    'opts': ['Fire Magic', 'Anti-Magic', 'Darkness Magic', 'Light Magic'],
    'ans': 1
  },
  {
    'q': "What is Yuno's grimoire clover type?",
    'opts': ['Four-leaf', 'Five-leaf', 'Three-leaf', 'Two-leaf'],
    'ans': 0
  },
  {
    'q': "What is Asta's squad in Black Clover?",
    'opts': ['Silver Eagles', 'Golden Dawn', 'Black Bulls', 'Crimson Lion'],
    'ans': 2
  },
  // ── Jujutsu Kaisen ────────────────────────────────────────────
  {
    'q': "Who is Ryomen Sukuna?",
    'opts': ['A hero', 'The King of Curses', 'A teacher', 'A student'],
    'ans': 1
  },
  {
    'q': "What is Gojo Satoru's Infinity technique called?",
    'opts': [
      'Domain Expansion',
      'Limitless + Six Eyes',
      'Cursed Energy',
      'Black Flash'
    ],
    'ans': 1
  },
  {
    'q': "What curse does Yuji Itadori eat at the start?",
    'opts': [
      "Sukuna's finger",
      "Uraume's crystal",
      "Mahito's flesh",
      "Geto's hands"
    ],
    'ans': 0
  },
  // ── Miscellaneous ─────────────────────────────────────────────
  {
    'q': 'In Re:Zero, what power does Subaru have?',
    'opts': [
      'Time Manipulation',
      'Return by Death',
      'Future Sight',
      'Teleportation'
    ],
    'ans': 1
  },
  {
    'q': "What is the name of Rem's weapon?",
    'opts': ['Naginata', 'Morning Star Flail', 'Kusarigama', 'Battle Axe'],
    'ans': 1
  },
  {
    'q': 'In No Game No Life, Shiro and Sora are known as what?',
    'opts': ['Tet', 'Blank (Kuuhaku)', 'Jibril', 'Izuna'],
    'ans': 1
  },
  {
    'q': "What is Kirigakure Saizo's nickname in Wise man's Grandchild?",
    'opts': ['Great Sage', 'Merlin', 'Shin', 'Wiseman'],
    'ans': 2
  },
  {
    'q': 'In Overlord, what is Ainz Ooal Gown\'s real-world name?',
    'opts': ['Suzuki Satoru', 'Momonga', 'Punitto Moe', 'TouchMe'],
    'ans': 0
  },
  {
    'q': "Which anime features the Celestial Spirits?",
    'opts': ['SAO', 'Fairy Tail', 'Black Clover', 'Magi'],
    'ans': 1
  },
  {
    'q': "What is the name of Natsu's fire magic?",
    'opts': [
      'Dragon Slayer Magic',
      'Fire God Slayer',
      'Phoenix Drive',
      'Flame Emperor'
    ],
    'ans': 0
  },
  {
    'q': 'Who is the strongest Hashira in Demon Slayer?',
    'opts': ['Giyu', 'Sanemi', 'Gyomei Himejima', 'Mitsuri'],
    'ans': 2
  },
  {
    'q': 'What is the main currency in the SAO world?',
    'opts': ['Zenny', 'Col', 'Berries', 'Meseta'],
    'ans': 1
  },
  {
    'q': "In Evangelion, what is Shinji's dad's name?",
    'opts': ['Gendo Ikari', 'Kaji Ryoji', 'Kozo Fuyutsuki', 'Yui Ikari'],
    'ans': 0
  },
  {
    'q': 'What does AOT stand for?',
    'opts': [
      'Army of Titans',
      'Attack on Titan',
      'Age of Titans',
      'Assault on Titans'
    ],
    'ans': 1
  },
  {
    'q': "What powers the FranXX mechs in DitF?",
    'opts': ['Klaxosaur blood', 'FRANXX Core', 'Magma energy', 'APE tech'],
    'ans': 0
  },
  {
    'q': "What studio produced Attack on Titan Season 1?",
    'opts': ['MAPPA', 'Ufotable', 'Wit Studio', 'Bones'],
    'ans': 2
  },
  {
    'q': 'Who voices Naruto Uzumaki in the Japanese dub?',
    'opts': [
      'Maile Flanagan',
      'Junko Takeuchi',
      'Noriaki Sugiyama',
      'Chie Nakamura'
    ],
    'ans': 1
  },
];

class AnimeQuizPage extends StatefulWidget {
  const AnimeQuizPage({super.key});
  @override
  State<AnimeQuizPage> createState() => _AnimeQuizPageState();
}

class _AnimeQuizPageState extends State<AnimeQuizPage>
    with SingleTickerProviderStateMixin {
  static const int _questionsPerRound = 10;
  // OpenTDB: Anime & Manga category = 31, free, no key required
  static const String _apiBaseUrl =
      'https://opentdb.com/api.php?amount=10&category=31&type=multiple&encode=url3986';

  final Random _rng = Random();
  late final String _bgAsset;

  // ── Round state ────────────────────────────────────────────────
  int _round = 1;
  int _currentQ = 0;
  int _roundScore = 0;
  int _totalScore = 0;

  bool _answered = false;
  int? _selectedIdx;

  // Quiz data for current round — each entry: {q, opts: [String], ans: int}
  List<Map<String, dynamic>> _roundQuestions = [];
  bool _loading = false; // Start false to show difficulty selector

  // Phase: 'difficulty' | 'quiz' | 'roundSummary'
  String _phase = 'difficulty';
  String _selectedDifficulty = 'medium';

  late AnimationController _timerController;
  Timer? _autoAdvanceTimer;

  @override
  void initState() {
    super.initState();
    _bgAsset = _randomO2GameBackground();
    _timerController =
        AnimationController(vsync: this, duration: const Duration(seconds: 15))
          ..addStatusListener((s) {
            if (s == AnimationStatus.completed && !_answered) {
              _answer(-1); // time out = wrong answer
            }
          });
    // Wait for user to select difficulty before fetching
  }

  // ── API fetch ─────────────────────────────────────────────────
  Future<void> _fetchRound() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
    });
    try {
      final url = '$_apiBaseUrl&difficulty=$_selectedDifficulty';
      final resp =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));
      if (resp.statusCode != 200) throw Exception('HTTP ${resp.statusCode}');
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final code = data['response_code'] as int;
      if (code != 0) throw Exception('OpenTDB code $code');
      // ... same parsing logic ...
      final results = data['results'] as List<dynamic>;
      final parsed = <Map<String, dynamic>>[];
      for (final r in results) {
        final question = Uri.decodeComponent(r['question'] as String);
        final correct = Uri.decodeComponent(r['correct_answer'] as String);
        final incorrects = (r['incorrect_answers'] as List<dynamic>)
            .map((e) => Uri.decodeComponent(e as String))
            .toList();
        final allOpts = [...incorrects, correct]..shuffle(_rng);
        final ansIdx = allOpts.indexOf(correct);
        parsed.add({'q': question, 'opts': allOpts, 'ans': ansIdx});
      }
      if (!mounted) return;
      setState(() {
        _roundQuestions = parsed;
        _loading = false;
        _currentQ = 0;
        _roundScore = 0;
        _answered = false;
        _selectedIdx = null;
        _phase = 'quiz';
      });
      _timerController.forward(from: 0);
    } catch (e) {
      // Fallback to local bank if no internet
      _useFallback();
    }
  }

  void _useFallback() {
    if (!mounted) return;
    final pool = List.of(_kAnimeQuestions)..shuffle(_rng);
    setState(() {
      _roundQuestions = pool.take(_questionsPerRound).toList();
      _loading = false;
      _currentQ = 0;
      _roundScore = 0;
      _answered = false;
      _selectedIdx = null;
      _phase = 'quiz';
    });
    _timerController.forward(from: 0);
  }

  // ── Gameplay ───────────────────────────────────────────────────
  void _answer(int idx) {
    if (_answered || _roundQuestions.isEmpty) return;
    _timerController.stop();
    setState(() {
      _answered = true;
      _selectedIdx = idx;
      if (idx == _roundQuestions[_currentQ]['ans']) {
        _roundScore++;
        _totalScore++;
      }
    });
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      _goNext();
    });
  }

  void _goNext() {
    if (_currentQ < _questionsPerRound - 1) {
      setState(() {
        _currentQ++;
        _answered = false;
        _selectedIdx = null;
      });
      _timerController.forward(from: 0);
    } else {
      setState(() => _phase = 'roundSummary');
    }
  }

  void _nextRound() {
    setState(() => _round++);
    _fetchRound();
  }

  @override
  void dispose() {
    _timerController.dispose();
    _autoAdvanceTimer?.cancel();
    super.dispose();
  }

  String _gradeLabel() {
    final pct = _roundScore / _questionsPerRound;
    if (pct == 1.0) return '🏆 Perfect!';
    if (pct >= 0.8) return '⭐ Excellent!';
    if (pct >= 0.6) return '👍 Good Job!';
    if (pct >= 0.4) return '😊 Keep Going!';
    return '💪 Try Again!';
  }

  Color _gradeColor() {
    final pct = _roundScore / _questionsPerRound;
    if (pct == 1.0) return Colors.amberAccent;
    if (pct >= 0.8) return Colors.greenAccent;
    if (pct >= 0.6) return Colors.cyanAccent;
    if (pct >= 0.4) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A24),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _phase == 'difficulty'
              ? 'Select Difficulty'
              : _phase == 'roundSummary'
                  ? 'Round $_round Done!'
                  : 'Round $_round  •  Q${_currentQ + 1}/$_questionsPerRound',
          style: GoogleFonts.outfit(
              color: Colors.pinkAccent, fontWeight: FontWeight.w800),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text('🏅 $_totalScore',
                  style: GoogleFonts.outfit(
                      color: Colors.amberAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
      body: Stack(children: [
        _GameBackdrop(
            asset: _bgAsset,
            glowColor: Colors.pinkAccent,
            surfaceTint: const Color(0xFF1A1A24)),
        SafeArea(child: _buildBody()),
      ]),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.pinkAccent));
    }
    if (_phase == 'difficulty') return _buildDifficultySelection();
    if (_phase == 'roundSummary') return _buildRoundSummary();
    return _buildQuizBody();
  }

  Widget _buildDifficultySelection() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.psychology_rounded, size: 64, color: Colors.pinkAccent),
          const SizedBox(height: 24),
          _difficultyBtn('Easy', 'easy', Colors.greenAccent),
          const SizedBox(height: 16),
          _difficultyBtn('Medium', 'medium', Colors.orangeAccent),
          const SizedBox(height: 16),
          _difficultyBtn('Hard', 'hard', Colors.redAccent),
        ],
      ),
    );
  }

  Widget _difficultyBtn(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: InkWell(
        onTap: () {
          _selectedDifficulty = value;
          _fetchRound();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            border: Border.all(color: color.withValues(alpha: 0.6), width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(label,
              style: GoogleFonts.outfit(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2)),
        ),
      ),
    );
  }

  Widget _buildQuizBody() {
    if (_roundQuestions.isEmpty) {
      return Center(
          child: Text('No questions loaded.',
              style: GoogleFonts.outfit(color: Colors.white54)));
    }
    final q = _roundQuestions[_currentQ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Round progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (_currentQ + 1) / _questionsPerRound,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation(Colors.pinkAccent),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          // Timer bar
          AnimatedBuilder(
            animation: _timerController,
            builder: (_, __) {
              final remaining = 1.0 - _timerController.value;
              final color = remaining > 0.5
                  ? Colors.greenAccent
                  : remaining > 0.25
                      ? Colors.orangeAccent
                      : Colors.redAccent;
              return ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: remaining,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 4,
                ),
              );
            },
          ),
          const SizedBox(height: 18),
          // Question card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: Colors.pinkAccent.withValues(alpha: 0.22)),
              boxShadow: [
                BoxShadow(
                    color: Colors.pinkAccent.withValues(alpha: 0.10),
                    blurRadius: 18),
              ],
            ),
            child: Text(
              q['q'] as String,
              style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.4),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 22),
          // Answer options
          ...List.generate(4, (i) {
            final opts = q['opts'] as List<dynamic>;
            final isCorrect = i == q['ans'];
            final isSelected = i == _selectedIdx;

            Color borderColor = Colors.white.withValues(alpha: 0.12);
            Color bgColor = Colors.white.withValues(alpha: 0.06);
            Color textColor = Colors.white70;
            IconData? trailingIcon;

            if (_answered) {
              if (isCorrect) {
                borderColor = Colors.greenAccent;
                bgColor = Colors.greenAccent.withValues(alpha: 0.15);
                textColor = Colors.greenAccent;
                trailingIcon = Icons.check_circle_rounded;
              } else if (isSelected) {
                borderColor = Colors.redAccent;
                bgColor = Colors.redAccent.withValues(alpha: 0.14);
                textColor = Colors.redAccent;
                trailingIcon = Icons.cancel_rounded;
              }
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: GestureDetector(
                onTap: () => _answer(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor, width: 1.2),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                        child: Text(['A', 'B', 'C', 'D'][i],
                            style: GoogleFonts.outfit(
                                color: textColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 12)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(opts[i] as String,
                            style: GoogleFonts.outfit(
                                fontSize: 15,
                                color: textColor,
                                fontWeight: FontWeight.w600)),
                      ),
                      if (trailingIcon != null)
                        Icon(trailingIcon, color: textColor, size: 20),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRoundSummary() {
    final grade = _gradeLabel();
    final gradeColor = _gradeColor();
    final pct = _roundScore / _questionsPerRound;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(grade,
                style: GoogleFonts.outfit(
                    color: gradeColor,
                    fontSize: 32,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 18),
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: gradeColor, width: 3),
                boxShadow: [
                  BoxShadow(
                      color: gradeColor.withValues(alpha: 0.30),
                      blurRadius: 28,
                      spreadRadius: 4),
                ],
              ),
              alignment: Alignment.center,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('$_roundScore/$_questionsPerRound',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900)),
                Text('${(pct * 100).round()}%',
                    style: GoogleFonts.outfit(
                        color: Colors.white60, fontSize: 13)),
              ]),
            ),
            const SizedBox(height: 18),
            Text('Total Score: $_totalScore pts',
                style: GoogleFonts.outfit(
                    color: Colors.amberAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('Round $_round complete!',
                style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                ),
                onPressed: _nextRound,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text('Next Round →',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Exit Quiz',
                  style:
                      GoogleFonts.outfit(color: Colors.white38, fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BLOCK BLAST GAME
// Place tetromino-like pieces onto an 8×8 grid. Full rows/cols clear for score.
// ─────────────────────────────────────────────────────────────────────────────

// All possible piece shapes (list of [row, col] offsets from an anchor)
const List<List<List<int>>> _kBlockBlastPieces = [
  // O-piece (2×2)
  [
    [0, 0],
    [0, 1],
    [1, 0],
    [1, 1]
  ],
  // I-piece horizontal
  [
    [0, 0],
    [0, 1],
    [0, 2],
    [0, 3]
  ],
  // I-piece vertical
  [
    [0, 0],
    [1, 0],
    [2, 0],
    [3, 0]
  ],
  // L-piece
  [
    [0, 0],
    [1, 0],
    [2, 0],
    [2, 1]
  ],
  // J-piece
  [
    [0, 1],
    [1, 1],
    [2, 0],
    [2, 1]
  ],
  // S-piece
  [
    [0, 1],
    [0, 2],
    [1, 0],
    [1, 1]
  ],
  // Z-piece
  [
    [0, 0],
    [0, 1],
    [1, 1],
    [1, 2]
  ],
  // T-piece
  [
    [0, 0],
    [0, 1],
    [0, 2],
    [1, 1]
  ],
  // Single cell
  [
    [0, 0]
  ],
  // 2×1
  [
    [0, 0],
    [0, 1]
  ],
  // 1×2
  [
    [0, 0],
    [1, 0]
  ],
  // 3×1
  [
    [0, 0],
    [0, 1],
    [0, 2]
  ],
  // 1×3
  [
    [0, 0],
    [1, 0],
    [2, 0]
  ],
  // 2×2 corner
  [
    [0, 0],
    [0, 1],
    [1, 0]
  ],
  [
    [0, 0],
    [0, 1],
    [1, 1]
  ],
];

const List<Color> _kBlockColors = [
  Color(0xFFFF4081),
  Color(0xFF26C6DA),
  Color(0xFF7C4DFF),
  Color(0xFF00E676),
  Color(0xFFFF9100),
  Color(0xFFEC407A),
  Color(0xFF40C4FF),
];

class BlockBlastPage extends StatefulWidget {
  const BlockBlastPage({super.key});
  @override
  State<BlockBlastPage> createState() => _BlockBlastPageState();
}

class _BlockBlastPageState extends State<BlockBlastPage> {
  static const int _kSize = 8;
  final Random _rng = Random();
  late final String _bgAsset;

  // Grid: null = empty, Color = filled
  List<List<Color?>> _grid =
      List.generate(_kSize, (_) => List.filled(_kSize, null));

  // 3 upcoming pieces
  late List<List<List<int>>> _tray;
  late List<Color> _trayColors;
  late List<bool> _trayUsed;
  int? _draggingIndex;

  int _score = 0;
  bool _gameOver = false;

  @override
  void initState() {
    super.initState();
    _bgAsset = _randomO2GameBackground();
    _newTray();
  }

  void _newTray() {
    _tray = List.generate(
        3, (_) => _kBlockBlastPieces[_rng.nextInt(_kBlockBlastPieces.length)]);
    _trayColors = List.generate(
        3, (_) => _kBlockColors[_rng.nextInt(_kBlockColors.length)]);
    _trayUsed = List.filled(3, false);
    _checkGameOver();
  }

  List<List<int>> _piece(int idx) => _tray[idx];

  bool _canPlace(List<List<int>> piece, int row, int col) {
    for (final cell in piece) {
      final r = row + cell[0], c = col + cell[1];
      if (r < 0 || r >= _kSize || c < 0 || c >= _kSize) return false;
      if (_grid[r][c] != null) return false;
    }
    return true;
  }

  void _place(int pieceIdx, int row, int col) {
    if (_trayUsed[pieceIdx]) return;
    final piece = _piece(pieceIdx);
    if (!_canPlace(piece, row, col)) return;
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.selectionClick();
    setState(() {
      for (final cell in piece) {
        _grid[row + cell[0]][col + cell[1]] = _trayColors[pieceIdx];
      }
      _trayUsed[pieceIdx] = true;
      _clearLines();
      if (_trayUsed.every((u) => u)) _newTray();
    });
  }

  void _clearLines() {
    // Detect full rows
    final rowsToClear = <int>[];
    for (int r = 0; r < _kSize; r++) {
      if (_grid[r].every((c) => c != null)) rowsToClear.add(r);
    }
    // Detect full columns
    final colsToClear = <int>[];
    for (int c = 0; c < _kSize; c++) {
      if (List.generate(_kSize, (r) => _grid[r][c]).every((x) => x != null)) {
        colsToClear.add(c);
      }
    }
    for (final r in rowsToClear) {
      for (int c = 0; c < _kSize; c++) {
        _grid[r][c] = null;
      }
    }
    for (final c in colsToClear) {
      for (int r = 0; r < _kSize; r++) {
        _grid[r][c] = null;
      }
    }
    _score += (rowsToClear.length + colsToClear.length) * 10;
  }

  void _checkGameOver() {
    for (int i = 0; i < 3; i++) {
      if (_trayUsed[i]) continue;
      final piece = _piece(i);
      for (int r = 0; r < _kSize; r++) {
        for (int c = 0; c < _kSize; c++) {
          if (_canPlace(piece, r, c)) return;
        }
      }
    }
    setState(() => _gameOver = true);
  }

  void _restart() {
    setState(() {
      _grid = List.generate(_kSize, (_) => List.filled(_kSize, null));
      _score = 0;
      _gameOver = false;
    });
    _newTray();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Block Blast — $_score pts',
            style: GoogleFonts.outfit(
                color: Colors.orangeAccent, fontWeight: FontWeight.w800)),
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          _GameBackdrop(
            asset: _bgAsset,
            glowColor: Colors.orangeAccent,
            surfaceTint: const Color(0xFF0A0A1A),
          ),
          SafeArea(
            child: Column(
              children: [
                // Grid
                Expanded(
                  flex: 5,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: _buildGrid(),
                      ),
                    ),
                  ),
                ),
                // Tray with 3 pieces
                Expanded(
                  flex: 3,
                  child: _buildTray(),
                ),
              ],
            ),
          ),
          if (_gameOver) _buildGameOverOverlay(),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return LayoutBuilder(builder: (ctx, constraints) {
      final cellSize = constraints.maxWidth / _kSize;
      return DragTarget<int>(
        onAcceptWithDetails: (details) {
          // Compute cell from position
          final box = ctx.findRenderObject() as RenderBox?;
          if (box == null) return;
          final local = box.globalToLocal(details.offset);
          final col = (local.dx / cellSize).floor();
          final row = (local.dy / cellSize).floor();
          if (_draggingIndex != null) _place(_draggingIndex!, row, col);
          _draggingIndex = null;
        },
        onWillAcceptWithDetails: (_) => true,
        builder: (ctx, candidateData, rejectedData) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white.withValues(alpha: 0.04),
              border: Border.all(color: Colors.white12),
            ),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _kSize,
              ),
              itemCount: _kSize * _kSize,
              itemBuilder: (ctx, idx) {
                final r = idx ~/ _kSize, c = idx % _kSize;
                final color = _grid[r][c];
                return Container(
                  margin: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: color ?? Colors.white.withValues(alpha: 0.06),
                    boxShadow: color != null
                        ? [
                            BoxShadow(
                                color: color.withValues(alpha: 0.4),
                                blurRadius: 4)
                          ]
                        : null,
                  ),
                );
              },
            ),
          );
        },
      );
    });
  }

  Widget _buildTray() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(3, (i) {
        if (_trayUsed[i]) return const SizedBox(width: 90, height: 90);
        return Draggable<int>(
          data: i,
          onDragStarted: () => _draggingIndex = i,
          onDraggableCanceled: (_, __) => _draggingIndex = null,
          feedback: _buildMiniPiece(_piece(i), _trayColors[i], scale: 2.0),
          childWhenDragging: Opacity(
              opacity: 0.3, child: _buildMiniPiece(_piece(i), _trayColors[i])),
          child: _buildMiniPiece(_piece(i), _trayColors[i]),
        );
      }),
    );
  }

  Widget _buildMiniPiece(List<List<int>> piece, Color color,
      {double scale = 1.0}) {
    if (piece.isEmpty) return const SizedBox(width: 80, height: 80);
    final maxR = piece.map((c) => c[0]).reduce(max) + 1;
    final maxC = piece.map((c) => c[1]).reduce(max) + 1;
    final cellSize = 16.0 * scale;
    final cells = <Widget>[];
    for (int r = 0; r < maxR; r++) {
      for (int c = 0; c < maxC; c++) {
        final filled = piece.any((p) => p[0] == r && p[1] == c);
        cells.add(Container(
          width: cellSize,
          height: cellSize,
          margin: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: filled ? color : Colors.transparent,
            boxShadow: filled
                ? [
                    BoxShadow(
                        color: color.withValues(alpha: 0.5), blurRadius: 4)
                  ]
                : null,
          ),
        ));
      }
    }
    return SizedBox(
      width: maxC * (cellSize + 2),
      height: maxR * (cellSize + 2),
      child: GridView.count(
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: maxC,
        padding: EdgeInsets.zero,
        children: cells,
      ),
    );
  }

  Widget _buildGameOverOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.72),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('No More Moves!',
                  style: GoogleFonts.outfit(
                      color: Colors.orangeAccent,
                      fontSize: 30,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text('Score: $_score',
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 36, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20))),
                onPressed: _restart,
                child: Text('Play Again',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BLOCK BREAKER GAME (Arkanoid / Breakout)
// ─────────────────────────────────────────────────────────────────────────────

class BlockBreakerPage extends StatefulWidget {
  const BlockBreakerPage({super.key});
  @override
  State<BlockBreakerPage> createState() => _BlockBreakerPageState();
}

class _BreakerBrick {
  double x, y, w, h;
  Color color;
  bool alive;
  _BreakerBrick(
      {required this.x,
      required this.y,
      required this.w,
      required this.h,
      required this.color})
      : alive = true;
}

class _BlockBreakerPageState extends State<BlockBreakerPage>
    with SingleTickerProviderStateMixin {
  static const double _paddleW = 80, _paddleH = 14, _ballR = 9;
  static const double _brickW = 40, _brickH = 18, _brickGap = 4;
  static const int _cols = 7, _rows = 5;

  final Random _rng = Random();
  late final String _bgAsset;
  late AnimationController _ticker;

  // Game world size (set in LayoutBuilder)
  double _w = 360, _h = 600;

  double _paddleX = 140;
  double _ballX = 180, _ballY = 450;
  double _vx = 3, _vy = -5;

  List<_BreakerBrick> _bricks = [];
  int _score = 0;
  bool _started = false, _gameOver = false, _won = false;

  @override
  void initState() {
    super.initState();
    _bgAsset = _randomO2GameBackground();
    _ticker = AnimationController(
        vsync: this, duration: const Duration(seconds: 9999))
      ..addListener(_tick);
  }

  void _initBricks() {
    _bricks = [];
    final totalBrickWidth = _cols * (_brickW + _brickGap) - _brickGap;
    final startX = (_w - totalBrickWidth) / 2;
    final startY = 60.0;
    final colors = [
      Colors.pinkAccent,
      Colors.cyanAccent,
      Colors.purpleAccent,
      Colors.orangeAccent,
      Colors.greenAccent,
    ];
    for (int r = 0; r < _rows; r++) {
      for (int c = 0; c < _cols; c++) {
        _bricks.add(_BreakerBrick(
          x: startX + c * (_brickW + _brickGap),
          y: startY + r * (_brickH + _brickGap),
          w: _brickW,
          h: _brickH,
          color: colors[r % colors.length],
        ));
      }
    }
  }

  void _startGame() {
    _paddleX = _w / 2 - _paddleW / 2;
    _ballX = _w / 2;
    _ballY = _h - 120;
    final angle = (_rng.nextDouble() * 60 - 30) * (3.14159 / 180);
    _vx = 4 * sin(angle);
    _vy = -5;
    _score = 0;
    _gameOver = false;
    _won = false;
    _initBricks();
    _started = true;
    _ticker.repeat();
  }

  void _tick() {
    if (!_started || _gameOver || _won) return;
    setState(() {
      _ballX += _vx;
      _ballY += _vy;

      // Wall bounce
      if (_ballX - _ballR <= 0) {
        _ballX = _ballR;
        _vx = _vx.abs();
      }
      if (_ballX + _ballR >= _w) {
        _ballX = _w - _ballR;
        _vx = -_vx.abs();
      }
      if (_ballY - _ballR <= 0) {
        _ballY = _ballR;
        _vy = _vy.abs();
      }

      // Paddle bounce
      final paddleTop = _h - _paddleH - 28;
      if (_ballY + _ballR >= paddleTop &&
          _ballY + _ballR <= paddleTop + _paddleH + _ballR &&
          _ballX >= _paddleX - _ballR &&
          _ballX <= _paddleX + _paddleW + _ballR) {
        // Angle based on hit position
        final hitPos = (_ballX - _paddleX) / _paddleW; // 0-1
        _vx = (hitPos - 0.5) * 10;
        _vy = -_vy.abs();
        _ballY = paddleTop - _ballR;
        SystemSound.play(SystemSoundType.click);
        HapticFeedback.selectionClick();
      }

      // Brick collision
      for (final brick in _bricks) {
        if (!brick.alive) continue;
        if (_ballX + _ballR > brick.x &&
            _ballX - _ballR < brick.x + brick.w &&
            _ballY + _ballR > brick.y &&
            _ballY - _ballR < brick.y + brick.h) {
          brick.alive = false;
          _score += 10;
          SystemSound.play(SystemSoundType.click);
          HapticFeedback.lightImpact();
          // Determine bounce direction
          final overlapLeft = (_ballX + _ballR) - brick.x;
          final overlapRight = (brick.x + brick.w) - (_ballX - _ballR);
          final overlapTop = (_ballY + _ballR) - brick.y;
          final overlapBottom = (brick.y + brick.h) - (_ballY - _ballR);
          final minLR = min(overlapLeft, overlapRight);
          final minTB = min(overlapTop, overlapBottom);
          if (minLR < minTB) {
            _vx = -_vx;
          } else {
            _vy = -_vy;
          }
          break;
        }
      }

      // Win condition
      if (_bricks.every((b) => !b.alive)) {
        _won = true;
        _ticker.stop();
      }

      // Ball fell below
      if (_ballY - _ballR > _h) {
        _gameOver = true;
        _ticker.stop();
      }
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060D18),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Block Breaker — $_score pts',
            style: GoogleFonts.outfit(
                color: Colors.cyanAccent, fontWeight: FontWeight.w800)),
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          _GameBackdrop(
            asset: _bgAsset,
            glowColor: Colors.cyanAccent,
            surfaceTint: const Color(0xFF060D18),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                _w = constraints.maxWidth;
                _h = constraints.maxHeight;
                return GestureDetector(
                  onPanUpdate: (d) {
                    if (!_started || _gameOver || _won) return;
                    setState(() {
                      _paddleX = (_paddleX + d.delta.dx)
                          .clamp(0, _w - _paddleW)
                          .toDouble();
                    });
                  },
                  onTap: () {
                    if (!_started || _gameOver || _won) {
                      _startGame();
                    }
                  },
                  child: CustomPaint(
                    size: Size(_w, _h),
                    painter: _BreakerPainter(
                      bricks: _bricks,
                      ballX: _ballX,
                      ballY: _ballY,
                      ballR: _ballR,
                      paddleX: _paddleX,
                      paddleW: _paddleW,
                      paddleH: _paddleH,
                      screenH: _h,
                    ),
                    child: (!_started || _gameOver || _won)
                        ? Center(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_won)
                                    Text('You Win! 🎉',
                                        style: GoogleFonts.outfit(
                                            color: Colors.greenAccent,
                                            fontSize: 32,
                                            fontWeight: FontWeight.w900)),
                                  if (_gameOver)
                                    Text('Game Over!',
                                        style: GoogleFonts.outfit(
                                            color: Colors.redAccent,
                                            fontSize: 32,
                                            fontWeight: FontWeight.w900)),
                                  const SizedBox(height: 8),
                                  if (_score > 0)
                                    Text('Score: $_score',
                                        style: GoogleFonts.outfit(
                                            color: Colors.white70,
                                            fontSize: 18)),
                                  const SizedBox(height: 20),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.cyanAccent,
                                        foregroundColor: Colors.black,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 36, vertical: 14),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20))),
                                    onPressed: _startGame,
                                    child: Text(
                                        _started ? 'Play Again' : 'Start',
                                        style: GoogleFonts.outfit(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16)),
                                  ),
                                ]),
                          )
                        : const SizedBox.expand(),
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

class _BreakerPainter extends CustomPainter {
  final List<_BreakerBrick> bricks;
  final double ballX, ballY, ballR, paddleX, paddleW, paddleH, screenH;

  const _BreakerPainter({
    required this.bricks,
    required this.ballX,
    required this.ballY,
    required this.ballR,
    required this.paddleX,
    required this.paddleW,
    required this.paddleH,
    required this.screenH,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF060D18),
    );

    // Bricks
    for (final b in bricks) {
      if (!b.alive) continue;
      final paint = Paint()
        ..color = b.color
        ..style = PaintingStyle.fill;
      final glowPaint = Paint()
        ..color = b.color.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      final rrect = RRect.fromRectAndRadius(
          Rect.fromLTWH(b.x, b.y, b.w, b.h), const Radius.circular(5));
      canvas.drawRRect(rrect, glowPaint);
      canvas.drawRRect(rrect, paint);
    }

    // Ball
    final ballGlow = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(Offset(ballX, ballY), ballR + 4, ballGlow);
    canvas.drawCircle(
        Offset(ballX, ballY), ballR, Paint()..color = Colors.white);

    // Paddle
    final paddleTop = screenH - paddleH - 28;
    final paddlePaint = Paint()
      ..shader = LinearGradient(colors: [Colors.cyanAccent, Colors.blueAccent])
          .createShader(Rect.fromLTWH(paddleX, paddleTop, paddleW, paddleH));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(paddleX, paddleTop, paddleW, paddleH),
            const Radius.circular(7)),
        paddlePaint);
  }

  @override
  bool shouldRepaint(_BreakerPainter old) => true;
}
