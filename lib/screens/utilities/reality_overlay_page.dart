import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RealityOverlayPage extends StatefulWidget {
  const RealityOverlayPage({super.key});
  @override
  State<RealityOverlayPage> createState() => _RealityOverlayPageState();
}

class _RealityOverlayPageState extends State<RealityOverlayPage>
    with TickerProviderStateMixin {
  static const _accent = Color(0xFF00FF88);
  static const _bg = Color(0xFF060A06);

  late AnimationController _scanCtrl;
  late Animation<double> _scanAnim;

  bool _cameraActive = false;
  String _detectedObject = '';
  Map<String, dynamic>? _overlayData;
  String _mode = 'Auto Detect';
  Timer? _scanTimer;

  static const _modes = ['Auto Detect', 'Book Scanner', 'Food Analyzer', 'Place Info', 'Text Reader'];

  static const _simulatedObjects = {
    'Book Scanner': {
      'object': '📚 "Atomic Habits" by James Clear',
      'data': {
        'title': 'Atomic Habits',
        'author': 'James Clear',
        'rating': '4.8/5 ⭐',
        'summary': 'A practical guide to building good habits and breaking bad ones through tiny 1% improvements.',
        'key_idea': 'Systems > Goals. Focus on who you want to become, not what you want to achieve.',
        'read_time': '5h 30min',
      },
    },
    'Food Analyzer': {
      'object': '🍕 Pizza Margherita (1 slice)',
      'data': {
        'calories': '285 kcal',
        'protein': '12g',
        'carbs': '36g',
        'fat': '10g',
        'verdict': '⚠️ Moderate — okay for cheat day',
        'healthier_alt': 'Cauliflower crust pizza (180 kcal)',
      },
    },
    'Place Info': {
      'object': '🏛️ Detected: Library / Study Space',
      'data': {
        'type': 'Public Library',
        'rating': '4.6/5 ⭐',
        'hours': 'Open until 9:00 PM',
        'wifi': 'Free WiFi available',
        'noise': 'Quiet zone',
        'tip': 'Best seats: 2nd floor near windows',
      },
    },
    'Text Reader': {
      'object': '📄 Text detected (English)',
      'data': {
        'word_count': '342 words',
        'reading_time': '~2 minutes',
        'language': 'English',
        'sentiment': 'Informative / Neutral',
        'summary': 'The text discusses productivity techniques and time management strategies for knowledge workers.',
        'action': 'Save to notes',
      },
    },
    'Auto Detect': {
      'object': '🔍 Scanning environment...',
      'data': {
        'detected': 'Multiple objects in frame',
        'confidence': '87%',
        'suggestion': 'Switch to specific mode for detailed analysis',
        'objects': 'Book, Coffee cup, Laptop, Notebook',
      },
    },
  };

  @override
  void initState() {
    super.initState();
    _scanCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _scanAnim = Tween<double>(begin: 0.0, end: 1.0).animate(_scanCtrl);
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    _scanTimer?.cancel();
    super.dispose();
  }

  void _toggleCamera() {
    setState(() {
      _cameraActive = !_cameraActive;
      if (!_cameraActive) {
        _detectedObject = '';
        _overlayData = null;
        _scanTimer?.cancel();
      } else {
        _startScanning();
      }
    });
  }

  void _startScanning() {
    _scanTimer?.cancel();
    _scanTimer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted || !_cameraActive) return;
      final obj = _simulatedObjects[_mode]!;
      setState(() {
        _detectedObject = obj['object'] as String;
        _overlayData = obj['data'] as Map<String, dynamic>;
      });
    });
  }

  void _setMode(String m) {
    setState(() { _mode = m; _detectedObject = ''; _overlayData = null; });
    if (_cameraActive) _startScanning();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        title: Text('🧿 Reality Overlay', style: GoogleFonts.orbitron(color: _accent, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: _accent),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _cameraView(),
          const SizedBox(height: 16),
          _modeSelector(),
          const SizedBox(height: 16),
          _cameraButton(),
          if (_overlayData != null) ...[const SizedBox(height: 16), _overlayCard()],
          const SizedBox(height: 16),
          _infoCard(),
        ]),
      ),
    );
  }

  Widget _cameraView() => AnimatedBuilder(
    animation: _scanAnim,
    builder: (_, __) => Container(
      height: 220,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0F0A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cameraActive ? _accent.withAlpha(180) : Colors.white12),
      ),
      child: Stack(children: [
        // Simulated camera feed
        if (_cameraActive)
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0A1A0A), Color(0xFF0A0F0A)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
        // Scan line
        if (_cameraActive)
          Positioned(
            top: 220 * _scanAnim.value - 1,
            left: 0, right: 0,
            child: Container(height: 2, color: _accent.withAlpha(120)),
          ),
        // Corner brackets
        if (_cameraActive) ...[
          _corner(0, 0, true, true),
          _corner(0, null, true, false),
          _corner(null, 0, false, true),
          _corner(null, null, false, false),
        ],
        // Center content
        Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(_cameraActive ? Icons.camera : Icons.camera_alt,
                color: _cameraActive ? _accent : Colors.white24, size: 40),
            const SizedBox(height: 8),
            Text(
              _cameraActive
                  ? (_detectedObject.isEmpty ? 'Scanning...' : _detectedObject)
                  : 'Camera Off',
              style: GoogleFonts.orbitron(
                  color: _cameraActive ? _accent : Colors.white24, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ]),
        ),
      ]),
    ),
  );

  Widget _corner(double? top, double? bottom, bool left, bool right) => Positioned(
    top: top, bottom: bottom,
    left: left ? 12 : null, right: right ? null : 12,
    child: Container(
      width: 20, height: 20,
      decoration: BoxDecoration(
        border: Border(
          top: top != null ? const BorderSide(color: _accent, width: 2) : BorderSide.none,
          bottom: bottom != null ? const BorderSide(color: _accent, width: 2) : BorderSide.none,
          left: left ? const BorderSide(color: _accent, width: 2) : BorderSide.none,
          right: !left ? const BorderSide(color: _accent, width: 2) : BorderSide.none,
        ),
      ),
    ),
  );

  Widget _modeSelector() => _card(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label('SCAN MODE'),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8, runSpacing: 8,
        children: _modes.map((m) {
          final sel = m == _mode;
          return GestureDetector(
            onTap: () => _setMode(m),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: sel ? _accent.withAlpha(30) : Colors.white10,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: sel ? _accent : Colors.white24),
              ),
              child: Text(m, style: TextStyle(color: sel ? _accent : Colors.white54, fontSize: 11, fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
            ),
          );
        }).toList(),
      ),
    ]),
  );

  Widget _cameraButton() => SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: _toggleCamera,
      icon: Icon(_cameraActive ? Icons.camera_alt : Icons.camera),
      label: Text(_cameraActive ? '⏹ Stop Camera' : '📷 Start Camera',
          style: GoogleFonts.orbitron(fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: _cameraActive ? Colors.red : _accent,
        foregroundColor: _cameraActive ? Colors.white : Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );

  Widget _overlayCard() => Container(
    width: double.infinity, padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _accent.withAlpha(15), borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _accent.withAlpha(100)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label('OVERLAY DATA'),
      const SizedBox(height: 10),
      ..._overlayData!.entries.map((e) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${e.key}: ', style: const TextStyle(color: Colors.white38, fontSize: 12)),
          Expanded(child: Text(e.value.toString(), style: const TextStyle(color: _accent, fontSize: 12, fontWeight: FontWeight.bold))),
        ]),
      )),
    ]),
  );

  Widget _infoCard() => _card(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label('HOW IT WORKS'),
      const SizedBox(height: 8),
      const Text(
        '• Point camera at any object, text, or place\n'
        '• AI identifies and overlays relevant information\n'
        '• Book: summary + key ideas\n'
        '• Food: calories + nutrition facts\n'
        '• Place: hours, rating, tips\n'
        '• Text: summary + sentiment analysis',
        style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.6),
      ),
    ]),
  );

  Widget _card({required Widget child}) => Container(
    width: double.infinity, padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF080E08), borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _accent.withAlpha(40)),
    ),
    child: child,
  );

  Widget _label(String t) => Text(t, style: GoogleFonts.orbitron(color: _accent, fontSize: 11, fontWeight: FontWeight.bold));
}
