import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:anime_waifu/config/app_themes.dart';
import 'package:anime_waifu/widgets/premium_ui_kit.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PREMIUM NAVIGATION DRAWER — Optimized & Polished
/// ═══════════════════════════════════════════════════════════════════════════

class PremiumDrawer extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.appTokens;

    return Drawer(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.scaffoldBackgroundColor,
              theme.scaffoldBackgroundColor.withValues(alpha: 0.95),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── User Profile Header ────────────────────────────────────
              _buildProfileHeader(context, theme, tokens),

              const SizedBox(height: 8),

              // ── Stats Row ──────────────────────────────────────────────
              _buildStatsRow(context, theme, tokens),

              const PremiumDivider(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                hasGradient: true,
              ),

              // ── Navigation Items ───────────────────────────────────────
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildNavSection(
                      context,
                      'MAIN',
                      [
                        _NavItem(
                          icon: Icons.chat_bubble_rounded,
                          label: 'Chat',
                          index: 0,
                        ),
                        _NavItem(
                          icon: Icons.notifications_rounded,
                          label: 'Notifications',
                          index: 1,
                        ),
                        _NavItem(
                          icon: Icons.video_library_rounded,
                          label: 'Media',
                          index: 2,
                        ),
                        _NavItem(
                          icon: Icons.apps_rounded,
                          label: 'All Features',
                          route: '/comprehensive-features-hub',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildNavSection(
                      context,
                      'CUSTOMIZE',
                      [
                        _NavItem(
                          icon: Icons.palette_rounded,
                          label: 'Themes',
                          index: 4,
                        ),
                        _NavItem(
                          icon: Icons.settings_rounded,
                          label: 'Settings',
                          index: 3,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildNavSection(
                      context,
                      'ADVANCED',
                      [
                        _NavItem(
                          icon: Icons.code_rounded,
                          label: 'Dev Config',
                          index: 5,
                        ),
                        _NavItem(
                          icon: Icons.bug_report_rounded,
                          label: 'Debug',
                          index: 6,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Footer ─────────────────────────────────────────────────
              _buildFooter(context, theme, tokens),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
      BuildContext context, ThemeData theme, AppDesignTokens tokens) {
    return GlassCard(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      glow: true,
      child: Row(
        children: [
          // Avatar
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.tertiary,
                ],
              ),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: userAvatarUrl != null
                ? ClipOval(
                    child: Image.network(
                      userAvatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.person_rounded,
                        size: 28,
                        color: Colors.white,
                      ),
                    ),
                  )
                : Icon(
                    Icons.person_rounded,
                    size: 28,
                    color: Colors.white,
                  ),
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
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  userEmail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: tokens.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                PremiumBadge(
                  text: relationshipLevel,
                  icon: Icons.favorite_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(
      BuildContext context, ThemeData theme, AppDesignTokens tokens) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              context,
              icon: Icons.favorite_rounded,
              label: 'Affection',
              value: affectionPoints.toString(),
              color: Colors.pinkAccent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildStatCard(
              context,
              icon: Icons.local_fire_department_rounded,
              label: 'Streak',
              value: '$streakDays days',
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final tokens = context.appTokens;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.panelElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.outline),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
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
    );
  }

  Widget _buildNavSection(
      BuildContext context, String title, List<_NavItem> items) {
    final tokens = context.appTokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            title,
            style: GoogleFonts.outfit(
              color: tokens.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...items.map((item) => _buildNavItem(context, item)),
      ],
    );
  }

  Widget _buildNavItem(BuildContext context, _NavItem item) {
    final theme = Theme.of(context);
    final tokens = context.appTokens;
    final isActive = item.index != null && currentIndex == item.index;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            if (item.route != null) {
              Navigator.pushNamed(context, item.route!);
            } else if (item.index != null) {
              onNavigate(item.index!);
            }
          },
          borderRadius: BorderRadius.circular(14),
          splashColor: theme.colorScheme.primary.withValues(alpha: 0.1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: isActive
                  ? LinearGradient(
                      colors: [
                        theme.colorScheme.primary.withValues(alpha: 0.15),
                        theme.colorScheme.primary.withValues(alpha: 0.08),
                      ],
                    )
                  : null,
              borderRadius: BorderRadius.circular(14),
              border: isActive
                  ? Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    )
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isActive
                        ? theme.colorScheme.primary.withValues(alpha: 0.2)
                        : tokens.panelMuted,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    item.icon,
                    size: 18,
                    color:
                        isActive ? theme.colorScheme.primary : tokens.textMuted,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    item.label,
                    style: GoogleFonts.outfit(
                      color: isActive
                          ? theme.colorScheme.onSurface
                          : tokens.textMuted,
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ),
                if (isActive)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary,
                      boxShadow: [
                        BoxShadow(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.5),
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

  Widget _buildFooter(
      BuildContext context, ThemeData theme, AppDesignTokens tokens) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: tokens.outline),
        ),
      ),
      child: Column(
        children: [
          PremiumListTile(
            leadingIcon: Icons.info_outline_rounded,
            title: 'About',
            onTap: () {
              Navigator.pop(context);
              onNavigate(7);
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Zero Two v9.3 • Core 0.02',
            style: GoogleFonts.outfit(
              color: tokens.textSoft,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final int? index;
  final String? route;

  _NavItem({
    required this.icon,
    required this.label,
    this.index,
    this.route,
  });
}
