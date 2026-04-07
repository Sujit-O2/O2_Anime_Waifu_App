import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PackageTrackerPage extends StatefulWidget {
  const PackageTrackerPage({super.key});
  @override
  State<PackageTrackerPage> createState() => _PackageTrackerPageState();
}

class _PackageTrackerPageState extends State<PackageTrackerPage> {
  List<Map<String, dynamic>> _packages = [];
  final _trackCtrl = TextEditingController();
  final _labelCtrl = TextEditingController();
  int _selectedCarrier = 0;
  static const _carriers = [
    '📦 General',
    '🟤 UPS',
    '🔵 FedEx',
    '🟠 Amazon',
    '🔴 DHL',
    '🟡 DTDC',
    '🟢 Delhivery'
  ];
  static const _statuses = [
    '📋 Order Placed',
    '📦 Packed',
    '🚚 Shipped',
    '✈️ In Transit',
    '🏬 Out for Delivery',
    '✅ Delivered'
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _trackCtrl.dispose();
    _labelCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    try {
      _packages =
          (jsonDecode(p.getString('package_tracker_data') ?? '[]') as List)
              .cast<Map<String, dynamic>>();
    } catch (_) {}
    setState(() {});
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('package_tracker_data', jsonEncode(_packages));
  }

  void _addPackage() {
    if (_trackCtrl.text.trim().isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() => _packages.insert(0, {
          'tracking': _trackCtrl.text.trim(),
          'label': _labelCtrl.text.trim().isEmpty
              ? 'My Package'
              : _labelCtrl.text.trim(),
          'carrier': _carriers[_selectedCarrier],
          'status': 0,
          'time': DateTime.now().millisecondsSinceEpoch,
          'updates': [
            {'status': 0, 'time': DateTime.now().millisecondsSinceEpoch}
          ],
        }));
    _trackCtrl.clear();
    _labelCtrl.clear();
    _save();
    _snack('✅ Package added!', Colors.purpleAccent);
  }

  void _updateStatus(int pkgIdx, int newStatus) {
    HapticFeedback.lightImpact();
    final updates =
        List<Map<String, dynamic>>.from(_packages[pkgIdx]['updates'] ?? []);
    updates.add(
        {'status': newStatus, 'time': DateTime.now().millisecondsSinceEpoch});
    setState(() {
      _packages[pkgIdx]['status'] = newStatus;
      _packages[pkgIdx]['updates'] = updates;
    });
    _save();
  }

  void _deletePackage(int i) {
    HapticFeedback.mediumImpact();
    setState(() => _packages.removeAt(i));
    _save();
  }

