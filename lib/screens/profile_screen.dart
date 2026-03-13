import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/affection_service.dart';
import '../services/achievements_service.dart';
import '../services/firestore_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic> _profile = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await FirestoreService().loadProfile();
    if (mounted) {
      setState(() {
        _profile = profile;
        _loading = false;
      });
    }
  }

  String _formatAnniversary(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return 'Since today 🌸';
    try {
      final d = DateTime.parse(isoDate);
      final diff = DateTime.now().difference(d).inDays;
      return '${d.day}/${d.month}/${d.year} ($diff days together)';
    } catch (_) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final affection = AffectionService.instance;
    final achievements = AchievementsService.instance;

    final displayName = _profile['displayName'] as String? ??
        user?.displayName ??
        user?.email?.split('@').first ??
        'Darling';

    final anniversary =
        _formatAnniversary(_profile['anniversaryDate'] as String?);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'PROFILE',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.pinkAccent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Avatar + Name
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Colors.pinkAccent, Colors.deepPurple],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.pinkAccent.withValues(alpha: 0.4),
                              blurRadius: 20,
                              spreadRadius: 4,
                            )
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 52,
                          backgroundImage: (user?.photoURL != null)
                              ? NetworkImage(user!.photoURL!)
                              : const AssetImage('assets/img/logi.png')
                                  as ImageProvider,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    displayName,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    user?.email ?? '',
                    style:
                        GoogleFonts.outfit(color: Colors.white54, fontSize: 13),
                  ),
                  const SizedBox(height: 24),

                  // Affection card
                  _card(
                    children: [
                      _row('💖 Level', affection.levelName),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: affection.levelProgress,
                        minHeight: 8,
                        backgroundColor: Colors.white12,
                        valueColor:
                            AlwaysStoppedAnimation(affection.levelColor),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 6),
                      _row('✨ Points', '${affection.points}'),
                      _row('🔥 Streak', '${affection.streakDays} days'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Profile info card
                  _card(
                    children: [
                      _row('📅 Together Since', anniversary),
                      _row('🏅 Achievements',
                          '${achievements.unlocked.length} / ${AchievementsService.all.length}'),
                      _row(
                          '👤 UID',
                          (user?.uid ?? '').length > 12
                              ? '${user!.uid.substring(0, 12)}...'
                              : user?.uid ?? '—'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Edit display name
                  _card(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '✏️ Display Name',
                            style: GoogleFonts.outfit(
                                color: Colors.white70, fontSize: 14),
                          ),
                          TextButton(
                            onPressed: () => _editDisplayName(context),
                            child: Text('Edit',
                                style: GoogleFonts.outfit(
                                    color: Colors.pinkAccent,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.outfit(color: Colors.white60, fontSize: 13)),
          Text(value,
              style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Future<void> _editDisplayName(BuildContext context) async {
    final ctrl =
        TextEditingController(text: _profile['displayName'] as String? ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Display Name',
            style: GoogleFonts.outfit(
                color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Your name',
            hintStyle: const TextStyle(color: Colors.white38),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.pinkAccent),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.outfit(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: Text('Save',
                style: GoogleFonts.outfit(
                    color: Colors.pinkAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await FirestoreService().saveUserProfile(displayName: result);
      setState(() => _profile['displayName'] = result);
    }
  }
}
