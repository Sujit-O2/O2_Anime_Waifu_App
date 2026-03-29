import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencySosPage extends StatefulWidget {
  const EmergencySosPage({super.key});
  @override
  State<EmergencySosPage> createState() => _EmergencySosPageState();
}

class _EmergencySosPageState extends State<EmergencySosPage> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _contacts = [];
  Map<String, String> _medInfo = {'blood': '', 'allergies': '', 'conditions': ''};
  bool _shakeEnabled = false;
  bool _sendingSos = false;
  int _countdown = 0;
  Timer? _timer;
  late AnimationController _pulseCtrl;
  StreamSubscription? _accelSub;
  DateTime? _lastShake;
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    _load();
  }

  @override
  void dispose() { _pulseCtrl.dispose(); _timer?.cancel(); _accelSub?.cancel(); _nameCtrl.dispose(); _phoneCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    try { _contacts = (jsonDecode(p.getString('sos_contacts_data') ?? '[]') as List).cast<Map<String, dynamic>>(); } catch (_) {}
    try { _medInfo = Map<String, String>.from(jsonDecode(p.getString('sos_medical_info') ?? '{}')); } catch (_) {}
    _shakeEnabled = p.getBool('sos_shake_enabled') ?? false;
    if (_shakeEnabled) _startShakeDetection();
    setState(() {});
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('sos_contacts_data', jsonEncode(_contacts));
    await p.setString('sos_medical_info', jsonEncode(_medInfo));
    await p.setBool('sos_shake_enabled', _shakeEnabled);
  }

  void _addContact() {
    if (_nameCtrl.text.trim().isEmpty || _phoneCtrl.text.trim().isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() => _contacts.add({'name': _nameCtrl.text.trim(), 'phone': _phoneCtrl.text.trim()}));
    _nameCtrl.clear(); _phoneCtrl.clear(); _save();
  }

  void _deleteContact(int i) { HapticFeedback.mediumImpact(); setState(() => _contacts.removeAt(i)); _save(); }

  void _startShakeDetection() {
    _accelSub?.cancel();
    _accelSub = accelerometerEventStream().listen((event) {
      final acceleration = (event.x * event.x + event.y * event.y + event.z * event.z);
      if (acceleration > 600) {
        final now = DateTime.now();
        if (_lastShake == null || now.difference(_lastShake!).inSeconds > 5) {
          _lastShake = now;
          _triggerSos();
        }
      }
    });
  }

  void _toggleShake(bool v) {
    setState(() => _shakeEnabled = v);
    if (v) { _startShakeDetection(); } else { _accelSub?.cancel(); }
    _save();
  }

  void _triggerSos() {
    if (_contacts.isEmpty) { _snack('❌ Add emergency contacts first!', Colors.redAccent); return; }
    if (_sendingSos) return;
    HapticFeedback.heavyImpact();
    setState(() { _sendingSos = true; _countdown = 3; });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown <= 1) { t.cancel(); _sendSos(); }
      else { setState(() => _countdown--); HapticFeedback.heavyImpact(); }
    });
  }

  void _cancelSos() { _timer?.cancel(); setState(() { _sendingSos = false; _countdown = 0; }); _snack('SOS cancelled', Colors.white38); }

  Future<void> _sendSos() async {
    try {
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 5)));
      } catch (_) {}

      final locationStr = pos != null ? 'https://www.google.com/maps?q=${pos.latitude},${pos.longitude}' : 'Location unavailable';
      final message = '🆘 EMERGENCY SOS from O2-WAIFU!\n\nI need help! My location:\n$locationStr\n\n${_medInfo['blood']!.isNotEmpty ? 'Blood: ${_medInfo['blood']}\n' : ''}${_medInfo['allergies']!.isNotEmpty ? 'Allergies: ${_medInfo['allergies']}\n' : ''}${_medInfo['conditions']!.isNotEmpty ? 'Conditions: ${_medInfo['conditions']}\n' : ''}';

      for (final c in _contacts) {
        final phone = c['phone'] as String;
        final smsUri = Uri.parse('sms:$phone?body=${Uri.encodeComponent(message)}');
        try { await launchUrl(smsUri); } catch (_) {}
      }

      setState(() { _sendingSos = false; _countdown = 0; });
      _snack('🆘 SOS sent to ${_contacts.length} contacts!', Colors.redAccent);
    } catch (e) {
      setState(() { _sendingSos = false; _countdown = 0; });
      _snack('❌ Error: $e', Colors.redAccent);
    }
  }

  void _editMedInfo() {
    final bCtrl = TextEditingController(text: _medInfo['blood']);
    final aCtrl = TextEditingController(text: _medInfo['allergies']);
    final cCtrl = TextEditingController(text: _medInfo['conditions']);
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: const Color(0xFF12121E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text('🏥 Medical Info', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        _medField(bCtrl, 'Blood Type (e.g. O+)'),
        const SizedBox(height: 8),
        _medField(aCtrl, 'Allergies'),
        const SizedBox(height: 8),
        _medField(cCtrl, 'Medical Conditions'),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.white38))),
        ElevatedButton(onPressed: () {
          setState(() => _medInfo = {'blood': bCtrl.text, 'allergies': aCtrl.text, 'conditions': cCtrl.text});
          _save(); Navigator.pop(context);
        }, style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: Text('Save', style: GoogleFonts.outfit(fontWeight: FontWeight.w700))),
      ],
    ));
  }

  Widget _medField(TextEditingController c, String hint) => TextField(controller: c, style: GoogleFonts.outfit(color: Colors.white, fontSize: 13), cursorColor: Colors.redAccent, decoration: InputDecoration(hintText: hint, hintStyle: GoogleFonts.outfit(color: Colors.white30, fontSize: 12), filled: true, fillColor: Colors.white.withValues(alpha: 0.06), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none), isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)));

  void _snack(String msg, Color c) { if (!mounted) return; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700)), backgroundColor: c, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A16),
      body: SafeArea(child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 0), child: Row(children: [
          GestureDetector(onTap: () => Navigator.pop(context), child: Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white12)), child: const Icon(Icons.arrow_back_ios_new, color: Colors.white60, size: 16))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('EMERGENCY SOS', style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            Text('${_contacts.length} emergency contacts', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11)),
          ])),
        ])),
        const SizedBox(height: 14),
        Expanded(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), child: Column(children: [
          // SOS Button
          GestureDetector(
            onTap: _sendingSos ? _cancelSos : _triggerSos,
            child: AnimatedBuilder(animation: _pulseCtrl, builder: (_, __) => Container(
              width: 160, height: 160,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: _sendingSos ? Colors.redAccent.withValues(alpha: 0.3) : Colors.redAccent.withValues(alpha: 0.1 + _pulseCtrl.value * 0.05),
                border: Border.all(color: Colors.redAccent.withValues(alpha: _sendingSos ? 0.9 : 0.4 + _pulseCtrl.value * 0.3), width: 3),
                boxShadow: [BoxShadow(color: Colors.redAccent.withValues(alpha: _sendingSos ? 0.4 : _pulseCtrl.value * 0.15), blurRadius: _sendingSos ? 40 : 20)],
              ),
              child: Center(child: _sendingSos
                ? Text('$_countdown', style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 60, fontWeight: FontWeight.w900))
                : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.sos_rounded, color: Colors.redAccent, size: 48),
                    Text('SOS', style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 3)),
                  ]),
              ),
            )),
          ),
          if (_sendingSos) ...[const SizedBox(height: 12), Text('Tap again to CANCEL', style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w700))],
          const SizedBox(height: 8),
          Text(_sendingSos ? 'Sending SOS in $_countdown...' : 'Tap to send emergency alert', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12)),

          const SizedBox(height: 20),
          // Shake toggle + Med info
          Row(children: [
            Expanded(child: GestureDetector(onTap: () => _toggleShake(!_shakeEnabled), child: Container(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14), decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: _shakeEnabled ? Colors.orangeAccent.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.03), border: Border.all(color: _shakeEnabled ? Colors.orangeAccent.withValues(alpha: 0.4) : Colors.white12)),
              child: Row(children: [Icon(Icons.vibration_rounded, color: _shakeEnabled ? Colors.orangeAccent : Colors.white30, size: 20), const SizedBox(width: 8), Text('Shake SOS', style: GoogleFonts.outfit(color: _shakeEnabled ? Colors.orangeAccent : Colors.white38, fontSize: 12, fontWeight: FontWeight.w700)), const Spacer(), Icon(_shakeEnabled ? Icons.toggle_on : Icons.toggle_off, color: _shakeEnabled ? Colors.orangeAccent : Colors.white24, size: 28)])))),
            const SizedBox(width: 10),
            GestureDetector(onTap: _editMedInfo, child: Container(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14), decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.white.withValues(alpha: 0.03), border: Border.all(color: Colors.white12)),
              child: Row(children: [const Icon(Icons.medical_information_rounded, color: Colors.white38, size: 20), const SizedBox(width: 8), Text('Medical Info', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w700))]))),
          ]),

          const SizedBox(height: 20),
          // Add contact
          Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: Colors.white.withValues(alpha: 0.03), border: Border.all(color: Colors.white.withValues(alpha: 0.08))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('EMERGENCY CONTACTS', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextField(controller: _nameCtrl, style: GoogleFonts.outfit(color: Colors.white, fontSize: 13), cursorColor: Colors.redAccent, decoration: InputDecoration(hintText: 'Name', hintStyle: GoogleFonts.outfit(color: Colors.white30, fontSize: 12), filled: true, fillColor: Colors.white.withValues(alpha: 0.04), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none), isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10)))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone, style: GoogleFonts.outfit(color: Colors.white, fontSize: 13), cursorColor: Colors.redAccent, decoration: InputDecoration(hintText: 'Phone', hintStyle: GoogleFonts.outfit(color: Colors.white30, fontSize: 12), filled: true, fillColor: Colors.white.withValues(alpha: 0.04), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none), isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10)))),
                const SizedBox(width: 8),
                GestureDetector(onTap: _addContact, child: Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4))), child: const Icon(Icons.add_rounded, color: Colors.redAccent, size: 20))),
              ]),
            ]),
          ),
          const SizedBox(height: 10),
          // Contact list
          ..._contacts.asMap().entries.map((e) => Container(margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.redAccent.withValues(alpha: 0.05), border: Border.all(color: Colors.redAccent.withValues(alpha: 0.15))),
            child: Row(children: [
              Container(width: 36, height: 36, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.redAccent.withValues(alpha: 0.15)), child: Center(child: Text(e.value['name'].toString()[0].toUpperCase(), style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.w800)))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e.value['name'] as String, style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                Text(e.value['phone'] as String, style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11)),
              ])),
              GestureDetector(onTap: () => _deleteContact(e.key), child: const Icon(Icons.close_rounded, color: Colors.white24, size: 18)),
            ]),
          )),
        ]))),
      ])),
    );
  }
}
