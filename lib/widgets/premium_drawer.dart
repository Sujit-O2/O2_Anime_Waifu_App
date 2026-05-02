import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:anime_waifu/config/app_themes.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PREMIUM NAVIGATION DRAWER — v2 Enhanced UI
/// ═══════════════════════════════════════════════════════════════════════════

class PremiumDrawer extends StatefulWidget {
  final int currentIndex;
  final Function(int) onNavigate;
  final String userName;
  final String userEmail;
  final String? userAvatarUrl;
  final int affectionPoints;
  final int streakDays;
  final String relationshipLevel;

  const PremiumDrawer({
    super.key,
    required this.currentIndex,
    required this.onNavigate,
    required this.userName,
    required this.userEmail,
    this.userAvatarUrl,
    required this.affectionPoints,
    required this.streakDays,
    required this.relationshipLevel,
  });

  @override
  State<PremiumDrawer> createState() => _PremiumDrawerState();
}

class _PremiumDrawerState extends State<PremiumDrawer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(-0.05, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.appTokens;

    return Drawer(
      backgroundColor: Colors.transparent,
      child: SlideTransition(
        position: _slideAnim,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.scaffoldBackgroundColor,
                  Color.lerp(
                    theme.scaffoldBackgroundColor,
                    theme.colorScheme.primary,
                    0.04,
                  )!,
                ],
              ),
              border: Border(
                right: BorderSide(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // ── Profile Header ─────────────────────────────────────
                  _ProfileHeader(
                    userName: widget.userName,
                    userEmail: widget.userEmail,
                    userAvatarUrl: widget.userAvatarUrl,
                    relationshipLevel: widget.relationshipLevel,
                  ),

                  const SizedBox(height: 12),

                  // ── Stats Row ──────────────────────────────────────────
                  _StatsRow(
                    affectionPoints: widget.affectionPoints,
                    streakDays: widget.streakDays,
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    child: Divider(
                      color: tokens.outline.withValues(alpha: 0.6),
                      height: 1,
                    ),
                  ),

                  // ── Navigation Items ───────────────────────────────────
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _NavSection(
                          title: 'MAIN',
                          items: const [
                            _NavItem(
                              icon: Icons.chat_bubble_rounded,
                              label: 'Chat',
                              index: 0,
                              accentColor: Colors.pinkAccent,
                            ),
                            _NavItem(
                              icon: Icons.notifications_rounded,
                              label: 'Notifications',
                              index: 1,
                              accentColor: Colors.amber,
                            ),
                            _NavItem(
                              icon: Icons.video_library_rounded,
                              label: 'Media',
                              index: 2,
                              accentColor: Colors.redAccent,
                            ),
                            _NavItem(
                              icon: Icons.apps_rounded,
                              label: 'All Features',
                              route: '/comprehensive-features-hub',
                              accentColor: Colors.tealAccent,
                              badge: 'NEW',
                            ),
                          ],
                          currentIndex: widget.currentIndex,
                          onNavigate: widget.onNavigate,
                        ),
                        const SizedBox(height: 8),
                        _NavSection(
                          title: 'CUSTOMIZE',
                          items: const [
                            _NavItem(
                              icon: Icons.palette_rounded,
                              label: 'Themes',
                              index: 4,
                              accentColor: Colors.purpleAccent,
                            ),
                            _NavItem(
                              icon: Icons.settings_rounded,
                              label: 'Settings',
                              index: 3,
                              accentColor: Colors.blueGrey,
                            ),
                          ],
                          currentIndex: widget.currentIndex,
                          onNavigate: widget.onNavigate,
                        ),
                        const SizedBox(height: 8),
                        _NavSection(
                          title: 'ADVANCED',
                          items: const [
                            _NavItem(
                              icon: Icons.code_rounded,
                              label: 'Dev Config',
                              index: 5,
                              accentColor: Colors.greenAccent,
                            ),
                            _NavItem(
                              icon: Icons.bug_report_rounded,
                              label: 'Debug',
                              index: 6,
                              accentColor: Colors.orangeAccent,
                            ),
                          ],
                          currentIndex: widget.currentIndex,
                          onNavigate: widget.onNavigate,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),

                  // ── Footer ─────────────────────────────────────────────
                  _DrawerFooter(onAboutTap: () {
                    Navigator.pop(context);
                    widget.onNavigate(7);
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile Header
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String? userAvatarUrl;
  final String relationshipLevel;

  const _ProfileHeader({
    required this.userName,
    required this.userEmail,
    this.userAvatarUrl,
    required this.relationshipLevel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.appTokens;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.15),
            theme.colorScheme.tertiary.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/gif/sidebar_top.gif',
                fit: BoxFit.cover,
                filterQuality: FilterQuality.low,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Row(
            children: [
              // Avatar with glow ring
              _AvatarWidget(
                avatarUrl: userAvatarUrl,
                primaryColor: theme.colorScheme.primary,
                tertiaryColor: theme.colorScheme.tertiary,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        color: theme.colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      userEmail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        color: tokens.textMuted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _RelationshipBadge(level: relationshipLevel),
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
}

class _AvatarWidget extends StatelessWidget {
  final String? avatarUrl;
  final Color primaryColor;
  final Color tertiaryColor;

  const _AvatarWidget({
    this.avatarUrl,
    required this.primaryColor,
    required this.tertiaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Glow ring
        Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [primaryColor, tertiaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.4),
                blurRadius: 16,
                spreadRadius: 0,
              ),
            ],
          ),
        ),
        // Avatar
        Positioned(
          left: 3,
          top: 3,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  primaryColor.withValues(alpha: 0.8),
                  tertiaryColor.withValues(alpha: 0.8),
                ],
              ),
            ),
            child: avatarUrl != null
                ? ClipOval(
                    child: Image.network(
                      avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.person_rounded,
                        size: 28,
                        color: Colors.white,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.person_rounded,
                    size: 28,
                    color: Colors.white,
                  ),
          ),
        ),
        // Online indicator
        Positioned(
          right: 2,
          bottom: 2,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.greenAccent,
              border: Border.all(
                color: Theme.of(context).scaffoldBackgroundColor,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.greenAccent.withValues(alpha: 0.6),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RelationshipBadge extends StatelessWidget {
  final String level;

  const _RelationshipBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.25),
            theme.colorScheme.tertiary.withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.favorite_rounded,
            size: 11,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 5),
          Text(
            level,
            style: GoogleFonts.outfit(
              color: theme.colorScheme.primary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats Row
// ─────────────────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final int affectionPoints;
  final int streakDays;

  const _StatsRow({
    required this.affectionPoints,
    required this.streakDays,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.favorite_rounded,
              label: 'Affection',
              value: _formatNumber(affectionPoints),
              color: Colors.pinkAccent,
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B9D), Color(0xFFFF4081)],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              icon: Icons.local_fire_department_rounded,
              label: 'Streak',
              value: '$streakDays days',
              color: Colors.orange,
              gradient: const LinearGradient(
                colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final LinearGradient gradient;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTokens;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: tokens.panelElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    color: tokens.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Navigation Section & Items
// ─────────────────────────────────────────────────────────────────────────────

class _NavSection extends StatelessWidget {
  final String title;
  final List<_NavItem> items;
  final int currentIndex;
  final Function(int) onNavigate;

  const _NavSection({
    required this.title,
    required this.items,
    required this.currentIndex,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
          child: Text(
            title,
            style: GoogleFonts.outfit(
              color: tokens.textMuted.withValues(alpha: 0.7),
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        ),
        ...items.map((item) => _NavItemWidget(
              item: item,
              isActive: item.index != null && currentIndex == item.index,
              onNavigate: onNavigate,
            )),
      ],
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final int? index;
  final String? route;
  final Color accentColor;
  final String? badge;

  const _NavItem({
    required this.icon,
    required this.label,
    this.index,
    this.route,
    required this.accentColor,
    this.badge,
  });
}

class _NavItemWidget extends StatefulWidget {
  final _NavItem item;
  final bool isActive;
  final Function(int) onNavigate;

  const _NavItemWidget({
    required this.item,
    required this.isActive,
    required this.onNavigate,
  });

  @override
  State<_NavItemWidget> createState() => _NavItemWidgetState();
}

class _NavItemWidgetState extends State<_NavItemWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnim = _pressCtrl;
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _pressCtrl.reverse();
  void _onTapUp(TapUpDetails _) => _pressCtrl.forward();
  void _onTapCancel() => _pressCtrl.forward();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.appTokens;
    final item = widget.item;
    final isActive = widget.isActive;
    final accent = isActive ? theme.colorScheme.primary : item.accentColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.pop(context);
          if (item.route != null) {
            Navigator.pushNamed(context, item.route!);
          } else if (item.index != null) {
            widget.onNavigate(item.index!);
          }
        },
        child: ScaleTransition(
          scale: _scaleAnim,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              gradient: isActive
                  ? LinearGradient(
                      colors: [
                        theme.colorScheme.primary.withValues(alpha: 0.18),
                        theme.colorScheme.primary.withValues(alpha: 0.06),
                      ],
                    )
                  : null,
              borderRadius: BorderRadius.circular(14),
              border: isActive
                  ? Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.35),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: [
                // Icon container
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isActive
                        ? accent.withValues(alpha: 0.2)
                        : tokens.panelMuted,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    item.icon,
                    size: 18,
                    color: isActive ? accent : tokens.textMuted,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    item.label,
                    style: GoogleFonts.outfit(
                      color: isActive
                          ? theme.colorScheme.onSurface
                          : tokens.textSoft,
                      fontSize: 14,
                      fontWeight:
                          isActive ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                // Badge
                if (item.badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          item.accentColor,
                          item.accentColor.withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.badge!,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                // Active indicator dot
                if (isActive && item.badge == null)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent,
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.6),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Footer
// ─────────────────────────────────────────────────────────────────────────────

class _DrawerFooter extends StatelessWidget {
  final VoidCallback onAboutTap;

  const _DrawerFooter({required this.onAboutTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.appTokens;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: tokens.outline.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onAboutTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: tokens.textMuted,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'About',
                      style: GoogleFonts.outfit(
                        color: tokens.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Zero Two v9.3 • Core 0.02',
                style: GoogleFonts.outfit(
                  color: tokens.textSoft.withValues(alpha: 0.6),
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
