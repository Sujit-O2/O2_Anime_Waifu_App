import 'package:flutter/material.dart';
import 'package:o2_waifu/config/app_themes.dart';
import 'package:o2_waifu/services/alter_ego_service.dart';
import 'package:o2_waifu/widgets/glass_container.dart';

/// Settings page with card-based layout.
/// Hidden dev config accessible by triple-tapping app logo.
class SettingsPage extends StatefulWidget {
  final AppThemeMode currentTheme;
  final AlterEgo currentAlterEgo;
  final String currentModel;
  final String currentVoice;
  final Function(AppThemeMode) onThemeChanged;
  final Function(AlterEgo) onAlterEgoChanged;
  final Function(String) onModelChanged;
  final Function(String) onVoiceChanged;
  final VoidCallback onClearHistory;

  const SettingsPage({
    super.key,
    required this.currentTheme,
    required this.currentAlterEgo,
    required this.currentModel,
    required this.currentVoice,
    required this.onThemeChanged,
    required this.onAlterEgoChanged,
    required this.onModelChanged,
    required this.onVoiceChanged,
    required this.onClearHistory,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _logoTapCount = 0;
  bool _showDevPanel = false;
  late TextEditingController _modelController;
  late TextEditingController _voiceController;

  @override
  void initState() {
    super.initState();
    _modelController = TextEditingController(text: widget.currentModel);
    _voiceController = TextEditingController(text: widget.currentVoice);
  }

  @override
  void dispose() {
    _modelController.dispose();
    _voiceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Logo with triple-tap detector
          Center(
            child: GestureDetector(
              onTap: () {
                _logoTapCount++;
                if (_logoTapCount >= 3) {
                  setState(() => _showDevPanel = !_showDevPanel);
                  _logoTapCount = 0;
                }
                Future.delayed(const Duration(seconds: 2), () {
                  _logoTapCount = 0;
                });
              },
              child: Icon(
                Icons.favorite,
                color: theme.colorScheme.primary,
                size: 48,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Theme Selection
          _buildSectionTitle('Theme'),
          const SizedBox(height: 8),
          GlassContainer(
            child: Column(
              children: AppThemeMode.values.map((mode) {
                final config = AppThemes.getConfig(mode);
                return RadioListTile<AppThemeMode>(
                  title: Text(
                    mode.name,
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                  value: mode,
                  groupValue: widget.currentTheme,
                  activeColor: config.primaryColor,
                  onChanged: (v) => widget.onThemeChanged(v!),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Persona Selection
          _buildSectionTitle('Persona'),
          const SizedBox(height: 8),
          GlassContainer(
            child: Column(
              children: AlterEgo.values.map((ego) {
                return RadioListTile<AlterEgo>(
                  title: Text(
                    ego.displayName,
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                  value: ego,
                  groupValue: widget.currentAlterEgo,
                  activeColor: theme.colorScheme.primary,
                  onChanged: (v) => widget.onAlterEgoChanged(v!),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Danger Zone
          _buildSectionTitle('Data'),
          const SizedBox(height: 8),
          GlassContainer(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('Clear Chat History',
                      style: TextStyle(color: Colors.red)),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Clear History?'),
                        content: const Text(
                            'This will delete all chat messages. This action cannot be undone.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              widget.onClearHistory();
                              Navigator.pop(ctx);
                            },
                            child: const Text('Clear',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Dev Panel (hidden)
          if (_showDevPanel) ...[
            const SizedBox(height: 24),
            _buildSectionTitle('Developer Config'),
            const SizedBox(height: 8),
            GlassContainer(
              borderColor: Colors.amber.withValues(alpha: 0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _modelController,
                    decoration: const InputDecoration(
                      labelText: 'LLM Model Name',
                      hintText: 'e.g. moonshotai/kimi-k2-instruct',
                    ),
                    onSubmitted: widget.onModelChanged,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _voiceController,
                    decoration: const InputDecoration(
                      labelText: 'TTS Voice',
                      hintText: 'e.g. aisha, autumn',
                    ),
                    onSubmitted: widget.onVoiceChanged,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Triple-tap logo to toggle this panel',
                    style: TextStyle(
                      color: Colors.amber.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
