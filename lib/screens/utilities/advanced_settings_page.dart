import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdvancedSettingsPage extends StatefulWidget {
  const AdvancedSettingsPage({super.key});

  @override
  State<AdvancedSettingsPage> createState() => _AdvancedSettingsPageState();
}

class _AdvancedSettingsPageState extends State<AdvancedSettingsPage> {
  int _memoryLimit = 15;
  bool _debugLogs = false;
  bool _strictWake = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }
    setState(() {
      _memoryLimit = prefs.getInt('flutter.advanced_memory_limit') ?? 15;
      _debugLogs = prefs.getBool('flutter.advanced_debug_logs') ?? false;
      _strictWake = prefs.getBool('flutter.advanced_strict_wake') ?? false;
    });
  }

  Future<void> _saveMemoryLimit(double value) async {
    HapticFeedback.selectionClick();
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }
    setState(() => _memoryLimit = value.toInt());
    await prefs.setInt('flutter.advanced_memory_limit', _memoryLimit);
  }

  Future<void> _saveDebugLogs(bool value) async {
    HapticFeedback.selectionClick();
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }
    setState(() => _debugLogs = value);
    await prefs.setBool('flutter.advanced_debug_logs', _debugLogs);
  }

  Future<void> _saveStrictWake(bool value) async {
    HapticFeedback.selectionClick();
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }
    setState(() => _strictWake = value);
    await prefs.setBool('flutter.advanced_strict_wake', _strictWake);
  }

  Future<void> _refresh() => _loadSettings();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: V2Theme.surfaceDark,
      body: WaifuBackground(
        opacity: 0.08,
        tint: const Color(0xFF081019),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refresh,
            color: V2Theme.primaryColor,
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
                            'ADVANCED SETTINGS',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.4,
                            ),
                          ),
                          Text(
                            'Fine tune memory, wake sensitivity, and debug behavior',
                            style: GoogleFonts.outfit(
                              color: Colors.white60,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GlassCard(
                  margin: EdgeInsets.zero,
                  glow: true,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Core tuning profile',
                              style: GoogleFonts.outfit(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _debugLogs || _strictWake
                                  ? 'Manual control enabled'
                                  : 'Balanced default profile',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Current memory retention is $_memoryLimit messages with ${_debugLogs ? 'debug traces on' : 'debug traces off'} and ${_strictWake ? 'strict wake sensitivity' : 'relaxed wake sensitivity'}.',
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
                        progress: _memoryLimit / 40,
                        foreground: V2Theme.secondaryColor,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.memory_rounded,
                              color: V2Theme.secondaryColor,
                              size: 28,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$_memoryLimit',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Msgs',
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
                const SizedBox(height: 12),

                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        title: 'Memory',
                        value: '$_memoryLimit',
                        icon: Icons.psychology_alt_rounded,
                        color: V2Theme.secondaryColor,
                      ),
                    ),
                    Expanded(
                      child: StatCard(
                        title: 'Debug',
                        value: _debugLogs ? 'On' : 'Off',
                        icon: Icons.bug_report_outlined,
                        color: Colors.purpleAccent,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        title: 'Wake',
                        value: _strictWake ? 'Strict' : 'Balanced',
                        icon: Icons.hearing_rounded,
                        color: V2Theme.primaryColor,
                      ),
                    ),
                    Expanded(
                      child: StatCard(
                        title: 'Risk',
                        value: _debugLogs || _strictWake ? 'Manual' : 'Low',
                        icon: Icons.shield_outlined,
                        color: Colors.lightGreenAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GlassCard(
                  margin: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Context Memory Limit',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Higher retention improves continuity but increases token usage and prompt cost.',
                        style: GoogleFonts.outfit(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Message retention',
                            style: GoogleFonts.outfit(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '$_memoryLimit msgs',
                            style: GoogleFonts.outfit(
                              color: V2Theme.secondaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: V2Theme.secondaryColor,
                          inactiveTrackColor: Colors.white12,
                          thumbColor: Colors.white,
                          overlayColor:
                              V2Theme.secondaryColor.withValues(alpha: 0.18),
                        ),
                        child: Slider(
                          value: _memoryLimit.toDouble(),
                          min: 5,
                          max: 40,
                          divisions: 35,
                          onChanged: _saveMemoryLimit,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _toggleCard(
                  title: 'Enable Debug Logs',
                  subtitle:
                      'Print internal reasoning traces and API details to the console.',
                  value: _debugLogs,
                  accentColor: Colors.purpleAccent,
                  onChanged: _saveDebugLogs,
                ),
                const SizedBox(height: 12),
                _toggleCard(
                  title: 'Strict Wake Word Sensitivity',
                  subtitle:
                      'Reduce false positives, but require a clearer Zero Two wake phrase.',
                  value: _strictWake,
                  accentColor: V2Theme.primaryColor,
                  onChanged: _saveStrictWake,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _toggleCard({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color accentColor,
  }) {
    return GlassCard(
      margin: EdgeInsets.zero,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    color: Colors.white60,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: accentColor,
            inactiveTrackColor: Colors.white12,
            inactiveThumbColor: Colors.white54,
          ),
        ],
      ),
    );
  }
}



