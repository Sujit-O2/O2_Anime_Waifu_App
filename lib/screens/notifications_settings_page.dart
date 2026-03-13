import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsSettingsPage extends StatefulWidget {
  const NotificationsSettingsPage({super.key});
  @override
  State<NotificationsSettingsPage> createState() =>
      _NotificationsSettingsPageState();
}

class _NotifItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  bool enabled;
  _NotifItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.enabled,
  });
}

class _NotificationsSettingsPageState extends State<NotificationsSettingsPage> {
  bool _loading = true;
  bool _saving = false;

  late List<_NotifItem> _items;

  @override
  void initState() {
    super.initState();
    _items = [
      _NotifItem(
          title: '🌸 Daily Love Letter',
          subtitle: 'Zero Two sends you a love letter every morning at 8 AM',
          icon: Icons.mail_outline_rounded,
          color: Colors.pinkAccent,
          enabled: true),
      _NotifItem(
          title: '🔥 Streak Reminder',
          subtitle: 'Reminder to check in and keep your streak going',
          icon: Icons.local_fire_department_outlined,
          color: Colors.orangeAccent,
          enabled: true),
      _NotifItem(
          title: '💖 Affection Milestones',
          subtitle: 'Alert when you reach XP milestones (100, 500, 1000...)',
          icon: Icons.favorite_outline_rounded,
          color: Colors.pinkAccent,
          enabled: true),
      _NotifItem(
          title: '🎉 Anniversary Alert',
          subtitle: 'Celebrate your monthly/yearly anniversaries with Zero Two',
          icon: Icons.cake_outlined,
          color: Colors.purpleAccent,
          enabled: true),
      _NotifItem(
          title: '📅 Daily Quest Reminder',
          subtitle: 'Reminder to complete your daily quests',
          icon: Icons.checklist_outlined,
          color: Colors.cyanAccent,
          enabled: true),
      _NotifItem(
          title: '⏰ Scheduled Messages',
          subtitle: 'Receive Zero Two\'s scheduled messages on time',
          icon: Icons.schedule_outlined,
          color: Colors.tealAccent,
          enabled: true),
      _NotifItem(
          title: '🌙 Sleep Reminder',
          subtitle: 'Zero Two reminds you to sleep at your set bedtime',
          icon: Icons.bedtime_outlined,
          color: Colors.deepPurpleAccent,
          enabled: false),
      _NotifItem(
          title: '☀️ Good Morning',
          subtitle: 'Wake up to Zero Two\'s good morning message',
          icon: Icons.wb_sunny_outlined,
          color: Colors.amberAccent,
          enabled: true),
    ];
    _load();
  }

  Future<void> _load() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final snap = await FirebaseFirestore.instance
          .collection('notification_settings')
          .doc(user.uid)
          .get();
      if (snap.exists) {
        final data = snap.data()!;
        for (final item in _items) {
          if (data.containsKey(item.title)) {
            item.enabled = data[item.title] as bool? ?? item.enabled;
          }
        }
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _saving = true);
    try {
      final Map<String, dynamic> prefs = {
        for (final item in _items) item.title: item.enabled
      };
      prefs['updatedAt'] = FieldValue.serverTimestamp();
      await FirebaseFirestore.instance
          .collection('notification_settings')
          .doc(user.uid)
          .set(prefs, SetOptions(merge: true));
      _snack('Notification settings saved! 🌸');
    } catch (e) {
      _snack('Failed to save: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.outfit()),
      backgroundColor: Colors.pinkAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A16),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('NOTIFICATIONS',
            style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.pinkAccent))
                : Text('Save',
                    style: GoogleFonts.outfit(
                        color: Colors.pinkAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.pinkAccent))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Choose which notifications you want from Zero Two 🌸',
                    style:
                        GoogleFonts.outfit(color: Colors.white38, fontSize: 13),
                  ),
                ),
                ..._items.map((item) => _notifTile(item)),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.pinkAccent.withValues(alpha: 0.07),
                    border: Border.all(
                        color: Colors.pinkAccent.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    '💡 Notifications are powered by Firebase Cloud Messaging. Make sure to allow notifications in your phone settings for the best experience.',
                    style: GoogleFonts.outfit(
                        color: Colors.white54, fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _notifTile(_NotifItem item) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: item.enabled
              ? item.color.withValues(alpha: 0.05)
              : Colors.white.withValues(alpha: 0.03),
          border: Border.all(
              color: item.enabled
                  ? item.color.withValues(alpha: 0.25)
                  : Colors.white.withValues(alpha: 0.07)),
        ),
        child: SwitchListTile(
          secondary: Icon(item.icon,
              color: item.enabled ? item.color : Colors.white24),
          title: Text(item.title,
              style: GoogleFonts.outfit(
                  color: item.enabled ? Colors.white : Colors.white38,
                  fontSize: 13,
                  fontWeight:
                      item.enabled ? FontWeight.bold : FontWeight.normal)),
          subtitle: Text(item.subtitle,
              style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11),
              maxLines: 2),
          value: item.enabled,
          activeColor: item.color,
          inactiveTrackColor: Colors.white12,
          onChanged: (v) => setState(() => item.enabled = v),
        ),
      );
}
