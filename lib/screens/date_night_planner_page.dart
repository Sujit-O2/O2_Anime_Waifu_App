import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_call.dart';
import '../services/affection_service.dart';

class DateNightPlannerPage extends StatefulWidget {
  const DateNightPlannerPage({super.key});
  @override
  State<DateNightPlannerPage> createState() => _DateNightPlannerPageState();
}

class _DateNightPlannerPageState extends State<DateNightPlannerPage> {
  final _vibes = [
    'Romantic 💝',
    'Adventurous 🏔️',
    'Cosy 🕯️',
    'Playful 🎮',
    'Foodie 🍜',
    'Creative 🎨'
  ];
  final _settings = [
    'Home 🏠',
    'Restaurant 🍽️',
    'Outdoors 🌿',
    'Virtual 💻',
    'Cinema 🎬',
    'Surprise me! 🎲'
  ];

  String _vibe = 'Romantic 💝';
  String _setting = 'Home 🏠';
  String _budget = 'Free';
  String _plan = '';
  bool _loading = false;
  final _budgets = ['Free', 'Under ₹500', '₹500-2000', '₹2000+'];

  Future<void> _generatePlan() async {
    setState(() {
      _loading = true;
      _plan = '';
    });
    try {
      final prompt = 'You are Zero Two from DARLING in the FRANXX. '
          'Plan a detailed, fun date night with the following preferences:\n'
          '- Vibe: $_vibe\n'
          '- Setting: $_setting\n'
          '- Budget: $_budget\n'
          'Create a step-by-step date plan with: '
          '1) What to prepare/set up, '
          '2) Activities (at least 3), '
          '3) Food/snacks suggestion, '
          '4) A romantic finale. '
          'Speak as Zero Two planning this WITH me, warm and excited. Use emojis!';
      final reply = await ApiService().sendConversation([
        {'role': 'user', 'content': prompt},
      ]);
      setState(() => _plan = reply);
      AffectionService.instance.addPoints(5);
    } catch (e) {
      setState(() =>
          _plan = 'Something went wrong~ Let me think of something else!');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('DATE NIGHT PLANNER',
            style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Intro
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.pinkAccent.withValues(alpha: 0.08),
              border:
                  Border.all(color: Colors.pinkAccent.withValues(alpha: 0.2)),
            ),
            child: Row(children: [
              const Text('💞', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(
                'Tell me what kind of date you want, Darling~ I\'ll plan the perfect night for us!',
                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12),
              )),
            ]),
          ),

          _label('Vibe'),
          _chips(_vibes, _vibe, (v) => setState(() => _vibe = v),
              Colors.pinkAccent),
          const SizedBox(height: 16),
          _label('Setting'),
          _chips(_settings, _setting, (v) => setState(() => _setting = v),
              Colors.deepPurpleAccent),
          const SizedBox(height: 16),
          _label('Budget'),
          _chips(_budgets, _budget, (v) => setState(() => _budget = v),
              Colors.greenAccent),
          const SizedBox(height: 24),

          // Generate button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                    colors: [Color(0xFFFF4D8D), Color(0xFFB44FD6)]),
                boxShadow: [
                  BoxShadow(
                      color: Colors.pinkAccent.withValues(alpha: 0.4),
                      blurRadius: 18,
                      offset: const Offset(0, 6))
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _generatePlan,
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.favorite_rounded, size: 18),
                label: Text(
                    _loading ? 'Zero Two is planning~' : 'Plan Our Date Night!',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ),

          // Plan output
          if (_plan.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white.withValues(alpha: 0.03),
                border: Border.all(
                    color: Colors.pinkAccent.withValues(alpha: 0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Text('💌', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text('Our Date Plan~',
                        style: GoogleFonts.outfit(
                            color: Colors.pinkAccent,
                            fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 12),
                  Text(_plan,
                      style: GoogleFonts.outfit(
                          color: Colors.white70, fontSize: 14, height: 1.7)),
                ],
              ),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: GoogleFonts.outfit(
                color: Colors.white60, fontSize: 11, letterSpacing: 1.5)),
      );

  Widget _chips(List<String> items, String selected,
          ValueChanged<String> onSelect, Color color) =>
      Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) {
            final sel = item == selected;
            return GestureDetector(
              onTap: () => onSelect(item),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: sel
                      ? color.withValues(alpha: 0.18)
                      : Colors.white.withValues(alpha: 0.04),
                  border: Border.all(
                      color:
                          sel ? color.withValues(alpha: 0.6) : Colors.white12),
                ),
                child: Text(item,
                    style: GoogleFonts.outfit(
                        color: sel ? color : Colors.white54,
                        fontSize: 12,
                        fontWeight: sel ? FontWeight.w700 : FontWeight.normal)),
              ),
            );
          }).toList());
}
