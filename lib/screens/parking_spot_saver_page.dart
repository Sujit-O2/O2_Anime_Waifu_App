import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class ParkingSpotSaverPage extends StatefulWidget {
  const ParkingSpotSaverPage({super.key});
  @override
  State<ParkingSpotSaverPage> createState() => _ParkingSpotSaverPageState();
}

class _ParkingSpotSaverPageState extends State<ParkingSpotSaverPage>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _spots = [];
  bool _saving = false;
  Position? _currentPos;
  late AnimationController _pulseCtrl;
  final _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _load();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('parking_spots_data') ?? '[]';
    try {
      setState(() => _spots =
          (jsonDecode(raw) as List).cast<Map<String, dynamic>>());
    } catch (_) {}
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
        'parking_spots_data', jsonEncode(_spots.take(10).toList()));
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return;
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.high));
      if (mounted) setState(() => _currentPos = pos);
    } catch (_) {}
  }

  Future<void> _saveSpot() async {
    setState(() => _saving = true);
    await _getCurrentLocation();
    if (_currentPos == null) {
      _snack('❌ Could not get GPS location', Colors.redAccent);
      setState(() => _saving = false);
      return;
    }

    String? photoPath;
    final picker = ImagePicker();
    if (!mounted) return;
    final shouldPhoto = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF12121E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('📸 Add Photo?',
            style: GoogleFonts.outfit(
                color: Colors.white, fontWeight: FontWeight.w800)),
        content: Text('Take a photo of your parking spot for easier finding?',
            style: GoogleFonts.outfit(color: Colors.white60)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child:
                  Text('Skip', style: GoogleFonts.outfit(color: Colors.white38))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlueAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: Text('📸 Photo',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (shouldPhoto == true) {
      try {
        final img = await picker.pickImage(
            source: ImageSource.camera, imageQuality: 70);
        if (img != null) photoPath = img.path;
      } catch (_) {}
    }

    HapticFeedback.heavyImpact();
    final spot = {
      'lat': _currentPos!.latitude,
      'lng': _currentPos!.longitude,
      'time': DateTime.now().millisecondsSinceEpoch,
      'note': _noteCtrl.text.trim(),
      'photo': photoPath,
    };

    setState(() {
      _spots.insert(0, spot);
      _saving = false;
    });
    _noteCtrl.clear();
    _save();
    _snack('✅ Parking spot saved!', Colors.lightBlueAccent);
  }

  void _navigateTo(Map<String, dynamic> spot) async {
    final lat = spot['lat'];
    final lng = spot['lng'];
    final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=walking';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  void _deleteSpot(int idx) {
    HapticFeedback.mediumImpact();
    setState(() => _spots.removeAt(idx));
    _save();
  }

  double _distanceTo(Map<String, dynamic> spot) {
    if (_currentPos == null) return 0;
    return Geolocator.distanceBetween(
      _currentPos!.latitude,
      _currentPos!.longitude,
      (spot['lat'] as num).toDouble(),
      (spot['lng'] as num).toDouble(),
    );
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()}m away';
    return '${(meters / 1000).toStringAsFixed(1)}km away';
  }

  String _timeAgo(int ms) {
    final diff = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ms));
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A16),
      body: SafeArea(
        child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white12)),
                  child: const Icon(Icons.arrow_back_ios_new,
                      color: Colors.white60, size: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PARKING SAVER',
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5)),
                      Text(
                          _currentPos != null
                              ? '📍 GPS Active'
                              : '⏳ Getting location...',
                          style: GoogleFonts.outfit(
                              color: _currentPos != null
                                  ? Colors.lightBlueAccent
                                  : Colors.white38,
                              fontSize: 11)),
                    ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.lightBlueAccent.withValues(alpha: 0.15),
                  border: Border.all(
                      color: Colors.lightBlueAccent.withValues(alpha: 0.4)),
                ),
                child: Text('🅿️ ${_spots.length}',
                    style: GoogleFonts.outfit(
                        color: Colors.lightBlueAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
            ]),
          ),

          const SizedBox(height: 16),

          // Save button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(children: [
              // Note field
              TextField(
                controller: _noteCtrl,
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
                cursorColor: Colors.lightBlueAccent,
                decoration: InputDecoration(
                  hintText: 'Note (e.g. Level 3, near elevator)',
                  hintStyle:
                      GoogleFonts.outfit(color: Colors.white30, fontSize: 12),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.04),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  prefixIcon: const Icon(Icons.note_add_rounded,
                      color: Colors.white24, size: 20),
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _saving ? null : _saveSpot,
                child: AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, __) => Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(colors: [
                        Colors.lightBlueAccent
                            .withValues(alpha: 0.15 + _pulseCtrl.value * 0.1),
                        Colors.cyanAccent
                            .withValues(alpha: 0.1 + _pulseCtrl.value * 0.08),
                      ]),
                      border: Border.all(
                          color: Colors.lightBlueAccent
                              .withValues(alpha: 0.4 + _pulseCtrl.value * 0.3),
                          width: 2),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.lightBlueAccent
                                .withValues(alpha: _pulseCtrl.value * 0.15),
                            blurRadius: 20)
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_saving)
                          const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.lightBlueAccent))
                        else
                          const Icon(Icons.local_parking_rounded,
                              color: Colors.lightBlueAccent, size: 26),
                        const SizedBox(width: 12),
                        Text(
                          _saving ? 'SAVING SPOT...' : 'SAVE PARKING SPOT',
                          style: GoogleFonts.outfit(
                              color: Colors.lightBlueAccent,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ]),
          ),

          const Divider(color: Colors.white12, height: 24),

          // Saved spots
          Expanded(
            child: _spots.isEmpty
                ? Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                        const Text('🚗', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text('No parking spots saved yet',
                            style:
                                GoogleFonts.outfit(color: Colors.white38)),
                        Text('Tap the button above to save your spot!',
                            style: GoogleFonts.outfit(
                                color: Colors.white24, fontSize: 12)),
                      ]))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: _spots.length,
                    itemBuilder: (ctx, i) {
                      final spot = _spots[i];
                      final dist = _distanceTo(spot);
                      final isLatest = i == 0;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: isLatest
                              ? Colors.lightBlueAccent.withValues(alpha: 0.08)
                              : Colors.white.withValues(alpha: 0.03),
                          border: Border.all(
                              color: isLatest
                                  ? Colors.lightBlueAccent
                                      .withValues(alpha: 0.3)
                                  : Colors.white.withValues(alpha: 0.07)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.lightBlueAccent
                                      .withValues(alpha: isLatest ? 0.2 : 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                    isLatest
                                        ? Icons.local_parking_rounded
                                        : Icons.history_rounded,
                                    color: isLatest
                                        ? Colors.lightBlueAccent
                                        : Colors.white38,
                                    size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          isLatest
                                              ? '🟢 Current Spot'
                                              : 'Spot #${_spots.length - i}',
                                          style: GoogleFonts.outfit(
                                              color: isLatest
                                                  ? Colors.lightBlueAccent
                                                  : Colors.white60,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700)),
                                      Text(
                                          '${_timeAgo(spot['time'] as int)} • ${_formatDistance(dist)}',
                                          style: GoogleFonts.outfit(
                                              color: Colors.white30,
                                              fontSize: 11)),
                                    ]),
                              ),
                              // Navigate button
                              GestureDetector(
                                onTap: () => _navigateTo(spot),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: Colors.lightBlueAccent
                                        .withValues(alpha: 0.15),
                                    border: Border.all(
                                        color: Colors.lightBlueAccent
                                            .withValues(alpha: 0.4)),
                                  ),
                                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                                    const Icon(Icons.navigation_rounded,
                                        color: Colors.lightBlueAccent,
                                        size: 16),
                                    const SizedBox(width: 4),
                                    Text('Navigate',
                                        style: GoogleFonts.outfit(
                                            color: Colors.lightBlueAccent,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700)),
                                  ]),
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => _deleteSpot(i),
                                child: const Icon(Icons.close_rounded,
                                    color: Colors.white24, size: 18),
                              ),
                            ]),
                            if ((spot['note'] as String?)?.isNotEmpty ?? false) ...[
                              const SizedBox(height: 8),
                              Text('📝 ${spot['note']}',
                                  style: GoogleFonts.outfit(
                                      color: Colors.white54, fontSize: 12)),
                            ],
                            if (spot['photo'] != null) ...[
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  File(spot['photo'].toString()),
                                  height: 120,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const SizedBox.shrink(),
                                ),
                              ),
                            ],
                            // GPS coords
                            const SizedBox(height: 6),
                            Text(
                                '${(spot['lat'] as num).toStringAsFixed(6)}, ${(spot['lng'] as num).toStringAsFixed(6)}',
                                style: GoogleFonts.firaCode(
                                    color: Colors.white24, fontSize: 9)),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ]),
      ),
    );
  }
}
