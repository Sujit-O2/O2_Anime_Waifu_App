import 'package:anime_waifu/services/memory_context/enhanced_memory_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class EnhancedMemoryPage extends StatefulWidget {
  const EnhancedMemoryPage({super.key});

  @override
  State<EnhancedMemoryPage> createState() => _EnhancedMemoryPageState();
}

class _EnhancedMemoryPageState extends State<EnhancedMemoryPage> {
  final _service = EnhancedMemoryService.instance;
  final _keyCtrl = TextEditingController();
  final _valueCtrl = TextEditingController();
  Map<String, String> _facts = {};
  bool _loading = true;
  bool _saving = false;
  String _memoryBlock = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _keyCtrl.dispose();
    _valueCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final facts = await _service.recallAll();
    final block = await _service.buildMemoryBlock();
    if (mounted) {
      setState(() {
        _facts = facts;
        _memoryBlock = block;
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    final key = _keyCtrl.text.trim();
    final value = _valueCtrl.text.trim();
    if (key.isEmpty || value.isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() => _saving = true);
    await _service.saveFact(key, value);
    _keyCtrl.clear();
    _valueCtrl.clear();
    await _load();
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _delete(String key) async {
    HapticFeedback.mediumImpact();
    await _service.deleteFact(key);
    await _load();
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1B2E),
        title: Text('Clear All Memories?',
            style: GoogleFonts.outfit(color: Colors.white)),
        content: Text('This will delete all stored facts permanently.',
            style: GoogleFonts.outfit(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Clear', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await _service.clearAll();
      await _load();
    }
  }

  // Quick-add common facts
  static const _quickFacts = [
    {'key': 'Name', 'value': 'Sujit'},
    {'key': 'Favorite anime', 'value': 'Darling in the FranXX'},
    {'key': 'Hobby', 'value': 'Coding'},
    {'key': 'Mood today', 'value': 'Happy'},
    {'key': 'Goal', 'value': 'Build something amazing'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0B14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white60, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('🧠 Enhanced Memory',
            style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18)),
        actions: [
          if (_facts.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded,
                  color: Colors.redAccent, size: 20),
              onPressed: _clearAll,
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white38),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent))
          : Column(children: [
              // Stats
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(children: [
                  _statPill(
                      '${_facts.length}/30', 'Facts Stored', Colors.cyanAccent),
                  const SizedBox(width: 8),
                  _statPill(
                      _memoryBlock.trim().isEmpty ? 'Empty' : 'Active',
                      'Memory Block',
                      _memoryBlock.trim().isEmpty
                          ? Colors.white38
                          : Colors.greenAccent),
                ]),
              ),

              // Add fact form
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Colors.cyanAccent.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Add Memory Fact',
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _keyCtrl,
                            style: GoogleFonts.outfit(
                                color: Colors.white, fontSize: 13),
                            decoration: _inputDeco('Key (e.g. Name)'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _valueCtrl,
                            style: GoogleFonts.outfit(
                                color: Colors.white, fontSize: 13),
                            decoration: _inputDeco('Value (e.g. Sujit)'),
                            onSubmitted: (_) => _save(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _saving ? null : _save,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.cyanAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color:
                                      Colors.cyanAccent.withValues(alpha: 0.4)),
                            ),
                            child: _saving
                                ? const Padding(
                                    padding: EdgeInsets.all(10),
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.cyanAccent))
                                : const Icon(Icons.add_rounded,
                                    color: Colors.cyanAccent, size: 22),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 8),
                      // Quick add chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _quickFacts.map((f) {
                            return GestureDetector(
                              onTap: () {
                                _keyCtrl.text = f['key']!;
                                _valueCtrl.text = f['value']!;
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: Text('+ ${f['key']}',
                                    style: GoogleFonts.outfit(
                                        color: Colors.white54, fontSize: 11)),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Facts list
              Expanded(
                child: _facts.isEmpty
                    ? Center(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                            const Text('🧠', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 12),
                            Text('No facts stored yet',
                                style: GoogleFonts.outfit(
                                    color: Colors.white38, fontSize: 16)),
                            Text(
                                'Add facts above to help Zero Two remember you',
                                style: GoogleFonts.outfit(
                                    color: Colors.white24, fontSize: 12)),
                          ]))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: _facts.length,
                        itemBuilder: (ctx, i) {
                          final key = _facts.keys.elementAt(i);
                          final value = _facts[key]!;
                          return Dismissible(
                            key: ValueKey(key),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 16),
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: Colors.redAccent.withValues(alpha: 0.15),
                              ),
                              child: const Icon(Icons.delete_outline_rounded,
                                  color: Colors.redAccent),
                            ),
                            onDismissed: (_) => _delete(key),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color:
                                        Colors.white.withValues(alpha: 0.07)),
                              ),
                              child: Row(children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.cyanAccent
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.memory_rounded,
                                      color: Colors.cyanAccent, size: 16),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(key,
                                            style: GoogleFonts.outfit(
                                                color: Colors.cyanAccent,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12)),
                                        Text(value,
                                            style: GoogleFonts.outfit(
                                                color: Colors.white,
                                                fontSize: 14)),
                                      ]),
                                ),
                                GestureDetector(
                                  onTap: () => _delete(key),
                                  child: const Icon(Icons.close_rounded,
                                      color: Colors.white24, size: 18),
                                ),
                              ]),
                            ),
                          );
                        },
                      ),
              ),
            ]),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.outfit(color: Colors.white30, fontSize: 12),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.04),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      );

  Widget _statPill(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(value,
            style: GoogleFonts.outfit(
                color: color, fontWeight: FontWeight.w800, fontSize: 13)),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11)),
      ]),
    );
  }
}
