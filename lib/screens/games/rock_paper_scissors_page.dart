import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:anime_waifu/core/v2_upgrade_kit.dart';

class RockPaperScissorsPage extends StatefulWidget {
  const RockPaperScissorsPage({super.key});

  @override
  State<RockPaperScissorsPage> createState() => _RockPaperScissorsPageState();
}

class _RockPaperScissorsPageState extends State<RockPaperScissorsPage>
    with TickerProviderStateMixin {
  static const List<String> _emojis = <String>['✊', '✋', '✌️'];
  static const Map<String, List<String>> _comments = <String, List<String>>{
    'win': <String>[
      'Lucky shot. You win this round.',
      'Nice play. You got me.',
      'Clean win. Respect.',
    ],
    'lose': <String>[
      'Too easy. Try again.',
      'I saw that coming.',
      'Nice try. My win.',
    ],
    'draw': <String>[
      'A tie. We think alike.',
      'Same move. Again?',
      'Matched. No winner.',
    ],
  };

  int _playerWins = 0;
  int _zeroWins = 0;
  int _draws = 0;

  int? _playerChoice;
  int? _zeroChoice;
  String? _result;
  String? _comment;
  bool _revealing = false;

  late final AnimationController _bounceCtrl;
  late final Animation<double> _bounceAnim;
  late final AnimationController _pulseCtrl;

  String get _commentaryMood {
    if (_playerWins > _zeroWins) {
      return 'achievement';
    }
    if (_playerWins + _zeroWins + _draws > 0) {
      return 'motivated';
    }
    return 'neutral';
  }

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _bounceAnim = CurvedAnimation(parent: _bounceCtrl, curve: Curves.elasticOut);
    
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..repeat(reverse: true);
    
    _loadStats();
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }
    setState(() {
      _playerWins = prefs.getInt('rps_player_wins') ?? 0;
      _zeroWins = prefs.getInt('rps_zerotwo_wins') ?? 0;
      _draws = prefs.getInt('rps_draws') ?? 0;
    });
  }

  Future<void> _saveStats() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('rps_player_wins', _playerWins);
    await prefs.setInt('rps_zerotwo_wins', _zeroWins);
    await prefs.setInt('rps_draws', _draws);
  }

  Future<void> _play(int choice) async {
    if (_revealing) {
      return;
    }
    setState(() {
      _playerChoice = choice;
      _zeroChoice = null;
      _result = null;
      _comment = null;
      _revealing = true;
    });

    _bounceCtrl.reset();

    // Dramatic pause for suspense
    await Future<void>.delayed(const Duration(milliseconds: 800));
    final int zChoice = Random().nextInt(3);
    
    if (!mounted) return;
    setState(() {
        _zeroChoice = zChoice;
    });
    
    // Slight pause to process what 02 picked before displaying outcome
    await Future<void>.delayed(const Duration(milliseconds: 300));
    

    final int diff = (choice - zChoice + 3) % 3;
    final String outcome = diff == 0 ? 'draw' : diff == 1 ? 'win' : 'lose';

    if (outcome == 'win') {
      _playerWins++;
    } else if (outcome == 'lose') {
      _zeroWins++;
    } else {
      _draws++;
    }
    await _saveStats();

    final List<String> choices = _comments[outcome]!;
    final String comment = choices[Random().nextInt(choices.length)];

    if (!mounted) {
      return;
    }
    setState(() {
      _result = outcome;
      _comment = comment;
      _revealing = false;
    });
    _bounceCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return FeaturePageV2(
      title: 'ROCK PAPER SCISSORS',
      onBack: () => Navigator.pop(context),
      content: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          AnimatedEntry(
            index: 1,
            child: GlassCard(
              margin: EdgeInsets.zero,
              glow: true,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Match status',
                          style: GoogleFonts.outfit(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _result == null ? 'Choose your move' : _resultText(_result!),
                          style: GoogleFonts.outfit(
                            color: _result == 'win' ? Colors.greenAccent : _result == 'lose' ? V2Theme.primaryColor : Colors.amberAccent,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Select an element to challenge Zero Two.',
                          style: GoogleFonts.outfit(
                            color: Colors.white60,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ProgressRing(
                    progress: (_playerWins + _zeroWins + _draws) / 12, // arbitrary display scaling
                    foreground: V2Theme.primaryColor,
                    child: const Icon(
                      Icons.sports_esports_rounded,
                      color: V2Theme.primaryColor,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          AnimatedEntry(
            index: 2,
            child: WaifuCommentary(mood: _commentaryMood),
          ),
          const SizedBox(height: 12),
          AnimatedEntry(
            index: 3,
            child: _buildArena(),
          ),
          const SizedBox(height: 12),
          AnimatedEntry(
              index: 4,
              child: Column(
                  children: [
                    Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              title: 'You',
                              value: '$_playerWins',
                              icon: Icons.person_rounded,
                              color: Colors.greenAccent,
                            ),
                          ),
                          Expanded(
                            child: StatCard(
                              title: 'Zero Two',
                              value: '$_zeroWins',
                              icon: Icons.favorite_rounded,
                              color: V2Theme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              title: 'Draws',
                              value: '$_draws',
                              icon: Icons.remove_rounded,
                              color: Colors.amberAccent,
                            ),
                          ),
                          Expanded(
                            child: StatCard(
                              title: 'Round',
                              value: '${_playerWins + _zeroWins + _draws + 1}',
                              icon: Icons.timer_rounded,
                              color: V2Theme.secondaryColor,
                            ),
                          ),
                        ],
                      ),
                  ]
              ),
          ),
          const SizedBox(height: 12),
          if (_result != null)
            ScaleTransition(
              scale: _bounceAnim,
              child: GlassCard(
                margin: EdgeInsets.zero,
                child: Row(
                  children: [
                    const Icon(Icons.chat_bubble_rounded, color: Colors.white70),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _comment ?? '',
                        style: GoogleFonts.outfit(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          AnimatedEntry(
            index: 5,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List<Widget>.generate(
                3,
                (int i) => GestureDetector(
                  onTap: () => _play(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _playerChoice == i
                          ? V2Theme.primaryColor.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.06),
                      border: Border.all(
                        color: _playerChoice == i
                            ? V2Theme.primaryColor
                            : Colors.white24,
                      ),
                      boxShadow: _playerChoice == i ? [
                          BoxShadow(
                              color: V2Theme.primaryColor.withValues(alpha: 0.3),
                              blurRadius: 12,
                              spreadRadius: 2,
                          )
                      ] : [],
                    ),
                    child: Center(
                      child: Text(
                        _emojis[i],
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArena() {
      return GlassCard(
          margin: EdgeInsets.zero,
          child: Column(
              children: [
                  Text('ARENA', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  const SizedBox(height: 24),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                          // Player Choice
                          Column(
                              children: [
                                  Text('You', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13)),
                                  const SizedBox(height: 12),
                                  if (_playerChoice != null)
                                      ScaleTransition(
                                          scale: _playerChoice != null && !_revealing ? _bounceAnim : const AlwaysStoppedAnimation(1.0),
                                          child: Text(_emojis[_playerChoice!], style: const TextStyle(fontSize: 48)),
                                      )
                                  else
                                      const Icon(Icons.help_outline, color: Colors.white24, size: 48),
                                  
                              ]
                          ),
                          Text('VS', style: GoogleFonts.outfit(color: V2Theme.primaryColor, fontSize: 24, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
                          
                          // 02 Choice
                          Column(
                              children: [
                                  Text('Zero Two', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13)),
                                  const SizedBox(height: 12),
                                  if (_zeroChoice != null)
                                      ScaleTransition(
                                          scale: _bounceAnim,
                                          child: Text(_emojis[_zeroChoice!], style: const TextStyle(fontSize: 48)),
                                      )
                                  else if (_revealing)
                                      FadeTransition(
                                          opacity: _pulseCtrl,
                                          child: const Icon(Icons.sync_rounded, color: V2Theme.primaryColor, size: 48)
                                      )
                                  else 
                                      const Icon(Icons.help_outline, color: Colors.white24, size: 48),
                              ]
                          )
                      ]
                  ),
                  const SizedBox(height: 16),
              ]
          )
      );
  }

  String _resultText(String result) {
    switch (result) {
      case 'win':
        return 'You win';
      case 'lose':
        return 'Zero Two wins';
      default:
        return 'Draw';
    }
  }
}



