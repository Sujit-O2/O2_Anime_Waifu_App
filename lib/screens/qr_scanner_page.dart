import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});
  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  // Scanner
  MobileScannerController? _camCtrl;
  String? _scannedData;
  String _scannedType = 'text';
  List<Map<String, dynamic>> _history = [];
  bool _scannerActive = false;
  // Generator
  final _genCtrl = TextEditingController();
  int _genType = 0;
  final _ssidCtrl = TextEditingController();
  final _wifiPassCtrl = TextEditingController();
  String? _generatedData;

  static const _genTypes = ['📝 Text/URL', '📶 Wi-Fi', '👤 Contact'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() { _tabCtrl.dispose(); _camCtrl?.dispose(); _genCtrl.dispose(); _ssidCtrl.dispose(); _wifiPassCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    try { _history = (jsonDecode(p.getString('qr_history_data') ?? '[]') as List).cast<Map<String, dynamic>>(); } catch (_) {}
    setState(() {});
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('qr_history_data', jsonEncode(_history.take(30).toList()));
  }

  void _startScanner() {
    _camCtrl = MobileScannerController(detectionSpeed: DetectionSpeed.normal, facing: CameraFacing.back);
    setState(() { _scannerActive = true; _scannedData = null; });
  }

  void _stopScanner() {
    _camCtrl?.dispose();
    _camCtrl = null;
    setState(() => _scannerActive = false);
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scannedData != null) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    final data = barcode.rawValue!;
    String type = 'text';
    if (RegExp(r'https?://').hasMatch(data)) {
      type = 'url';
    } else if (data.startsWith('WIFI:')) {
      type = 'wifi';
    } else if (data.startsWith('BEGIN:VCARD')) {
      type = 'contact';
    } else if (RegExp(r'^\+?[\d\s-]{7,15}$').hasMatch(data.trim())) {
      type = 'phone';
    }

    HapticFeedback.heavyImpact();
    _stopScanner();
    setState(() { _scannedData = data; _scannedType = type; });
    _history.insert(0, {'data': data, 'type': type, 'time': DateTime.now().millisecondsSinceEpoch});
    _save();
  }

  void _actOnScan() async {
    if (_scannedData == null) return;
    switch (_scannedType) {
      case 'url':
        try { await launchUrl(Uri.parse(_scannedData!), mode: LaunchMode.externalApplication); } catch (_) {}
        break;
      default:
        Clipboard.setData(ClipboardData(text: _scannedData!));
        _snack('📋 Copied!', Colors.tealAccent);
    }
  }

  void _generateQr() {
    String data;
    if (_genType == 0) {
      data = _genCtrl.text.trim();
    } else if (_genType == 1) {
      data = 'WIFI:T:WPA;S:${_ssidCtrl.text};P:${_wifiPassCtrl.text};;';
    } else {
      data = 'BEGIN:VCARD\nVERSION:3.0\nFN:${_genCtrl.text}\nEND:VCARD';
    }
    if (data.isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() => _generatedData = data);
  }

  IconData _typeIcon(String type) {
    switch (type) { case 'url': return Icons.link_rounded; case 'wifi': return Icons.wifi_rounded; case 'contact': return Icons.person_rounded; case 'phone': return Icons.phone_rounded; default: return Icons.text_snippet_rounded; }
  }

  Color _typeColor(String type) {
    switch (type) { case 'url': return Colors.lightBlueAccent; case 'wifi': return Colors.greenAccent; case 'contact': return Colors.purpleAccent; case 'phone': return Colors.orangeAccent; default: return Colors.white54; }
  }

  String _timeAgo(int ms) { final diff = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ms)); if (diff.inDays > 0) return '${diff.inDays}d'; if (diff.inHours > 0) return '${diff.inHours}h'; return '${diff.inMinutes}m'; }
  void _snack(String msg, Color c) { if (!mounted) return; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg, style: GoogleFonts.outfit(color: Colors.black87, fontWeight: FontWeight.w700)), backgroundColor: c, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 0), child: Row(children: [
          GestureDetector(onTap: () { _stopScanner(); Navigator.pop(context); }, child: Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white12)), child: const Icon(Icons.arrow_back_ios_new, color: Colors.white60, size: 16))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('QR TOOLS', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            Text('Scan & generate QR codes', style: GoogleFonts.outfit(color: Colors.indigoAccent, fontSize: 11)),
          ])),
        ])),
        const SizedBox(height: 12),
        // Tabs
        Container(margin: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.white.withValues(alpha: 0.04)),
          child: TabBar(controller: _tabCtrl, indicator: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.indigoAccent.withValues(alpha: 0.2)),
            labelColor: Colors.indigoAccent, unselectedLabelColor: Colors.white38, labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13),
            dividerColor: Colors.transparent, indicatorSize: TabBarIndicatorSize.tab,
            tabs: const [Tab(text: '📷 Scanner'), Tab(text: '✨ Generator')])),
        const SizedBox(height: 12),
        Expanded(child: TabBarView(controller: _tabCtrl, children: [_buildScannerTab(), _buildGeneratorTab()])),
      ])),
    );
  }

  Widget _buildScannerTab() {
    return SingleChildScrollView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), child: Column(children: [
      // Scanner area
      if (_scannerActive && _camCtrl != null)
        ClipRRect(borderRadius: BorderRadius.circular(18), child: SizedBox(height: 280, child: MobileScanner(controller: _camCtrl!, onDetect: _onDetect)))
      else
        GestureDetector(onTap: _startScanner, child: Container(height: 200, width: double.infinity,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: Colors.indigoAccent.withValues(alpha: 0.08), border: Border.all(color: Colors.indigoAccent.withValues(alpha: 0.3), width: 2)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.qr_code_scanner_rounded, color: Colors.indigoAccent, size: 48), const SizedBox(height: 12),
            Text('TAP TO SCAN', style: GoogleFonts.outfit(color: Colors.indigoAccent, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1)),
            Text('Point camera at QR code or barcode', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11)),
          ]))),
      const SizedBox(height: 14),

      // Scanned result
      if (_scannedData != null) Container(width: double.infinity, padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: _typeColor(_scannedType).withValues(alpha: 0.06), border: Border.all(color: _typeColor(_scannedType).withValues(alpha: 0.25))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(_typeIcon(_scannedType), color: _typeColor(_scannedType), size: 20), const SizedBox(width: 8),
            Text(_scannedType.toUpperCase(), style: GoogleFonts.outfit(color: _typeColor(_scannedType), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
          ]),
          const SizedBox(height: 8),
          SelectableText(_scannedData!, style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, height: 1.4)),
          const SizedBox(height: 10),
          Row(children: [
            GestureDetector(onTap: _actOnScan, child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: _typeColor(_scannedType).withValues(alpha: 0.15), border: Border.all(color: _typeColor(_scannedType).withValues(alpha: 0.4))),
              child: Text(_scannedType == 'url' ? '🌐 Open' : '📋 Copy', style: GoogleFonts.outfit(color: _typeColor(_scannedType), fontSize: 12, fontWeight: FontWeight.w700)))),
            const SizedBox(width: 8),
            GestureDetector(onTap: () { Clipboard.setData(ClipboardData(text: _scannedData!)); _snack('📋 Copied!', Colors.tealAccent); },
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.white.withValues(alpha: 0.06)),
                child: Text('Copy', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w700)))),
            const SizedBox(width: 8),
            GestureDetector(onTap: _startScanner, child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.white.withValues(alpha: 0.06)),
              child: Text('Scan Again', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w700)))),
          ]),
        ]),
      ),

      // History
      if (_history.isNotEmpty) ...[
        const SizedBox(height: 18),
        Align(alignment: Alignment.centerLeft, child: Text('SCAN HISTORY', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1))),
        const SizedBox(height: 8),
        ..._history.take(10).map((h) => GestureDetector(onTap: () { Clipboard.setData(ClipboardData(text: h['data']?.toString() ?? '')); _snack('📋 Copied!', Colors.tealAccent); },
          child: Container(margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Icon(_typeIcon(h['type']?.toString() ?? 'text'), color: _typeColor(h['type']?.toString() ?? 'text'), size: 16), const SizedBox(width: 10),
              Expanded(child: Text(h['data']?.toString() ?? '', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11), overflow: TextOverflow.ellipsis)),
              Text(_timeAgo(h['time'] as int), style: GoogleFonts.outfit(color: Colors.white24, fontSize: 9)),
            ]),
          ),
        )),
      ],
    ]));
  }

  Widget _buildGeneratorTab() {
    return SingleChildScrollView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), child: Column(children: [
      // Type selector
      SizedBox(height: 36, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: _genTypes.length, itemBuilder: (c, i) => GestureDetector(onTap: () => setState(() { _genType = i; _generatedData = null; }),
        child: AnimatedContainer(duration: const Duration(milliseconds: 150), margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: _genType == i ? Colors.indigoAccent.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.04), border: Border.all(color: _genType == i ? Colors.indigoAccent : Colors.white12)),
          child: Text(_genTypes[i], style: GoogleFonts.outfit(color: _genType == i ? Colors.indigoAccent : Colors.white38, fontSize: 12, fontWeight: FontWeight.w600)))))),
      const SizedBox(height: 14),

      // Input fields based on type
      if (_genType == 0) TextField(controller: _genCtrl, maxLines: 3, style: GoogleFonts.outfit(color: Colors.white, fontSize: 13), cursorColor: Colors.indigoAccent,
        decoration: InputDecoration(hintText: 'Enter text or URL...', hintStyle: GoogleFonts.outfit(color: Colors.white30, fontSize: 12), filled: true, fillColor: Colors.white.withValues(alpha: 0.04), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none), contentPadding: const EdgeInsets.all(14))),

      if (_genType == 1) ...[
        TextField(controller: _ssidCtrl, style: GoogleFonts.outfit(color: Colors.white, fontSize: 13), cursorColor: Colors.indigoAccent,
          decoration: InputDecoration(hintText: 'Wi-Fi Network Name (SSID)', hintStyle: GoogleFonts.outfit(color: Colors.white30, fontSize: 12), filled: true, fillColor: Colors.white.withValues(alpha: 0.04), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none), isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12))),
        const SizedBox(height: 8),
        TextField(controller: _wifiPassCtrl, obscureText: true, style: GoogleFonts.outfit(color: Colors.white, fontSize: 13), cursorColor: Colors.indigoAccent,
          decoration: InputDecoration(hintText: 'Password', hintStyle: GoogleFonts.outfit(color: Colors.white30, fontSize: 12), filled: true, fillColor: Colors.white.withValues(alpha: 0.04), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none), isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12))),
      ],

      if (_genType == 2) TextField(controller: _genCtrl, style: GoogleFonts.outfit(color: Colors.white, fontSize: 13), cursorColor: Colors.indigoAccent,
        decoration: InputDecoration(hintText: 'Full Name', hintStyle: GoogleFonts.outfit(color: Colors.white30, fontSize: 12), filled: true, fillColor: Colors.white.withValues(alpha: 0.04), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none), isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12))),

      const SizedBox(height: 12),
      GestureDetector(onTap: _generateQr, child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: Colors.indigoAccent.withValues(alpha: 0.15), border: Border.all(color: Colors.indigoAccent.withValues(alpha: 0.4))),
        child: Center(child: Text('✨ GENERATE QR CODE', style: GoogleFonts.outfit(color: Colors.indigoAccent, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1))))),
      const SizedBox(height: 20),

      // Generated QR
      if (_generatedData != null) Container(padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: Colors.white, boxShadow: [BoxShadow(color: Colors.indigoAccent.withValues(alpha: 0.2), blurRadius: 20)]),
        child: QrImageView(data: _generatedData!, version: QrVersions.auto, size: 200, backgroundColor: Colors.white, eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF0A0A16)), dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Color(0xFF0A0A16)))),
    ]));
  }
}
