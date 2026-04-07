// ignore_for_file: use_build_context_synchronously
part of '../main.dart';

extension _MainDrawerExtension on _ChatHomePageState {
  Widget _buildNavDrawer(AppThemeMode mode) {
    final theme = AppThemes.getTheme(mode);
    final primary = theme.primaryColor;

    Widget navItem(String label, IconData icon, int navIdx, {int? badgeCount}) {
      final selected = _navIndex == navIdx;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: selected ? LinearGradient(
            colors: [primary.withValues(alpha: 0.28), primary.withValues(alpha: 0.08)],
            begin: Alignment.centerLeft, end: Alignment.centerRight,
          ) : null,
          border: Border.all(
            color: selected ? primary.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.04),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected ? [
            BoxShadow(color: primary.withValues(alpha: 0.25), blurRadius: 16, spreadRadius: -2),
          ] : null,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          splashColor: primary.withValues(alpha: 0.12),
          highlightColor: primary.withValues(alpha: 0.06),
          onTap: () {
            updateState(() => _navIndex = navIdx);
            Navigator.pop(context);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(children: [
              // Left active bar
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 3, height: selected ? 20 : 0,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: primary,
                  boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.7), blurRadius: 6)],
                ),
              ),
              // Icon box
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 28, height: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: selected ? LinearGradient(
                    colors: [primary, primary.withValues(alpha: 0.65)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ) : null,
                  color: selected ? null : Colors.white.withValues(alpha: 0.07),
                  boxShadow: selected ? [BoxShadow(color: primary.withValues(alpha: 0.4), blurRadius: 10)] : null,
                ),
                child: Icon(icon, color: selected ? Colors.white : Colors.white54, size: 14),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label, style: GoogleFonts.outfit(
                  color: selected ? Colors.white : Colors.white60,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                  letterSpacing: 0.2,
                )),
              ),
              if (badgeCount != null && badgeCount > 0)
                Container(
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [primary, primary.withValues(alpha: 0.6)]),
                    boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.5), blurRadius: 6)],
                  ),
                  child: Center(child: Text('$badgeCount',
                    style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w800))),
                ),
              if (selected)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(Icons.arrow_forward_ios_rounded, color: primary, size: 11),
                ),
            ]),
          ),
        ),
      );
    }

    Widget drawerTile(String label, IconData icon, Color color, VoidCallback onTap, {String? badge}) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            splashColor: color.withValues(alpha: 0.12),
            highlightColor: color.withValues(alpha: 0.06),
            onTap: () {
              Navigator.pop(context);
              onTap();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withValues(alpha: 0.07)),
                gradient: LinearGradient(
                  colors: [color.withValues(alpha: 0.04), Colors.transparent],
                  begin: Alignment.centerLeft, end: Alignment.centerRight,
                ),
              ),
              child: Row(children: [
                // Premium glowing icon
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(
                      colors: [color.withValues(alpha: 0.35), color.withValues(alpha: 0.12)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
                    boxShadow: [
                      BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, spreadRadius: -2),
                    ],
                  ),
                  child: Icon(icon, color: color, size: 14),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(label, style: GoogleFonts.outfit(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  )),
                ),
                if (badge != null)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color.withValues(alpha: 0.35)),
                      color: color.withValues(alpha: 0.12),
                    ),
                    child: Text(badge, style: GoogleFonts.jetBrainsMono(
                      color: color, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                Icon(Icons.chevron_right_rounded, color: color.withValues(alpha: 0.4), size: 16),
              ]),
            ),
          ),
        ),
      );
    }



    Widget hubAccordion(String title, IconData icon, Color color, List<Widget> children, {String? badge}) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
          color: Colors.white.withValues(alpha: 0.02),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
            splashColor: color.withValues(alpha: 0.06),
            highlightColor: Colors.transparent,
          ),
          child: ExpansionTile(
            collapsedIconColor: Colors.white30,
            iconColor: color,
            tilePadding: const EdgeInsets.symmetric(horizontal: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.08)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                boxShadow: [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 8, spreadRadius: -2)],
              ),
              child: Icon(icon, color: color, size: 14),
            ),
            title: Row(
              children: [
                Text(title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                if (badge != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      gradient: LinearGradient(
                        colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.05)],
                      ),
                      border: Border.all(color: color.withValues(alpha: 0.3)),
                    ),
                    child: Text(badge, style: GoogleFonts.outfit(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ),
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                  color: Colors.white.withValues(alpha: 0.015),
                ),
                padding: const EdgeInsets.only(bottom: 6, top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              )
            ],
          ),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final drawerWidth = (screenWidth * 0.82).clamp(0.0, 320.0);
    return Drawer(
      width: drawerWidth,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Deep cinematic dark layout
      child: Stack(
        children: [
          // Subtle background GIF overlay
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: Image.asset(
                  'assets/gif/sidebar_bg.gif',
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.low,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink()),
            ),
          ),
          // Removed Frosted Glass Layer over the GIF to drastically improve scroll performance and eliminate drawer open lag.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, const Color(0xFF0F1014).withValues(alpha: 0.9)],
                ),
              ),
            ),
          ),
          // ── ULTRA-PREMIUM FULL-BLEED "SEXY" HEADER ───────────────────────
          /* 
             We remove SafeArea from wrapping the entire drawer so the banner 
             can dynamically extend all the way under the status bar, creating
             a stunning, edge-to-edge "sexy" immersive gaming aesthetic.
          */
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 180, // Restored, slightly more compact
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Dynamic Animated Cover Image (sidebartop.gif)
                    Image.asset(
                      'assets/gif/sidebar_top.gif',
                      fit: BoxFit.cover,
                      alignment: const Alignment(0, -0.2), // Focus on face/eyes
                      gaplessPlayback: true, // Prevents flickering
                    ),
                    
                    // Deep Vignette + Fade to Black (seamless merge)
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter, end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.2), // Top edge shading
                            Colors.transparent,
                            const Color(0xFF0F1014).withValues(alpha: 0.6),
                            const Color(0xFF0F1014), // Exactly matches drawer BG
                          ],
                          stops: const [0.0, 0.4, 0.8, 1.0],
                        ),
                      ),
                    ),

                    // Top-right dynamic ambient quote
                    const Positioned(
                      top: 16, right: 16,
                      child: SafeArea(child: FadingQuoteOverlay()),
                    ),

                    // Avatar & Stats directly overlaid on the fade
                    Positioned(
                      left: 20, right: 20, bottom: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Scaled down Avatar
                              Container(
                                width: 56, height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: primary.withValues(alpha: 0.8), width: 2),
                                  boxShadow: [
                                    BoxShadow(color: primary.withValues(alpha: 0.6), blurRadius: 16, spreadRadius: -2),
                                    BoxShadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 8, offset: const Offset(0, 4)),
                                  ],
                                  image: DecorationImage(
                                    image: _imageProviderFor(assetPath: _appIconImageAsset, customPath: _effectiveAppIconCustomPath),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ShaderMask(
                                        shaderCallback: (bounds) => LinearGradient(
                                          colors: [Colors.white, Colors.pink.shade200],
                                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                                        ).createShader(bounds),
                                        child: Text('ZERO TWO',
                                          style: GoogleFonts.outfit(
                                            color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 3)),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          const BreathingPulse(color: Colors.greenAccent, size: 6),
                                          const SizedBox(width: 6),
                                          Text('SYSTEM ONLINE',
                                            style: GoogleFonts.jetBrainsMono(color: Colors.white70, fontSize: 9, letterSpacing: 1.5, fontWeight: FontWeight.w800)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── SCROLLING NAV LIST ─────────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── PREMIER NEON XP BAR ──────────────────
                      AnimatedBuilder(
                        animation: AffectionService.instance,
                        builder: (context, child) {
                          final srv = AffectionService.instance;
                          final Color color = srv.levelColor;
                          final barColor = const Color(0xFFFF2D55); // Vibrant Reddish Pink
                          
                          // Custom max points for display
                          int maxPts = 50;
                          if (srv.points >= 2500) {
                            maxPts = 9999;
                          } else if (srv.points >= 1500) {
                            maxPts = 2500;
                          } else if (srv.points >= 900) {
                            maxPts = 1500;
                          } else if (srv.points >= 500) {
                            maxPts = 900;
                          } else if (srv.points >= 200) {
                            maxPts = 500;
                          } else if (srv.points >= 50) {
                            maxPts = 200;
                          }

                          return Padding(
                            padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.auto_awesome_rounded, color: color, size: 12),
                                        const SizedBox(width: 6),
                                        Text(srv.levelName.toUpperCase(),
                                            style: GoogleFonts.outfit(
                                                color: Colors.white.withValues(alpha: 0.95), 
                                                fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.8)),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: color.withValues(alpha: 0.2), width: 0.5),
                                      ),
                                      child: Text('${(srv.levelProgress * 100).toInt()}%',
                                          style: GoogleFonts.jetBrainsMono(
                                              color: color, fontSize: 10, fontWeight: FontWeight.w900)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                // The Glass Neon Bar
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    // Background / Track
                                    Container(
                                      height: 6,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: Colors.black.withValues(alpha: 0.6),
                                        boxShadow: [
                                          BoxShadow(color: Colors.white.withValues(alpha: 0.02), offset: const Offset(0, 1)),
                                        ],
                                      ),
                                    ),
                                    // Progress Fill
                                    FractionallySizedBox(
                                      widthFactor: srv.levelProgress,
                                      child: Container(
                                        height: 6,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10),
                                          gradient: LinearGradient(
                                            colors: [barColor.withValues(alpha: 0.6), barColor],
                                            begin: Alignment.centerLeft, end: Alignment.centerRight,
                                          ),
                                          boxShadow: [
                                            BoxShadow(color: barColor.withValues(alpha: 0.5), blurRadius: 12, spreadRadius: 1),
                                            BoxShadow(color: barColor.withValues(alpha: 0.3), blurRadius: 2, spreadRadius: -1),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: const _XPShimmerOverlay(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('${srv.points} / $maxPts XP TO NEXT LEVEL',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.jetBrainsMono(
                                    color: Colors.white24, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1)),
                              ],
                            ),
                          );
                        },
                      ),

                      Divider(color: Colors.white.withValues(alpha: 0.05), height: 1, indent: 20, endIndent: 20),
                      const SizedBox(height: 8),

                      _DrawerStaggerItem(index: 0, child: navItem('Chat', Icons.chat_bubble_outline, 0)),
                      const SizedBox(height: 4),
                      _DrawerStaggerItem(index: 1, child: navItem('Explore', Icons.explore_outlined, 2)),

                      const SizedBox(height: 12),
                      Divider(color: Colors.white.withValues(alpha: 0.06), height: 1, indent: 20, endIndent: 20),
                      const SizedBox(height: 12),

                      // ── ⚡ FAVORITES ───────────────────────────────────────
                      _DrawerStaggerItem(index: 2, child: hubAccordion('Favorites', Icons.star_rounded, Colors.amber, [
                        drawerTile('Voice Call', Icons.call_rounded, Colors.greenAccent, () => Navigator.push(context, MaterialPageRoute(builder: (_) => WaifuVoiceCallScreen(waifuImageAsset: _chatImageAsset, waifuName: _selectedPersona == 'Default' ? 'Zero Two' : _selectedPersona, onMicPressed: () => unawaited(_startContinuousListening()),)))),
                        drawerTile('Cloud Videos', Icons.cloud_queue_rounded, Colors.cyanAccent, () => updateState(() => _navIndex = 12), badge: 'HD'),
                        drawerTile('Manga Reader', Icons.menu_book_rounded, const Color(0xFFBB52FF), () => Navigator.pushNamed(context, '/manga-section'), badge: 'All'),
                        drawerTile('Web Streamers', Icons.travel_explore_rounded, Colors.lightBlueAccent, () => Navigator.pushNamed(context, '/web-streamers-hub'), badge: '26'),
                        drawerTile('Music Player', Icons.music_note_rounded, Colors.tealAccent, () => Navigator.pushNamed(context, '/music-player'), badge: '🎵'),
                        drawerTile('My Watchlist', Icons.favorite_rounded, Colors.pinkAccent, () => Navigator.pushNamed(context, '/watchlist'), badge: '❤️'),
                        drawerTile('Anime Quiz', Icons.quiz_rounded, Colors.amber, () => Navigator.pushNamed(context, '/anime-quiz'), badge: '🎮'),
                      ])),

                      // ── 💕 DAILY RITUALS ────────────────────────────────────
                      _DrawerStaggerItem(index: 3, child: hubAccordion('Daily Rituals', Icons.wb_sunny_rounded, Colors.pinkAccent, [
                        drawerTile('ZT Diary', Icons.book_outlined, Colors.pinkAccent, () => Navigator.pushNamed(context, '/zero-two-diary'), badge: 'Daily'),
                        drawerTile('Love Letter', Icons.mail_outline_rounded, Colors.pinkAccent, () => Navigator.pushNamed(context, '/daily-love-letter')),
                        drawerTile('Affirmations', Icons.self_improvement_outlined, Colors.purpleAccent, () => Navigator.pushNamed(context, '/daily-affirmations')),
                        drawerTile('Quote of Day', Icons.format_quote_outlined, Colors.cyanAccent, () => Navigator.pushNamed(context, '/quote-of-day')),
                        drawerTile('Fortune Cookie', Icons.cookie_outlined, Colors.amberAccent, () => Navigator.pushNamed(context, '/fortune-cookie'), badge: '🥠'),
                        drawerTile('Check-In', Icons.check_circle_outlined, Colors.greenAccent, () => Navigator.pushNamed(context, '/checkin-streak'), badge: '🔥'),
                      ], badge: 'Heart')),

                      // ── 🎮 FUN & GAMES ──────────────────────────────────────
                      _DrawerStaggerItem(index: 4, child: hubAccordion('Fun & Games', Icons.sports_esports_rounded, Colors.greenAccent, [
                        drawerTile('Boss Battles', Icons.security_rounded, Colors.redAccent, () => Navigator.pushNamed(context, '/boss-battle'), badge: 'NEW'),
                        drawerTile('Anime Wordle', Icons.grid_view_rounded, Colors.orangeAccent, () => Navigator.pushNamed(context, '/anime-wordle'), badge: 'NEW'),
                        drawerTile('Gacha Cards', Icons.card_giftcard_rounded, Colors.purpleAccent, () => Navigator.pushNamed(context, '/gacha-collector'), badge: 'NEW'),
                        drawerTile('Mini Games', Icons.sports_esports_rounded, Colors.greenAccent, () => Navigator.pushNamed(context, '/mini-games'), badge: '8+'),
                        drawerTile('Story Mode', Icons.book_rounded, Colors.purpleAccent, () => Navigator.pushNamed(context, '/story-mode')),
                        drawerTile('AR Companion', Icons.view_in_ar_rounded, Colors.pinkAccent, () => Navigator.pushNamed(context, '/ar-companion'), badge: '3D'),
                        drawerTile('Virtual Date', Icons.favorite_outline_rounded, Colors.redAccent, () => Navigator.pushNamed(context, '/virtual-date')),
                        drawerTile('Spin Wheel', Icons.radio_button_checked_outlined, Colors.amberAccent, () => Navigator.pushNamed(context, '/spinner-wheel')),
                      ], badge: 'Play')),

                      // ── 🧠 AI TOOLS ─────────────────────────────────────────
                      _DrawerStaggerItem(index: 5, child: hubAccordion('AI Tools', Icons.psychology_rounded, Colors.cyanAccent, [
                        drawerTile('AI Art Gen', Icons.brush_rounded, Colors.deepPurpleAccent, () => Navigator.pushNamed(context, '/ai-art-generator'), badge: 'NEW'),
                        drawerTile('Anime Picks', Icons.movie_filter_outlined, Colors.deepPurpleAccent, () => Navigator.pushNamed(context, '/anime-recommender'), badge: 'AI'),
                        drawerTile('Book Picks', Icons.menu_book_outlined, Colors.amberAccent, () => Navigator.pushNamed(context, '/book-recommender'), badge: 'AI'),
                        drawerTile('Dream Reader', Icons.bedtime_rounded, Colors.deepPurpleAccent, () => Navigator.pushNamed(context, '/dream-interpreter'), badge: 'AI'),
                        drawerTile('Life Coach', Icons.psychology_outlined, Colors.cyanAccent, () => Navigator.pushNamed(context, '/relationship-coach'), badge: 'AI'),
                        drawerTile('Manga Translator', Icons.translate_rounded, Colors.tealAccent, () => Navigator.pushNamed(context, '/manga-translator'), badge: 'NEW'),
                        drawerTile('Movie Picks', Icons.movie_outlined, Colors.orangeAccent, () => Navigator.pushNamed(context, '/movie-recommender'), badge: 'AI'),
                        drawerTile('Poem Generator', Icons.edit_note_rounded, Colors.pinkAccent, () => Navigator.pushNamed(context, '/poem-generator'), badge: 'AI'),
                        drawerTile('Writing Helper', Icons.edit_rounded, Colors.lightBlueAccent, () => Navigator.pushNamed(context, '/writing-helper'), badge: 'AI'),
                        drawerTile('Recipe Picks', Icons.restaurant_rounded, Colors.green, () => Navigator.pushNamed(context, '/recipe-recommender'), badge: 'AI'),
                        drawerTile('Language Tool', Icons.language_rounded, Colors.indigoAccent, () => Navigator.pushNamed(context, '/language-translator'), badge: 'AI'),
                      ], badge: 'Smart')),

                      // ── 📊 ANALYTICS & STATS ──────────────────────────────────
                      _DrawerStaggerItem(index: 6, child: hubAccordion('Analytics', Icons.analytics_rounded, Colors.cyanAccent, [
                        drawerTile('Memory Vault', Icons.memory_rounded, Colors.deepPurpleAccent, () => Navigator.pushNamed(context, '/memory-vault'), badge: 'Deep'),
                        drawerTile('Chat Analytics', Icons.bar_chart_rounded, Colors.pinkAccent, () => Navigator.pushNamed(context, '/chat-analytics'), badge: '📊'),
                        drawerTile('Stats & Habits', Icons.insights_rounded, Colors.greenAccent, () => Navigator.pushNamed(context, '/stats-habits')),
                        drawerTile('Mood Tracking', Icons.mood_rounded, Colors.amberAccent, () => Navigator.pushNamed(context, '/mood-tracking')),
                        drawerTile('Relationship Map', Icons.map_rounded, Colors.pinkAccent, () => Navigator.pushNamed(context, '/relationship-level-map')),
                        drawerTile('Love Timeline', Icons.timeline_rounded, Colors.redAccent, () => Navigator.pushNamed(context, '/relationship-timeline')),
                        drawerTile('Year In Review', Icons.calendar_today_rounded, Colors.purpleAccent, () => Navigator.pushNamed(context, '/year-in-review'), badge: '📅'),
                        drawerTile('Leaderboard', Icons.leaderboard_rounded, Colors.amberAccent, () => Navigator.pushNamed(context, '/leaderboard'), badge: '🏆'),
                      ], badge: 'Data')),

                      // ── 📝 PRODUCTIVITY ────────────────────────────────────────
                      _DrawerStaggerItem(index: 7, child: hubAccordion('Productivity', Icons.task_alt_rounded, Colors.blueAccent, [
                        drawerTile('Notes Pad', Icons.note_alt_rounded, Colors.amberAccent, () => Navigator.pushNamed(context, '/notes-pad'), badge: '📝'),
                        drawerTile('Pomodoro', Icons.timer_rounded, Colors.redAccent, () => Navigator.pushNamed(context, '/pomodoro')),
                        drawerTile('Study Timer', Icons.school_rounded, Colors.blueAccent, () => Navigator.pushNamed(context, '/study-timer')),
                        drawerTile('Goal Tracker', Icons.flag_rounded, Colors.greenAccent, () => Navigator.pushNamed(context, '/goal-tracker')),
                        drawerTile('Habit Tracker', Icons.checklist_rounded, Colors.tealAccent, () => Navigator.pushNamed(context, '/habit-tracker')),
                        drawerTile('Budget Tracker', Icons.account_balance_wallet_rounded, Colors.green, () => Navigator.pushNamed(context, '/budget-tracker')),
                        drawerTile('Countdown Timer', Icons.hourglass_bottom_rounded, Colors.orangeAccent, () => Navigator.pushNamed(context, '/countdown-timer')),
                        drawerTile('Workout Planner', Icons.fitness_center_rounded, Colors.cyanAccent, () => Navigator.pushNamed(context, '/workout-planner')),
                        drawerTile('Scheduled Msgs', Icons.schedule_send_rounded, Colors.lightBlueAccent, () => Navigator.pushNamed(context, '/scheduled-messages')),
                      ], badge: 'Focus')),

                      // ── 🧰 REAL-LIFE TOOLS ───────────────────────────────────
                      _DrawerStaggerItem(index: 7, child: hubAccordion('Real-Life Tools', Icons.handyman_rounded, Colors.purpleAccent, [
                        drawerTile('Parking Saver', Icons.local_parking_rounded, Colors.tealAccent, () => Navigator.pushNamed(context, '/parking-spot-saver'), badge: '🅿️'),
                        drawerTile('Smart Scanner', Icons.document_scanner_rounded, Colors.lightBlueAccent, () => Navigator.pushNamed(context, '/smart-scanner'), badge: 'OCR'),
                        drawerTile('Medication', Icons.medication_rounded, Colors.pinkAccent, () => Navigator.pushNamed(context, '/medication-reminder'), badge: '💊'),
                        drawerTile('Package Track', Icons.local_shipping_rounded, Colors.purpleAccent, () => Navigator.pushNamed(context, '/package-tracker'), badge: '📦'),
                        drawerTile('Emergency SOS', Icons.sos_rounded, Colors.redAccent, () => Navigator.pushNamed(context, '/emergency-sos'), badge: '🆘'),
                        drawerTile('Clipboard', Icons.content_paste_rounded, Colors.tealAccent, () => Navigator.pushNamed(context, '/clipboard-manager'), badge: '📋'),
                        drawerTile('Bill Splitter', Icons.receipt_rounded, Colors.amberAccent, () => Navigator.pushNamed(context, '/bill-splitter'), badge: '💰'),
                        drawerTile('Unit Converter', Icons.straighten_rounded, Colors.orangeAccent, () => Navigator.pushNamed(context, '/ar-ruler'), badge: '📏'),
                        drawerTile('Password Gen', Icons.password_rounded, Colors.greenAccent, () => Navigator.pushNamed(context, '/password-generator'), badge: '🔑'),
                        drawerTile('QR Scanner', Icons.qr_code_scanner_rounded, Colors.cyanAccent, () => Navigator.pushNamed(context, '/qr-scanner'), badge: '🌐'),
                      ], badge: 'Tools')),

                      // ── ⚙️ SETTINGS ─────────────────────────────────────────
                      _DrawerStaggerItem(index: 8, child: hubAccordion('Settings', Icons.settings_rounded, Colors.blueGrey, [
                        drawerTile('App Settings', Icons.settings_rounded, Colors.white70, () => updateState(() => _navIndex = 3)),
                        drawerTile('Themes', Icons.palette_rounded, Colors.pinkAccent, () => updateState(() => _navIndex = 4)),
                        drawerTile('Geofence Settings', Icons.map_rounded, Colors.tealAccent, () => Navigator.pushNamed(context, '/geofencing-settings'), badge: 'GPS'),
                        drawerTile('My Profile', Icons.person_rounded, Colors.blueAccent, () => Navigator.pushNamed(context, '/profile')),
                        drawerTile('Achievements', Icons.emoji_events_rounded, Colors.amberAccent, () => Navigator.pushNamed(context, '/achievements')),
                        drawerTile('App Icons', Icons.app_shortcut_rounded, Colors.deepPurpleAccent, () => Navigator.pushNamed(context, '/app-icon-picker'), badge: '🎨'),
                        drawerTile('Dev Config', Icons.terminal_rounded, Colors.greenAccent, () => updateState(() => _navIndex = 5)),
                        drawerTile('Debug Panel', Icons.bug_report_rounded, Colors.orangeAccent, () => updateState(() => _navIndex = 6), badge: '🛠'),
                        drawerTile('About App', Icons.info_outline_rounded, Colors.grey, () => updateState(() => _navIndex = 7)),
                      ], badge: 'Config')),

                      // ── SEE ALL FEATURES BUTTON ─────────────────────────────
                      const SizedBox(height: 16),
                      _DrawerStaggerItem(index: 9, child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            updateState(() => _navIndex = 2);
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                colors: [Colors.pinkAccent.withValues(alpha: 0.15), Colors.deepPurpleAccent.withValues(alpha: 0.15)],
                              ),
                              border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.explore_rounded, color: Colors.pinkAccent.withValues(alpha: 0.8), size: 18),
                                const SizedBox(width: 8),
                                Text('See All Features',
                                  style: GoogleFonts.outfit(color: Colors.pinkAccent, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                                const SizedBox(width: 4),
                                Icon(Icons.arrow_forward_ios_rounded, color: Colors.pinkAccent.withValues(alpha: 0.6), size: 14),
                              ],
                            ),
                          ),
                        ),
                      )),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              // ── STATIC BOTTOM STATUS STRIP (always visible) ──────────
              const _DrawerStatusFooter(),
              const SizedBox(height: 16),
            ],
          ),
          // Stack children end
        ],
      ),
    );
  }
}

