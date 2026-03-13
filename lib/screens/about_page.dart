part of '../main.dart';

extension _AboutPageExtension on _ChatHomePageState {
  Widget _buildAboutPage() {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/gif/background_of_about_section_blurry.gif',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
        Positioned.fill(
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: Container(
                color: Colors.black.withValues(alpha: 0.12),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.20),
                  Colors.black.withValues(alpha: 0.35),
                  Colors.black.withValues(alpha: 0.50),
                ],
              ),
            ),
          ),
        ),
        const Positioned.fill(
          child: _AboutFireflyLayer(),
        ),
        SafeArea(
          child: Column(
            children: [
              _buildAboutHeader(),
              _buildHorizontalDivider(),
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 860),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.24),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.18)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.30),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              padding: EdgeInsets.zero,
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 24, 16, 24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildSectionTitle('DASHBOARD'),
                                    const SizedBox(height: 12),
                                    _buildSubNavigationDashboard(),
                                    const SizedBox(height: 28),
                                    _buildSectionTitle('SYSTEM STATUS'),
                                    const SizedBox(height: 12),
                                    _buildStatusGrid(),
                                    const SizedBox(height: 28),
                                    _buildSectionTitle(
                                        'DEVELOPER & PROJECT INFO'),
                                    const SizedBox(height: 12),
                                    _buildProjectInfoCard(),
                                    const SizedBox(height: 30),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAboutHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.pinkAccent.withValues(alpha: 0.4),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.purpleAccent.withValues(alpha: 0.4),
                  blurRadius: 36,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: ClipOval(
              child: Image(
                image: _imageProviderFor(
                  assetPath: _chatImageAsset,
                  customPath: _effectiveChatCustomPath,
                ),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.white10,
                  child:
                      const Icon(Icons.face, color: Colors.white38, size: 40),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              final now = DateTime.now();
              if (_aboutLastTap == null ||
                  now.difference(_aboutLastTap!) > const Duration(seconds: 2)) {
                _aboutTapCount = 1;
              } else {
                _aboutTapCount++;
              }
              _aboutLastTap = now;
              if (_aboutTapCount >= 7) {
                _aboutTapCount = 0;
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const DataVaultPage()));
              }
            },
            child: Text(
              'O2-WAIFU',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
                shadows: [
                  Shadow(
                    color: Colors.pinkAccent.withValues(alpha: 0.6),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Text(
              'STATE-AWARE VOICE COMPANION',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 10,
                letterSpacing: 2.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalDivider() {
    return Container(
      height: 1,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, Colors.white10, Colors.transparent],
        ),
      ),
    );
  }

  Widget _buildSubNavigationDashboard() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDashboardCard(
                title: 'Features',
                subtitle: 'All capabilities',
                icon: Icons.auto_awesome_rounded,
                color: Colors.cyanAccent,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const FeaturesPage())),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDashboardCard(
                title: 'Stats & Habits',
                subtitle: 'Activity & bonds',
                icon: Icons.insert_chart_rounded,
                color: Colors.orangeAccent,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const StatsAndHabitsPage())),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDashboardCard(
                title: 'Commands',
                subtitle: 'Voice syntax',
                icon: Icons.terminal_rounded,
                color: Colors.pinkAccent,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const CommandsPage())),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDashboardCard(
                title: 'App Guide',
                subtitle: 'How to use',
                icon: Icons.menu_book_rounded,
                color: Colors.greenAccent,
                onTap: () {
                  showDialog(
                      context: context,
                      builder: (ctx) => _FeatureGuideDialog());
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDashboardCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.05),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.outfit(
                color: Colors.white60,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        color: Colors.white,
        fontSize: 13,
        letterSpacing: 1.8,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildStatusGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _statusChip('Wake', _wakeWordService.isRunning ? 'ACTIVE' : 'IDLE',
            _wakeWordService.isRunning ? Colors.greenAccent : Colors.redAccent),
        _statusChip('Foreground', _isInForeground ? 'YES' : 'NO',
            _isInForeground ? Colors.cyanAccent : Colors.orangeAccent),
        _statusChip('Assistant', _assistantModeEnabled ? 'ON' : 'OFF',
            _assistantModeEnabled ? Colors.pinkAccent : Colors.white54),
        _statusChip('Idle Timer', _idleTimerEnabled ? 'ON' : 'OFF',
            _idleTimerEnabled ? Colors.yellowAccent : Colors.white54),
      ],
    );
  }

  Widget _statusChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            spreadRadius: -2,
          ),
        ],
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: GoogleFonts.outfit(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: value,
              style: GoogleFonts.outfit(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const String _projectGitHubUrl =
      'https://github.com/Sujit-O2/O2_Anime_Waifu-Mobile-App';

  Future<void> _openProjectGitHub() async {
    final uri = Uri.parse(_projectGitHubUrl);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (ok || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open GitHub link.')),
    );
  }

  Widget _buildProjectInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.lightBlueAccent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: Colors.lightBlueAccent.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.lightBlueAccent.withValues(alpha: 0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildModernDevChip(
                  Icons.code, 'Dev By', 'Sujit 02', Colors.pinkAccent),
              const SizedBox(width: 10),
              _buildModernDevChip(
                  Icons.new_releases, 'Version', 'v02', Colors.cyanAccent),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _openProjectGitHub,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.white10,
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.link, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GitHub Repository',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Sujit-O2/O2_Anime_Waifu',
                          style: GoogleFonts.outfit(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.open_in_new,
                      color: Colors.white38, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernDevChip(
      IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      color: Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    value,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


}


class _Firefly {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  double alphaBase;
  Color color;

  _Firefly({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.alphaBase,
    required this.color,
  });
}

class _AboutFireflyLayer extends StatefulWidget {
  const _AboutFireflyLayer();

  @override
  State<_AboutFireflyLayer> createState() => _AboutFireflyLayerState();
}

class _AboutFireflyLayerState extends State<_AboutFireflyLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_Firefly> _fireflies = [];
  Offset? _touchPos;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )
      ..addListener(_updateParticles)
      ..repeat();
  }

  void _initParticles(Size size) {
    if (_fireflies.isNotEmpty) return;
    final random = math.Random();
    const colors = [
      Colors.amberAccent,
      Colors.orangeAccent,
      Colors.deepOrangeAccent
    ];
    for (int i = 0; i < 40; i++) {
      _fireflies.add(_Firefly(
        x: random.nextDouble() * size.width,
        y: random.nextDouble() * size.height,
        vx: (random.nextDouble() - 0.5) * 0.5,
        vy: -0.2 - random.nextDouble() * 0.8,
        size: 1.5 + random.nextDouble() * 2.5,
        alphaBase: 0.2 + random.nextDouble() * 0.6,
        color: colors[random.nextInt(colors.length)],
      ));
    }
  }

  void _updateParticles() {
    if (_fireflies.isEmpty) return;
    final size = MediaQuery.of(context).size;

    for (final f in _fireflies) {
      // Normal drift
      f.x += f.vx;
      f.y += f.vy;

      // Interaction
      if (_touchPos != null) {
        final dx = f.x - _touchPos!.dx;
        final dy = f.y - _touchPos!.dy;
        final dist = math.sqrt(dx * dx + dy * dy);
        if (dist < 120) {
          final force = (120 - dist) / 120;
          f.x += (dx / dist) * force * 5.0;
          f.y += (dy / dist) * force * 5.0;
        }
      }

      // Sine wobble
      f.x += math.sin(f.y * 0.02) * 0.3;

      // Wrap around
      if (f.y < -10) f.y = size.height + 10;
      if (f.x < -10) f.x = size.width + 10;
      if (f.x > size.width + 10) f.x = -10;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _initParticles(Size(constraints.maxWidth, constraints.maxHeight));
        return GestureDetector(
          onPanUpdate: (d) => _touchPos = d.localPosition,
          onPanEnd: (_) => _touchPos = null,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (_, __) => CustomPaint(
              painter: _AboutFireflyPainter(
                  t: _controller.value, fireflies: _fireflies),
              size: Size.infinite,
            ),
          ),
        );
      },
    );
  }
}

