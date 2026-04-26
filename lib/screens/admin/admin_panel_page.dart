import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:anime_waifu/config/app_themes.dart';
import 'package:anime_waifu/core/v2_upgrade_kit.dart';

/// Admin Dashboard Panel - Moderation, User Management, Analytics
class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({super.key});

  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage>
    with TickerProviderStateMixin {
  late TabController _tabCtrl;
  // final AdminDashboardService _admin = AdminDashboardService();
  Map<String, dynamic> _systemHealth = {};
  bool _maintenanceMode = false;
  bool _loading = true;
  bool _hadLoadError = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _loadDashboard();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    try {
      // getSystemHealth is not available - use placeholder
      if (mounted) {
        setState(() {
          _systemHealth = {'status': 'online'};
          _loading = false;
          _hadLoadError = false;
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading dashboard: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _hadLoadError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tokens = context.appTokens;
    return FeaturePageV2(
      title: 'Admin Dashboard',
      subtitle: 'Moderation, analytics, feature flags, and live ops',
      onBack: () => Navigator.pop(context),
      actions: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: (_systemHealth['status'] == 'online'
                    ? Colors.greenAccent
                    : colors.primary)
                .withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: (_systemHealth['status'] == 'online'
                      ? Colors.greenAccent
                      : colors.primary)
                  .withValues(alpha: 0.24),
            ),
          ),
          child: Text(
            (_systemHealth['status'] ?? 'online').toString().toUpperCase(),
            style: GoogleFonts.outfit(
              color: _systemHealth['status'] == 'online'
                  ? Colors.greenAccent
                  : colors.primary,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
      content: _loading
          ? const PremiumLoadingState(
              label: 'Loading dashboard',
              subtitle:
                  'Pulling moderation, analytics, and system health into one view.',
            )
          : _hadLoadError
              ? PremiumErrorState(
                  title: 'Dashboard unavailable',
                  subtitle:
                      'The admin dashboard could not load right now. Try refreshing the panel.',
                  buttonText: 'Retry',
                  onRetry: _loadDashboard,
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: _buildOverviewHero(colors, tokens),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: tokens.glassGradient,
                        color: tokens.panel.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: tokens.outlineStrong),
                      ),
                      child: TabBar(
                        controller: _tabCtrl,
                        tabs: const [
                          Tab(icon: Icon(Icons.people_outline), text: 'Users'),
                          Tab(
                              icon: Icon(Icons.warning_rounded),
                              text: 'Moderation'),
                          Tab(
                              icon: Icon(Icons.analytics_outlined),
                              text: 'Analytics'),
                          Tab(
                              icon: Icon(Icons.settings_outlined),
                              text: 'Settings'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: TabBarView(
                        controller: _tabCtrl,
                        children: [
                          ListView(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            children: [
                              _buildCard(
                                title: '👥 User Management',
                                children: [
                                  _buildStatRow('Total Users',
                                      '${_systemHealth['totalUsers'] ?? 0}'),
                                  _buildStatRow('Active Users (30d)',
                                      '${_systemHealth['activeUsers30d'] ?? 0}'),
                                  _buildStatRow('New Users (7d)',
                                      '${_systemHealth['newUsers7d'] ?? 0}'),
                                  const SizedBox(height: 16),
                                  _buildActionButton(
                                      'View All Users', Icons.people_outline,
                                      () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text('Loading users...',
                                              style: GoogleFonts.outfit())),
                                    );
                                  }),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildCard(
                                title: '🔒 Account Controls',
                                children: [
                                  _buildActionButton('Suspend User',
                                      Icons.person_remove_outlined, () {}),
                                  const SizedBox(height: 8),
                                  _buildActionButton(
                                      'Ban User', Icons.block_outlined, () {}),
                                  const SizedBox(height: 8),
                                  _buildActionButton('Restore Access',
                                      Icons.person_add_outlined, () {}),
                                ],
                              ),
                            ],
                          ),
                          ListView(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            children: [
                              _buildCard(
                                title: '⚠️ Reports Queue',
                                children: [
                                  _buildStatRow('Pending Reports',
                                      '${_systemHealth['pendingReports'] ?? 0}'),
                                  _buildStatRow('Urgent (24h)',
                                      '${_systemHealth['urgentReports'] ?? 0}'),
                                  const SizedBox(height: 16),
                                  _buildActionButton(
                                      'Review Reports', Icons.inbox_outlined,
                                      () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Loading report queue...',
                                              style: GoogleFonts.outfit())),
                                    );
                                  }),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildCard(
                                title: '🚫 Warning System',
                                children: [
                                  _buildStatRow('Total Warnings',
                                      '${_systemHealth['totalWarnings'] ?? 0}'),
                                  _buildStatRow('Auto-Suspended (3 strikes)',
                                      '${_systemHealth['autoSuspended'] ?? 0}'),
                                  const SizedBox(height: 16),
                                  _buildActionButton('Issue Warning',
                                      Icons.warning_rounded, () {}),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildCard(
                                title: '🗑️ Content Moderation',
                                children: [
                                  _buildStatRow('Flagged Content',
                                      '${_systemHealth['flaggedContent'] ?? 0}'),
                                  _buildStatRow('Removed Today',
                                      '${_systemHealth['removedToday'] ?? 0}'),
                                  const SizedBox(height: 16),
                                  _buildActionButton('Remove Content',
                                      Icons.delete_outline, () {}),
                                ],
                              ),
                            ],
                          ),
                          ListView(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            children: [
                              _buildCard(
                                title: '📊 Today\'s Analytics',
                                children: [
                                  _buildStatRow('New Users',
                                      '${_systemHealth['newUsersToday'] ?? 0}'),
                                  _buildStatRow('Messages Sent',
                                      '${_systemHealth['messagesToday'] ?? 0}'),
                                  _buildStatRow('Active Users',
                                      '${_systemHealth['activeToday'] ?? 0}'),
                                  _buildStatRow('Avg Session (min)',
                                      '${_systemHealth['avgSessionMinutes'] ?? 0}'),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildCard(
                                title: '📈 Weekly Trends',
                                children: [
                                  _buildStatRow('Week-over-Week Growth',
                                      '+${_systemHealth['weeklyGrowth'] ?? 0}%'),
                                  _buildStatRow('Message Growth',
                                      '+${_systemHealth['messageGrowth'] ?? 0}%'),
                                  _buildStatRow('Engagement Rate',
                                      '${_systemHealth['engagementRate'] ?? 0}%'),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildCard(
                                title: '🎯 System Status',
                                children: [
                                  _buildStatusRow(
                                      'Database',
                                      _systemHealth['databaseStatus'] ?? 'OK',
                                      Colors.green),
                                  _buildStatusRow(
                                      'API',
                                      _systemHealth['apiStatus'] ?? 'OK',
                                      Colors.green),
                                  _buildStatusRow(
                                      'Cache',
                                      _systemHealth['cacheStatus'] ?? 'OK',
                                      Colors.green),
                                ],
                              ),
                            ],
                          ),
                          ListView(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            children: [
                              _buildCard(
                                title: '⚙️ System Settings',
                                children: [
                                  _buildToggleOption(
                                    'Maintenance Mode',
                                    _maintenanceMode,
                                    (val) {
                                      setState(() => _maintenanceMode = val);
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  _buildToggleOption(
                                    'Strict Content Filter',
                                    true,
                                    (val) {},
                                  ),
                                  const SizedBox(height: 12),
                                  _buildToggleOption(
                                    'Email Notifications',
                                    true,
                                    (val) {},
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildCard(
                                title: '🔑 Feature Flags',
                                children: [
                                  _buildFeatureFlagRow(
                                      'Premium Features', true),
                                  _buildFeatureFlagRow('Beta Features', false),
                                  _buildFeatureFlagRow('New Dashboard', true),
                                  const SizedBox(height: 16),
                                  _buildActionButton('Manage Flags',
                                      Icons.flag_outlined, () {}),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildCard(
                                title: '📋 Audit Log',
                                children: [
                                  Builder(
                                    builder: (context) {
                                      final tokens = context.appTokens;
                                      return Text(
                                        'Recent admin actions logged and tracked',
                                        style: GoogleFonts.outfit(
                                            color: tokens.textMuted),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  _buildActionButton('View Audit Log',
                                      Icons.history_rounded, () {}),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tokens = context.appTokens;
    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              color: colors.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Divider(color: tokens.outline, height: 1),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    final theme = Theme.of(context);
    final tokens = context.appTokens;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.outfit(color: tokens.textMuted, fontSize: 13)),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String status, Color color) {
    final tokens = context.appTokens;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.outfit(color: tokens.textMuted, fontSize: 13)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: GoogleFonts.outfit(
                  color: color, fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap) {
    final theme = Theme.of(context);
    final tokens = context.appTokens;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.16),
              theme.colorScheme.tertiary.withValues(alpha: 0.10),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.22)),
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: tokens.textMuted, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleOption(
      String label, bool value, Function(bool) onChanged) {
    final theme = Theme.of(context);
    final tokens = context.appTokens;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.outfit(
                color: theme.colorScheme.onSurface, fontSize: 13)),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: value ? theme.colorScheme.primary : tokens.textSoft,
        ),
      ],
    );
  }

  Widget _buildFeatureFlagRow(String feature, bool enabled) {
    final tokens = context.appTokens;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(feature,
              style: GoogleFonts.outfit(color: tokens.textMuted, fontSize: 13)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (enabled ? Colors.greenAccent : Colors.red)
                  .withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              enabled ? 'ON' : 'OFF',
              style: GoogleFonts.outfit(
                color: enabled ? Colors.greenAccent : Colors.red,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewHero(ColorScheme colors, AppDesignTokens tokens) {
    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(18),
      glow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colors.primary.withValues(alpha: 0.28),
                      colors.tertiary.withValues(alpha: 0.12),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: colors.primary.withValues(alpha: 0.26)),
                ),
                child:
                    Icon(Icons.space_dashboard_rounded, color: colors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Operations Overview',
                      style: GoogleFonts.outfit(
                        color: colors.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Monitor health, manage people, and ship admin actions without leaving this surface.',
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
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Users',
                  value: '${_systemHealth['totalUsers'] ?? 0}',
                  icon: Icons.people_outline_rounded,
                  color: colors.primary,
                ),
              ),
              Expanded(
                child: StatCard(
                  title: 'Reports',
                  value: '${_systemHealth['pendingReports'] ?? 0}',
                  icon: Icons.warning_amber_rounded,
                  color: Colors.orangeAccent,
                ),
              ),
              Expanded(
                child: StatCard(
                  title: 'Health',
                  value: (_systemHealth['status'] ?? 'ok')
                      .toString()
                      .toUpperCase(),
                  icon: Icons.health_and_safety_rounded,
                  color: Colors.greenAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
