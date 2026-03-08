import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GAMES HUB – lists all playable animated games
// ─────────────────────────────────────────────────────────────────────────────

class GamesHubPage extends StatelessWidget {
  const GamesHubPage({super.key});

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
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              backgroundColor: const Color(0xFF0A0A1A),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 22),
                onPressed: () => Navigator.canPop(context)
                    ? Navigator.pop(context)
                    : Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const ChatHomePage()),
                        (r) => false),
              ),
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                title: Text('GAME ZONE',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      color: Colors.white,
                      letterSpacing: 3,
                      shadows: [
                        Shadow(color: Colors.pinkAccent, blurRadius: 12)
                      ],
                    )),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF2D0845), Color(0xFF0A0A1A)],
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.sports_esports_rounded,
                        size: 80, color: Colors.white10),
                  ),
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
                ],
              ),
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

  @override
  void initState() {
    super.initState();
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
      body: Column(
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
                  child: CustomPaint(
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
                                          fontWeight: FontWeight.w900)),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.greenAccent,
                                      foregroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20)),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 36, vertical: 14)),
                                  onPressed: () {
                                    setState(() => _resetGame());
                                    _startGame();
                                  },
                                  child: Text(_dead ? 'Play Again' : 'Start',
                                      style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16)),
                                ),
                              ],
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ),
          // D-PAD controls
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(children: [
              _dpadBtn(Icons.keyboard_arrow_up_rounded, const Point(0, -1)),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _dpadBtn(Icons.keyboard_arrow_left_rounded, const Point(-1, 0)),
                const SizedBox(width: 56),
                _dpadBtn(Icons.keyboard_arrow_right_rounded, const Point(1, 0)),
              ]),
              _dpadBtn(Icons.keyboard_arrow_down_rounded, const Point(0, 1)),
            ]),
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

  @override
  void initState() {
    super.initState();
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
      body: Column(
        children: [
          if (won)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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

  @override
  void initState() {
    super.initState();
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
      body: GestureDetector(
        onTap: _phase == _Phase.idle || _phase == _Phase.result ? _start : _tap,
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
                Text(_phase == _Phase.result ? 'Tap anywhere to try again' : '',
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

  @override
  void initState() {
    super.initState();
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
      body: SingleChildScrollView(
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
                          color: _won ? Colors.greenAccent : Colors.pinkAccent,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            const SizedBox(height: 24),
            if (!_won) ...[
              TextField(
                controller: _ctrl,
                keyboardType: TextInputType.number,
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 20),
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
    );
  }
}
