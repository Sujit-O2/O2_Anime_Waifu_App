import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:anime_waifu/services/integrations/discord_integration_manager.dart';
import 'package:anime_waifu/widgets/waifu_background.dart';

/// Discord Integration Panel - Webhooks, Event Streaming, Settings
class DiscordIntegrationPanelPage extends StatefulWidget {
  const DiscordIntegrationPanelPage({super.key});

  @override
  State<DiscordIntegrationPanelPage> createState() => _DiscordIntegrationPanelPageState();
}

class _DiscordIntegrationPanelPageState extends State<DiscordIntegrationPanelPage> {
  final DiscordIntegrationManager _discord = DiscordIntegrationManager();
  final TextEditingController _webhookCtrl = TextEditingController();
  bool _webhookEnabled = false;
  Map<String, dynamic> _stats = {};
  bool _streamAchievements = true;
  bool _streamGameVictories = true;
  bool _streamMilestones = true;
  bool _loading = true;

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
        });
      }
    } catch (e) {
      debugPrint('Error loading Discord settings: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _setupWebhook() async {
    if (_webhookCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter webhook URL', style: GoogleFonts.outfit())),
      );
      return;
    }

    final success = await _discord.setWebhookUrl('user123', _webhookCtrl.text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? '✅ Webhook configured successfully!' : '❌ Failed to setup webhook',
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Discord Integration',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w900, letterSpacing: 1.5),
        ),
        elevation: 0,
      ),
      body: WaifuBackground(
        opacity: 0.12,
        child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ===== STATUS CARD =====
              _buildCard(
                title: '🎮 Connection Status',
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: (_webhookEnabled ? Colors.green : Colors.red).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (_webhookEnabled ? Colors.green : Colors.red).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _webhookEnabled ? Icons.check_circle : Icons.cancel,
                          color: _webhookEnabled ? Colors.green : Colors.red,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _webhookEnabled ? 'Connected' : 'Disconnected',
                                style: GoogleFonts.outfit(
                                  color: _webhookEnabled ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                _webhookEnabled
                                  ? 'Discord webhook is active and sending events'
                                  : 'Set up webhook URL to enable discord integration',
                                style: GoogleFonts.outfit(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ===== WEBHOOK SETUP =====
              _buildCard(
                title: '🔗 Webhook Configuration',
                children: [
                  Text(
                    'Discord Webhook URL',
                    style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: TextField(
                      controller: _webhookCtrl,
                      style: GoogleFonts.outfit(color: Colors.white),
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'https://discord.com/api/webhooks/...',
                        hintStyle: GoogleFonts.outfit(color: Colors.white24),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _setupWebhook,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.pinkAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.3)),
                      ),
                      child: Center(
                        child: Text('Connect Webhook',
                          style: GoogleFonts.outfit(
                            color: Colors.cyanAccent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '📖 How to get webhook URL:\n1. Go to Discord server settings > Integrations\n2. Create a webhook in the channel you want\n3. Copy the webhook URL and paste it above',
                    style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11, height: 1.5),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ===== EVENT STREAMING =====
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

              // ===== STATS =====
              _buildCard(
                title: '📊 Webhook Statistics',
                children: [
                  _buildStatRow('Queued Messages', '${_stats['queuedMessages'] ?? 0}'),
                  _buildStatRow('Sent Messages', '${_stats['sentMessages'] ?? 0}'),
                  _buildStatRow('Total Events', '${_stats['totalEvents'] ?? 0}'),
                  const SizedBox(height: 8),
                  Text(
                    'Last Activity: ${_stats['lastActivity'] ?? 'None'}',
                    style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ===== MESSAGE TEMPLATES =====
              _buildCard(
                title: '💬 Message Examples',
                children: [
                  _buildTemplateExample(
                    '🏆 Achievement Unlocked',
                    'Title: "Achievement Unlocked!"\nDescription: Showing achievement tier and points\nColor: Golden (Legendary), Purple (Epic), Blue (Rare)',
                  ),
                  const SizedBox(height: 12),
                  _buildTemplateExample(
                    '🎮 Game Victory',
                    'Title: "Game Victory!"\nDescription: Game name and score\nColor: Green for wins, Red for losses',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ===== TEST BUTTON =====
              _buildCard(
                title: '🧪 Testing',
                children: [
                  GestureDetector(
                    onTap: _webhookEnabled
                      ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('✅ Test message sent to Discord!', style: GoogleFonts.outfit()),
                            backgroundColor: Colors.greenAccent,
                          ),
                        );
                      }
                      : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _webhookEnabled
                          ? Colors.cyanAccent.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _webhookEnabled
                            ? Colors.cyanAccent.withValues(alpha: 0.3)
                            : Colors.white12,
                        ),
                      ),
                      child: Center(
                        child: Text('Send Test Message',
                          style: GoogleFonts.outfit(
                            color: _webhookEnabled ? Colors.cyanAccent : Colors.white54,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ===== DISCONNECT =====
              if (_webhookEnabled)
                GestureDetector(
                  onTap: () {
                    _discord.disableWebhook();
                    setState(() => _webhookEnabled = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('❌ Webhook disconnected', style: GoogleFonts.outfit()),
                        backgroundColor: Colors.red,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Center(
                      child: Text('Disconnect Webhook',
                        style: GoogleFonts.outfit(
                          color: Colors.red,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
      ),
    );
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
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
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(description,
                style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12)),
          Text(value,
            style: GoogleFonts.outfit(
              color: Colors.cyanAccent,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateExample(String title, String content) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.outfit(color: Colors.cyanAccent, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 8),
          Text(content, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 10, height: 1.4)),
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