class _AboutFireflyPainter extends CustomPainter {
  final double t;
  final List<_Firefly> fireflies;
  const _AboutFireflyPainter({required this.t, required this.fireflies});

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    final core = Paint()..style = PaintingStyle.fill;

    for (final f in fireflies) {
      // Twinkle effect
      final twinkle = 0.5 + 0.5 * math.sin((t * math.pi * 20) + (f.x + f.y));
      final alpha = (f.alphaBase * twinkle).clamp(0.0, 1.0);

      glow.color = f.color.withValues(alpha: alpha * 0.6);
      core.color = Colors.white.withValues(alpha: alpha);

      canvas.drawCircle(Offset(f.x, f.y), f.size * 2, glow);
      canvas.drawCircle(Offset(f.x, f.y), f.size, core);
    }
  }

  @override
  bool shouldRepaint(covariant _AboutFireflyPainter oldDelegate) => true;
}

class _FeatureGuideDialog extends StatelessWidget {
  const _FeatureGuideDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 400,
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: const Color(0xFF161618),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white10)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.menu_book_rounded,
                      color: Colors.white, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Feature Guide',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildFeatureItem(
                    icon: Icons.timer,
                    color: Colors.redAccent,
                    title: 'Pomodoro Timer',
                    description:
                        'A focus timer that sets a system alarm for you.',
                    howTo:
                        'Tap the mic and say: "Start a 25 minute pomodoro" or "Set a focus timer for 30 minutes".',
                  ),
                  const SizedBox(height: 20),
                  _buildFeatureItem(
                    icon: Icons.summarize,
                    color: Colors.blueAccent,
                    title: 'Conversation Summary',
                    description: 'Let the AI recap the chat history for you.',
                    howTo:
                        'Tap the mic and say: "Summarize our conversation" or "What were we just talking about?".',
                  ),
                  const SizedBox(height: 20),
                  _buildFeatureItem(
                    icon: Icons.file_download,
                    color: Colors.greenAccent,
                    title: 'Chat Export',
                    description: 'Save your memories to a local text file.',
                    howTo:
                        'Tap the mic and say: "Export the chat history" or "Save our conversation".',
                  ),
                  const SizedBox(height: 20),
                  _buildFeatureItem(
                    icon: Icons.content_paste,
                    color: Colors.orangeAccent,
                    title: 'Clipboard Assistant',
                    description: 'Have the AI read what you recently copied.',
                    howTo:
                        'Tap the mic and say: "What did I copy?" or "Read my clipboard".',
                  ),
                  const SizedBox(height: 20),
                  _buildFeatureItem(
                    icon: Icons.sms,
                    color: Colors.pinkAccent,
                    title: 'SMS Reader',
                    description:
                        'Have the AI securely read your latest text messages.',
                    howTo:
                        'Tap the mic and say: "Read my last SMS" or "Check my texts".',
                  ),
                  const SizedBox(height: 20),
                  _buildFeatureItem(
                    icon: Icons.person_pin_circle,
                    color: Colors.cyanAccent,
                    title: 'Persona Switcher',
                    description: 'Change the AI\'s personality and TTS voice.',
                    howTo:
                        'Open Settings -> AI PERSONA -> Select Personality. Choose between Zero Two, Rem, Miku, or Custom.',
                  ),
                  const SizedBox(height: 20),
                  _buildFeatureItem(
                    icon: Icons.lock,
                    color: Colors.purpleAccent,
                    title: 'Secret Notes',
                    description:
                        'A private vault where you can securely store personal information the AI can remember.',
                    howTo:
                        'Open Settings -> APPS & TOOLS -> Secret Notes (or say "Open my notes").',
                  ),
                  const SizedBox(height: 20),
                  _buildFeatureItem(
                    icon: Icons.casino,
                    color: Colors.amberAccent,
                    title: 'Gacha Minigame',
                    description:
                        'A fun minigame to get random iconic anime quotes.',
                    howTo:
                        'Open Settings -> APPS & TOOLS -> Gacha Quotes (Or say "Roll a quote").',
                  ),
                  const SizedBox(height: 20),
                  _buildFeatureItem(
                    icon: Icons.mood,
                    color: Colors.tealAccent,
                    title: 'Mood Tracker',
                    description: 'Keep a daily journal of your emotions.',
                    howTo:
                        'Open Settings → APPS & TOOLS → Mood Tracker (Or say "Track my mood").',
                  ),
                  const SizedBox(height: 20),

                  // ── NEW FEATURES ──────────────────────────────────────────
                  _buildFeatureItem(
                    icon: Icons.music_note_rounded,
                    color: Colors.purpleAccent,
                    title: '🎵 Music Player',
                    description:
                        'Full in-app music player with animated vinyl disc, album art, seek bar, and song queue — plays local music from your device.',
                    howTo:
                        'Say "Play music" or "Play [song name]". Or open via Settings → APPS & TOOLS → Music Player. The mini-player bar appears above chat input while music is playing.',
                  ),
                  const SizedBox(height: 20),
                  _buildFeatureItem(
                    icon: Icons.alarm_rounded,
                    color: Colors.orangeAccent,
                    title: '⏰ Waifu Wake-Up Alarm',
                    description:
                        'Set device alarms by voice. When it fires, Zero Two wakes you up and reads the weather.',
                    howTo:
                        'Say "Wake me up at 7 AM" or "Set an alarm for 6:30". Fires even when app is closed.',
                  ),
                  const SizedBox(height: 20),
                  _buildFeatureItem(
                    icon: Icons.contacts_rounded,
                    color: Colors.greenAccent,
                    title: '📞 Contacts Lookup',
                    description:
                        'Ask Zero Two about anyone in your contacts — she looks them up instantly.',
                    howTo:
                        'Say "Who is John?" or "Find contact for Priya". Requires Contacts permission.',
                  ),
                  const SizedBox(height: 20),
                  _buildFeatureItem(
                    icon: Icons.auto_fix_high_rounded,
                    color: Colors.cyanAccent,
                    title: '🖼️ AI Drawing',
                    description:
                        'Zero Two generates images for you on demand using Pollinations.ai — no API key needed!',
                    howTo:
                        'Say "Draw me a cat", "Generate an anime girl", or "Draw [anything]". The image appears in-chat.',
                  ),
                  const SizedBox(height: 20),
                  _buildFeatureItem(
                    icon: Icons.games_rounded,
                    color: Colors.amberAccent,
                    title: '🎮 Mini-Games',
                    description:
                        'Play Rock-Paper-Scissors, Tic-Tac-Toe, or Anime Trivia — all directly in the chat!',
                    howTo:
                        'RPS: Say "Rock", "Paper", or "Scissors"\nTic-Tac-Toe: Say "tic tac toe" then a number 1–9\nTrivia: Say "trivia" to get a question',
                  ),
                  const SizedBox(height: 20),
                  _buildFeatureItem(
                    icon: Icons.fingerprint_rounded,
                    color: Colors.redAccent,
                    title: '🔒 App Lock',
                    description:
                        'Secure the app with your phone fingerprint or PIN so only you can open it.',
                    howTo:
                        'Open Settings → SECURITY → App Lock → Enable Biometric Lock.',
                  ),
                  const SizedBox(height: 20),
                  _buildFeatureItem(
                    icon: Icons.cloud_sync_rounded,
                    color: Colors.blueAccent,
                    title: '☁️ Google Drive Backup',
                    description:
                        'Save your chat memories, secret notes, and settings to Google Drive automatically.',
                    howTo:
                        'Open Settings → BACKUP → Cloud Sync → tap "Backup". Setup: create OAuth credentials at console.cloud.google.com, download google-services.json to android/app/.',
                  ),
                  const SizedBox(height: 20),
                  _buildFeatureItem(
                    icon: Icons.search_rounded,
                    color: Colors.white70,
                    title: '🔎 Chat Search',
                    description:
                        'Find any old message in the chat history instantly with a live search bar.',
                    howTo:
                        'Tap the 🔍 SEARCH chip in the chat header. Type any keyword to filter messages in real-time.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
    required String howTo,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.4)),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.outfit(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          description,
          style: GoogleFonts.outfit(
            color: Colors.white70,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.mic, color: Colors.white54, size: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  howTo,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
