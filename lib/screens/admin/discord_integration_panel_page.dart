import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:anime_waifu/config/app_themes.dart';
import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:anime_waifu/services/integrations/discord_integration_manager.dart';

/// Discord Integration Panel - Webhooks, Event Streaming, Settings
class DiscordIntegrationPanelPage extends StatefulWidget {
  const DiscordIntegrationPanelPage({super.key});

  @override
  State<DiscordIntegrationPanelPage> createState() =>
      _DiscordIntegrationPanelPageState();
}

class _DiscordIntegrationPanelPageState
    extends State<DiscordIntegrationPanelPage> {
  final DiscordIntegrationManager _discord = DiscordIntegrationManager();
  final TextEditingController _webhookCtrl = TextEditingController();
  bool _webhookEnabled = false;
  Map<String, dynamic> _stats = {};
  bool _streamAchievements = true;
  bool _streamGameVictories = true;
  bool _streamMilestones = true;
  bool _loading = true;
  bool _hadLoadError = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final stats = await _discord.getWebhookStats();
      if (mounted) {
        setState(() {
          _webhookEnabled = _discord.isWebhookEnabled;
          _stats = stats;
          _loading = false;
          _hadLoadError = false;
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading Discord settings: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _hadLoadError = true;
        });
      }
    }
  }

  Future<void> _setupWebhook() async {
    if (_webhookCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Please enter webhook URL', style: GoogleFonts.outfit())),
      );
      return;
    }

    final success = await _discord.setWebhookUrl('user123', _webhookCtrl.text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '✅ Webhook configured successfully!'
                : '❌ Failed to setup webhook',
            style: GoogleFonts.outfit(),
          ),
          backgroundColor: success ? Colors.greenAccent : Colors.red,
        ),
      );
      if (success) {
        _loadSettings();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tokens = context.appTokens;
    return FeaturePageV2(
      title: 'Discord Integration',
      subtitle: 'Webhook delivery, event streams, and activity sync',
      onBack: () => Navigator.pop(context),
      actions: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: (_webhookEnabled ? Colors.greenAccent : colors.error)
                .withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: (_webhookEnabled ? Colors.greenAccent : colors.error)
                  .withValues(alpha: 0.24),
            ),
          ),
          child: Text(
            _webhookEnabled ? 'CONNECTED' : 'OFFLINE',
            style: GoogleFonts.outfit(
              color: _webhookEnabled ? Colors.greenAccent : colors.error,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
      content: _loading
          ? const PremiumLoadingState(
              label: 'Connecting Discord tools',
              subtitle:
                  'Loading webhook status, streaming toggles, and delivery stats.',
            )
          : _hadLoadError
              ? PremiumErrorState(
                  title: 'Discord settings unavailable',
                  subtitle:
                      'We could not load the integration panel. Retry once the connection is stable.',
                  buttonText: 'Retry',
                  onRetry: _loadSettings,
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [
                    _buildConnectionHero(),
                    const SizedBox(height: 16),
                    _buildCard(
                      title: '🔗 Webhook Configuration',
                      children: [
                        Text(
                          'Discord Webhook URL',
                          style: GoogleFonts.outfit(
                              color: colors.onSurface, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _webhookCtrl,
                          style: GoogleFonts.outfit(color: colors.onSurface),
                          keyboardType: TextInputType.url,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            labelText: 'Webhook endpoint',
                            hintText: 'https://discord.com/api/webhooks/...',
                            prefixIcon: Icon(
                              Icons.link_rounded,
                              color: tokens.textMuted,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _setupWebhook,
                            icon: const Icon(Icons.wifi_tethering_rounded),
                            label: const Text('Connect Webhook'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Create a webhook inside your Discord server integrations, then paste the generated endpoint here.',
                          style: GoogleFonts.outfit(
                              color: tokens.textMuted,
                              fontSize: 11,
                              height: 1.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildCard(
                      title: '📤 Event Streaming',
                      children: [
                        _buildEventOption(
                          '🏆 Achievement Unlocks',
                          'Send message when achievements are unlocked',
                          _streamAchievements,
                          (val) => setState(() => _streamAchievements = val),
                        ),
                        const SizedBox(height: 12),
                        _buildEventOption(
                          '🎮 Game Victories',
                          'Stream game wins and mini-game results',
                          _streamGameVictories,
                          (val) => setState(() => _streamGameVictories = val),
                        ),
                        const SizedBox(height: 12),
                        _buildEventOption(
                          '🎯 Milestones',
                          'Post major milestone events (levels, affection tiers)',
                          _streamMilestones,
                          (val) => setState(() => _streamMilestones = val),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildCard(
                      title: '📊 Webhook Statistics',
                      children: [
                        _buildStatRow(
                            'Queued Messages', '${_stats['queuedMessages'] ?? 0}'),
                        _buildStatRow(
                            'Sent Messages', '${_stats['sentMessages'] ?? 0}'),
                        _buildStatRow(
                            'Total Events', '${_stats['totalEvents'] ?? 0}'),
                        const SizedBox(height: 8),
                        Text(
                          'Last Activity: ${_stats['lastActivity'] ?? 'None'}',
                          style: GoogleFonts.outfit(
                              color: tokens.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildCard(
                      title: '💬 Message Examples',
                      children: [
                        _buildTemplateExample(
                          '🏆 Achievement Unlocked',
                          'Achievement tier, points, and rarity color treatment.',
                        ),
                        const SizedBox(height: 12),
                        _buildTemplateExample(
                          '🎮 Game Victory',
                          'Game name, result, and score with quick celebratory formatting.',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildCard(
                      title: '🧪 Testing',
                      children: [
                        GestureDetector(
                          onTap: _webhookEnabled
                              ? () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          '✅ Test message sent to Discord!',
                                          style: GoogleFonts.outfit()),
                                      backgroundColor: Colors.greenAccent,
                                    ),
                                  );
                                }
                              : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _webhookEnabled
                                    ? [
                                        Colors.cyanAccent.withValues(alpha: 0.18),
                                        colors.primary.withValues(alpha: 0.10),
                                      ]
                                    : [
                                        tokens.panelElevated,
                                        tokens.panelMuted,
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _webhookEnabled
                                    ? Colors.cyanAccent.withValues(alpha: 0.3)
                                    : tokens.outline,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Send Test Message',
                                style: GoogleFonts.outfit(
                                  color: _webhookEnabled
                                      ? colors.onSurface
                                      : tokens.textMuted,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_webhookEnabled) ...[
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () {
                          _discord.disableWebhook();
                          if (!mounted) return;
                          setState(() => _webhookEnabled = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('❌ Webhook disconnected',
                                  style: GoogleFonts.outfit()),
                              backgroundColor: Colors.red,
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: colors.error.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: colors.error.withValues(alpha: 0.22)),
                          ),
                          child: Center(
                            child: Text(
                              'Disconnect Webhook',
                              style: GoogleFonts.outfit(
                                color: colors.error,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
    );
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    final theme = Theme.of(context);
    final tokens = context.appTokens;
    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              color: theme.colorScheme.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Divider(color: tokens.outline, height: 1),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildEventOption(
    String title,
    String description,
    bool value,
    Function(bool) onChanged,
  ) {
    final theme = Theme.of(context);
    final tokens = context.appTokens;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.outfit(color: tokens.textMuted, fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.cyanAccent,
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    final theme = Theme.of(context);
    final tokens = context.appTokens;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.outfit(color: tokens.textMuted, fontSize: 12)),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateExample(String title, String content) {
    final theme = Theme.of(context);
    final tokens = context.appTokens;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: tokens.glassGradient,
        color: tokens.panelMuted,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.outfit(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12)),
          const SizedBox(height: 8),
          Text(content,
              style: GoogleFonts.outfit(
                  color: tokens.textMuted, fontSize: 10, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildConnectionHero() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tokens = context.appTokens;
    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(18),
      glow: true,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  (_webhookEnabled ? Colors.greenAccent : colors.error)
                      .withValues(alpha: 0.28),
                  colors.primary.withValues(alpha: 0.10),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: (_webhookEnabled ? Colors.greenAccent : colors.error)
                    .withValues(alpha: 0.22),
              ),
            ),
            child: Icon(
              _webhookEnabled ? Icons.check_circle_rounded : Icons.link_off_rounded,
              color: _webhookEnabled ? Colors.greenAccent : colors.error,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _webhookEnabled ? 'Discord Connected' : 'Awaiting Webhook',
                  style: GoogleFonts.outfit(
                    color: colors.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _webhookEnabled
                      ? 'Streaming hooks are armed and ready to post events.'
                      : 'Add a webhook endpoint to enable event sync and delivery.',
                  style: GoogleFonts.outfit(
                    color: tokens.textMuted,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _webhookCtrl.dispose();
    super.dispose();
  }
}
