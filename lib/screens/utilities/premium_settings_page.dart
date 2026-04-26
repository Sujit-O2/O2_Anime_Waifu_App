import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:anime_waifu/config/app_themes.dart';
import 'package:anime_waifu/widgets/premium_ui_kit.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PREMIUM SETTINGS PAGE — Reference Implementation
/// ═══════════════════════════════════════════════════════════════════════════

class PremiumSettingsPage extends StatefulWidget {
  const PremiumSettingsPage({super.key});

  @override
  State<PremiumSettingsPage> createState() => _PremiumSettingsPageState();
}

class _PremiumSettingsPageState extends State<PremiumSettingsPage> {
  bool _wakeWordEnabled = true;
  bool _notificationsEnabled = true;
  bool _hapticFeedback = true;
  bool _autoListen = false;
  bool _showTimestamps = false;
  double _ttsSpeed = 1.0;
  String _voiceModel = 'autumn';
  String _responseLength = 'normal';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.appTokens;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── App Bar ────────────────────────────────────────────────
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_rounded,
                    color: theme.colorScheme.onSurface),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'Settings',
                style: GoogleFonts.outfit(
                  color: theme.colorScheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),

            // ── Voice & Audio ──────────────────────────────────────────
            const SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Voice & Audio',
                subtitle: 'Configure speech and sound settings',
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GlassCard(
                  child: Column(
                    children: [
                      PremiumListTile(
                        leadingIcon: Icons.mic_rounded,
                        title: 'Wake Word',
                        subtitle: 'Say "Zero Two" to activate',
                        trailing: Switch(
                          value: _wakeWordEnabled,
                          onChanged: (value) {
                            setState(() => _wakeWordEnabled = value);
                          },
                        ),
                      ),
                      const PremiumDivider(margin: EdgeInsets.symmetric(horizontal: 16)),
                      PremiumListTile(
                        leadingIcon: Icons.hearing_rounded,
                        title: 'Auto Listen',
                        subtitle: 'Continuous voice input',
                        trailing: Switch(
                          value: _autoListen,
                          onChanged: (value) {
                            setState(() => _autoListen = value);
                          },
                        ),
                      ),
                      const PremiumDivider(margin: EdgeInsets.symmetric(horizontal: 16)),
                      PremiumListTile(
                        leadingIcon: Icons.record_voice_over_rounded,
                        title: 'Voice Model',
                        subtitle: _voiceModel.toUpperCase(),
                        trailing: Icon(Icons.chevron_right_rounded,
                            color: tokens.textSoft),
                        onTap: () => _showVoiceModelPicker(),
                      ),
                      const PremiumDivider(margin: EdgeInsets.symmetric(horizontal: 16)),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.speed_rounded,
                                    size: 20, color: theme.colorScheme.primary),
                                const SizedBox(width: 12),
                                Text(
                                  'TTS Speed',
                                  style: GoogleFonts.outfit(
                                    color: theme.colorScheme.onSurface,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${_ttsSpeed.toStringAsFixed(1)}x',
                                  style: GoogleFonts.outfit(
                                    color: theme.colorScheme.primary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Slider(
                              value: _ttsSpeed,
                              min: 0.5,
                              max: 2.0,
                              divisions: 15,
                              onChanged: (value) {
                                setState(() => _ttsSpeed = value);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ── Chat Settings ──────────────────────────────────────────
            const SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Chat Settings',
                subtitle: 'Customize your conversation experience',
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GlassCard(
                  child: Column(
                    children: [
                      PremiumListTile(
                        leadingIcon: Icons.schedule_rounded,
                        title: 'Show Timestamps',
                        subtitle: 'Display message times',
                        trailing: Switch(
                          value: _showTimestamps,
                          onChanged: (value) {
                            setState(() => _showTimestamps = value);
                          },
                        ),
                      ),
                      const PremiumDivider(margin: EdgeInsets.symmetric(horizontal: 16)),
                      PremiumListTile(
                        leadingIcon: Icons.text_fields_rounded,
                        title: 'Response Length',
                        subtitle: _responseLength.toUpperCase(),
                        trailing: Icon(Icons.chevron_right_rounded,
                            color: tokens.textSoft),
                        onTap: () => _showResponseLengthPicker(),
                      ),
                      const PremiumDivider(margin: EdgeInsets.symmetric(horizontal: 16)),
                      PremiumListTile(
                        leadingIcon: Icons.cleaning_services_rounded,
                        title: 'Clear Chat History',
                        subtitle: 'Delete all messages',
                        iconColor: theme.colorScheme.error,
                        trailing: Icon(Icons.chevron_right_rounded,
                            color: tokens.textSoft),
                        onTap: () => _showClearChatDialog(),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ── Notifications ──────────────────────────────────────────
            const SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Notifications',
                subtitle: 'Manage alerts and reminders',
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GlassCard(
                  child: Column(
                    children: [
                      PremiumListTile(
                        leadingIcon: Icons.notifications_rounded,
                        title: 'Push Notifications',
                        subtitle: 'Receive alerts',
                        trailing: Switch(
                          value: _notificationsEnabled,
                          onChanged: (value) {
                            setState(() => _notificationsEnabled = value);
                          },
                        ),
                      ),
                      const PremiumDivider(margin: EdgeInsets.symmetric(horizontal: 16)),
                      PremiumListTile(
                        leadingIcon: Icons.vibration_rounded,
                        title: 'Haptic Feedback',
                        subtitle: 'Vibration on interactions',
                        trailing: Switch(
                          value: _hapticFeedback,
                          onChanged: (value) {
                            setState(() => _hapticFeedback = value);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ── Advanced ───────────────────────────────────────────────
            const SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Advanced',
                subtitle: 'Developer and debug options',
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GlassCard(
                  child: Column(
                    children: [
                      PremiumListTile(
                        leadingIcon: Icons.code_rounded,
                        title: 'Developer Config',
                        subtitle: 'API keys and overrides',
                        trailing: Icon(Icons.chevron_right_rounded,
                            color: tokens.textSoft),
                        onTap: () {
                          // Navigate to dev config
                        },
                      ),
                      const PremiumDivider(margin: EdgeInsets.symmetric(horizontal: 16)),
                      PremiumListTile(
                        leadingIcon: Icons.bug_report_rounded,
                        title: 'Debug Panel',
                        subtitle: 'Performance metrics',
                        trailing: Icon(Icons.chevron_right_rounded,
                            color: tokens.textSoft),
                        onTap: () {
                          // Navigate to debug
                        },
                      ),
                      const PremiumDivider(margin: EdgeInsets.symmetric(horizontal: 16)),
                      PremiumListTile(
                        leadingIcon: Icons.storage_rounded,
                        title: 'Clear Cache',
                        subtitle: 'Free up storage',
                        trailing: Icon(Icons.chevron_right_rounded,
                            color: tokens.textSoft),
                        onTap: () => _showClearCacheDialog(),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ── About ──────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GlassCard(
                  child: Column(
                    children: [
                      PremiumListTile(
                        leadingIcon: Icons.info_outline_rounded,
                        title: 'About',
                        subtitle: 'Version 9.3 • Core 0.02',
                        trailing: Icon(Icons.chevron_right_rounded,
                            color: tokens.textSoft),
                        onTap: () {
                          // Navigate to about
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  void _showVoiceModelPicker() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        child: GlassCard(
          margin: EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Select Voice Model',
                  style: GoogleFonts.outfit(
                    color: theme.colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const PremiumDivider(hasGradient: true),
              ..._buildVoiceOptions(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildVoiceOptions() {
    final voices = ['autumn', 'hannah', 'diana', 'aisha', 'lulwa'];
    return voices.map((voice) {
      final isSelected = _voiceModel == voice;
      return PremiumListTile(
        title: voice.toUpperCase(),
        trailing: isSelected
            ? Icon(Icons.check_circle_rounded,
                color: Theme.of(context).colorScheme.primary)
            : null,
        onTap: () {
          setState(() => _voiceModel = voice);
          Navigator.pop(context);
        },
      );
    }).toList();
  }

  void _showResponseLengthPicker() {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        child: GlassCard(
          margin: EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Response Length',
                  style: GoogleFonts.outfit(
                    color: theme.colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const PremiumDivider(hasGradient: true),
              ..._buildResponseLengthOptions(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildResponseLengthOptions() {
    final options = {
      'short': 'Short (10-15 words)',
      'normal': 'Normal (15-25 words)',
      'long': 'Long (25-40 words)',
    };

    return options.entries.map((entry) {
      final isSelected = _responseLength == entry.key;
      return PremiumListTile(
        title: entry.key.toUpperCase(),
        subtitle: entry.value,
        trailing: isSelected
            ? Icon(Icons.check_circle_rounded,
                color: Theme.of(context).colorScheme.primary)
            : null,
        onTap: () {
          setState(() => _responseLength = entry.key);
          Navigator.pop(context);
        },
      );
    }).toList();
  }

  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear Chat History?',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Text(
          'This will permanently delete all messages. This action cannot be undone.',
          style: GoogleFonts.outfit(),
        ),
        actions: [
          PremiumButton(
            text: 'Cancel',
            isSecondary: true,
            onPressed: () => Navigator.pop(context),
          ),
          PremiumButton(
            text: 'Clear',
            isDestructive: true,
            onPressed: () {
              // Clear chat logic
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chat history cleared')),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear Cache?',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Text(
          'This will free up storage by removing cached images and data.',
          style: GoogleFonts.outfit(),
        ),
        actions: [
          PremiumButton(
            text: 'Cancel',
            isSecondary: true,
            onPressed: () => Navigator.pop(context),
          ),
          PremiumButton(
            text: 'Clear',
            onPressed: () {
              // Clear cache logic
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared')),
              );
            },
          ),
        ],
      ),
    );
  }
}