// ── CUSTOM ANIMATION WIDGETS ─────────────────────────────────────────────────

/// Staggered slide+fade entrance for drawer items.
class _DrawerStaggerItem extends StatefulWidget {
  final int index;
  final Widget child;
  const _DrawerStaggerItem({required this.index, required this.child});
  @override
  State<_DrawerStaggerItem> createState() => _DrawerStaggerItemState();
}
class _DrawerStaggerItemState extends State<_DrawerStaggerItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    final delay = widget.index * 0.06;
    final curve = CurvedAnimation(parent: _ctrl, curve: Interval(delay.clamp(0,0.6), 1.0, curve: Curves.easeOutCubic));
    _fade  = Tween<double>(begin: 0, end: 1).animate(curve);
    _slide = Tween<Offset>(begin: const Offset(-0.12, 0), end: Offset.zero).animate(curve);
    _ctrl.forward();
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child));
  }
}

/// Animated bottom footer shown at the bottom of the drawer.
class _DrawerStatusFooter extends StatefulWidget {
  const _DrawerStatusFooter();
  @override State<_DrawerStatusFooter> createState() => _DrawerStatusFooterState();
}
class _DrawerStatusFooterState extends State<_DrawerStatusFooter>
    with SingleTickerProviderStateMixin {
  late AnimationController _glow;
  @override
  void initState() {
    super.initState();
    _glow = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
  }
  @override void dispose() { _glow.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glow,
      builder: (_, __) {
        final t = _glow.value;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFF4FA8).withValues(alpha: 0.2)),
            gradient: LinearGradient(
              colors: [
                const Color(0xFFFF4FA8).withValues(alpha: 0.06 + 0.03 * t),
                const Color(0xFF9B59B6).withValues(alpha: 0.04),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF4FA8).withValues(alpha: 0.08 + 0.06 * t),
                blurRadius: 20,
              ),
            ],
          ),
          child: Row(
            children: [
              // Pulsing status dot
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.greenAccent,
                  boxShadow: [BoxShadow(
                    color: Colors.greenAccent.withValues(alpha: 0.3 + 0.5 * t),
                    blurRadius: 8,
                  )],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CORE ONLINE',
                      style: GoogleFonts.jetBrainsMono(
                        color: Colors.greenAccent.withValues(alpha: 0.8),
                        fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    Text('ZERO TWO  002',
                      style: GoogleFonts.jetBrainsMono(
                        color: Colors.white30, fontSize: 8, letterSpacing: 1.5)),
                  ],
                ),
              ),
              Text('❤️ MY DARLING',
                style: GoogleFonts.outfit(
                  color: const Color(0xFFFF4FA8).withValues(alpha: 0.6 + 0.3 * t),
                  fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
            ],
          ),
        );
      },
    );
  }
}

