import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

class GeofencingSettingsPage extends StatefulWidget {
  const GeofencingSettingsPage({super.key});

  @override
  State<GeofencingSettingsPage> createState() => _GeofencingSettingsPageState();
}

class _GeofencingSettingsPageState extends State<GeofencingSettingsPage> {
  bool _isLoading = false;
  
  Map<String, double?> _home = {'lat': null, 'lng': null};
  Map<String, double?> _work = {'lat': null, 'lng': null};
  Map<String, double?> _gym = {'lat': null, 'lng': null};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _home = {
        'lat': prefs.getDouble('geofence_home_lat'),
        'lng': prefs.getDouble('geofence_home_lng'),
      };
      _work = {
        'lat': prefs.getDouble('geofence_work_lat'),
        'lng': prefs.getDouble('geofence_work_lng'),
      };
      _gym = {
        'lat': prefs.getDouble('geofence_gym_lat'),
        'lng': prefs.getDouble('geofence_gym_lng'),
      };
    });
  }

  Future<void> _setLocation(String key) async {
    setState(() => _isLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location services disabled.');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw Exception('Permission denied.');
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permission permanently denied.');
      }

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setDouble('geofence_${key}_lat', pos.latitude);
      await prefs.setDouble('geofence_${key}_lng', pos.longitude);
      
      // Reset currently tracked zone so it can re-trigger
      await prefs.setString('last_geofence_zone', 'Away');

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$key location updated!', style: GoogleFonts.outfit()),
        backgroundColor: Colors.green,
      ));
      
      await _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e', style: GoogleFonts.outfit()),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _clearLocation(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('geofence_${key}_lat');
    await prefs.remove('geofence_${key}_lng');
    await _loadData();
  }

  Widget _buildZoneCard(String name, String keyPrefix, Map<String, double?> data, IconData icon) {
    final hasData = data['lat'] != null && data['lng'] != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.orangeAccent),
              const SizedBox(width: 8),
              Text(name, style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            hasData 
                ? 'Lat: ${data['lat']?.toStringAsFixed(4)}, Lng: ${data['lng']?.toStringAsFixed(4)}' 
                : 'Not configured yet.',
            style: GoogleFonts.outfit(color: Colors.white60),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : () => _setLocation(keyPrefix),
                  icon: const Icon(Icons.my_location, size: 16),
                  label: const Text('Set to Current Location'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent.withValues(alpha: 0.2),
                    foregroundColor: Colors.orangeAccent,
                    elevation: 0,
                  ),
                ),
              ),
              if (hasData) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _clearLocation(keyPrefix),
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  tooltip: 'Clear',
                ),
              ]
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Proactive Geofencing', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orangeAccent))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Set your zones. Zero Two will run periodically in the background and proactively send you greetings when you arrive at these locations.',
                  style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 24),
                _buildZoneCard('Home', 'home', _home, Icons.home),
                _buildZoneCard('Work', 'work', _work, Icons.work),
                _buildZoneCard('Gym', 'gym', _gym, Icons.fitness_center),
              ],
            ),
    );
  }
}