  String _timeAgo(int ms) {
    final diff =
        DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ms));
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }

  void _snack(String msg, Color c) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg,
            style: GoogleFonts.outfit(
                color: Colors.black87, fontWeight: FontWeight.w700)),
        backgroundColor: c,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
          child: Column(children: [
        // Header
        Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(children: [
              GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white12)),
                      child: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white60, size: 16))),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('PACKAGE TRACKER',
                        style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5)),
                    Text(
                        '${_packages.where((p) => (p['status'] as int) < 5).length} active shipments',
                        style: GoogleFonts.outfit(
                            color: Colors.purpleAccent, fontSize: 11)),
                  ])),
            ])),
        const SizedBox(height: 14),
        // Add package
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.white.withValues(alpha: 0.03),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.08))),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                          child: TextField(
                              controller: _trackCtrl,
                              style: GoogleFonts.outfit(
                                  color: Colors.white, fontSize: 13),
                              cursorColor: Colors.purpleAccent,
                              decoration: InputDecoration(
                                  hintText: 'Tracking Number',
                                  hintStyle: GoogleFonts.outfit(
                                      color: Colors.white30, fontSize: 12),
                                  filled: true,
                                  fillColor:
                                      Colors.white.withValues(alpha: 0.04),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 10)))),
                      const SizedBox(width: 8),
                      SizedBox(
                          width: 100,
                          child: TextField(
                              controller: _labelCtrl,
                              style: GoogleFonts.outfit(
                                  color: Colors.white, fontSize: 13),
                              cursorColor: Colors.purpleAccent,
                              decoration: InputDecoration(
                                  hintText: 'Label',
                                  hintStyle: GoogleFonts.outfit(
                                      color: Colors.white30, fontSize: 12),
                                  filled: true,
                                  fillColor:
                                      Colors.white.withValues(alpha: 0.04),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 10)))),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                          child: SizedBox(
                              height: 32,
                              child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _carriers.length,
                                  itemBuilder: (c, i) => GestureDetector(
                                      onTap: () =>
                                          setState(() => _selectedCarrier = i),
                                      child: AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 150),
                                          margin:
                                              const EdgeInsets.only(right: 6),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              color: _selectedCarrier == i
                                                  ? Colors.purpleAccent
                                                      .withValues(alpha: 0.15)
                                                  : Colors.white
                                                      .withValues(alpha: 0.04),
                                              border:
                                                  Border.all(color: _selectedCarrier == i ? Colors.purpleAccent : Colors.white12)),
                                          child: Text(_carriers[i], style: GoogleFonts.outfit(color: _selectedCarrier == i ? Colors.purpleAccent : Colors.white38, fontSize: 11))))))),
                      const SizedBox(width: 8),
                      GestureDetector(
                          onTap: _addPackage,
                          child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                  color: Colors.purpleAccent
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: Colors.purpleAccent
                                          .withValues(alpha: 0.4))),
                              child: const Icon(Icons.add_rounded,
                                  color: Colors.purpleAccent, size: 20))),
                    ]),
                  ]),
            )),
        const Divider(color: Colors.white12, height: 20),
        // Packages list
        Expanded(
          child: _packages.isEmpty
              ? Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                      const Text('📦', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 12),
                      Text('No packages tracked',
                          style: GoogleFonts.outfit(color: Colors.white38)),
                      Text('Add a tracking number above',
                          style: GoogleFonts.outfit(
                              color: Colors.white24, fontSize: 12))
                    ]))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: _packages.length,
                  itemBuilder: (ctx, i) => _buildPackageCard(i)),
        ),
      ])),
    );
  }

  Widget _buildPackageCard(int i) {
    final pkg = _packages[i];
    final status = pkg['status'] as int;
    final isDelivered = status >= 5;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isDelivered
              ? Colors.greenAccent.withValues(alpha: 0.05)
              : Colors.purpleAccent.withValues(alpha: 0.05),
          border: Border.all(
              color: isDelivered
                  ? Colors.greenAccent.withValues(alpha: 0.2)
                  : Colors.purpleAccent.withValues(alpha: 0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(pkg['carrier'].toString().split(' ').first,
              style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(pkg['label']?.toString() ?? '',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
                Text(pkg['tracking']?.toString() ?? '',
                    style: GoogleFonts.firaCode(
                        color: Colors.white38, fontSize: 10)),
              ])),
          GestureDetector(
              onTap: () {
                Clipboard.setData(
                    ClipboardData(text: pkg['tracking']?.toString() ?? ''));
                _snack('📋 Tracking number copied', Colors.purpleAccent);
              },
              child: const Icon(Icons.copy_rounded,
                  color: Colors.white24, size: 16)),
          const SizedBox(width: 8),
          GestureDetector(
              onTap: () => _deletePackage(i),
              child: const Icon(Icons.close_rounded,
                  color: Colors.white24, size: 18)),
        ]),
        const SizedBox(height: 12),
        // Status timeline
        Row(
            children: List.generate(_statuses.length, (s) {
          final isActive = s <= status;
          final isCurrent = s == status;
          return Expanded(
              child: Column(children: [
            Container(
                height: 4,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: isActive
                        ? (isDelivered
                            ? Colors.greenAccent
                            : Colors.purpleAccent)
                        : Colors.white.withValues(alpha: 0.08))),
            const SizedBox(height: 4),
            if (isCurrent)
              Text(_statuses[s].split(' ').last,
                  style: GoogleFonts.outfit(
                      color: isDelivered
                          ? Colors.greenAccent
                          : Colors.purpleAccent,
                      fontSize: 8,
                      fontWeight: FontWeight.w700)),
          ]));
        })),
        const SizedBox(height: 8),
        Text(_statuses[status],
            style: GoogleFonts.outfit(
                color: isDelivered ? Colors.greenAccent : Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w700)),
        Text(_timeAgo(pkg['time'] as int),
            style: GoogleFonts.outfit(color: Colors.white24, fontSize: 10)),
        if (!isDelivered) ...[
          const SizedBox(height: 10),
          SizedBox(
              height: 30,
              child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _statuses.length,
                  itemBuilder: (c, s) => GestureDetector(
                      onTap: () => _updateStatus(i, s),
                      child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: s == status
                                  ? Colors.purpleAccent.withValues(alpha: 0.2)
                                  : Colors.white.withValues(alpha: 0.04),
                              border: Border.all(
                                  color: s == status
                                      ? Colors.purpleAccent
                                      : Colors.white12)),
                          child: Text(_statuses[s],
                              style: GoogleFonts.outfit(
                                  color: s == status
                                      ? Colors.purpleAccent
                                      : Colors.white30,
                                  fontSize: 9)))))),
        ],
      ]),
    );
  }
}
