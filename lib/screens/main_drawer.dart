part of '../main.dart';

extension _MainDrawerExtension on _ChatHomePageState {
  Widget _buildNavDrawer(AppThemeMode mode) {
    final theme = AppThemes.getTheme(mode);
    final primary = theme.primaryColor;
    final gradient = AppThemes.getGradient(mode);

    const labels = [
      'Chat',
      'Notification',
      'Videos',
      'Setting',
      'Themes',
      'Dev Config',
      'Debug',
      'About',
      'Gacha 🎲',
      'Mood Tracker',
      'Secret Notes',
    ];
    const icons = [
      Icons.chat_bubble_outline,
      Icons.notifications_outlined,
      Icons.videocam_outlined,
      Icons.settings_outlined,
      Icons.palette_outlined,
      Icons.terminal,
      Icons.bug_report_outlined,
      Icons.info_outline,
      Icons.casino_outlined,
      Icons.mood_outlined,
      Icons.lock_outline,
    ];

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
              top: 200,
              child: Opacity(
                opacity: 0.48,
                child: Image.asset(
                  'assets/gif/sidebar_bg.gif',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  filterQuality: FilterQuality.low,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
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
                      Colors.black.withValues(alpha: 0.08),
                      Colors.black.withValues(alpha: 0.28),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                    child: _buildDrawerTopBanner(primary),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primary.withValues(alpha: 0.2),
                            border: Border.all(
                                color: primary.withValues(alpha: 0.5)),
                          ),
                          child: ClipOval(
                            child: Image(
                              image: _imageProviderFor(
                                assetPath: _appIconImageAsset,
                                customPath: _effectiveAppIconCustomPath,
                              ),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.auto_awesome,
                                color: primary,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ZERO TWO',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                              ),
                            ),
                            Text(
                              'CORE 002',
                              style: GoogleFonts.outfit(
                                color: Colors.white38,
                                fontSize: 10,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Divider(
                      color: Colors.white.withValues(alpha: 0.08), height: 1),
                  _buildDrawerAutoListenTile(primary),
                  Divider(
                      color: Colors.white.withValues(alpha: 0.08), height: 1),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: labels.length,
                      itemBuilder: (ctx, i) {
                        final selected = _navIndex == i;
                        return InkWell(
                          onTap: () {
                            updateState(() => _navIndex = i);
                            Navigator.of(ctx).pop();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 3),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 13),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: selected
                                  ? primary.withValues(alpha: 0.18)
                                  : Colors.transparent,
                              border: Border.all(
                                color: selected
                                    ? primary.withValues(alpha: 0.4)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  icons[i],
                                  color: selected ? primary : Colors.white54,
                                  size: 20,
                                ),
                                const SizedBox(width: 14),
                                Text(
                                  labels[i],
                                  style: GoogleFonts.outfit(
                                    color: selected
                                        ? Colors.white
                                        : Colors.white60,
                                    fontSize: 14,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                  ),
                                ),
                                if (i == 1 && _notifHistory.isNotEmpty) ...[
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: primary,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${_notifHistory.length}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Divider(
                      color: Colors.white.withValues(alpha: 0.08), height: 1),
                  // Quick actions section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                    child: Text(
                      'QUICK LAUNCH',
                      style: GoogleFonts.outfit(
                          color: Colors.white24,
                          fontSize: 10,
                          letterSpacing: 1.6,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  // Commands
                  InkWell(
                    onTap: () {
                      Navigator.of(context)
                        ..pop()
                        ..push(MaterialPageRoute(
                            builder: (_) => const CommandsPage()));
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      child: Row(
                        children: [
                          Icon(Icons.terminal_rounded,
                              color: Colors.pinkAccent.withValues(alpha: 0.8),
                              size: 18),
                          const SizedBox(width: 14),
                          Text(
                            'Commands',
                            style: GoogleFonts.outfit(
                                color: Colors.white60,
                                fontSize: 14,
                                fontWeight: FontWeight.w400),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.pinkAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('40+',
                                style: GoogleFonts.outfit(
                                    color: Colors.pinkAccent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Features
                  InkWell(
                    onTap: () {
                      Navigator.of(context)
                        ..pop()
                        ..push(MaterialPageRoute(
                            builder: (_) => const FeaturesPage()));
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      child: Row(
                        children: [
                          Icon(Icons.auto_awesome_rounded,
                              color: Colors.amberAccent.withValues(alpha: 0.8),
                              size: 18),
                          const SizedBox(width: 14),
                          Text(
                            'All Features',
                            style: GoogleFonts.outfit(
                                color: Colors.white60,
                                fontSize: 14,
                                fontWeight: FontWeight.w400),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Divider(
                      color: Colors.white.withValues(alpha: 0.08), height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Zero Two | CORE 002',
                          style: GoogleFonts.outfit(
                            color: Colors.white24,
                            fontSize: 11,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Dev by Sujit-O2',
                          style: GoogleFonts.outfit(
                            color: Colors.white10,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
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

  Widget _buildDrawerTopBanner(Color primary) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 150,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/gif/sidebar_top.gif',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              filterQuality: FilterQuality.low,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.06),
                    Colors.black.withValues(alpha: 0.58),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Neural Link',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Voice control active',
                    style: GoogleFonts.outfit(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 42,
                    height: 3,
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(99),
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

  Widget _buildDrawerAutoListenTile(Color primary) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Icon(
            _isAutoListening ? Icons.mic : Icons.mic_off,
            color: _isAutoListening ? primary : Colors.white38,
            size: 18,
          ),
          const SizedBox(width: 10),
          Text(
            'Auto Listen',
            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13),
          ),
          const Spacer(),
          Switch(
            value: _isAutoListening,
            onChanged: (_) => _toggleAutoListen(),
            activeColor: primary,
            inactiveThumbColor: Colors.white38,
            inactiveTrackColor: Colors.white12,
          ),
        ],
      ),
    );
  }
}
