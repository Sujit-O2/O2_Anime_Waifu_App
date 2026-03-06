import 'package:flutter/material.dart';
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
    setState(() {
      _memoryLimit = prefs.getInt('flutter.advanced_memory_limit') ?? 15;
      _debugLogs = prefs.getBool('flutter.advanced_debug_logs') ?? false;
      _strictWake = prefs.getBool('flutter.advanced_strict_wake') ?? false;
    });
  }

  Future<void> _saveMemoryLimit(double value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _memoryLimit = value.toInt());
    await prefs.setInt('flutter.advanced_memory_limit', _memoryLimit);
  }

  Future<void> _saveDebugLogs(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _debugLogs = value);
    await prefs.setBool('flutter.advanced_debug_logs', _debugLogs);
  }

  Future<void> _saveStrictWake(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _strictWake = value);
    await prefs.setBool('flutter.advanced_strict_wake', _strictWake);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Advanced Settings', style: GoogleFonts.outfit()),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            Text(
              'Power User Config',
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Fine-tune the AI core behavior and hardware limits. Changes apply immediately.',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: Colors.white60,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),

            // Memory Limit Section
            _buildSectionHeader(
                Icons.memory, "Context Memory Limit", Colors.blueAccent),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Message Retention',
                        style: GoogleFonts.outfit(
                            fontSize: 16, color: Colors.white),
                      ),
                      Text(
                        '$_memoryLimit msgs',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Limits how many recent messages the AI remembers. Higher limits use more API tokens.',
                    style:
                        GoogleFonts.outfit(fontSize: 12, color: Colors.white54),
                  ),
                  const SizedBox(height: 12),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.blueAccent,
                      inactiveTrackColor: Colors.white24,
                      thumbColor: Colors.white,
                      overlayColor: Colors.blueAccent.withOpacity(0.2),
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

            const SizedBox(height: 32),

            // Core Toggles
            _buildSectionHeader(
                Icons.settings_suggest, "Core Behavior", Colors.purpleAccent),
            const SizedBox(height: 16),
            _buildToggleItem(
              title: "Enable Debug Logs",
              subtitle:
                  "Print detailed LLM reasoning and API traces to the console terminal.",
              value: _debugLogs,
              onChanged: _saveDebugLogs,
              accentColor: Colors.purpleAccent,
            ),
            const SizedBox(height: 12),
            _buildToggleItem(
              title: "Strict Wake Word Sensitivity",
              subtitle:
                  "Reduces false physical triggers, but requires you to say 'Zero Two' more clearly.",
              value: _strictWake,
              onChanged: _saveStrictWake,
              accentColor: Colors.redAccent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildToggleItem({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: value ? accentColor.withOpacity(0.5) : Colors.white12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                      fontSize: 12, color: Colors.white54, height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: accentColor,
            inactiveTrackColor: Colors.white24,
            inactiveThumbColor: Colors.white54,
          ),
        ],
      ),
    );
  }
}
