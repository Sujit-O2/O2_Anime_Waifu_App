import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anime_waifu/widgets/waifu_background.dart';

/// Plugin System v2 — Community-extensible command/API framework with
/// animated cards, search, and Zero Two context.
class PluginSystemPage extends StatefulWidget {
  const PluginSystemPage({super.key});
  @override
  State<PluginSystemPage> createState() => _PluginSystemPageState();
}

class _PluginSystemPageState extends State<PluginSystemPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  List<Map<String, dynamic>> _plugins = [];
  String _searchQuery = '';

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
      _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();
      _load();
    }

    @override
    void dispose() { _fadeCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    try {
      final stored = prefs.getString('user_plugins');
      final userPlugins = stored != null
          ? (jsonDecode(stored) as List).cast<Map<String, dynamic>>()
          : <Map<String, dynamic>>[];
      if (!mounted) return;
      setState(() => _plugins = [..._builtInPlugins, ...userPlugins]);
    } catch (_) {
      setState(() => _plugins = [..._builtInPlugins]);
    }
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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.95),
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
      final filtered = _plugins.where((p) {
        if (_searchQuery.isEmpty) return true;
        return (p['name']?.toString() ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
                (p['trigger']?.toString() ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
      final enabledCount = _plugins.where((p) => p['enabled'] == true).length;

      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: WaifuBackground(
          opacity: 0.07,
          tint: const Color(0xFF080C14),
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeCtrl,
              child: Column(children: [
                // ── Header ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Row(children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white12)),
                        child: const Icon(Icons.arrow_back_ios_new, color: Colors.white60, size: 16)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('PLUGINS', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                      Text('$enabledCount/${_plugins.length} active', style: GoogleFonts.outfit(color: Colors.cyanAccent.withValues(alpha: 0.7), fontSize: 10)),
                    ])),
                    GestureDetector(
                      onTap: _addPlugin,
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(color: Colors.cyanAccent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3))),
                        child: const Icon(Icons.add_rounded, color: Colors.cyanAccent, size: 20)),
                    ),
                  ]),
                ),

                // ── Search ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.15))),
                    child: TextField(
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
                      cursorColor: Colors.cyanAccent,
                      decoration: InputDecoration(hintText: 'Search plugins...', hintStyle: GoogleFonts.outfit(color: Colors.white24), border: InputBorder.none, icon: const Icon(Icons.search, color: Colors.white30, size: 18)),
                    ),
                  ),
                ),

                // ── Plugins List ──
                Expanded(
                  child: filtered.isEmpty
                      ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                          const Text('🔌', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 12),
                          Text('No plugins found', style: GoogleFonts.outfit(color: Colors.white30, fontSize: 14)),
                        ]))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) => _buildPluginCard(i, filtered[i]),
                        ),
                ),

                // ── Waifu Card ──
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.pinkAccent.withValues(alpha: 0.06),
                    border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.2)),
                  ),
                  child: Row(children: [
                    const Text('💕', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(child: Text(
                      '"Want to add a new ability, Darling? Plugins let me do even more for you~"',
                      style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12, fontStyle: FontStyle.italic, height: 1.5),
                    )),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      );
    }

    Widget _buildPluginCard(int index, Map<String, dynamic> p) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 300 + index * 60),
        curve: Curves.easeOut,
        builder: (_, val, child) => Opacity(opacity: val, child: Transform.translate(offset: Offset(0, 12 * (1 - val)), child: child)),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
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
              onChanged: (v) { HapticFeedback.selectionClick(); setState(() => p['enabled'] = v); _save(); },
              activeColor: Colors.cyanAccent,
            ),
          ]),
        ),
      );
    }
  }



