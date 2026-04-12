import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:anime_waifu/core/v2_upgrade_kit.dart';

class PasswordGeneratorPage extends StatefulWidget {
  const PasswordGeneratorPage({super.key});

  @override
  State<PasswordGeneratorPage> createState() => _PasswordGeneratorPageState();
}

class _PasswordGeneratorPageState extends State<PasswordGeneratorPage>
    with SingleTickerProviderStateMixin {
  static const String _historyKey = 'password_gen_history';
  static const String _settingsKey = 'password_gen_settings';

  double _length = 16;
  bool _upper = true;
  bool _lower = true;
  bool _numbers = true;
  bool _symbols = true;
  String _password = '';
  List<Map<String, dynamic>> _history = <Map<String, dynamic>>[];
  late final AnimationController _glowCtrl;

  String get _commentaryMood {
    if (_strength >= 4) {
      return 'achievement';
    }
    if (_history.length >= 3) {
      return 'motivated';
    }
    return 'neutral';
  }

  int get _strength {
    int score = 0;
    if (_password.length >= 12) score++;
    if (_password.length >= 20) score++;
    if (_upper && RegExp(r'[A-Z]').hasMatch(_password)) score++;
    if (_numbers && RegExp(r'[0-9]').hasMatch(_password)) score++;
    if (_symbols &&
        RegExp(r'[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]').hasMatch(_password)) {
      score++;
    }
    return score.clamp(0, 4);
  }

  String get _strengthLabel =>
      <String>['Weak', 'Fair', 'Good', 'Strong', 'Very Strong'][_strength];

  Color get _strengthColor => <Color>[
        Colors.redAccent,
        Colors.orangeAccent,
        Colors.amberAccent,
        Colors.greenAccent,
        Colors.cyanAccent,
      ][_strength];

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _bootstrap();
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await _load();
    if (!mounted) {
      return;
    }
    if (_history.isNotEmpty) {
      setState(() {
        _password = _history.first['pw']?.toString() ?? '';
      });
    } else {
      _generate();
    }
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final config =
          jsonDecode(prefs.getString(_settingsKey) ?? '{}') as Map<String, dynamic>;
      _length = (config['length'] as num?)?.toDouble() ?? _length;
      _upper = config['upper'] as bool? ?? _upper;
      _lower = config['lower'] as bool? ?? _lower;
      _numbers = config['numbers'] as bool? ?? _numbers;
      _symbols = config['symbols'] as bool? ?? _symbols;
    } catch (_) {}

    try {
      final decoded = jsonDecode(prefs.getString(_historyKey) ?? '[]') as List;
      _history = decoded
          .map((entry) => Map<String, dynamic>.from(entry as Map))
          .toList();
    } catch (_) {}

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _settingsKey,
      jsonEncode(<String, dynamic>{
        'length': _length,
        'upper': _upper,
        'lower': _lower,
        'numbers': _numbers,
        'symbols': _symbols,
      }),
    );
    await prefs.setString(
      _historyKey,
      jsonEncode(_history.take(15).toList()),
    );
  }

  Future<void> _refresh() async {
    _generate();
  }

  void _generate() {
    String chars = '';
    if (_lower) chars += 'abcdefghijklmnopqrstuvwxyz';
    if (_upper) chars += 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    if (_numbers) chars += '0123456789';
    if (_symbols) chars += r'!@#$%^&*()_+-=[]{}|;:,.<>?';
    if (chars.isEmpty) {
      chars = 'abcdefghijklmnopqrstuvwxyz';
    }

    final rng = Random.secure();
    final password = List<String>.generate(
      _length.round(),
      (_) => chars[rng.nextInt(chars.length)],
    ).join();

    HapticFeedback.lightImpact();
    _glowCtrl.forward(from: 0);
    setState(() {
      _password = password;
      _history.insert(0, <String, dynamic>{
        'pw': password,
        'time': DateTime.now().millisecondsSinceEpoch,
        'length': _length.round(),
      });
    });
    _save();
  }

  void _copyCurrent() {
    if (_password.isEmpty) {
      return;
    }
    Clipboard.setData(ClipboardData(text: _password));
    HapticFeedback.mediumImpact();
    showSuccessSnackbar(context, 'Copied to clipboard.');
  }

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.mediumImpact();
    showSuccessSnackbar(context, 'Copied to clipboard.');
  }

  void _clearHistory() {
    HapticFeedback.lightImpact();
    setState(() => _history.clear());
    _save();
    showSuccessSnackbar(context, 'Password history cleared.');
  }

  String _timeAgo(int ms) {
    final diff = DateTime.now()
        .difference(DateTime.fromMillisecondsSinceEpoch(ms));
    if (diff.inDays > 0) {
      return '${diff.inDays}d';
    }
    if (diff.inHours > 0) {
      return '${diff.inHours}h';
    }
    return '${diff.inMinutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: V2Theme.surfaceDark,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: V2Theme.primaryColor,
          backgroundColor: V2Theme.surfaceLight,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white70,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PASSWORD GEN',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          'Secure password generator',
                          style: GoogleFonts.outfit(
                            color: Colors.greenAccent,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _clearHistory,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white70,
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('Clear'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AnimatedEntry(
                index: 0,
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
                              'Security snapshot',
                              style: GoogleFonts.outfit(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _strengthLabel,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your current key is ${_length.round()} characters long and the vault remembers ${_history.length} recent generations.',
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
                        progress: _strength / 4,
                        foreground: _strengthColor,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.security_rounded,
                              color: _strengthColor,
                              size: 28,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${_length.round()}',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Chars',
                              style: GoogleFonts.outfit(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              AnimatedEntry(
                index: 1,
                child: WaifuCommentary(mood: _commentaryMood),
              ),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Strength',
                      value: _strengthLabel,
                      icon: Icons.speed_rounded,
                      color: _strengthColor,
                    ),
                  ),
                  Expanded(
                    child: StatCard(
                      title: 'History',
                      value: '${_history.length}',
                      icon: Icons.history_rounded,
                      color: V2Theme.primaryColor,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Uppercase',
                      value: _upper ? 'On' : 'Off',
                      icon: Icons.text_fields_rounded,
                      color: V2Theme.secondaryColor,
                    ),
                  ),
                  Expanded(
                    child: StatCard(
                      title: 'Symbols',
                      value: _symbols ? 'On' : 'Off',
                      icon: Icons.tag_rounded,
                      color: Colors.amberAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AnimatedBuilder(
                animation: _glowCtrl,
                builder: (_, __) => GlassCard(
                  margin: EdgeInsets.zero,
                  padding: const EdgeInsets.all(18),
                  glow: true,
                  child: Column(
                    children: [
                      SelectableText(
                        _password,
                        style: GoogleFonts.firaCode(
                          color: Colors.greenAccent,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FilledButton.icon(
                            onPressed: _copyCurrent,
                            style: FilledButton.styleFrom(
                              backgroundColor:
                                  Colors.greenAccent.withValues(alpha: 0.2),
                              foregroundColor: Colors.greenAccent,
                            ),
                            icon: const Icon(Icons.copy_rounded, size: 16),
                            label: const Text('Copy'),
                          ),
                          const SizedBox(width: 10),
                          FilledButton.icon(
                            onPressed: _generate,
                            style: FilledButton.styleFrom(
                              backgroundColor:
                                  V2Theme.secondaryColor.withValues(alpha: 0.2),
                              foregroundColor: V2Theme.secondaryColor,
                            ),
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('Regenerate'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              GlassCard(
                margin: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Length',
                          style: GoogleFonts.outfit(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '${_length.round()} chars',
                          style: GoogleFonts.outfit(
                            color: Colors.greenAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: Colors.greenAccent,
                        inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
                        thumbColor: Colors.greenAccent,
                        overlayColor: Colors.greenAccent.withValues(alpha: 0.1),
                      ),
                      child: Slider(
                        value: _length,
                        min: 4,
                        max: 64,
                        divisions: 60,
                        onChanged: (value) {
                          setState(() => _length = value);
                          _generate();
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    _toggleRow(
                      'ABC',
                      'Uppercase',
                      _upper,
                      (value) {
                        setState(() => _upper = value);
                        _generate();
                      },
                    ),
                    _toggleRow(
                      'abc',
                      'Lowercase',
                      _lower,
                      (value) {
                        setState(() => _lower = value);
                        _generate();
                      },
                    ),
                    _toggleRow(
                      '123',
                      'Numbers',
                      _numbers,
                      (value) {
                        setState(() => _numbers = value);
                        _generate();
                      },
                    ),
                    _toggleRow(
                      '#!@',
                      'Symbols',
                      _symbols,
                      (value) {
                        setState(() => _symbols = value);
                        _generate();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (_history.isEmpty)
                GlassCard(
                  margin: EdgeInsets.zero,
                  child: const EmptyState(
                    icon: Icons.history_toggle_off_rounded,
                    title: 'No saved history yet',
                    subtitle:
                        'Generate a few passwords and your recent secure mixes will show up here.',
                  ),
                )
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'RECENT PASSWORDS',
                        style: GoogleFonts.outfit(
                          color: Colors.white38,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    Text(
                      'Tap any row to copy',
                      style: GoogleFonts.outfit(
                        color: Colors.white30,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ..._history.take(10).map(
                      (entry) => GestureDetector(
                        onTap: () => _copy(entry['pw']?.toString() ?? ''),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  entry['pw']?.toString() ?? '',
                                  style: GoogleFonts.firaCode(
                                    color: Colors.white54,
                                    fontSize: 11,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${entry['length']}ch | ${_timeAgo(entry['time'] as int)}',
                                style: GoogleFonts.outfit(
                                  color: Colors.white24,
                                  fontSize: 9,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.copy_rounded,
                                color: Colors.white24,
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _toggleRow(
    String badge,
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: value
                    ? Colors.greenAccent.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.04),
                border: Border.all(
                  color: value ? Colors.greenAccent : Colors.white12,
                ),
              ),
              child: Center(
                child: Text(
                  badge,
                  style: GoogleFonts.firaCode(
                    color: value ? Colors.greenAccent : Colors.white24,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: value ? Colors.white : Colors.white38,
                fontSize: 12,
              ),
            ),
            const Spacer(),
            Icon(
              value ? Icons.toggle_on : Icons.toggle_off,
              color: value ? Colors.greenAccent : Colors.white24,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}



