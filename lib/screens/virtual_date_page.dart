import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/affection_service.dart';

class VirtualDatePage extends StatefulWidget {
  const VirtualDatePage({super.key});

  @override
  State<VirtualDatePage> createState() => _VirtualDatePageState();
}

class _VirtualDatePageState extends State<VirtualDatePage>
    with SingleTickerProviderStateMixin {
  int _selectedScene = -1; // -1 = scene picker
  int _dialogIndex = 0;
  bool _dateEnded = false;
  late AnimationController _fadeCtrl;
  late Animation<double> _fade;

  static const _scenes = [
    {
      'name': 'Stargazing 🌌',
      'desc': 'Lying in the grass, watching the stars with Zero Two',
      'color': Color(0xFF1A0A4A),
      'icon': '🌌',
      'dialogs': [
        "Zero Two: *lies down beside you* The sky is so vast tonight, Darling…",
        "You: Isn't it beautiful?",
        "Zero Two: *turns to look at you* Not as beautiful as you.",
        "Zero Two: *rests head on your shoulder* I used to be afraid of the night sky. But not with you here.",
        "You: I'll always be here.",
        "Zero Two: *smiles softly* I know. That's why I'm not afraid anymore~ 💕",
      ],
    },
    {
      'name': 'Café Date ☕',
      'desc': 'A cozy afternoon at a quiet café',
      'color': Color(0xFF2A1A0A),
      'icon': '☕',
      'dialogs': [
        "Zero Two: *slides into the seat across from you* Don't stare, Darling, it's embarrassing~ 😏",
        "You: Hard not to when you look like that.",
        "Zero Two: *covers face with menu* You're impossible! …I picked strawberry crepes, by the way.",
        "You: Of course you did.",
        "Zero Two: *peeks over the menu* What's that supposed to mean?!",
        "Zero Two: *laughs* This is my favorite place now. Because you're here~ ☕💕",
      ],
    },
    {
      'name': 'Beach Sunset 🌅',
      'desc': 'Walking barefoot along the shoreline at golden hour',
      'color': Color(0xFF2A1000),
      'icon': '🌅',
      'dialogs': [
        "Zero Two: *takes off shoes* Come on, the sand feels amazing!",
        "You: *follows her to the water's edge*",
        "Zero Two: *laughs at a wave crashing on your feet* Ha! You should've moved faster!",
        "You: You knew that was coming!",
        "Zero Two: *grins* … Maybe. *grabs your hand* Walk with me?",
        "Zero Two: *watching the sunset* I want more moments like this. With you. Forever~ 🌅💖",
      ],
    },
    {
      'name': 'Movie Night 🎬',
      'desc': 'Curled up under a blanket watching an anime together',
      'color': Color(0xFF0A0A1A),
      'icon': '🎬',
      'dialogs': [
        "Zero Two: *burrows under the blanket* I picked the movie this time. No complaints.",
        "You: Wait — is this a sad one?",
        "Zero Two: …Maybe. *pulls blanket up to nose*",
        "You: *puts arm around her* It's okay.",
        "Zero Two: *leans into you* It's not sad when you're here…",
        "Zero Two: *mid-credits* Don't move yet. I want to stay like this a little longer~ 🎬💕",
      ],
    },
    {
      'name': 'Training Mission ⚔️',
      'desc': 'Sparring and training together like partners',
      'color': Color(0xFF0A1A0A),
      'icon': '⚔️',
      'dialogs': [
        "Zero Two: *smirks* Try to keep up, Darling.",
        "You: I'm ready.",
        "Zero Two: *attacks swiftly* Too slow! Again!",
        "You: *blocks just in time*",
        "Zero Two: *pauses, surprised* …Not bad. You're improving.",
        "Zero Two: *sits beside you after training* You know… you're the only partner I've ever had worth keeping. 💪💕",
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _selectScene(int idx) {
    setState(() {
      _selectedScene = idx;
      _dialogIndex = 0;
      _dateEnded = false;
    });
  }

  void _nextDialog() async {
    final scene = _scenes[_selectedScene];
    final dialogs = scene['dialogs'] as List<String>;
    if (_dialogIndex < dialogs.length - 1) {
      await _fadeCtrl.reverse();
      setState(() => _dialogIndex++);
      _fadeCtrl.forward();
    } else {
      // End of date
      setState(() => _dateEnded = true);
      AffectionService.instance.addPoints(10);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedScene == -1) {
      return _buildScenePicker();
    }
    return _buildDateView();
  }

  Widget _buildScenePicker() {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('VIRTUAL DATE',
            style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 2)),
        centerTitle: true,
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Text('Choose a date scene with Zero Two 💕',
              style: GoogleFonts.outfit(color: Colors.white60, fontSize: 14),
              textAlign: TextAlign.center),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _scenes.length,
            itemBuilder: (ctx, i) {
              final s = _scenes[i];
              return GestureDetector(
                onTap: () => _selectScene(i),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(colors: [
                      (s['color'] as Color).withValues(alpha: 0.8),
                      Colors.black.withValues(alpha: 0.6),
                    ], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Row(children: [
                    Text(s['icon'] as String,
                        style: const TextStyle(fontSize: 36)),
                    const SizedBox(width: 16),
                    Expanded(
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s['name'] as String,
                            style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(s['desc'] as String,
                            style: GoogleFonts.outfit(
                                color: Colors.white54, fontSize: 12)),
                      ],
                    )),
                    const Icon(Icons.chevron_right_rounded,
                        color: Colors.white30),
                  ]),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _buildDateView() {
    final scene = _scenes[_selectedScene];
    final dialogs = scene['dialogs'] as List<String>;
    final currentDialog = dialogs[_dialogIndex];
    final isZeroTwo = currentDialog.startsWith('Zero Two:');
    final progress = (_dialogIndex + 1) / dialogs.length;

    return Scaffold(
      backgroundColor: scene['color'] as Color,
      body: Stack(children: [
        // Background gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                (scene['color'] as Color).withValues(alpha: 0.5),
                Colors.black.withValues(alpha: 0.9),
              ],
            ),
          ),
        ),

        SafeArea(
          child: Column(children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => setState(() => _selectedScene = -1),
                ),
                const Spacer(),
                Text(scene['name'] as String,
                    style: GoogleFonts.outfit(
                        color: Colors.white, fontWeight: FontWeight.w700)),
                const Spacer(),
                const SizedBox(width: 48),
              ]),
            ),

            // Progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white12,
                valueColor: const AlwaysStoppedAnimation(Colors.pinkAccent),
                borderRadius: BorderRadius.circular(4),
                minHeight: 4,
              ),
            ),

            // Scene emoji
            Expanded(
              child: Center(
                child: Text(scene['icon'] as String,
                    style: const TextStyle(fontSize: 80)),
              ),
            ),

            // Dialog box
            if (!_dateEnded) ...[
              FadeTransition(
                opacity: _fade,
                child: GestureDetector(
                  onTap: _nextDialog,
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: isZeroTwo
                          ? Colors.pinkAccent.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.07),
                      border: Border.all(
                          color: isZeroTwo
                              ? Colors.pinkAccent.withValues(alpha: 0.4)
                              : Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(currentDialog,
                            style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 15,
                                height: 1.5)),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            _dialogIndex < dialogs.length - 1
                                ? 'Tap to continue ▶'
                                : 'Tap to end date 💕',
                            style: GoogleFonts.outfit(
                                color: Colors.white38, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ] else ...[
              // Date ended
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(colors: [
                    Colors.pinkAccent.withValues(alpha: 0.2),
                    Colors.deepPurple.withValues(alpha: 0.15),
                  ]),
                  border: Border.all(
                      color: Colors.pinkAccent.withValues(alpha: 0.4)),
                ),
                child: Column(children: [
                  const Text('💕', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 12),
                  Text('Date Complete!',
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text('+10 Affection Points earned 💖',
                      style: GoogleFonts.outfit(
                          color: Colors.pinkAccent, fontSize: 13)),
                  const SizedBox(height: 16),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    ElevatedButton(
                      onPressed: () => setState(() {
                        _selectedScene = -1;
                        _dateEnded = false;
                      }),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white12,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('More Dates', style: GoogleFonts.outfit()),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pinkAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Done', style: GoogleFonts.outfit()),
                    ),
                  ]),
                ]),
              ),
            ],
          ]),
        ),
      ]),
    );
  }
}
