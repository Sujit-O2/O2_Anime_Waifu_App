part of '../main.dart';

class FeaturesPage extends StatelessWidget {
  const FeaturesPage({super.key});

  @override
  Widget build(BuildContext context) {
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
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text(
            'ALL FEATURES',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.0,
            ),
          ),
          backgroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const ChatHomePage()),
                    (r) => false);
              }
            },
          ),
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                physics: const BouncingScrollPhysics(),
                child: _buildFeatureCatalog(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCatalog() {
    final sections = _aboutFeatureSections();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tree root: O2-WAIFU
          Row(
            children: [
              const Icon(Icons.account_tree_rounded,
                  color: Colors.pinkAccent, size: 16),
              const SizedBox(width: 8),
              Text(
                'O2-WAIFU',
                style: GoogleFonts.outfit(
                  color: Colors.pinkAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Each section is a branch off the root
          for (int s = 0; s < sections.length; s++)
            _AboutStaggerReveal(
              delayMs: s * 60,
              child: _buildFeatureGroup(
                sections[s].title,
                sections[s].items,
                isLast: s == sections.length - 1,
              ),
            ),
          const SizedBox(height: 16),
          _AboutStaggerReveal(
            delayMs: sections.length * 60,
            child: _buildCommandExamples(),
          ),
          const SizedBox(height: 16),
          _AboutStaggerReveal(
            delayMs: sections.length * 60 + 100,
            child: _buildHowToUseRules(),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureGroup(String title, List<String> items,
      {bool isLast = false}) {
    // Color palette per group index
    final colors = [
      Colors.cyanAccent,
      Colors.pinkAccent,
      Colors.greenAccent,
      Colors.orangeAccent,
      Colors.purpleAccent,
      Colors.amberAccent,
      Colors.tealAccent,
      Colors.redAccent,
      Colors.lightBlueAccent,
    ];
    final idx = _aboutFeatureSections()
        .indexWhere((s) => s.title == title)
        .clamp(0, colors.length - 1);
    final color = colors[idx];

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vertical track line + horizontal branch stub
          SizedBox(
            width: 22,
            child: Column(
              children: [
                Container(width: 1, height: 18, color: Colors.white24),
                Container(width: 14, height: 1, color: Colors.white24),
                if (!isLast)
                  Expanded(child: Container(width: 1, color: Colors.white24))
                else
                  const SizedBox.shrink(),
              ],
            ),
          ),
          const SizedBox(width: 6),
          // Branch content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Group label (branch root)
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.5),
                              blurRadius: 6,
                            )
                          ],
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          color: color,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Leaf nodes with tree connectors
                  Padding(
                    padding: const EdgeInsets.only(left: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (int i = 0; i < items.length; i++)
                          _buildTreeLeaf(items[i],
                              isLast: i == items.length - 1),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Visual tree leaf node — a single feature item with tree connectors
  Widget _buildTreeLeaf(String text, {bool isLast = false}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            child: Column(
              children: [
                Container(width: 1, height: 14, color: Colors.white24),
                Container(
                  width: 10,
                  height: 1,
                  color: Colors.white24,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 1, color: Colors.white24),
                  )
                else
                  const SizedBox(height: 8),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                text,
                style: GoogleFonts.outfit(
                  color: Colors.white60,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommandExamples() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.pinkAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.mic, color: Colors.pinkAccent, size: 20),
              const SizedBox(width: 8),
              Text(
                'VOICE COMMANDS',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildCmd('📝 Summarize Chat', '"Summarize our conversation"'),
          _buildCmd('📄 Export Chat', '"Export the chat history"'),
          _buildCmd('🎲 Gacha Quote', '"Roll a random quote"'),
          _buildCmd('😄 Mood Tracker', '"I am feeling happy today"'),
          _buildCmd('🍅 Pomodoro Timer', '"Start a 25 minute pomodoro"'),
          _buildCmd('🌐 Translation', '"Translate hello to Japanese"'),
        ],
      ),
    );
  }

  Widget _buildCmd(String title, String example) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Text(title,
                style: GoogleFonts.outfit(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white12),
              ),
              child: Text(example,
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 11,
                      fontStyle: FontStyle.italic)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowToUseRules() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amberAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book_rounded,
                  color: Colors.amberAccent, size: 20),
              const SizedBox(width: 8),
              Text(
                'HOW TO USE & RULES',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'The App is designed to act as your personal AI companion. Here are the core rules and guidelines to get the most out of your experience:',
            style: GoogleFonts.outfit(
                color: Colors.white70, fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 12),
          _buildRuleItem('1', 'Wake Word',
              'Say the wake word to activate hands-free listening. You can change sensitivity in Advanced Settings.'),
          _buildRuleItem('2', 'Memory Limit',
              'The AI remembers your recent context. You can lower the memory limit if responses get slow.'),
          _buildRuleItem('3', 'Background Mode',
              'Keep the app running in the background for proactive notifications and random check-ins.'),
          _buildRuleItem('4', 'Image & Themes',
              'Use the Settings panel to apply custom backgrounds (Image Pack) or change the entire app\'s neon accent color.'),
          _buildRuleItem('5', 'Dev Config',
              'For power users: Override the LLM model, Voice, API Keys, or System Persona live without restarting.'),
          const SizedBox(height: 12),
          Text(
            '⚠️ Note: Do not share your API keys if you set custom ones in Dev Config. The core features run on secure edge functions by default.',
            style: GoogleFonts.outfit(
                color: Colors.redAccent.withValues(alpha: 0.9),
                fontSize: 11,
                fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleItem(String numText, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.amberAccent.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Text(
              numText,
              style: GoogleFonts.outfit(
                  color: Colors.amberAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(body,
                    style: GoogleFonts.outfit(
                        color: Colors.white54, fontSize: 11, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<_AboutFeatureSection> _aboutFeatureSections() {
    return const [
      _AboutFeatureSection('Chat and Conversation', [
        'Persistent chat history with bounded memory window',
        'Typed input and voice-driven interaction',
        'Assistant replies appended to history and memory store',
        'State-aware one-shot idle prompt until next user message',
        'Animated list insertion for user and assistant turns',
        'Conversation payload trimming for predictable model context size',
      ]),
      _AboutFeatureSection('Wake, STT and TTS', [
        'Porcupine wake-word pipeline with runtime recovery',
        'Speech-to-text capture from wake trigger and manual mic',
        'Text-to-speech response playback',
        'Dual-voice mode with selectable secondary voice',
        'Auto-listen mode for continuous flow after response',
        'Wake watchdog timer to recover stopped wake listeners',
        'Speech status and error callbacks wired to runtime state',
      ]),
      _AboutFeatureSection('Background and Check-ins', [
        'Android foreground assistant service for proactive behavior',
        'Manual check-in interval and random check-in mode',
        'Background wake detection notification path',
        'Queued proactive messages restored into chat on resume',
        'Notification history panel with clear/remove actions',
        'Foreground/background awareness to shift assistant behavior',
        'Shared preference persistence for check-in configuration',
      ]),
      _AboutFeatureSection('Video and Media', [
        'Cloudinary episode loading via Admin API credentials',
        'Folder-based source filtering for episode discovery',
        'Transformed MP4 URL preference for stable playback',
        'Episode selector with in-app player controls',
        'Landscape fullscreen playback route',
        'Tap-to-toggle controls with 2-second auto-hide in landscape',
        'Playback resume position restored when exiting fullscreen',
      ]),
      _AboutFeatureSection('App Automation and Launch', [
        'Strict assistant action format for app launch commands',
        'Method-channel Android launch resolution',
        'Package, alias, and intent-based app opening strategies',
        'Case-insensitive app name handling',
        'Play Store fallback when direct launch path is unavailable',
      ]),
      _AboutFeatureSection('UI and Personalization', [
        'Multi-panel navigation: Chat, Themes, Dev Config, Notifications, Videos, Settings, Debug, About',
        'Fixed top image banners on control panels',
        'Image pack switching (code assets) and system image pick',
        'Chat-log assistant avatar rendering from current image source',
        'Launcher icon variant switch (old/new) on Android',
        'Theme mode persistence across app restarts',
        'Opening overlay animation with branded style',
      ]),
      _AboutFeatureSection('Developer and Debug Tools', [
        'Dev overrides for API key, model, endpoint, and prompt',
        'Debug status cards for wake, STT, TTS, API, and notifications',
        'Quick debug actions for wake and proactive test flows',
        'Runtime diagnostics and persisted feature toggles',
        'Wake-word debug route exposed through app navigation',
        'Verbose startup diagnostics in debug logging paths',
      ]),
      _AboutFeatureSection('Controls and Data', [
        'Wake word toggle and 002 mode toggle',
        'Idle timer toggle with duration slider',
        'Check-in random/manual mode control with interval slider',
        'Clear chat memory and clear notification history actions',
        'Default behavior: idle enabled, random check-in mode enabled',
        'Notification and memory buffers capped for stable runtime usage',
      ]),
      _AboutFeatureSection('Utilities and Minigames', [
        'Gacha system for random Zero Two quotes',
        'Mood Tracker with persistent emotion history',
        'Secret Notes secured with local PIN code and XOR masking',
        'Pomodoro timer utilizing system alarms',
        'On-demand chat summary condensation via LLM',
        'Chat export to local .txt file using the native share sheet',
        'Instant translation through MyMemory API integration',
      ]),
      _AboutFeatureSection('Reliability and Safety', [
        'Mic and notification permission gating before sensitive actions',
        'Wake-word stop fallback when user disables wake mode',
        'Mount guards and async safety checks before setState calls',
        'Controller attach/detach lifecycle management for media playback',
        'Portrait orientation restoration after leaving landscape player',
      ]),
    ];
  }
}

class _AboutFeatureSection {
  final String title;
  final List<String> items;

  const _AboutFeatureSection(this.title, this.items);
}

class _AboutStaggerReveal extends StatefulWidget {
  final Widget child;
  final int delayMs;

  const _AboutStaggerReveal({
    required this.child,
    this.delayMs = 0,
  });

  @override
  State<_AboutStaggerReveal> createState() => _AboutStaggerRevealState();
}

class _AboutStaggerRevealState extends State<_AboutStaggerReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );
    Future<void>.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}
