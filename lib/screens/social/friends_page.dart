import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:anime_waifu/services/user_profile/affection_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';


class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<Map<String, dynamic>> _friends = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _requests = <Map<String, dynamic>>[];
  bool _loading = true;
  final String _myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  final User? _user = FirebaseAuth.instance.currentUser;

  String get _commentaryMood {
    if (_requests.isNotEmpty) {
      return 'motivated';
    }
    if (_friends.isNotEmpty) {
      return 'achievement';
    }
    return 'neutral';
  }

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
    _publishSelf();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _publishSelf() async {
    if (_user == null) {
      return;
    }
    final aff = AffectionService.instance;
    await FirebaseFirestore.instance.collection('users').doc(_myUid).set({
      'uid': _myUid,
      'name': _user?.displayName ?? _user?.email?.split('@').first ?? 'Darling',
      'photoUrl': _user?.photoURL ?? '',
      'email': _user?.email ?? '',
      'xp': aff.points,
      'level': aff.levelName,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _load() async {
    if (_user == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final friendsSnap = await FirebaseFirestore.instance
          .collection('friends')
          .doc(_myUid)
          .get();

      if (friendsSnap.exists) {
        final friendIds =
            List<String>.from((friendsSnap.data()?['friends'] as List?) ?? []);
        if (friendIds.isNotEmpty) {
          final friendDocs = await Future.wait(
            friendIds.map(
              (id) =>
                  FirebaseFirestore.instance.collection('users').doc(id).get(),
            ),
          );
          _friends = friendDocs
              .where((doc) => doc.exists)
              .map((doc) => doc.data()!)
              .toList();
        }

        final reqIds =
            List<String>.from((friendsSnap.data()?['requests'] as List?) ?? []);
        if (reqIds.isNotEmpty) {
          final reqDocs = await Future.wait(
            reqIds.map(
              (id) =>
                  FirebaseFirestore.instance.collection('users').doc(id).get(),
            ),
          );
          _requests = reqDocs
              .where((doc) => doc.exists)
              .map((doc) => doc.data()!)
              .toList();
        }
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _refresh() => _load();

  Future<void> _addFriendByEmail(String email) async {
    if (email.trim().isEmpty) {
      return;
    }
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get();
      if (snap.docs.isEmpty) {
        _snack('User not found.');
        return;
      }
      final targetUid = snap.docs.first.id;
      if (targetUid == _myUid) {
        _snack('That is your own account.');
        return;
      }
      await FirebaseFirestore.instance
          .collection('friends')
          .doc(targetUid)
          .set({
        'requests': FieldValue.arrayUnion([_myUid]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (mounted) {
        showSuccessSnackbar(context, 'Friend request sent.');
      }
    } catch (error) {
      _snack('Error: $error');
    }
  }

  Future<void> _acceptRequest(String uid) async {
    try {
      await FirebaseFirestore.instance.collection('friends').doc(_myUid).set({
        'friends': FieldValue.arrayUnion([uid]),
        'requests': FieldValue.arrayRemove([uid]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await FirebaseFirestore.instance.collection('friends').doc(uid).set({
        'friends': FieldValue.arrayUnion([_myUid]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (mounted) {
        final req = _requests.firstWhere(
          (request) => request['uid'] == uid,
          orElse: () => <String, dynamic>{},
        );
        if (req.isNotEmpty) {
          setState(() {
            _friends.add(req);
            _requests.removeWhere((request) => request['uid'] == uid);
          });
        }
        showSuccessSnackbar(context, 'Friend added.');
      }
    } catch (error) {
      _snack('Error: $error');
    }
  }

  void _showAddFriendDialog() {
    final ctrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: V2Theme.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Add Friend',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter their email address',
              style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'friend@example.com',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: V2Theme.primaryColor),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(color: Colors.white38),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _addFriendByEmail(ctrl.text);
            },
            child: Text(
              'Send Request',
              style: GoogleFonts.outfit(
                color: V2Theme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _shareMyCode() {
    Clipboard.setData(ClipboardData(text: _user?.email ?? _myUid));
    showSuccessSnackbar(context, 'Account email copied for sharing.');
  }

  void _snack(String msg) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.outfit()),
        backgroundColor: V2Theme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FeaturePageV2(
      title: 'FRIENDS',
      subtitle: '${_friends.length} friends • ${_requests.length} requests',
      onBack: () => Navigator.pop(context),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.person_add_outlined,
            color: V2Theme.primaryColor,
          ),
          onPressed: _showAddFriendDialog,
        ),
        GestureDetector(
          onTap: _shareMyCode,
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: V2Theme.primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: V2Theme.primaryColor.withValues(alpha: 0.4)),
            ),
            child: const Icon(Icons.share_outlined, color: V2Theme.primaryColor, size: 18),
          ),
        ),
      ],
      content: _loading
          ? const Center(
              child: CircularProgressIndicator(color: V2Theme.primaryColor),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: Column(
                    children: [
                      GlassCard(
                        margin: EdgeInsets.zero,
                        glow: true,
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Social snapshot',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _friends.isEmpty
                                        ? 'Build your first circle'
                                        : '${_friends.length} friends connected',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _requests.isEmpty
                                        ? 'Share your account email and start comparing progress with other players.'
                                        : 'You have ${_requests.length} pending requests waiting for a response.',
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
                              progress: (_friends.length.clamp(0, 10)) / 10,
                              foreground: V2Theme.primaryColor,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.people_alt_rounded,
                                    color: V2Theme.primaryColor,
                                    size: 28,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${_friends.length}',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    'Friends',
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
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              title: 'Friends',
                              value: '${_friends.length}',
                              icon: Icons.people_alt_rounded,
                              color: V2Theme.primaryColor,
                            ),
                          ),
                          Expanded(
                            child: StatCard(
                              title: 'Requests',
                              value: '${_requests.length}',
                              icon: Icons.mark_email_unread_outlined,
                              color: V2Theme.secondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Inline TabBar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: TabBar(
                      controller: _tab,
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: V2Theme.primaryGradient,
                      ),
                      dividerColor: Colors.transparent,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white38,
                      labelStyle: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      tabs: [
                        Tab(text: 'Friends (${_friends.length})'),
                        Tab(text: 'Requests (${_requests.length})'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: TabBarView(
                    controller: _tab,
                    children: [
                      RefreshIndicator(
                        onRefresh: _refresh,
                        color: V2Theme.primaryColor,
                        child: _buildFriendsTab(),
                      ),
                      RefreshIndicator(
                        onRefresh: _refresh,
                        color: V2Theme.primaryColor,
                        child: _buildRequestsTab(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFriendsTab() {
    if (_friends.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          EmptyState(
            icon: Icons.people_outline_rounded,
            title: 'No friends yet',
            subtitle:
                'Add friends to compare XP, streaks, and overall progress.',
            buttonText: 'Add Friend',
            onButtonPressed: _showAddFriendDialog,
          ),
        ],
      );
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _friends.length,
      itemBuilder: (ctx, i) => AnimatedEntry(
        index: i,
        child: _friendCard(_friends[i]),
      ),
    );
  }

  Widget _buildRequestsTab() {
    if (_requests.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 80),
          EmptyState(
            icon: Icons.mail_outline_rounded,
            title: 'No pending requests',
            subtitle:
                'Incoming friend requests will appear here when someone finds your account.',
          ),
        ],
      );
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _requests.length,
      itemBuilder: (ctx, i) {
        final request = _requests[i];
        return AnimatedEntry(
          index: i,
          child: GlassCard(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: V2Theme.primaryColor.withValues(alpha: 0.3),
                  child: Text(
                    (request['name'] as String? ?? 'D')[0].toUpperCase(),
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request['name']?.toString() ?? 'Darling',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        request['email']?.toString() ?? '',
                        style: GoogleFonts.outfit(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: () => _acceptRequest(request['uid'].toString()),
                  style: FilledButton.styleFrom(
                    backgroundColor: V2Theme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Accept'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _friendCard(Map<String, dynamic> friend) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: V2Theme.primaryColor.withValues(alpha: 0.3),
            child: Text(
              (friend['name'] as String? ?? 'D')[0].toUpperCase(),
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend['name']?.toString() ?? 'Darling',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  friend['level']?.toString() ?? '',
                  style: GoogleFonts.outfit(
                    color: Colors.white38,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${friend['xp'] ?? 0} XP',
            style: GoogleFonts.outfit(
              color: V2Theme.primaryColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}



