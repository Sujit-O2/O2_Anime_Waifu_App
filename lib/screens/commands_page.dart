import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart'; // To access ChatHomePage

// ─────────────────────────────────────────────────────────────────────────────
// Commands Reference Page
// Shows all example commands grouped by category with expandable cards.
// ─────────────────────────────────────────────────────────────────────────────

class CommandsPage extends StatelessWidget {
  const CommandsPage({super.key});

  static const _categories = <_CmdCat>[
    _CmdCat(
      icon: Icons.phone_rounded,
      color: Colors.greenAccent,
      title: 'Calls & Communication',
      cmds: [
        _Cmd('Call someone', '"Call Mom" / "Dial 9876543210"'),
        _Cmd('WhatsApp message', '"WhatsApp John saying I\'ll be late"'),
        _Cmd('Send email', '"Open Gmail" / "Open my email"'),
        _Cmd('Share text',
            '"Share this — Hello World!" / "Share my location text"'),
      ],
    ),
    _CmdCat(
      icon: Icons.search_rounded,
      color: Colors.cyanAccent,
      title: 'Search & Web',
      cmds: [
        _Cmd(
            'Google search', '"Search anime news" / "Search best phones 2025"'),
        _Cmd('Open website', '"Open amazon.com" / "Go to github.com"'),
        _Cmd('Open YouTube', '"Open YouTube" / "Open app YouTube"'),
        _Cmd('Google Maps navigate',
            '"Navigate to Bhubaneswar" / "Directions to airport"'),
      ],
    ),
    _CmdCat(
      icon: Icons.alarm_rounded,
      color: Colors.orangeAccent,
      title: 'Alarms & Timers',
      cmds: [
        _Cmd(
            'Set absolute alarm', '"Set alarm at 7:30 AM" / "Wake me at 6 AM"'),
        _Cmd('Set relative alarm',
            '"Set alarm in 10 minutes" / "Alarm after 1 hour"'),
        _Cmd('Set timer', '"Set timer for 5 minutes" / "Timer for 30 seconds"'),
        _Cmd('Set reminder', '"Remind me to drink water in 30 minutes"'),
        _Cmd('Add calendar event',
            '"Add meeting on Friday at 3 PM" / "Schedule dentist on March 10"'),
        _Cmd('Open calendar', '"Open my calendar" / "Show calendar"'),
      ],
    ),
    _CmdCat(
      icon: Icons.settings_remote_rounded,
      color: Colors.amberAccent,
      title: 'Device Controls',
      cmds: [
        _Cmd('Flashlight', '"Turn on flashlight" / "Turn off torch"'),
        _Cmd('Volume', '"Set volume to 80%" / "Max volume" / "Mute"'),
        _Cmd('Battery status', '"What\'s my battery?" / "Am I charging?"'),
        _Cmd('WiFi / Network', '"Am I connected?" / "Check my WiFi"'),
        _Cmd('DND / Silent mode',
            '"Enable Do Not Disturb" / "Turn off silent mode"'),
        _Cmd('Open camera', '"Open camera" / "Take a photo"'),
      ],
    ),
    _CmdCat(
      icon: Icons.bolt_rounded,
      color: Colors.pinkAccent,
      title: 'Smart Features',
      cmds: [
        _Cmd('Live weather',
            '"What\'s the weather in Mumbai?" / "Is it raining?"'),
        _Cmd('News briefing', '"What\'s in the news?" / "Latest headlines"'),
        _Cmd('YouTube play',
            '"Play Shape of You on YouTube" / "YouTube Naruto"'),
        _Cmd('Spotify / Music', '"Play Spotify" / "Next song" / "Pause music"'),
        _Cmd('Daily summary',
            '"Give me my daily summary" — auto-triggers every morning'),
        _Cmd('Sleep mode', 'Automatically mutes between midnight and 7 AM'),
        _Cmd('Daily Quests', '"What are my quests?" / "Show daily tasks"'),
        _Cmd('Morning Routine', '"Start my morning routine"'),
        _Cmd('Night Routine', '"Start my night routine" / "Time for bed"'),
        _Cmd('Mood Tracker', '"Log my mood" / "I am feeling happy today"'),
      ],
    ),
    _CmdCat(
      icon: Icons.psychology_rounded,
      color: Colors.purpleAccent,
      title: 'Memory & Intelligence',
      cmds: [
        _Cmd('Save a fact', '"Remember my dog\'s name is Bruno"'),
        _Cmd('Recall memory', '"What do you remember about me?"'),
        _Cmd('Clear a fact',
            '"Forget my password" / ask her to forget something'),
        _Cmd('Pin a message', 'Tap the ★ star on any AI reply to save it'),
        _Cmd('Image recognition', 'Tap 📎 and send a photo — AI describes it'),
        _Cmd('Persona', 'Switch between Zero Two / Rem / other in Settings'),
      ],
    ),
    _CmdCat(
      icon: Icons.chat_bubble_outline_rounded,
      color: Colors.tealAccent,
      title: 'Conversation',
      cmds: [
        _Cmd('Start chatting', '"Hey Zero Two, what\'s up?" / "How are you?"'),
        _Cmd('Ask anything', '"Tell me a joke" / "Explain black holes"'),
        _Cmd('Roleplay', '"Act like my teacher" / "Pretend you\'re a chef"'),
        _Cmd('Response style', 'Set Short / Normal / Detailed in Settings'),
      ],
    ),
    _CmdCat(
      icon: Icons.mic_rounded,
      color: Colors.lightGreenAccent,
      title: 'Voice & Wake Word',
      cmds: [
        _Cmd('Trigger by wake word', 'Say the configured wake word to start'),
        _Cmd('Auto-listen mode',
            'Toggle — she replies then listens automatically'),
        _Cmd('Manual mic', 'Tap the mic button to speak without wake word'),
        _Cmd('TTS speed', 'Adjust 0.5x – 2.0x in Settings'),
        _Cmd('Background wake', 'Say wake word even when app is closed'),
      ],
    ),
    _CmdCat(
      icon: Icons.notifications_active_outlined,
      color: Colors.redAccent,
      title: 'Proactive & Notifications',
      cmds: [
        _Cmd('Idle check-ins',
            'She messages you when you\'re inactive too long'),
        _Cmd(
            'Random check-ins', 'Random proactive messages throughout the day'),
        _Cmd('Notification history',
            'All proactive messages stored in Notification panel'),
        _Cmd('Background assistant',
            'Toggle in Settings to keep her running always'),
      ],
    ),
    _CmdCat(
      icon: Icons.palette_outlined,
      color: Colors.deepPurpleAccent,
      title: 'Personalization',
      cmds: [
        _Cmd('Change theme', 'Go to Themes panel — multiple visual presets'),
        _Cmd('Set avatar image', 'Change avatar / image pack in Settings'),
        _Cmd('App icon', 'Switch launcher icon variant in Settings'),
        _Cmd('Chat font size', 'Small / Medium / Large in Settings'),
        _Cmd('Lock screen widget', 'Long press home → Widgets → S-002'),
      ],
    ),
    _CmdCat(
      icon: Icons.build_circle_outlined,
      color: Colors.blueAccent,
      title: 'Developer Tools',
      cmds: [
        _Cmd('Override API key',
            'Set up to 5 Groq keys (comma-separated) in Dev Config'),
        _Cmd('Override model',
            'Switch LLM / TTS model at runtime in Dev Config'),
        _Cmd('Override STT language',
            'Set e.g. \'hi-IN\' for Hindi in Dev Config'),
        _Cmd('Debug panel',
            'Check live status of Wake, STT, TTS, API, Notifications'),
        _Cmd('Simulate exception',
            'Trigger exception for crash testing in Debug'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final totalCmds = _categories.fold<int>(0, (sum, c) => sum + c.cmds.length);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const ChatHomePage()),
              (r) => false);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0B0B18),
        body: SafeArea(
          child: Column(
            children: [
              // ── Header ────────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.pinkAccent.withValues(alpha: 0.14),
                      const Color(0xFF0B0B18),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        } else {
                          Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ChatHomePage()),
                              (r) => false);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white12),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white70, size: 16),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('CMD REFERENCE',
                              style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.8)),
                          Text('Everything your AI can do',
                              style: GoogleFonts.outfit(
                                  color: Colors.pinkAccent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.pinkAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.pinkAccent.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        '$totalCmds cmds',
                        style: GoogleFonts.outfit(
                            color: Colors.pinkAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
              // ── Category list ─────────────────────────────────────────────
              Expanded(
                child: ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _categories.length,
                  itemBuilder: (_, idx) =>
                      _CmdCategoryCard(cat: _categories[idx]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Data models ──────────────────────────────────────────────────────────────

class _CmdCat {
  final IconData icon;
  final Color color;
  final String title;
  final List<_Cmd> cmds;
  const _CmdCat(
      {required this.icon,
      required this.color,
      required this.title,
      required this.cmds});
}

class _Cmd {
  final String label;
  final String example;
  const _Cmd(this.label, this.example);
}

// ─── Expandable card ──────────────────────────────────────────────────────────

class _CmdCategoryCard extends StatefulWidget {
  final _CmdCat cat;
  const _CmdCategoryCard({required this.cat});

  @override
  State<_CmdCategoryCard> createState() => _CmdCategoryCardState();
}

class _CmdCategoryCardState extends State<_CmdCategoryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cat = widget.cat;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cat.color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cat.color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          // Header row
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cat.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(cat.icon, color: cat.color, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      cat.title,
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: cat.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('${cat.cmds.length}',
                        style: GoogleFonts.outfit(
                            color: cat.color,
                            fontSize: 11,
                            fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: Colors.white38, size: 20),
                  ),
                ],
              ),
            ),
          ),
          // Expanded content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                children: [
                  Divider(color: cat.color.withValues(alpha: 0.2), height: 16),
                  ...cat.cmds.map(
                    (cmd) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            margin: const EdgeInsets.only(top: 6, right: 10),
                            decoration: BoxDecoration(
                                color: cat.color, shape: BoxShape.circle),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(cmd.label,
                                    style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Text(cmd.example,
                                    style: GoogleFonts.outfit(
                                        color: Colors.white38,
                                        fontSize: 11.5,
                                        fontStyle: FontStyle.italic)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),
        ],
      ),
    );
  }
}
