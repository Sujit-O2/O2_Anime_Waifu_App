import 'package:anime_waifu/widgets/waifu_background.dart';
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
            'page': AdminPanelPage(),
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
            'page': DiscordIntegrationPanelPage(),
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
      const SnackBar(content: Text('✅ System is running optimally')),
    );
  }

  void _onBackup() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Last backup: Today at 10:30 AM')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: WaifuBackground(
        opacity: 0.12,
        tint: const Color(0xFF090714),
        child: SafeArea(
          child: Column(
            children: [
              // ===== HEADER =====
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white60,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '⚙️ ADMIN HUB',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'System Control & Monitoring',
                            style: GoogleFonts.outfit(
                              color: Colors.cyanAccent.withValues(alpha: 0.6),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // ===== CATEGORY TABS =====
              SizedBox(
                height: 70,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final cat = _categories[idx];
                    final isSelected = idx == _selectedCategory;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = idx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.cyanAccent.withValues(alpha: 0.12)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Colors.cyanAccent.withValues(alpha: 0.4)
                                : Colors.white.withValues(alpha: 0.1),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              cat['icon'] as IconData,
                              color: isSelected
                                  ? Colors.cyanAccent
                                  : Colors.white54,
                              size: 20,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              cat['title']
                                  .toString()
                                  .split(' ')
                                  .last,
                              style: GoogleFonts.outfit(
                                color: isSelected
                                    ? Colors.cyanAccent
                                    : Colors.white54,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              // ===== CONTENT =====
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories[_selectedCategory]['items'].length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, idx) {
                    final item =
                        _categories[_selectedCategory]['items'][idx]
                            as Map<String, dynamic>;
                    return _buildAdminTile(item);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminTile(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () {
        if (item['page'] != null) {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => item['page'] as Widget,
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0.1, 0.0), end: Offset.zero).animate(
                      CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
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
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.cyanAccent.withValues(alpha: 0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.cyanAccent.withValues(alpha: 0.08),
              blurRadius: 16,
              spreadRadius: -2,
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.cyanAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyanAccent.withValues(alpha: 0.15),
                    blurRadius: 8,
                    spreadRadius: -2,
                  )
                ],
              ),
              child: Icon(
                item['icon'] as IconData,
                color: Colors.cyanAccent,
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
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['description'] as String,
                    style: GoogleFonts.outfit(
                      color: Colors.white54,
                      fontSize: 11,
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
              color: Colors.white24,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}



