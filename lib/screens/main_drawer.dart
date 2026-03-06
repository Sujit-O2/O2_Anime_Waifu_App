part of '../main.dart';

extension _MainDrawerExtension on _ChatHomePageState {
  Widget _buildNavDrawer(AppThemeMode mode) {
    final theme = AppThemes.getTheme(mode);
    final primary = theme.primaryColor;
    final gradient = AppThemes.getGradient(mode);
    final screenH = MediaQuery.of(context).size.height;
    final isSmall = screenH < 700;

    // ── Section items ──────────────────────────────────────────────────────
    final mainItems = [
      {'label': 'Chat', 'icon': Icons.chat_bubble_outline, 'nav': 0},
      {
        'label': 'Notifications',
        'icon': Icons.notifications_outlined,
        'nav': 1
      },
      {'label': 'Videos', 'icon': Icons.videocam_outlined, 'nav': 2},
    ];
    final entertainmentItems = [
      {'label': 'Gacha 🎲', 'icon': Icons.casino_outlined, 'nav': 8},
      {'label': 'Mood Tracker', 'icon': Icons.mood_outlined, 'nav': 9},
      {'label': 'Secret Notes 🔒', 'icon': Icons.lock_outline, 'nav': 10},
    ];
    final settingsItems = [
      {'label': 'Settings', 'icon': Icons.settings_outlined, 'nav': 3},
      {'label': 'Themes', 'icon': Icons.palette_outlined, 'nav': 4},
    ];
    final devItems = [
      {'label': 'Dev Config', 'icon': Icons.terminal, 'nav': 5},
      {'label': 'Debug', 'icon': Icons.bug_report_outlined, 'nav': 6},
    ];

    Widget navItem(Map<String, dynamic> item) {
      final navIdx = item['nav'] as int;
      final selected = _navIndex == navIdx;
      return InkWell(
        onTap: () {
          updateState(() => _navIndex = navIdx);
          Navigator.of(context).pop();
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          padding:
              EdgeInsets.symmetric(horizontal: 14, vertical: isSmall ? 10 : 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color:
                selected ? primary.withValues(alpha: 0.18) : Colors.transparent,
            border: Border.all(
              color: selected
                  ? primary.withValues(alpha: 0.45)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(item['icon'] as IconData,
                  color: selected ? primary : Colors.white54,
                  size: isSmall ? 18 : 20),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  item['label'] as String,
                  style: GoogleFonts.outfit(
                    color: selected ? Colors.white : Colors.white70,
                    fontSize: isSmall ? 13 : 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
              if (navIdx == 1 && _notifHistory.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                      color: primary, borderRadius: BorderRadius.circular(10)),
                  child: Text('${_notifHistory.length}',
                      style: const TextStyle(
                          fontSize: 10,
                          color: Colors.black,
                          fontWeight: FontWeight.w700)),
                ),
              if (selected)
                Icon(Icons.chevron_right_rounded,
                    size: 16, color: primary.withValues(alpha: 0.55)),
            ],
          ),
        ),
      );
    }

    Widget sectionHeader(String title) => Padding(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 4),
          child: Row(children: [
            Text(title,
                style: GoogleFonts.outfit(
                    color: Colors.white24,
                    fontSize: 9,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w800)),
            const SizedBox(width: 8),
            Expanded(
                child: Divider(
                    color: Colors.white.withValues(alpha: 0.08), thickness: 1)),
          ]),
        );

    Widget quickItem(
        String label, IconData icon, Color color, VoidCallback onTap,
        {String? badge}) {
      return InkWell(
        onTap: () {
          Navigator.of(context).pop();
          onTap();
        },
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding:
              EdgeInsets.symmetric(horizontal: 22, vertical: isSmall ? 7 : 9),
          child: Row(children: [
            Icon(icon, color: color, size: 17),
            const SizedBox(width: 13),
            Expanded(
                child: Text(label,
                    style: GoogleFonts.outfit(
                        color: Colors.white60, fontSize: 13))),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(badge,
                    style: GoogleFonts.outfit(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ),
            const SizedBox(width: 4),
            Icon(Icons.open_in_new_rounded, color: Colors.white12, size: 12),
          ]),
        ),
      );
    }

