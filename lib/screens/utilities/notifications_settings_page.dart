import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:anime_waifu/core/v2_upgrade_kit.dart';

class NotificationsSettingsPage extends StatefulWidget {
  const NotificationsSettingsPage({super.key});

  @override
  State<NotificationsSettingsPage> createState() =>
      _NotificationsSettingsPageState();
}

class _NotifItem {
  _NotifItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.enabled,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  bool enabled;
}

class _NotificationsSettingsPageState extends State<NotificationsSettingsPage> {
  bool _loading = true;
  bool _saving = false;

  late final List<_NotifItem> _items;

  int get _enabledCount =>
      _items.where((_NotifItem item) => item.enabled).length;

  String get _commentaryMood {
    if (_enabledCount >= 6) {
      return 'achievement';
    }
    if (_enabledCount >= 3) {
      return 'motivated';
    }
    return 'neutral';
  }

  @override
  void initState() {
    super.initState();
    _items = <_NotifItem>[
      _NotifItem(
        title: '🌸 Daily Love Letter',
        subtitle: 'Zero Two sends you a soft love letter every morning.',
        icon: Icons.mail_outline_rounded,
        color: Colors.pinkAccent,
        enabled: true,
      ),
      _NotifItem(
        title: '🔥 Streak Reminder',
        subtitle: 'Get nudged to keep your streak alive.',
        icon: Icons.local_fire_department_outlined,
        color: Colors.orangeAccent,
        enabled: true,
      ),
      _NotifItem(
        title: '💖 Affection Milestones',
        subtitle: 'Celebrate XP milestones and relationship progress.',
        icon: Icons.favorite_outline_rounded,
        color: Colors.pinkAccent,
        enabled: true,
      ),
      _NotifItem(
        title: '🎉 Anniversary Alert',
        subtitle: 'Monthly and yearly anniversary reminders.',
        icon: Icons.cake_outlined,
        color: Colors.purpleAccent,
        enabled: true,
      ),
      _NotifItem(
        title: '📝 Daily Quest Reminder',
        subtitle: 'A reminder to finish daily quests and tasks.',
        icon: Icons.checklist_outlined,
        color: Colors.cyanAccent,
        enabled: true,
      ),
      _NotifItem(
        title: '⏰ Scheduled Messages',
        subtitle: 'Deliver scheduled Zero Two messages on time.',
        icon: Icons.schedule_outlined,
        color: Colors.tealAccent,
        enabled: true,
      ),
      _NotifItem(
        title: '🌙 Sleep Reminder',
        subtitle: 'Wind down at bedtime without losing your rhythm.',
        icon: Icons.bedtime_outlined,
        color: Colors.deepPurpleAccent,
        enabled: false,
      ),
      _NotifItem(
        title: '☀️ Good Morning',
        subtitle: 'Wake up to a morning message and soft reset.',
        icon: Icons.wb_sunny_outlined,
        color: Colors.amberAccent,
        enabled: true,
      ),
    ];
    _load();
  }

  Future<void> _load() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() => _loading = false);
      }
      return;
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>> snap =
          await FirebaseFirestore.instance
              .collection('notification_settings')
              .doc(user.uid)
              .get();
      if (snap.exists) {
        final Map<String, dynamic> data = snap.data()!;
        for (final _NotifItem item in _items) {
          if (data.containsKey(item.title)) {
            item.enabled = data[item.title] as bool? ?? item.enabled;
          }
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      showSuccessSnackbar(context, 'Sign in to sync notification settings.');
      return;
    }

    setState(() => _saving = true);
    HapticFeedback.mediumImpact();

    try {
      final Map<String, dynamic> prefs = <String, dynamic>{
        for (final _NotifItem item in _items) item.title: item.enabled,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await FirebaseFirestore.instance
          .collection('notification_settings')
          .doc(user.uid)
          .set(prefs, SetOptions(merge: true));
      if (mounted) {
        showSuccessSnackbar(context, 'Notification settings saved.');
      }
    } catch (error) {
      if (mounted) {
        showSuccessSnackbar(context, 'Save failed: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _refresh() async {
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: V2Theme.surfaceDark,
        body: Center(
          child: CircularProgressIndicator(color: V2Theme.primaryColor),
        ),
      );
    }

    return Scaffold(
      backgroundColor: V2Theme.surfaceDark,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: V2Theme.primaryColor,
          backgroundColor: V2Theme.surfaceLight,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white70,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NOTIFICATIONS',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          'Control your message stream',
                          style: GoogleFonts.outfit(
                            color: V2Theme.secondaryColor,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: V2Theme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AnimatedEntry(
                index: 0,
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
                              'Notification mission control',
                              style: GoogleFonts.outfit(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$_enabledCount of ${_items.length} channels enabled',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Choose which signals matter so the app feels thoughtful instead of noisy.',
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
                        progress: _enabledCount / _items.length,
                        foreground: V2Theme.primaryColor,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.notifications_active_rounded,
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
                              'Live',
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
                index: 1,
                child: WaifuCommentary(mood: _commentaryMood),
              ),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Enabled',
                      value: '$_enabledCount',
                      icon: Icons.toggle_on_rounded,
                      color: Colors.greenAccent,
                    ),
                  ),
                  Expanded(
                    child: StatCard(
                      title: 'Muted',
                      value: '${_items.length - _enabledCount}',
                      icon: Icons.notifications_off_rounded,
                      color: Colors.orangeAccent,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Expanded(
                    child: StatCard(
                      title: 'Sync',
                      value: 'Cloud',
                      icon: Icons.cloud_done_rounded,
                      color: V2Theme.secondaryColor,
                    ),
                  ),
                  Expanded(
                    child: StatCard(
                      title: 'Mode',
                      value: _enabledCount >= 6 ? 'Loud' : 'Balanced',
                      icon: Icons.tune_rounded,
                      color: V2Theme.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'NOTIFICATION CHANNELS',
                style: GoogleFonts.outfit(
                  color: Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 10),
              ..._items.map(_notifTile),
              const SizedBox(height: 12),
              GlassCard(
                margin: EdgeInsets.zero,
                child: Text(
                  'Notifications sync through Firebase, but your phone still needs system permission enabled for the full experience.',
                  style: GoogleFonts.outfit(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _notifTile(_NotifItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: item.enabled
            ? item.color.withValues(alpha: 0.07)
            : Colors.white.withValues(alpha: 0.03),
        border: Border.all(
          color: item.enabled
              ? item.color.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: SwitchListTile(
        secondary: Icon(
          item.icon,
          color: item.enabled ? item.color : Colors.white24,
        ),
        title: Text(
          item.title,
          style: GoogleFonts.outfit(
            color: item.enabled ? Colors.white : Colors.white54,
            fontSize: 13,
            fontWeight: item.enabled ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        subtitle: Text(
          item.subtitle,
          style: GoogleFonts.outfit(
            color: Colors.white38,
            fontSize: 11,
          ),
        ),
        value: item.enabled,
        activeColor: item.color,
        inactiveTrackColor: Colors.white12,
        onChanged: (bool value) {
          HapticFeedback.selectionClick();
          if (!mounted) return;
          setState(() => item.enabled = value);
        },
      ),
    );
  }
}



