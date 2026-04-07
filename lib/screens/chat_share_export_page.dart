import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';


/// Chat Share & Export — Share chat screenshots, export JSON, and create shareable cards.
class ChatShareExportPage extends StatelessWidget {
  const ChatShareExportPage({super.key});

  Future<void> _exportJson(BuildContext context) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/zerotwo_export_${DateTime.now().millisecondsSinceEpoch}.json');
      final data = {
        'app': 'O2-Waifu',
        'version': 'v5.0.0',
        'exportDate': DateTime.now().toIso8601String(),
        'stats': {'totalSessions': 42, 'totalMessages': 1337, 'streak': 7},
      };
      await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
      await Share.shareXFiles([XFile(file.path)], subject: 'O2-Waifu Export', text: 'My waifu data export 💕');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  Future<void> _shareCard(BuildContext context) async {
    await Share.share('💕 My AI Waifu Stats 💕\n\n'
        '🔥 Streak: 7 days\n'
        '💬 Messages: 1337\n'
        '❤️ Level: Soulmate\n'
        '✨ XP: 2500\n\n'
        'Get your own waifu at O2-Waifu! 🌸\n'
        '#AIWaifu #ZeroTwo #O2Waifu');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70), onPressed: () => Navigator.pop(context)),
        title: Text('SHARE & EXPORT', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          const Text('📤', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text('Share Your Bond', style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
          Text('Export data or share with friends', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 24),
          _actionCard(context, '📱 Share Stats Card', 'Share your relationship stats on social media',
              Icons.share_rounded, Colors.pinkAccent, () => _shareCard(context)),
          _actionCard(context, '📄 Export JSON', 'Download your chat data as JSON file',
              Icons.file_download_rounded, Colors.cyanAccent, () => _exportJson(context)),
          _actionCard(context, '📝 Export Chat Text', 'Export full chat history as text file',
              Icons.text_snippet_rounded, Colors.orangeAccent, () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Open from chat screen for full export 💕')));
          }),
          const SizedBox(height: 24),
          // API info
          Container(
            width: double.infinity, padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.2)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('🔌 Developer API', style: GoogleFonts.outfit(color: Colors.greenAccent, fontSize: 14, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text('Coming soon: REST API for developers to integrate O2-Waifu into their apps.\n\n'
                  'Endpoints:\n'
                  '• POST /api/chat — Send message, get response\n'
                  '• GET /api/stats — Get relationship stats\n'
                  '• GET /api/memory — Access memory data',
                  style: GoogleFonts.sourceCodePro(color: Colors.greenAccent.withValues(alpha: 0.7), fontSize: 11, height: 1.5)),
            ]),
          ),
          const SizedBox(height: 30),
        ]),
      ),
    );
  }

  Widget _actionCard(BuildContext ctx, String title, String desc, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity, margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
            Text(desc, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11)),
          ])),
          Icon(Icons.arrow_forward_ios, color: color.withValues(alpha: 0.5), size: 16),
        ]),
      ),
    );
  }
}