    return Drawer(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              gradient.first.withValues(alpha: 0.97),
              gradient.last.withValues(alpha: 0.97),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              top: 175,
              child: Opacity(
                opacity: 0.32,
                child: Image.asset('assets/gif/sidebar_bg.gif',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    filterQuality: FilterQuality.low,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink()),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.06),
                      Colors.black.withValues(alpha: 0.32),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top banner
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                    child: _buildDrawerTopBanner(primary),
                  ),
                  // Profile row
                  Padding(
                    padding: EdgeInsets.fromLTRB(18, isSmall ? 10 : 14, 18, 8),
                    child: Row(children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primary.withValues(alpha: 0.2),
                          border: Border.all(
                              color: primary.withValues(alpha: 0.55),
                              width: 1.5),
                        ),
                        child: ClipOval(
                          child: Image(
                            image: _imageProviderFor(
                                assetPath: _appIconImageAsset,
                                customPath: _effectiveAppIconCustomPath),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                                Icons.auto_awesome,
                                color: primary,
                                size: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ZERO TWO',
                                style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.4)),
                            Text('CORE 002 · S-002',
                                style: GoogleFonts.outfit(
                                    color: Colors.white38,
                                    fontSize: 9,
                                    letterSpacing: 1.8)),
                          ]),
                      const Spacer(),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.greenAccent,
                          boxShadow: [
                            BoxShadow(
                                color:
                                    Colors.greenAccent.withValues(alpha: 0.5),
                                blurRadius: 6)
                          ],
                        ),
                      ),
                    ]),
                  ),
                  Divider(
                      color: Colors.white.withValues(alpha: 0.08), height: 1),
                  _buildDrawerAutoListenTile(primary),
                  Divider(
                      color: Colors.white.withValues(alpha: 0.08), height: 1),

                  // NEW: System Info / Data Display
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('SYSTEM METRICS',
                              style: GoogleFonts.outfit(
                                  color: primary.withValues(alpha: 0.8),
                                  fontSize: 9,
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(Icons.memory_outlined,
                                  color: Colors.white54, size: 14),
                              const SizedBox(width: 8),
                              Text('Context Nodes:',
                                  style: GoogleFonts.outfit(
                                      color: Colors.white54, fontSize: 11)),
                              const Spacer(),
                              Text('${_messages.length}',
                                  style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.monitor_heart_outlined,
                                  color: Colors.white54, size: 14),
                              const SizedBox(width: 8),
                              Text('Core Status:',
                                  style: GoogleFonts.outfit(
                                      color: Colors.white54, fontSize: 11)),
                              const Spacer(),
                              Text('Stable',
                                  style: GoogleFonts.outfit(
                                      color: Colors.greenAccent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.hub_outlined,
                                  color: Colors.white54, size: 14),
                              const SizedBox(width: 8),
                              Text('Model Override:',
                                  style: GoogleFonts.outfit(
                                      color: Colors.white54, fontSize: 11)),
                              const Spacer(),
                              Expanded(
                                child: Text(
                                    _devModelOverride.isNotEmpty
                                        ? _devModelOverride
                                        : 'Default',
                                    textAlign: TextAlign.right,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Scrollable nav
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(top: 4, bottom: 6),
                      children: [
                        sectionHeader('MAIN'),
                        ...mainItems
                            .map((e) => navItem(Map<String, dynamic>.from(e))),
                        sectionHeader('ENTERTAINMENT'),
                        ...entertainmentItems
                            .map((e) => navItem(Map<String, dynamic>.from(e))),
                        sectionHeader('SETTINGS'),
                        ...settingsItems
                            .map((e) => navItem(Map<String, dynamic>.from(e))),
                        sectionHeader('DEVELOPER'),
                        ...devItems
                            .map((e) => navItem(Map<String, dynamic>.from(e))),
                        sectionHeader('QUICK LAUNCH'),
                        quickItem(
                          'Mini Games',
                          Icons.sports_esports_rounded,
                          Colors.cyanAccent,
                          () {
                            Navigator.pop(context);
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => MiniGamesPage(
                                          onGameSelected: (cmd) {
                                            _textController.text = cmd;
                                            _handleTextInput();
                                          },
                                        )));
                          },
                        ),
                        quickItem(
                          'Music Player',
                          Icons.music_note_rounded,
                          Colors.purpleAccent,
                          () {
                            Navigator.pop(context);
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const MusicPlayerPage()));
                          },
                        ),
                        quickItem(
                          'Commands',
                          Icons.terminal_rounded,
                          Colors.pinkAccent,
                          () {
                            Navigator.pop(context);
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const CommandsPage()));
                          },
                          badge: '40+',
                        ),
                        quickItem(
                          'All Features',
                          Icons.auto_awesome_rounded,
                          Colors.amberAccent,
                          () {
                            Navigator.pop(context);
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const FeaturesPage()));
                          },
                        ),
                        // INFO — About always last
                        sectionHeader('INFO'),
                        navItem({
                          'label': 'About',
                          'icon': Icons.info_outline,
                          'nav': 7
                        }),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  // Footer
                  Divider(
                      color: Colors.white.withValues(alpha: 0.07), height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(children: [
                      Text('S-002 · Zero Two',
                          style: GoogleFonts.outfit(
                              color: Colors.white24,
                              fontSize: 10,
                              letterSpacing: 1.2)),
                      const SizedBox(height: 2),
                      Text('Dev by Sujit-O2',
                          style: GoogleFonts.outfit(
                              color: Colors.white12,
                              fontSize: 9,
                              letterSpacing: 1)),
                    ]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerTopBanner(Color primary) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 125,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/gif/sidebar_top.gif',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                filterQuality: FilterQuality.low,
                errorBuilder: (_, __, ___) => Container(
                        decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                      primary.withValues(alpha: 0.4),
                      Colors.black54
                    ])))),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.04),
                    Colors.black.withValues(alpha: 0.65),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: primary.withValues(alpha: 0.5)),
                    ),
                    child: Text('NEURAL LINK ACTIVE',
                        style: GoogleFonts.outfit(
                            color: primary,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.6)),
                  ),
                  const SizedBox(height: 5),
                  Text('S-002',
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2)),
                  Text('AI Companion System',
                      style: GoogleFonts.outfit(
                          color: Colors.white60, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerAutoListenTile(Color primary) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Row(children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (_isAutoListening ? primary : Colors.white12)
                .withValues(alpha: 0.18),
          ),
          child: Icon(
            _isAutoListening ? Icons.mic_rounded : Icons.mic_off_rounded,
            color: _isAutoListening ? primary : Colors.white38,
            size: 15,
          ),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Auto Listen',
              style: GoogleFonts.outfit(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          Text(_isAutoListening ? 'Microphone active' : 'Tap to enable',
              style: GoogleFonts.outfit(color: Colors.white30, fontSize: 10)),
        ]),
        const Spacer(),
        Switch(
          value: _isAutoListening,
          onChanged: (_) => _toggleAutoListen(),
          activeColor: primary,
          inactiveThumbColor: Colors.white38,
          inactiveTrackColor: Colors.white12,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ]),
    );
  }
}
