import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:anime_waifu/services/user_profile/affection_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CloudSyncPage extends StatefulWidget {
  const CloudSyncPage({super.key});

  @override
  State<CloudSyncPage> createState() => _CloudSyncPageState();
}

class _CloudSyncPageState extends State<CloudSyncPage> {
  bool _syncing = false;
  bool _restoring = false;
  DateTime? _lastSync;
  final Map<String, bool> _syncItems = <String, bool>{
    'Dream Journal': true,
    'Notes Pad': true,
    'Habit Tracker': true,
    'Goal Tracker': true,
    'Bucket List': true,
    'Budget Tracker': true,
    'XP & Affection Points': true,
  };

  @override
  void initState() {
    super.initState();
    _loadLastSync();
  }

  Future<void> _loadLastSync() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getString('last_cloud_sync');
    if (mounted) {
      setState(() => _lastSync = ts == null ? null : DateTime.tryParse(ts));
    }
  }

  Future<void> _syncToCloud() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _snack('Please log in first.');
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _syncing = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final syncData = <String, dynamic>{};

      if (_syncItems['Dream Journal'] == true) {
        final raw = prefs.getString('dream_journal');
        if (raw != null) {
          syncData['dream_journal'] = raw;
        }
      }
      if (_syncItems['Notes Pad'] == true) {
        final raw = prefs.getString('notes_pad');
        if (raw != null) {
          syncData['notes_pad'] = raw;
        }
      }
      if (_syncItems['Habit Tracker'] == true) {
        final raw = prefs.getString('habit_tracker');
        if (raw != null) {
          syncData['habit_tracker'] = raw;
        }
      }
      if (_syncItems['Goal Tracker'] == true) {
        final raw = prefs.getString('goal_tracker');
        if (raw != null) {
          syncData['goal_tracker'] = raw;
        }
      }
      if (_syncItems['Bucket List'] == true) {
        final raw = prefs.getString('bucket_list');
        if (raw != null) {
          syncData['bucket_list'] = raw;
        }
      }
      if (_syncItems['Budget Tracker'] == true) {
        final raw = prefs.getString('budget_data');
        if (raw != null) {
          syncData['budget_data'] = raw;
        }
      }
      if (_syncItems['XP & Affection Points'] == true) {
        final affection = AffectionService.instance;
        syncData['affection_points'] = affection.points;
        syncData['streak_days'] = affection.streakDays;
      }

      syncData['syncedAt'] = DateTime.now().toIso8601String();
      syncData['deviceInfo'] = 'Android Flutter App';

      await FirebaseFirestore.instance
          .collection('user_data_sync')
          .doc(user.uid)
          .set(syncData, SetOptions(merge: true));

      final now = DateTime.now();
      await prefs.setString('last_cloud_sync', now.toIso8601String());
      if (mounted) {
        setState(() => _lastSync = now);
        showSuccessSnackbar(context, 'All selected data synced to the cloud.');
      }
    } catch (error) {
      _snack('Sync failed: $error');
    } finally {
      if (mounted) {
        setState(() => _syncing = false);
      }
    }
  }

  Future<void> _restoreFromCloud() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _snack('Please log in first.');
      return;
    }

    final confirmed = await _showConfirmDialog();
    if (!confirmed) {
      return;
    }

    HapticFeedback.mediumImpact();
    if (!mounted) return;
    setState(() => _restoring = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('user_data_sync')
          .doc(user.uid)
          .get();
      if (!snap.exists) {
        _snack('No cloud backup found.');
        return;
      }

      final data = snap.data()!;
      final prefs = await SharedPreferences.getInstance();

      if (data['dream_journal'] != null) {
        await prefs.setString(
            'dream_journal', data['dream_journal'].toString());
      }
      if (data['notes_pad'] != null) {
        await prefs.setString('notes_pad', data['notes_pad'].toString());
      }
      if (data['habit_tracker'] != null) {
        await prefs.setString(
            'habit_tracker', data['habit_tracker'].toString());
      }
      if (data['goal_tracker'] != null) {
        await prefs.setString('goal_tracker', data['goal_tracker'].toString());
      }
      if (data['bucket_list'] != null) {
        await prefs.setString('bucket_list', data['bucket_list'].toString());
      }
      if (data['budget_data'] != null) {
        await prefs.setString('budget_data', data['budget_data'].toString());
      }

      final synced = data['syncedAt'] as String?;
      if (mounted) {
        showSuccessSnackbar(
          context,
          'Backup restored from ${synced?.split('T').first ?? 'the cloud'}.',
        );
      }
    } catch (error) {
      _snack('Restore failed: $error');
    } finally {
      if (mounted) {
        setState(() => _restoring = false);
      }
    }
  }

  Future<void> _refresh() => _loadLastSync();

  Future<bool> _showConfirmDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (_) {
            return AlertDialog(
              backgroundColor: V2Theme.surfaceLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                'Restore from cloud?',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: Text(
                'This will overwrite local data for the selected modules with the cloud backup.',
                style: GoogleFonts.outfit(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: V2Theme.primaryColor,
                  ),
                  child: const Text('Restore'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void _snack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, style: GoogleFonts.outfit()),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  int get _enabledCount => _syncItems.values.where((value) => value).length;

  String get _commentaryMood {
    if (_lastSync != null && _enabledCount >= 5) {
      return 'achievement';
    }
    if (_enabledCount <= 2) {
      return 'neutral';
    }
    return 'motivated';
  }

  String get _lastSyncLabel {
    final lastSync = _lastSync;
    if (lastSync == null) {
      return 'Never';
    }
    return '${lastSync.day}/${lastSync.month}/${lastSync.year} ${lastSync.hour}:${lastSync.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return FeaturePageV2(
      title: 'CLOUD SYNC',
      onBack: () => Navigator.pop(context),
      content: RefreshIndicator(
        onRefresh: _refresh,
        color: V2Theme.primaryColor,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
                AnimatedEntry(
                  index: 1,
                  child: GlassCard(
                    margin: EdgeInsets.zero,
                    glow: true,
                    child: Row(
                      children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sync status',
                              style: GoogleFonts.outfit(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              user?.email ?? 'Not logged in',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Last sync: $_lastSyncLabel. $_enabledCount modules selected for backup.',
                              style: GoogleFonts.outfit(
                                color: Colors.white60,
                                fontSize: 12,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      ProgressRing(
                        progress: _enabledCount / _syncItems.length,
                        foreground: V2Theme.primaryColor,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.cloud_done_rounded,
                              color: V2Theme.primaryColor,
                              size: 28,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$_enabledCount',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Selected',
                              style: GoogleFonts.outfit(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              AnimatedEntry(
                  index: 2,
                  child: WaifuCommentary(mood: _commentaryMood),
                ),
                const SizedBox(height: 12),
                AnimatedEntry(
                  index: 3,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              title: 'Modules',
                              value: '$_enabledCount',
                              icon: Icons.widgets_outlined,
                              color: V2Theme.primaryColor,
                            ),
                          ),
                          Expanded(
                            child: StatCard(
                              title: 'Last Sync',
                              value: _lastSync == null ? 'Never' : 'Ready',
                              icon: Icons.schedule_rounded,
                              color: V2Theme.secondaryColor,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              title: 'Upload',
                              value: _syncing ? 'Live' : 'Idle',
                              icon: Icons.cloud_upload_outlined,
                              color: Colors.amberAccent,
                            ),
                          ),
                          Expanded(
                            child: StatCard(
                              title: 'Restore',
                              value: _restoring ? 'Live' : 'Idle',
                              icon: Icons.cloud_download_outlined,
                              color: Colors.lightGreenAccent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AnimatedEntry(
                  index: 4,
                  child: GlassCard(
                    margin: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'What to sync',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Pick the modules you want included in cloud backups.',
                          style: GoogleFonts.outfit(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._syncItems.entries.map(
                          (entry) => _toggleRow(entry.key, entry.value),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                AnimatedEntry(
                  index: 5,
                  child: Row(
                    children: [
                      Expanded(
                        child: _actionButton(
                          label: _syncing ? 'Syncing...' : 'Sync to Cloud',
                          icon: Icons.cloud_upload_rounded,
                          color: V2Theme.primaryColor,
                          loading: _syncing,
                          onTap: _syncing ? null : _syncToCloud,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _actionButton(
                          label: _restoring ? 'Restoring...' : 'Restore Backup',
                          icon: Icons.cloud_download_rounded,
                          color: Colors.deepPurpleAccent,
                          loading: _restoring,
                          onTap: _restoring ? null : _restoreFromCloud,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AnimatedEntry(
                  index: 6,
                  child: GlassCard(
                    margin: EdgeInsets.zero,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.lightGreenAccent.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.lock_rounded,
                            color: Colors.lightGreenAccent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Your synced data is encrypted in transit and associated with your signed-in account.',
                            style: GoogleFonts.outfit(
                              color: Colors.white70,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (user == null) const SizedBox(height: 12),
                if (user == null)
                  const AnimatedEntry(
                    index: 7,
                    child: EmptyState(
                      icon: Icons.cloud_off_outlined,
                      title: 'Sign in to use cloud sync',
                      subtitle:
                          'Connect an account first, then come back here to back up and restore your data.',
                    ),
                  ),
              ],
            ),
          ),
    );
  }

  Widget _toggleRow(String label, bool value) {
    final icons = <String, IconData>{
      'Dream Journal': Icons.nightlight_round,
      'Notes Pad': Icons.note_alt_outlined,
      'Habit Tracker': Icons.check_circle_outline,
      'Goal Tracker': Icons.flag_outlined,
      'Bucket List': Icons.list_alt_outlined,
      'Budget Tracker': Icons.account_balance_wallet_outlined,
      'XP & Affection Points': Icons.favorite_outline,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: SwitchListTile(
        secondary: Icon(
          icons[label] ?? Icons.cloud_outlined,
          color: value ? V2Theme.primaryColor : Colors.white54,
          size: 20,
        ),
        title: Text(
          label,
          style: GoogleFonts.outfit(
            color: Colors.white70,
            fontSize: 13,
          ),
        ),
        value: value,
        activeColor: Colors.white,
        activeTrackColor: V2Theme.primaryColor,
        inactiveTrackColor: Colors.white12,
        onChanged: (nextValue) {
          HapticFeedback.selectionClick();
          setState(() => _syncItems[label] = nextValue);
        },
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
    bool loading = false,
  }) {
    return SizedBox(
      height: 54,
      child: FilledButton.icon(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(icon),
        label: Text(
          label,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}



