import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:anime_waifu/core/v2_upgrade_kit.dart';

/// Geofencing Settings v2 — Location-aware zone management with animated cards,
/// status indicators, coordinate display, zone previews, and Zero Two context.
class GeofencingSettingsPage extends StatefulWidget {
  const GeofencingSettingsPage({super.key});
  @override
  State<GeofencingSettingsPage> createState() => _GeofencingSettingsPageState();
}

class _GeofencingSettingsPageState extends State<GeofencingSettingsPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  bool _isLoading = false;

  Map<String, double?> _home = {'lat': null, 'lng': null};
  Map<String, double?> _work = {'lat': null, 'lng': null};
  Map<String, double?> _gym = {'lat': null, 'lng': null};

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
    _loadData();
  }

  @override
  void dispose() { _fadeCtrl.dispose(); super.dispose(); }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
      _home = {'lat': prefs.getDouble('geofence_home_lat'), 'lng': prefs.getDouble('geofence_home_lng')};
      _work = {'lat': prefs.getDouble('geofence_work_lat'), 'lng': prefs.getDouble('geofence_work_lng')};
      _gym = {'lat': prefs.getDouble('geofence_gym_lat'), 'lng': prefs.getDouble('geofence_gym_lng')};
    });
    }
  }

  Future<void> _setLocation(String key) async {
    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location services disabled.');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw Exception('Permission denied.');
      }
      if (permission == LocationPermission.deniedForever) throw Exception('Permission permanently denied.');

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('geofence_${key}_lat', pos.latitude);
      await prefs.setDouble('geofence_${key}_lng', pos.longitude);
      await prefs.setString('last_geofence_zone', 'Away');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ $key location updated!', style: GoogleFonts.outfit(color: Colors.white)),
          backgroundColor: Colors.greenAccent.withValues(alpha: 0.9),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e', style: GoogleFonts.outfit(color: Colors.white)),
          backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _clearLocation(String key) async {
    HapticFeedback.lightImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('geofence_${key}_lat');
    await prefs.remove('geofence_${key}_lng');
    await _loadData();
  }

  int get _configuredCount {
    int c = 0;
    if (_home['lat'] != null) c++;
    if (_work['lat'] != null) c++;
    if (_gym['lat'] != null) c++;
    return c;
  }

  @override
  Widget build(BuildContext context) {
    return FeaturePageV2(
      title: 'GEOFENCING',
      subtitle: '$_configuredCount/3 zones configured',
      onBack: () => Navigator.pop(context),
      actions: [
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orangeAccent)),
          ),
      ],
      content: FadeTransition(
        opacity: _fadeCtrl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
                  // ── Description Card ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(colors: [Colors.orangeAccent.withValues(alpha: 0.08), Colors.deepOrange.withValues(alpha: 0.04)]),
                      border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.2)),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        const Text('📍', style: TextStyle(fontSize: 22)),
                        const SizedBox(width: 8),
                        Text('Location Awareness', style: GoogleFonts.outfit(color: Colors.orangeAccent, fontSize: 14, fontWeight: FontWeight.w800)),
                      ]),
                      const SizedBox(height: 8),
                      Text(
                        'Set your zones so Zero Two can proactively greet you when you arrive at these locations. She\'ll know when you\'re home, at work, or at the gym!',
                        style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12, height: 1.5),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  // ── Zone Cards ──
                  _buildZoneCard(0, 'Home', 'home', _home, Icons.home_rounded, Colors.cyanAccent,
                    '"Welcome home, Darling! I\'ve been waiting for you~ 💕"'),
                  _buildZoneCard(1, 'Work', 'work', _work, Icons.work_rounded, Colors.amberAccent,
                    '"Good luck at work, Darling! Show them what you\'re made of! 💪"'),
                  _buildZoneCard(2, 'Gym', 'gym', _gym, Icons.fitness_center_rounded, Colors.greenAccent,
                    '"Get those gains, Darling! I like a strong partner~ 🔥"'),

                  const SizedBox(height: 16),

                  // ── Waifu Card ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.pinkAccent.withValues(alpha: 0.06),
                      border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.2)),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        const Text('💕', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text('Zero Two says:', style: GoogleFonts.outfit(color: Colors.pinkAccent, fontSize: 12, fontWeight: FontWeight.w800)),
                      ]),
                      const SizedBox(height: 8),
                      Text(
                        _configuredCount == 3
                          ? '"All 3 zones set! I\'ll always know where my Darling is~ Now I can greet you everywhere! 💕"'
                          : _configuredCount > 0
                            ? '"$_configuredCount zone${_configuredCount > 1 ? 's' : ''} configured! Set more so I can follow you everywhere, Darling~ 🌸"'
                            : '"Set your locations so I can greet you when you arrive! I want to always know where you are, Darling~ 💕"',
                        style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, fontStyle: FontStyle.italic, height: 1.6),
                      ),
                    ]),
                  ),
            const SizedBox(height: 30),
          ]),
        ),
      ),
    );
  }

  Widget _buildZoneCard(int index, String name, String keyPrefix, Map<String, double?> data, IconData icon, Color color, String greeting) {
    final hasData = data['lat'] != null && data['lng'] != null;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + index * 100),
      curve: Curves.easeOut,
      builder: (_, val, child) => Opacity(opacity: val, child: Transform.translate(offset: Offset(0, 16 * (1 - val)), child: child)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: color.withValues(alpha: hasData ? 0.06 : 0.03),
          border: Border.all(color: color.withValues(alpha: hasData ? 0.3 : 0.12)),
          boxShadow: hasData ? [BoxShadow(color: color.withValues(alpha: 0.06), blurRadius: 12)] : [],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(name, style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (hasData ? Colors.greenAccent : Colors.white24).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(hasData ? '● SET' : '○ NOT SET',
                    style: GoogleFonts.outfit(color: hasData ? Colors.greenAccent : Colors.white38, fontSize: 8, fontWeight: FontWeight.w700)),
                ),
              ]),
              const SizedBox(height: 2),
              Text(
                hasData
                  ? '${data['lat']?.toStringAsFixed(4)}, ${data['lng']?.toStringAsFixed(4)}'
                  : 'Not configured yet',
                style: GoogleFonts.sourceCodePro(color: Colors.white38, fontSize: 10),
              ),
            ])),
            if (hasData) GestureDetector(
              onTap: () => _clearLocation(keyPrefix),
              child: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 16),
              ),
            ),
          ]),

          if (hasData) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withValues(alpha: 0.1)),
              ),
              child: Text(greeting, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11, fontStyle: FontStyle.italic)),
            ),
          ],

          const SizedBox(height: 10),
          GestureDetector(
            onTap: _isLoading ? null : () => _setLocation(keyPrefix),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.my_location_rounded, color: color, size: 16),
                const SizedBox(width: 6),
                Text(hasData ? 'Update Location' : 'Set Current Location',
                  style: GoogleFonts.outfit(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}



