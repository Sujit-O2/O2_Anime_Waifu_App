import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Plugin System — Community-extensible command/API framework.
/// Users can add custom commands that trigger API calls or built-in actions.
class PluginSystemPage extends StatefulWidget {
  const PluginSystemPage({super.key});
  @override
  State<PluginSystemPage> createState() => _PluginSystemPageState();
}

class _PluginSystemPageState extends State<PluginSystemPage> {
  List<Map<String, dynamic>> _plugins = [];

  // Built-in plugins
  static final _builtInPlugins = <Map<String, dynamic>>[
    {'name': 'Weather', 'trigger': 'weather in', 'api': 'openweathermap', 'icon': '🌤️', 'enabled': true, 'builtIn': true, 'desc': 'Get current weather for any city'},
    {'name': 'Crypto Price', 'trigger': 'price of', 'api': 'coingecko', 'icon': '₿', 'enabled': true, 'builtIn': true, 'desc': 'Check cryptocurrency prices'},
    {'name': 'Anime Search', 'trigger': 'anime', 'api': 'jikan', 'icon': '🎬', 'enabled': true, 'builtIn': true, 'desc': 'Search anime info via Jikan API'},
    {'name': 'Random Fact', 'trigger': 'tell me a fact', 'api': 'uselessfacts', 'icon': '🧠', 'enabled': true, 'builtIn': true, 'desc': 'Random interesting facts'},
    {'name': 'Quote', 'trigger': 'quote', 'api': 'quotable', 'icon': '💬', 'enabled': true, 'builtIn': true, 'desc': 'Inspirational quotes'},
    {'name': 'Joke', 'trigger': 'tell me a joke', 'api': 'jokeapi', 'icon': '😂', 'enabled': true, 'builtIn': true, 'desc': 'Random dad jokes'},
    {'name': 'News', 'trigger': 'news about', 'api': 'newsapi', 'icon': '📰', 'enabled': false, 'builtIn': true, 'desc': 'Search latest news (needs API key)'},
    {'name': 'Dictionary', 'trigger': 'define', 'api': 'dictionaryapi', 'icon': '📖', 'enabled': true, 'builtIn': true, 'desc': 'Word definitions'},
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('user_plugins');
    final userPlugins = stored != null
        ? (jsonDecode(stored) as List).cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];
    setState(() => _plugins = [..._builtInPlugins, ...userPlugins]);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final userOnly = _plugins.where((p) => p['builtIn'] != true).toList();
    await prefs.setString('user_plugins', jsonEncode(userOnly));
  }

  void _addPlugin() {
    final nameCtrl = TextEditingController();
    final triggerCtrl = TextEditingController();
    final apiCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Add Plugin', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800)),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          _field(nameCtrl, 'Plugin Name', Icons.extension),
          const SizedBox(height: 10),
          _field(triggerCtrl, 'Trigger Phrase', Icons.record_voice_over),
          const SizedBox(height: 10),
          _field(apiCtrl, 'API / Action', Icons.api),
          const SizedBox(height: 10),
          _field(descCtrl, 'Description', Icons.description),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.white54))),
          TextButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && triggerCtrl.text.isNotEmpty) {
                setState(() {
                  _plugins.add({
                    'name': nameCtrl.text, 'trigger': triggerCtrl.text,
                    'api': apiCtrl.text, 'icon': '🔌', 'enabled': true,
                    'builtIn': false, 'desc': descCtrl.text,
                  });
                });
                _save();
                Navigator.pop(ctx);
              }
            },
            child: Text('ADD', style: GoogleFonts.outfit(color: Colors.cyanAccent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String hint, IconData icon) {
    return TextField(
      controller: c,
      style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
      cursorColor: Colors.cyanAccent,
      decoration: InputDecoration(
        hintText: hint, hintStyle: GoogleFonts.outfit(color: Colors.white24),
        prefixIcon: Icon(icon, color: Colors.cyanAccent.withValues(alpha: 0.6), size: 18),
        filled: true, fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70), onPressed: () => Navigator.pop(context)),
        title: Text('PLUGINS', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPlugin,
        backgroundColor: Colors.cyanAccent,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _plugins.length,
        itemBuilder: (_, i) {
          final p = _plugins[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: (p['enabled'] == true ? Colors.cyanAccent : Colors.white12).withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              Text(p['icon'] ?? '🔌', style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(p['name'] ?? '', style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                  if (p['builtIn'] == true) ...[
                    const SizedBox(width: 6),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.cyanAccent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                      child: Text('BUILT-IN', style: GoogleFonts.outfit(color: Colors.cyanAccent, fontSize: 8, fontWeight: FontWeight.w700))),
                  ],
                ]),
                Text('Trigger: "${p['trigger']}"', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11)),
                if ((p['desc'] ?? '').isNotEmpty) Text(p['desc'], style: GoogleFonts.outfit(color: Colors.white54, fontSize: 10)),
              ])),
              Switch(
                value: p['enabled'] == true,
                onChanged: (v) { setState(() => _plugins[i]['enabled'] = v); _save(); },
                activeColor: Colors.cyanAccent,
              ),
            ]),
          );
        },
      ),
    );
  }
}