class BreathingPulse extends StatefulWidget {
  final Color color;
  final double size;
  const BreathingPulse({super.key, required this.color, this.size = 8.0});

  @override
  State<BreathingPulse> createState() => _BreathingPulseState();
}

class _BreathingPulseState extends State<BreathingPulse> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine));
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: widget.size, height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle, color: widget.color,
          boxShadow: [BoxShadow(color: widget.color, blurRadius: widget.size)],
        ),
      ),
    );
  }
}

class FadingQuoteOverlay extends StatefulWidget {
  const FadingQuoteOverlay({super.key});
  @override
  State<FadingQuoteOverlay> createState() => _FadingQuoteOverlayState();
}

class _FadingQuoteOverlayState extends State<FadingQuoteOverlay> {
  final List<String> _quotes = [
    "\"I've found you, my Darling.\"",
    "\"A beautiful world, isn't it?\"",
    "\"Will you be my wings?\"",
    "\"Let's fly away together.\"",
    "\"Don't let go of me...\"",
  ];
  int _index = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (mounted) setState(() => _index = (_index + 1) % _quotes.length);
    });
  }
  @override
  void dispose() { _timer.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(seconds: 2),
      switchInCurve: Curves.easeIn, switchOutCurve: Curves.easeOut,
      child: Text(
        _quotes[_index],
        key: ValueKey<int>(_index),
        style: GoogleFonts.outfit(
          color: Colors.white.withValues(alpha: 0.4),
          fontSize: 12,
          fontStyle: FontStyle.italic,
          letterSpacing: 1.0,
          fontWeight: FontWeight.w300,
        ),
      ),
    );
  }
}

class _XPShimmerOverlay extends StatefulWidget {
  const _XPShimmerOverlay();
  @override State<_XPShimmerOverlay> createState() => _XPShimmerOverlayState();
}
class _XPShimmerOverlayState extends State<_XPShimmerOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return FractionalTranslation(
          translation: Offset(_ctrl.value * 2 - 1, 0),
          child: Container(
            width: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white.withValues(alpha: 0), Colors.white.withValues(alpha: 0.3), Colors.white.withValues(alpha: 0)],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        );
      },
    );
  }
}

