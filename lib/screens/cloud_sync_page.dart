import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/affection_service.dart';
import '../widgets/waifu_background.dart';

class CloudSyncPage extends StatefulWidget {
  const CloudSyncPage({super.key});
  @override
  State<CloudSyncPage> createState() => _CloudSyncPageState();
}

class _CloudSyncPageState extends State<CloudSyncPage> {
  bool _syncing = false;
  bool _restoring = false;
  DateTime? _lastSync;
  final Map<String, bool> _syncItems = {
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
    if (ts != null) {
      setState(() => _lastSync = DateTime.tryParse(ts));
    }
  }

  Future<void> _syncToCloud() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _snack('Please log in first!');
      return;
    }
    setState(() => _syncing = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> syncData = {};

      if (_syncItems['Dream Journal'] == true) {
        final raw = prefs.getString('dream_journal');
        if (raw != null) syncData['dream_journal'] = raw;
      }
      if (_syncItems['Notes Pad'] == true) {
        final raw = prefs.getString('notes_pad');
        if (raw != null) syncData['notes_pad'] = raw;
      }
      if (_syncItems['Habit Tracker'] == true) {
        final raw = prefs.getString('habit_tracker');
        if (raw != null) syncData['habit_tracker'] = raw;
      }
      if (_syncItems['Goal Tracker'] == true) {
        final raw = prefs.getString('goal_tracker');
        if (raw != null) syncData['goal_tracker'] = raw;
      }
      if (_syncItems['Bucket List'] == true) {
        final raw = prefs.getString('bucket_list');
        if (raw != null) syncData['bucket_list'] = raw;
      }
      if (_syncItems['Budget Tracker'] == true) {
        final raw = prefs.getString('budget_data');
        if (raw != null) syncData['budget_data'] = raw;
      }
      if (_syncItems['XP & Affection Points'] == true) {
        final aff = AffectionService.instance;
        syncData['affection_points'] = aff.points;
        syncData['streak_days'] = aff.streakDays;
      }

      syncData['syncedAt'] = DateTime.now().toIso8601String();
      syncData['deviceInfo'] = 'Android Flutter App';

      await FirebaseFirestore.instance
          .collection('user_data_sync')
          .doc(user.uid)
          .set(syncData, SetOptions(merge: true));

      final now = DateTime.now();
      await prefs.setString('last_cloud_sync', now.toIso8601String());
      setState(() => _lastSync = now);
      _snack('✅ All data synced to cloud!');
    } catch (e) {
      _snack('Sync failed: $e');
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _restoreFromCloud() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _snack('Please log in first!');
      return;
    }
    final confirmed = await _showConfirmDialog();
    if (!confirmed) return;

    setState(() => _restoring = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('user_data_sync')
          .doc(user.uid)
          .get();
      if (!snap.exists) {
        _snack('No cloud backup found!');
        return;
      }
      final data = snap.data()!;
      final prefs = await SharedPreferences.getInstance();

      if (data['dream_journal'] != null) {
        await prefs.setString('dream_journal', data['dream_journal'] as String);
      }
      if (data['notes_pad'] != null) {
        await prefs.setString('notes_pad', data['notes_pad'] as String);
      }
      if (data['habit_tracker'] != null) {
        await prefs.setString('habit_tracker', data['habit_tracker'] as String);
      }
      if (data['goal_tracker'] != null) {
        await prefs.setString('goal_tracker', data['goal_tracker'] as String);
      }
      if (data['bucket_list'] != null) {
        await prefs.setString('bucket_list', data['bucket_list'] as String);
      }
      if (data['budget_data'] != null) {
        await prefs.setString('budget_data', data['budget_data'] as String);
      }

      final synced = data['syncedAt'] as String?;
      _snack('✅ Data restored from ${synced?.substring(0, 10) ?? 'cloud'}!');
    } catch (e) {
      _snack('Restore failed: $e');
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  Future<bool> _showConfirmDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A2E),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Restore from Cloud?',
                style: GoogleFonts.outfit(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            content: Text(
                'This will overwrite your local data with the cloud backup. Continue?',
                style: GoogleFonts.outfit(color: Colors.white60)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Cancel',
                      style: GoogleFonts.outfit(color: Colors.white38))),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text('Restore',
                      style: GoogleFonts.outfit(
                          color: Colors.pinkAccent,
                          fontWeight: FontWeight.bold))),
            ],
          ),
        ) ??
        false;
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.outfit()),
      backgroundColor: Colors.pinkAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A16),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('CLOUD SYNC',
            style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5)),
        centerTitle: true,
      ),
      body: WaifuBackground(
        opacity: 0.08,
        tint: const Color(0xFF080E14),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Status card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A0A2E), Color(0xFF0A1A2E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border:
                    Border.all(color: Colors.pinkAccent.withValues(alpha: 0.3)),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.cloud_done_outlined,
                          color: Colors.pinkAccent),
                      const SizedBox(width: 8),
                      Text('Sync Status',
                          style: GoogleFonts.outfit(
                              color: Colors.pinkAccent,
                              fontWeight: FontWeight.bold)),
                    ]),
                    const SizedBox(height: 10),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Account',
                              style: GoogleFonts.outfit(
                                  color: Colors.white54, fontSize: 12)),
                          Text(user?.email ?? 'Not logged in',
                              style: GoogleFonts.outfit(
                                  color: Colors.white, fontSize: 12)),
                        ]),
                    const SizedBox(height: 6),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Last Sync',
                              style: GoogleFonts.outfit(
                                  color: Colors.white54, fontSize: 12)),
                          Text(
                            _lastSync != null
                                ? '${_lastSync!.day}/${_lastSync!.month}/${_lastSync!.year} ${_lastSync!.hour}:${_lastSync!.minute.toString().padLeft(2, '0')}'
                                : 'Never',
                            style: GoogleFonts.outfit(
                                color: Colors.white, fontSize: 12),
                          ),
                        ]),
                  ]),
            ),
            const SizedBox(height: 24),

            // What to sync
            Text('WHAT TO SYNC',
                style: GoogleFonts.outfit(
                    color: Colors.white38, fontSize: 11, letterSpacing: 2)),
            const SizedBox(height: 10),
            ..._syncItems.entries.map((e) => _toggleRow(e.key, e.value)),

            const SizedBox(height: 28),

            // Sync button
            _bigBtn(
              label: _syncing ? 'Syncing…' : '☁️ Sync to Cloud Now',
              color: Colors.pinkAccent,
              onTap: _syncing ? null : _syncToCloud,
              loading: _syncing,
            ),
            const SizedBox(height: 12),

            // Restore button
            _bigBtn(
              label: _restoring ? 'Restoring…' : '⬇️ Restore from Cloud',
              color: Colors.deepPurpleAccent,
              onTap: _restoring ? null : _restoreFromCloud,
              loading: _restoring,
            ),
            const SizedBox(height: 24),

            // Note
            Center(
              child: Text(
                '🔒 Your data is encrypted in transit and only accessible by you.',
                style: GoogleFonts.outfit(color: Colors.white24, fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ),
          ]),
        ),
      ), // WaifuBackground
    );
  }

  Widget _toggleRow(String label, bool val) {
    final icons = {
      'Dream Journal': Icons.nights_stay_outlined,
      'Notes Pad': Icons.note_alt_outlined,
      'Habit Tracker': Icons.check_circle_outline,
      'Goal Tracker': Icons.flag_outlined,
      'Bucket List': Icons.list_alt_outlined,
      'Budget Tracker': Icons.account_balance_wallet_outlined,
      'XP & Affection Points': Icons.favorite_outline,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: SwitchListTile(
        dense: true,
        secondary: Icon(icons[label] ?? Icons.cloud_outlined,
            color: Colors.pinkAccent, size: 20),
        title: Text(label,
            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
        value: val,
        activeColor: Colors.pinkAccent,
        inactiveTrackColor: Colors.white12,
        onChanged: (v) => setState(() => _syncItems[label] = v),
      ),
    );
  }

  Widget _bigBtn({
    required String label,
    required Color color,
    VoidCallback? onTap,
    bool loading = false,
  }) =>
      SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: color.withValues(alpha: 0.85),
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Text(label,
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold, fontSize: 15)),
        ),
      );
}
