import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_call.dart';
import '../services/affection_service.dart';

class ConversationSummaryPage extends StatefulWidget {
  const ConversationSummaryPage({super.key});
  @override
  State<ConversationSummaryPage> createState() =>
      _ConversationSummaryPageState();
}

class _ConversationSummaryPageState extends State<ConversationSummaryPage> {
  final _ctrl = TextEditingController();
  String _summary = '';
  bool _loading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _summarise() async {
    final text = _ctrl.text.trim();
    if (text.length < 30) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Paste a longer conversation, Darling!',
            style: GoogleFonts.outfit()),
        backgroundColor: Colors.pinkAccent,
      ));
      return;
    }
    setState(() {
      _loading = true;
      _summary = '';
    });
    try {
      final prompt = 'You are Zero Two from DARLING in the FRANXX. '
          'Summarise this conversation into clear bullet points:\n\n$text\n\n'
          'Format as:\n'
          '📌 **Key topics discussed**\n'
          '💕 **How we connected** (emotional notes)\n'
          '✅ **Action items or things to follow up**\n\n'
          'Be warm, in Zero Two\'s voice, keep it concise.';
      final reply = await ApiService().sendConversation([
        {'role': 'user', 'content': prompt},
      ]);
      setState(() => _summary = reply);
      AffectionService.instance.addPoints(2);
    } catch (e) {
      setState(
          () => _summary = 'Something went wrong, Darling~ Please try again!');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('CHAT SUMMARY',
            style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.tealAccent.withValues(alpha: 0.07),
              border:
                  Border.all(color: Colors.tealAccent.withValues(alpha: 0.2)),
            ),
            child: Row(children: [
              const Text('📝', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(
                'Paste a long chat or conversation below, and I\'ll summarise it for you, Darling~',
                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12),
              )),
            ]),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white.withValues(alpha: 0.04),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: TextField(
              controller: _ctrl,
              maxLines: 8,
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
              cursorColor: Colors.tealAccent,
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(14),
                hintText: 'Paste conversation here…',
                hintStyle: GoogleFonts.outfit(color: Colors.white24),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                    colors: [Colors.tealAccent.shade700, Colors.cyan.shade600]),
                boxShadow: [
                  BoxShadow(
                      color: Colors.tealAccent.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 4))
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _summarise,
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.summarize_outlined, size: 18),
                label: Text(_loading ? 'Reading everything~' : 'Summarise Chat',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ),
          if (_summary.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white.withValues(alpha: 0.03),
                border:
                    Border.all(color: Colors.tealAccent.withValues(alpha: 0.2)),
              ),
              child: Text(_summary,
                  style: GoogleFonts.outfit(
                      color: Colors.white70, fontSize: 14, height: 1.7)),
            ),
            const SizedBox(height: 8),
            Text('+2 XP 💕',
                style: GoogleFonts.outfit(
                    color: Colors.tealAccent.withValues(alpha: 0.5),
                    fontSize: 11)),
          ],
        ]),
      ),
    );
  }
}
