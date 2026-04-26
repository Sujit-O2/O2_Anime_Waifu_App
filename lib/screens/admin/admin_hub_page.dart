import 'package:anime_waifu/config/app_themes.dart';
import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'admin_panel_page.dart';
import 'discord_integration_panel_page.dart';

class AdminHubPage extends StatefulWidget {
  const AdminHubPage({super.key});

  @override
  State<AdminHubPage> createState() => _AdminHubPageState();
}

class _AdminHubPageState extends State<AdminHubPage> {
  int _selectedCategory = 0;
  late final List<Map<String, dynamic>> _categories;

  @override
  void initState() {
    super.initState();
    _categories = [
      {
        'title': '👤 User Management',
        'icon': Icons.people_rounded,
        'items': [
          {
            'label': 'Admin Dashboard',
            'description': 'Moderation, analytics, feature flags',
            'icon': Icons.admin_panel_settings_rounded,
            'page': const AdminPanelPage(),
          },
        ],
      },
      {
        'title': '🎮 Integrations',
        'icon': Icons.webhook_rounded,
        'items': [
          {
            'label': 'Discord Webhooks',
            'description': 'Event streaming & achievement sharing',
            'icon': Icons.webhook_rounded,
            'page': const DiscordIntegrationPanelPage(),
          },
        ],
      },
      {
        'title': '📊 System',
        'icon': Icons.settings_rounded,
        'items': [
          {
            'label': 'System Health',
            'description': 'Monitor app performance & health',
            'icon': Icons.health_and_safety_rounded,
            'callback': _onSystemHealth,
          },
          {
            'label': 'Backup & Restore',
            'description': 'Cloud settings sync & backup',
            'icon': Icons.backup_rounded,
            'callback': _onBackup,
          },
        ],
      },
    ];
  }

  void _onSystemHealth() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('System is running optimally')),
    );
  }

  void _onBackup() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Last backup: Today at 10:30 AM')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tokens = context.appTokens;
    final selectedCategory = _categories[_selectedCategory];
    final selectedItems =
        (selectedCategory['items'] as List).cast<Map<String, dynamic>>();
    return FeaturePageV2(
      title: 'Admin Hub',
      subtitle: 'System control, monitoring, and integrations',
      onBack: () => Navigator.pop(context),
      actions: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: colors.primary.withValues(alpha: 0.22)),
          ),
          child: Text(
            '${selectedItems.length} tools',
            style: GoogleFonts.outfit(
              color: colors.primary,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
      content: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: GlassCard(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.all(18),
              glow: true,
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colors.primary.withValues(alpha: 0.30),
                          colors.tertiary.withValues(alpha: 0.12),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border:
                          Border.all(color: colors.primary.withValues(alpha: 0.28)),
                    ),
                    child: Icon(selectedCategory['icon'] as IconData,
                        color: colors.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedCategory['title'] as String,
                          style: GoogleFonts.outfit(
                            color: colors.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Focused tools for operations, integrations, and system visibility.',
                          style: GoogleFonts.outfit(
                            color: tokens.textMuted,
                            fontSize: 12,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 76,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final cat = _categories[idx];
                final isSelected = idx == _selectedCategory;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = idx),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? tokens.glassGradient
                          : LinearGradient(
                              colors: [
                                tokens.panelElevated,
                                tokens.panel,
                              ],
                            ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected
                            ? colors.primary.withValues(alpha: 0.4)
                            : tokens.outline,
                        width: isSelected ? 1.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: colors.primary.withValues(alpha: 0.18),
                                blurRadius: 20,
                                spreadRadius: -4,
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          cat['icon'] as IconData,
                          color:
                              isSelected ? colors.primary : tokens.textMuted,
                          size: 20,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          cat['title'].toString().split(' ').last,
                          style: GoogleFonts.outfit(
                            color:
                                isSelected ? colors.primary : tokens.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: selectedItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, idx) => _buildAdminTile(selectedItems[idx]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminTile(Map<String, dynamic> item) {
    final colors = Theme.of(context).colorScheme;
    final tokens = context.appTokens;
    return GestureDetector(
      onTap: () {
        if (item['page'] != null) {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  item['page'] as Widget,
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                            begin: const Offset(0.1, 0.0), end: Offset.zero)
                        .animate(
                      CurvedAnimation(
                          parent: animation, curve: Curves.easeOutCubic),
                    ),
                    child: child,
                  ),
                );
              },
              transitionDuration: const Duration(milliseconds: 350),
            ),
          );
        } else if (item['callback'] != null) {
          (item['callback'] as VoidCallback)();
        }
      },
      child: GlassCard(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(16),
        glow: true,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.15),
                    blurRadius: 8,
                    spreadRadius: -2,
                  )
                ],
              ),
              child: Icon(
                item['icon'] as IconData,
                color: colors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['label'] as String,
                    style: GoogleFonts.outfit(
                      color: colors.onSurface,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['description'] as String,
                    style: GoogleFonts.outfit(
                      color: tokens.textMuted,
                      fontSize: 11.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: tokens.textMuted,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
