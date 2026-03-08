import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
                        subtitle: 'Guess the anime word in 6 tries',
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
  final List<String> _words = [
    'ANIME',
    'OTAKU',
    'MANGA',
    'WAIFU',
    'KAWAI',
    'NINJA',
    'TITAN',
    'TOKYO',
    'GHOUL',
    'MECHA'
  ];
  late String _targetWord;
  final List<String> _guesses = [];
  String _currentGuess = '';
  final int _maxGuesses = 6;
  bool _gameOver = false;
  bool _won = false;
  late final String _bgAsset;

  @override
  void initState() {
    super.initState();
    _bgAsset = _randomO2GameBackground();
    _reset();
  }

  void _reset() {
    setState(() {
      _targetWord = _words[Random().nextInt(_words.length)];
      _guesses.clear();
      _currentGuess = '';
      _gameOver = false;
      _won = false;
    });
  }

  void _verifyGuess() {
    if (_currentGuess.length != 5) return;
    setState(() {
      _guesses.add(_currentGuess);
      if (_currentGuess == _targetWord) {
        _won = true;
        _gameOver = true;
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
            child: Column(
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
                    _won
                        ? 'Sugoi! You got it!'
                        : 'Game Over! Word was $_targetWord',
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
            ),
          ),
        ],
      ),
    );
  }
}

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// ANIME QUIZ GAME
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

class AnimeQuizPage extends StatefulWidget {
  const AnimeQuizPage({super.key});
  @override
  State<AnimeQuizPage> createState() => _AnimeQuizPageState();
}

class _AnimeQuizPageState extends State<AnimeQuizPage> {
  final List<Map<String, dynamic>> _questions = [
    {
      'q': 'Who is known as the One Punch Man?',
      'opts': ['Goku', 'Saitama', 'Naruto', 'Deku'],
      'ans': 1
    },
    {
      'q': 'What is the name of the protagonist in Attack on Titan?',
      'opts': ['Levi', 'Armin', 'Eren', 'Mikasa'],
      'ans': 2
    },
    {
      'q': 'Which anime features the Death Note?',
      'opts': ['Bleach', 'Death Note', 'Tokyo Ghoul', 'Naruto'],
      'ans': 1
    },
    {
      'q': 'What fruit gives Luffy rubber powers?',
      'opts': ['Gum-Gum Fruit', 'Mera Mera', 'Ope Ope', 'Gomu Gomu'],
      'ans': 0
    },
    {
      'q': "Who is Edward Elric's brother?",
      'opts': ['Roy', 'Alphonse', 'Hughes', 'Winry'],
      'ans': 1
    },
    {
      // new added to meet requirement
      'q': "In Darling in the Franxx, what is Zero Two's code?",
      'opts': ['016', '002', '326', '666'],
      'ans': 1
    }
  ];

  int _currentQ = 0;
  int _score = 0;
  bool _answered = false;
  int? _selectedIdx;
  bool _gameOver = false;
  late final String _bgAsset;

  @override
  void initState() {
    super.initState();
    _bgAsset = _randomO2GameBackground();
    _questions.shuffle();
  }

  void _answer(int idx) {
    if (_answered) return;
    setState(() {
      _answered = true;
      _selectedIdx = idx;
      if (idx == _questions[_currentQ]['ans']) {
        _score++;
      }
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        if (_currentQ < _questions.length - 1) {
          _currentQ++;
          _answered = false;
          _selectedIdx = null;
        } else {
          _gameOver = true;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_gameOver) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A1A24),
        appBar: AppBar(
            title: const Text('Result'), backgroundColor: Colors.transparent),
        body: Stack(
          children: [
            _GameBackdrop(
              asset: _bgAsset,
              glowColor: Colors.pinkAccent,
              surfaceTint: const Color(0xFF1A1A24),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Quiz Complete!',
                      style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 20),
                  Text('Score: $_score / ${_questions.length}',
                      style: GoogleFonts.outfit(
                          fontSize: 24, color: Colors.greenAccent)),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pinkAccent),
                    child: const Text('Back to Games',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final q = _questions[_currentQ];
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A24),
      appBar: AppBar(
        title: Text('Anime Quiz',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          _GameBackdrop(
            asset: _bgAsset,
            glowColor: Colors.pinkAccent,
            surfaceTint: const Color(0xFF1A1A24),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Question ${_currentQ + 1} of ${_questions.length}',
                    style: GoogleFonts.outfit(
                        color: Colors.white54, fontSize: 16)),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    q['q'],
                    style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.3),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 40),
                ...List.generate(4, (i) {
                  final isTarget = i == q['ans'];
                  final isSelected = i == _selectedIdx;
                  Color btnColor = Colors.white12;
                  if (_answered) {
                    if (isTarget) {
                      btnColor = Colors.green.shade600;
                    } else if (isSelected) {
                      btnColor = Colors.red.shade600;
                    }
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: ElevatedButton(
                      onPressed: () => _answer(i),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        backgroundColor: btnColor,
                        alignment: Alignment.centerLeft,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          q['opts'][i],
                          style: GoogleFonts.outfit(
                              fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
