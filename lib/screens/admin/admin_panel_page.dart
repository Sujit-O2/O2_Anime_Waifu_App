import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:anime_waifu/widgets/waifu_background.dart';

/// Admin Dashboard Panel - Moderation, User Management, Analytics
class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({super.key});

  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage> with TickerProviderStateMixin {
  late TabController _tabCtrl;
  // final AdminDashboardService _admin = AdminDashboardService();
  Map<String, dynamic> _systemHealth = {};
  bool _maintenanceMode = false;
  bool _loading = true;

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
        });
      }
    } catch (e) {
      debugPrint('Error loading dashboard: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Admin Dashboard',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w900, letterSpacing: 1.5),
        ),
        elevation: 0,
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(icon: Icon(Icons.people_outline), text: 'Users'),
            Tab(icon: Icon(Icons.warning_rounded), text: 'Moderation'),
            Tab(icon: Icon(Icons.analytics_outlined), text: 'Analytics'),
            Tab(icon: Icon(Icons.settings_outlined), text: 'Settings'),
          ],
        ),
      ),
      body: WaifuBackground(
        opacity: 0.12,
        child: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
            controller: _tabCtrl,
            children: [
              // ===== USERS TAB =====
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildCard(
                    title: '👥 User Management',
                    children: [
                      _buildStatRow('Total Users', '${_systemHealth['totalUsers'] ?? 0}'),
                      _buildStatRow('Active Users (30d)', '${_systemHealth['activeUsers30d'] ?? 0}'),
                      _buildStatRow('New Users (7d)', '${_systemHealth['newUsers7d'] ?? 0}'),
                      const SizedBox(height: 16),
                      _buildActionButton('View All Users', Icons.people_outline, () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Loading users...', style: GoogleFonts.outfit())),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildCard(
                    title: '🔒 Account Controls',
                    children: [
                      _buildActionButton('Suspend User', Icons.person_remove_outlined, () {}),
                      const SizedBox(height: 8),
                      _buildActionButton('Ban User', Icons.block_outlined, () {}),
                      const SizedBox(height: 8),
                      _buildActionButton('Restore Access', Icons.person_add_outlined, () {}),
                    ],
                  ),
                ],
              ),

              // ===== MODERATION TAB =====
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildCard(
                    title: '⚠️ Reports Queue',
                    children: [
                      _buildStatRow('Pending Reports', '${_systemHealth['pendingReports'] ?? 0}'),
                      _buildStatRow('Urgent (24h)', '${_systemHealth['urgentReports'] ?? 0}'),
                      const SizedBox(height: 16),
                      _buildActionButton('Review Reports', Icons.inbox_outlined, () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Loading report queue...', style: GoogleFonts.outfit())),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildCard(
                    title: '🚫 Warning System',
                    children: [
                      _buildStatRow('Total Warnings', '${_systemHealth['totalWarnings'] ?? 0}'),
                      _buildStatRow('Auto-Suspended (3 strikes)', '${_systemHealth['autoSuspended'] ?? 0}'),
                      const SizedBox(height: 16),
                      _buildActionButton('Issue Warning', Icons.warning_rounded, () {}),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildCard(
                    title: '🗑️ Content Moderation',
                    children: [
                      _buildStatRow('Flagged Content', '${_systemHealth['flaggedContent'] ?? 0}'),
                      _buildStatRow('Removed Today', '${_systemHealth['removedToday'] ?? 0}'),
                      const SizedBox(height: 16),
                      _buildActionButton('Remove Content', Icons.delete_outline, () {}),
                    ],
                  ),
                ],
              ),

              // ===== ANALYTICS TAB =====
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildCard(
                    title: '📊 Today\'s Analytics',
                    children: [
                      _buildStatRow('New Users', '${_systemHealth['newUsersToday'] ?? 0}'),
                      _buildStatRow('Messages Sent', '${_systemHealth['messagesToday'] ?? 0}'),
                      _buildStatRow('Active Users', '${_systemHealth['activeToday'] ?? 0}'),
                      _buildStatRow('Avg Session (min)', '${_systemHealth['avgSessionMinutes'] ?? 0}'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildCard(
                    title: '📈 Weekly Trends',
                    children: [
                      _buildStatRow('Week-over-Week Growth', '+${_systemHealth['weeklyGrowth'] ?? 0}%'),
                      _buildStatRow('Message Growth', '+${_systemHealth['messageGrowth'] ?? 0}%'),
                      _buildStatRow('Engagement Rate', '${_systemHealth['engagementRate'] ?? 0}%'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildCard(
                    title: '🎯 System Status',
                    children: [
                      _buildStatusRow('Database', _systemHealth['databaseStatus'] ?? 'OK', Colors.green),
                      _buildStatusRow('API', _systemHealth['apiStatus'] ?? 'OK', Colors.green),
                      _buildStatusRow('Cache', _systemHealth['cacheStatus'] ?? 'OK', Colors.green),
                    ],
                  ),
                ],
              ),

              // ===== SETTINGS TAB =====
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildCard(
                    title: '⚙️ System Settings',
                    children: [
                      _buildToggleOption(
                        'Maintenance Mode',
                        _maintenanceMode,
                        (val) {
                          setState(() => _maintenanceMode = val);
                          // Feature flag toggle (if method available)
                          // _admin.setMaintenanceMode(val, 'Admin toggle');
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
                      _buildFeatureFlagRow('Premium Features', true),
                      _buildFeatureFlagRow('Beta Features', false),
                      _buildFeatureFlagRow('New Dashboard', true),
                      const SizedBox(height: 16),
                      _buildActionButton('Manage Flags', Icons.flag_outlined, () {}),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildCard(
                    title: '📋 Audit Log',
                    children: [
                      Text('Recent admin actions logged and tracked',
                        style: GoogleFonts.outfit(color: Colors.white54),
                      ),
                      const SizedBox(height: 16),
                      _buildActionButton('View Audit Log', Icons.history_rounded, () {}),
                    ],
                  ),
                ],
              ),
            ],
          ),
      ),
    );
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
          Text(value,
            style: GoogleFonts.outfit(
              color: Colors.pinkAccent,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(status,
              style: GoogleFonts.outfit(color: color, fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.pinkAccent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.cyanAccent, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.cyanAccent, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleOption(String label, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.cyanAccent,
        ),
      ],
    );
  }

  Widget _buildFeatureFlagRow(String feature, bool enabled) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(feature, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (enabled ? Colors.greenAccent : Colors.red).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(enabled ? 'ON' : 'OFF',
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
}



