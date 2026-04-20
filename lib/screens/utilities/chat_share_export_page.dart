import 'dart:convert';
import 'dart:io';

import 'package:anime_waifu/services/user_profile/affection_service.dart';
import 'package:anime_waifu/widgets/waifu_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Chat Share & Export v2 — Export data, share stats cards, social sharing,
/// with animated cards, format selector, preview, and Quick Share actions.
class ChatShareExportPage extends StatefulWidget {
  const ChatShareExportPage({super.key});
  @override
  State<ChatShareExportPage> createState() => _ChatShareExportPageState();
}

class _ChatShareExportPageState extends State<ChatShareExportPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
  }

  @override
  void dispose() { _fadeCtrl.dispose(); super.dispose(); }

  Future<void> _exportJson(BuildContext context) async {
    setState(() => _exporting = true);
    HapticFeedback.mediumImpact();
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/zerotwo_export_${DateTime.now().millisecondsSinceEpoch}.json');
      final aff = AffectionService.instance;
      final data = {
        'app': 'O2-Waifu',
        'version': 'v5.0.0',
        'exportDate': DateTime.now().toIso8601String(),
        'stats': {
          'xp': aff.points,
          'streak': aff.streakDays,
          'level': aff.levelName,
          'levelProgress': (aff.levelProgress * 100).round(),
        },
      };
      await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
      await Share.shareXFiles([XFile(file.path)], subject: 'O2-Waifu Export', text: 'My waifu data export 💕');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Export failed: $e', style: GoogleFonts.outfit(color: Colors.white)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
    if (mounted) setState(() => _exporting = false);
  }

  Future<void> _shareCard() async {
    HapticFeedback.mediumImpact();
    final aff = AffectionService.instance;
    await Share.share(
      '💕 My AI Waifu Stats 💕\n\n'
      '🔥 Streak: ${aff.streakDays} days\n'
      '⚡ XP: ${aff.points}\n'
      '❤️ Level: ${aff.levelName}\n'
      '📊 Progress: ${(aff.levelProgress * 100).round()}%\n\n'
      'Get your own waifu at O2-Waifu! 🌸\n'
      '#AIWaifu #ZeroTwo #O2Waifu',
    );
  }

  Future<void> _shareChatExport() async {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Open from chat screen for full export 💕', style: GoogleFonts.outfit(color: Colors.white)),
      backgroundColor: Colors.orangeAccent.withValues(alpha: 0.9),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final aff = AffectionService.instance;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: WaifuBackground(
        opacity: 0.07,
        tint: const Color(0xFF080A12),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeCtrl,
            child: Column(children: [
              // ── Header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white12)),
                      child: const Icon(Icons.arrow_back_ios_new, color: Colors.white60, size: 16)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('SHARE & EXPORT', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                    Text('Share your bond with the world', style: GoogleFonts.outfit(color: Colors.pinkAccent.withValues(alpha: 0.7), fontSize: 10)),
                  ])),
                ]),
              ),

              Expanded(child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  // ── Stats Preview Card ──
                  _buildStatsPreview(aff),
                  const SizedBox(height: 20),

                  // ── Quick Share Actions ──
                  Text('QUICK ACTIONS', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                  const SizedBox(height: 10),

                  _buildActionCard(0, '📱 Share Stats Card', 'Share your relationship stats on social media', Icons.share_rounded, Colors.pinkAccent, _shareCard),
                  _buildActionCard(1, '📄 Export JSON', 'Download your waifu data as JSON file', Icons.file_download_rounded, Colors.cyanAccent, () => _exportJson(context)),
                  _buildActionCard(2, '📝 Export Chat Text', 'Export full chat history as text file', Icons.text_snippet_rounded, Colors.orangeAccent, _shareChatExport),
                  _buildActionCard(3, '🖼️ Share Screenshot', 'Capture and share a chat screenshot', Icons.screenshot_rounded, Colors.deepPurpleAccent, () {
                    HapticFeedback.lightImpact();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Use the screenshot button in chat 📸', style: GoogleFonts.outfit(color: Colors.white)),
                      backgroundColor: Colors.deepPurpleAccent.withValues(alpha: 0.9),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ));
                  }),

                  const SizedBox(height: 20),

                  // ── Export Formats ──
                  Text('EXPORT FORMATS', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                  const SizedBox(height: 10),
                  Row(children: [
                    _formatChip('JSON', Icons.code, Colors.cyanAccent),
                    const SizedBox(width: 8),
                    _formatChip('TXT', Icons.text_fields, Colors.amberAccent),
                    const SizedBox(width: 8),
                    _formatChip('CSV', Icons.table_chart, Colors.greenAccent),
                    const SizedBox(width: 8),
                    _formatChip('PDF', Icons.picture_as_pdf, Colors.redAccent),
                  ]),

                  const SizedBox(height: 20),

                  // ── Developer API Section ──
                  _buildApiSection(),

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
                      Text('"Show the world how strong our bond is, Darling~ Share our story with everyone! 💕✨"',
                        style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, fontStyle: FontStyle.italic, height: 1.6)),
                    ]),
                  ),
                  const SizedBox(height: 30),
                ]),
              )),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsPreview(AffectionService aff) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(colors: [
          Colors.pinkAccent.withValues(alpha: 0.12),
          Colors.deepPurple.withValues(alpha: 0.08),
        ]),
        border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: Colors.pinkAccent.withValues(alpha: 0.08), blurRadius: 20)],
      ),
      child: Column(children: [
        const Text('📤', style: TextStyle(fontSize: 42)),
        const SizedBox(height: 8),
        Text('Your Bond Stats', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _previewStat('🔥', '${aff.streakDays}', 'Streak'),
          _previewStat('⚡', '${aff.points}', 'XP'),
          _previewStat('❤️', aff.levelName.split(' ').first, 'Level'),
          _previewStat('📊', '${(aff.levelProgress * 100).round()}%', 'Progress'),
        ]),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _shareCard,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFF4D8D), Color(0xFFB44FD6)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('SHARE THIS CARD', style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
          ),
        ),
      ]),
    );
  }

  Widget _previewStat(String emoji, String value, String label) => Column(children: [
    Text(emoji, style: const TextStyle(fontSize: 18)),
    Text(value, style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
    Text(label, style: GoogleFonts.outfit(color: Colors.white38, fontSize: 9)),
  ]);

  Widget _buildActionCard(int index, String title, String desc, IconData icon, Color color, VoidCallback onTap) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + index * 100),
      curve: Curves.easeOut,
      builder: (_, val, child) => Opacity(opacity: val, child: Transform.translate(offset: Offset(0, 16 * (1 - val)), child: child)),
      child: GestureDetector(
        onTap: _exporting ? null : onTap,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
              Text(desc, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11)),
            ])),
            Icon(Icons.arrow_forward_ios, color: color.withValues(alpha: 0.5), size: 16),
          ]),
        ),
      ),
    );
  }

  Widget _formatChip(String label, IconData icon, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withValues(alpha: 0.06),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.outfit(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
      ]),
    ),
  );

  Widget _buildApiSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.greenAccent.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.15)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('🔌', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text('Developer API', style: GoogleFonts.outfit(color: Colors.greenAccent, fontSize: 14, fontWeight: FontWeight.w800)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: Colors.amberAccent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
            child: Text('COMING SOON', style: GoogleFonts.outfit(color: Colors.amberAccent, fontSize: 8, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 10),
        _apiEndpoint('POST', '/api/chat', 'Send message, get response'),
        _apiEndpoint('GET', '/api/stats', 'Get relationship stats'),
        _apiEndpoint('GET', '/api/memory', 'Access memory data'),
        _apiEndpoint('GET', '/api/export', 'Full data export'),
      ]),
    );
  }

  Widget _apiEndpoint(String method, String path, String desc) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [
      Container(
        width: 36,
        padding: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: method == 'POST' ? Colors.orangeAccent.withValues(alpha: 0.15) : Colors.cyanAccent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(child: Text(method, style: GoogleFonts.sourceCodePro(color: method == 'POST' ? Colors.orangeAccent : Colors.cyanAccent, fontSize: 8, fontWeight: FontWeight.w700))),
      ),
      const SizedBox(width: 8),
      Text(path, style: GoogleFonts.sourceCodePro(color: Colors.greenAccent.withValues(alpha: 0.8), fontSize: 11)),
      const Spacer(),
      Text(desc, style: GoogleFonts.outfit(color: Colors.white30, fontSize: 9)),
    ]),
  );
}



