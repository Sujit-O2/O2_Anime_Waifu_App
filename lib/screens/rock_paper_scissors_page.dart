import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

/// Rock Paper Scissors mini-game vs Zero Two.
class RockPaperScissorsPage extends StatefulWidget {
  const RockPaperScissorsPage({super.key});

  @override
  State<RockPaperScissorsPage> createState() => _RockPaperScissorsPageState();
}

class _RockPaperScissorsPageState extends State<RockPaperScissorsPage>
    with SingleTickerProviderStateMixin {
  static const _choices = ['✊', '✋', '✌️'];
  static const _names   = ['Rock', 'Paper', 'Scissors'];
  static const _zeroTwoComments = {
    'win':  ['Hmph... you got lucky, Darling~', 'How did you— fine. You win this round.',
              'Not bad... for a human 💕', 'I\'ll get you next time~'],
    'lose': ['Too easy~ 😏', 'Did you really think you could beat me?',
             'Better luck next time, Darling~', 'Fufufu~ 💕'],
    'draw': ['Interesting... we think the same way.', 'A tie? How boring~',
             'We\'re matched, Darling. How fitting~', 'Same mind. Same heart.'],
  };

  int _playerWins = 0;
  int _zeroTwoWins = 0;
  int _draws = 0;

  int? _playerChoice;
  int? _zeroChoice;
  String? _result; // 'win' | 'lose' | 'draw'
  String? _comment;
  bool _revealing = false;

  late AnimationController _bounceCtrl;
  late Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _bounceAnim = CurvedAnimation(parent: _bounceCtrl, curve: Curves.elasticOut);
    _loadStats();
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _playerWins  = prefs.getInt('rps_player_wins') ?? 0;
      _zeroTwoWins = prefs.getInt('rps_zerotwo_wins') ?? 0;
      _draws       = prefs.getInt('rps_draws') ?? 0;
    });
  }

  Future<void> _play(int choice) async {
    if (_revealing) return;
    setState(() {
      _playerChoice = choice;
      _zeroChoice = null;
      _result = null;
      _comment = null;
      _revealing = true;
    });

    await Future.delayed(const Duration(milliseconds: 600));
    final zChoice = Random().nextInt(3);
    final diff = (choice - zChoice + 3) % 3;
    final outcome = diff == 0 ? 'draw' : diff == 1 ? 'win' : 'lose';

    final prefs = await SharedPreferences.getInstance();
    if (outcome == 'win') {
      _playerWins++;
      await prefs.setInt('rps_player_wins', _playerWins);
    } else if (outcome == 'lose') {
      _zeroTwoWins++;
      await prefs.setInt('rps_zerotwo_wins', _zeroTwoWins);
    } else {
      _draws++;
      await prefs.setInt('rps_draws', _draws);
    }

    final comments = _zeroTwoComments[outcome]!;
    final comment = comments[Random().nextInt(comments.length)];

    setState(() {
      _zeroChoice = zChoice;
      _result = outcome;
      _comment = comment;
      _revealing = false;
    });
    _bounceCtrl.forward(from: 0);
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
        title: Text('Rock Paper Scissors',
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Scoreboard
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.pinkAccent.withValues(alpha: 0.15), Colors.purple.withValues(alpha: 0.1)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.25)),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _Score('You', _playerWins, Colors.greenAccent),
                Column(children: [
                  Text('VS', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 14, fontWeight: FontWeight.w800)),
                  Text('Draws: $_draws', style: GoogleFonts.outfit(color: Colors.white30, fontSize: 10)),
                ]),
                _Score('Zero Two', _zeroTwoWins, Colors.pinkAccent),
              ]),
            ),
            const SizedBox(height: 30),

            // Zero Two avatar fight area
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              // Player hand
              _HandDisplay(
                emoji: _playerChoice != null ? _choices[_playerChoice!] : '❓',
                label: 'You',
                color: Colors.greenAccent,
                flipped: false,
                reveal: _playerChoice != null,
              ),
              Text('⚡', style: TextStyle(fontSize: 28, color: Colors.white.withValues(alpha: 0.3))),
              // Zero Two hand
              _HandDisplay(
                emoji: _revealing ? '🤔' : (_zeroChoice != null ? _choices[_zeroChoice!] : '💕'),
                label: 'Zero Two',
                color: Colors.pinkAccent,
                flipped: true,
                reveal: _zeroChoice != null,
              ),
            ]),
            const SizedBox(height: 24),

            // Result
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _result == null
                  ? Text('Choose your move, Darling~',
                      key: const ValueKey('prompt'),
                      style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13))
                  : ScaleTransition(
                      scale: _bounceAnim,
                      child: Column(key: ValueKey(_result), children: [
                        Text(_resultEmoji(_result!), style: const TextStyle(fontSize: 44)),
                        const SizedBox(height: 6),
                        Text(_resultText(_result!),
                            style: GoogleFonts.outfit(
                                color: _resultColor(_result!),
                                fontSize: 18,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.pinkAccent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.3)),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Text('💕', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Flexible(child: Text(_comment ?? '',
                                style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontStyle: FontStyle.italic))),
                          ]),
                        ),
                      ]),
                    ),
            ),
            const Spacer(),

            // Choice buttons
            Text('Pick your move:',
                style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(3, (i) => GestureDetector(
                onTap: () => _play(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 90, height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _playerChoice == i
                        ? Colors.pinkAccent.withValues(alpha: 0.25)
                        : Colors.white.withValues(alpha: 0.06),
                    border: Border.all(
                      color: _playerChoice == i ? Colors.pinkAccent : Colors.white24,
                      width: _playerChoice == i ? 2 : 1,
                    ),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(_choices[i], style: const TextStyle(fontSize: 32)),
                    Text(_names[i], style: GoogleFonts.outfit(color: Colors.white54, fontSize: 9)),
                  ]),
                ),
              )),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _resultEmoji(String r) {
    switch (r) {
      case 'win':  return '🎉';
      case 'lose': return '😅';
      default:     return '🤝';
    }
  }

  String _resultText(String r) {
    switch (r) {
      case 'win':  return 'You Won!';
      case 'lose': return 'Zero Two Won~';
      default:     return 'Draw!';
    }
  }

  Color _resultColor(String r) {
    switch (r) {
      case 'win':  return Colors.greenAccent;
      case 'lose': return Colors.pinkAccent;
      default:     return Colors.amberAccent;
    }
  }
}

class _Score extends StatelessWidget {
  final String label;
  final int score;
  final Color color;
  const _Score(this.label, this.score, this.color);

  @override
  Widget build(BuildContext context) => Column(children: [
    Text('$score', style: GoogleFonts.outfit(color: color, fontSize: 28, fontWeight: FontWeight.w900)),
    Text(label, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11)),
  ]);
}

class _HandDisplay extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  final bool flipped;
  final bool reveal;

  const _HandDisplay({
    required this.emoji, required this.label,
    required this.color, required this.flipped, required this.reveal,
  });

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(label, style: GoogleFonts.outfit(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
    const SizedBox(height: 8),
    AnimatedScale(
      scale: reveal ? 1.0 : 0.8,
      duration: const Duration(milliseconds: 300),
      curve: Curves.elasticOut,
      child: Container(
        width: 80, height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.12),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Center(
          child: Transform(
            alignment: Alignment.center,
            transform: flipped ? (Matrix4.identity()..scale(-1.0, 1.0)) : Matrix4.identity(),
            child: Text(emoji, style: const TextStyle(fontSize: 36)),
          ),
        ),
      ),
    ),
  ]);
}
