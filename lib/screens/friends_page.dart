import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/affection_service.dart';
import '../widgets/waifu_background.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});
  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;
  final _myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  final _user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
    // Publish self to the users collection so others can find
    _publishSelf();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _publishSelf() async {
    if (_user == null) return;
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
      // Load friends
      final friendsSnap = await FirebaseFirestore.instance
          .collection('friends')
          .doc(_myUid)
          .get();

      if (friendsSnap.exists) {
        final friendIds =
            List<String>.from((friendsSnap.data()?['friends'] as List?) ?? []);
        if (friendIds.isNotEmpty) {
          final friendDocs = await Future.wait(friendIds.map((id) =>
              FirebaseFirestore.instance.collection('users').doc(id).get()));
          _friends =
              friendDocs.where((d) => d.exists).map((d) => d.data()!).toList();
        }
        final reqIds =
            List<String>.from((friendsSnap.data()?['requests'] as List?) ?? []);
        if (reqIds.isNotEmpty) {
          final reqDocs = await Future.wait(reqIds.map((id) =>
              FirebaseFirestore.instance.collection('users').doc(id).get()));
          _requests =
              reqDocs.where((d) => d.exists).map((d) => d.data()!).toList();
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _addFriendByEmail(String email) async {
    if (email.isEmpty) return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get();
      if (snap.docs.isEmpty) {
        _snack('User not found!');
        return;
      }
      final targetUid = snap.docs.first.id;
      if (targetUid == _myUid) {
        _snack('That\'s you, Darling! 😅');
        return;
      }
      // Send friend request to target
      await FirebaseFirestore.instance
          .collection('friends')
          .doc(targetUid)
          .set({
        'requests': FieldValue.arrayUnion([_myUid]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      _snack('Friend request sent! 💌');
    } catch (e) {
      _snack('Error: $e');
    }
  }

  Future<void> _acceptRequest(String uid) async {
    try {
      // Add each other as friends
      await FirebaseFirestore.instance.collection('friends').doc(_myUid).set({
        'friends': FieldValue.arrayUnion([uid]),
        'requests': FieldValue.arrayRemove([uid]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await FirebaseFirestore.instance.collection('friends').doc(uid).set({
        'friends': FieldValue.arrayUnion([_myUid]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      _snack('Friend added! 💕');
      setState(() {
        final req =
            _requests.firstWhere((r) => r['uid'] == uid, orElse: () => {});
        if (req.isNotEmpty) {
          _friends.add(req);
          _requests.removeWhere((r) => r['uid'] == uid);
        }
      });
    } catch (e) {
      _snack('Error: $e');
    }
  }

  void _showAddFriendDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Add Friend',
            style: GoogleFonts.outfit(
                color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Enter their email address',
              style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13)),
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
                borderSide: const BorderSide(color: Colors.pinkAccent),
              ),
            ),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: GoogleFonts.outfit(color: Colors.white38))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _addFriendByEmail(ctrl.text);
            },
            child: Text('Send Request',
                style: GoogleFonts.outfit(
                    color: Colors.pinkAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _shareMyCode() {
    Clipboard.setData(ClipboardData(text: _user?.email ?? _myUid));
    _snack('Email copied to clipboard! Share with friends 📋');
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
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A16),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('FRIENDS',
            style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5)),
        centerTitle: true,
        actions: [
          IconButton(
            icon:
                const Icon(Icons.person_add_outlined, color: Colors.pinkAccent),
            onPressed: _showAddFriendDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          indicatorColor: Colors.pinkAccent,
          labelColor: Colors.pinkAccent,
          unselectedLabelColor: Colors.white38,
          labelStyle:
              GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12),
          tabs: [
            Tab(text: 'Friends (${_friends.length})'),
            Tab(text: 'Requests (${_requests.length})'),
          ],
        ),
      ),
      body: WaifuBackground(
        opacity: 0.08,
        tint: const Color(0xFF0A0A14),
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.pinkAccent))
            : TabBarView(
                controller: _tab,
                children: [
                  _buildFriendsTab(),
                  _buildRequestsTab(),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _shareMyCode,
        backgroundColor: Colors.pinkAccent,
        icon: const Icon(Icons.share_outlined, color: Colors.white),
        label: Text('Share My Code',
            style: GoogleFonts.outfit(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildFriendsTab() {
    if (_friends.isEmpty) {
      return Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('👫', style: TextStyle(fontSize: 56)),
        const SizedBox(height: 12),
        Text('No friends yet!',
            style: GoogleFonts.outfit(color: Colors.white38, fontSize: 16)),
        const SizedBox(height: 6),
        Text('Add friends to compare XP!',
            style: GoogleFonts.outfit(color: Colors.white24, fontSize: 13)),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _showAddFriendDialog,
          icon: const Icon(Icons.person_add_outlined, color: Colors.white),
          label: Text('Add Friend',
              style: GoogleFonts.outfit(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.pinkAccent,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _friends.length,
      itemBuilder: (ctx, i) => _friendCard(_friends[i]),
    );
  }

  Widget _buildRequestsTab() {
    if (_requests.isEmpty) {
      return Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('📬', style: TextStyle(fontSize: 56)),
        const SizedBox(height: 12),
        Text('No pending requests',
            style: GoogleFonts.outfit(color: Colors.white38, fontSize: 16)),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _requests.length,
      itemBuilder: (ctx, i) {
        final r = _requests[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.pinkAccent.withValues(alpha: 0.07),
            border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.3)),
          ),
          child: Row(children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.pinkAccent.withValues(alpha: 0.3),
              child: Text((r['name'] as String? ?? 'D')[0].toUpperCase(),
                  style: GoogleFonts.outfit(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(r['name'] as String? ?? 'Darling',
                  style: GoogleFonts.outfit(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () => _acceptRequest(r['uid'] as String),
              child: Text('Accept',
                  style: GoogleFonts.outfit(
                      color: Colors.pinkAccent, fontWeight: FontWeight.bold)),
            ),
          ]),
        );
      },
    );
  }

  Widget _friendCard(Map<String, dynamic> f) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withValues(alpha: 0.04),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.pinkAccent.withValues(alpha: 0.3),
            backgroundImage: (f['photoUrl'] as String?)?.isNotEmpty == true
                ? NetworkImage(f['photoUrl'] as String)
                : null,
            child: (f['photoUrl'] as String?)?.isNotEmpty != true
                ? Text((f['name'] as String? ?? 'D')[0].toUpperCase(),
                    style: GoogleFonts.outfit(
                        color: Colors.white, fontWeight: FontWeight.bold))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(f['name'] as String? ?? 'Darling',
                    style: GoogleFonts.outfit(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                Text(f['level'] as String? ?? '',
                    style: GoogleFonts.outfit(
                        color: Colors.white38, fontSize: 11)),
              ])),
          Column(children: [
            Text('⭐ ${f['xp'] ?? 0}',
                style: GoogleFonts.outfit(
                    color: Colors.pinkAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
            Text('XP',
                style: GoogleFonts.outfit(color: Colors.white38, fontSize: 10)),
          ]),
        ]),
      );
}
