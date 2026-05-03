import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/smart_features/inbox_copilot_service.dart';

class InboxCopilotPage extends StatefulWidget {
  const InboxCopilotPage({super.key});

  @override
  State<InboxCopilotPage> createState() => _InboxCopilotPageState();
}

class _InboxCopilotPageState extends State<InboxCopilotPage>
    with SingleTickerProviderStateMixin {
  final _service = InboxCopilotService.instance;
  late TabController _tabs;
  final _emailCtrl = TextEditingController();
  bool _analyzing = false;
  bool _initialized = false;

  static const _bg = Color(0xFF0A0B14);
  static const _accent = Color(0xFF00BCD4);

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _init();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await _service.initialize();
    if (mounted) setState(() => _initialized = true);
  }

  Future<void> _analyzeInbox() async {
    if (_emailCtrl.text.trim().isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() => _analyzing = true);

    _service.pasteEmails(_emailCtrl.text);
    await _service.summarizeEmails();

    if (mounted) {
      setState(() => _analyzing = false);
      _emailCtrl.clear();
      if (_service.getEmailSummaries().isNotEmpty) {
        _tabs.animateTo(0);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            'Analyzed ${_service.getEmailSummaries().length} emails',
            style: GoogleFonts.outfit(color: Colors.white),
          ),
          backgroundColor: _accent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1B2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Clear All Emails?',
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text('This will remove all analyzed emails, action items, and suggested replies.',
            style: GoogleFonts.outfit(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.outfit(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Clear',
                style: GoogleFonts.outfit(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      HapticFeedback.mediumImpact();
      await _service.clearInbox();
      if (mounted) setState(() {});
    }
  }

  Color _sentimentColor(String sentiment) {
    switch (sentiment.toLowerCase()) {
      case 'positive':
        return Colors.greenAccent;
      case 'negative':
        return Colors.redAccent;
      case 'urgent':
        return Colors.orangeAccent;
      default:
        return Colors.white38;
    }
  }

  String _sentimentEmoji(String sentiment) {
    switch (sentiment.toLowerCase()) {
      case 'positive':
        return '😊';
      case 'negative':
        return '😟';
      case 'urgent':
        return '🔥';
      default:
        return '😐';
    }
  }

  Color _priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.redAccent;
      case 'medium':
        return Colors.amberAccent;
      case 'low':
        return Colors.greenAccent;
      default:
        return Colors.white38;
    }
  }

  String _priorityIcon(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return '🔴';
      case 'medium':
        return '🟡';
      case 'low':
        return '🟢';
      default:
        return '⚪';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white60, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('📬 Inbox Copilot',
            style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: Colors.white54, size: 20),
            onPressed: _service.getEmailSummaries().isEmpty ? null : _clearAll,
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: _accent,
          labelColor: _accent,
          unselectedLabelColor: Colors.white38,
          labelStyle:
              GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: 'Summaries'),
            Tab(text: 'Action Items'),
            Tab(text: 'Replies'),
          ],
        ),
      ),
      body: _initialized
          ? TabBarView(
              controller: _tabs,
              children: [
                _buildSummariesTab(),
                _buildActionItemsTab(),
                _buildRepliesTab(),
              ],
            )
          : const Center(
              child: CircularProgressIndicator(color: _accent),
            ),
    );
  }

  Widget _buildSummariesTab() {
    final summaries = _service.getEmailSummaries();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.mail_outline_rounded,
                    color: _accent, size: 18),
                const SizedBox(width: 8),
                Text('Paste Emails',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
              ]),
              const SizedBox(height: 12),
              TextField(
                controller: _emailCtrl,
                maxLines: 6,
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText:
                      'Paste your emails here...\n\nFrom: sender@example.com\nSubject: Meeting Tomorrow\nBody: Hi, can we meet tomorrow at 3 PM?',
                  hintStyle:
                      GoogleFonts.outfit(color: Colors.white30, fontSize: 12),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.03),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Colors.white.withValues(alpha: 0.06))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: _accent.withValues(alpha: 0.5))),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _analyzing ? null : _analyzeInbox,
                  icon: _analyzing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child:
                              CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: Text(_analyzing ? 'Analyzing...' : 'Analyze Inbox',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (summaries.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(children: [
              const Text('📬', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              Text('No emails analyzed yet',
                  style: GoogleFonts.outfit(
                      color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 8),
              Text('Paste your emails above and tap Analyze',
                  style: GoogleFonts.outfit(color: Colors.white38, fontSize: 13)),
            ]),
          ),

        if (summaries.isNotEmpty)
          Text('Email Summaries (${summaries.length})',
              style: GoogleFonts.outfit(
                  color: Colors.white54,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 0.8)),

        const SizedBox(height: 8),

        ...summaries.map((email) => _emailCard(email)),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _emailCard(EmailSummary email) {
    final sentimentColor = _sentimentColor(email.sentiment);
    final isAnalyzed = email.summary.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isAnalyzed
                ? sentimentColor.withValues(alpha: 0.2)
                : Colors.white12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: sentimentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.person_outline_rounded,
                      color: sentimentColor, size: 14),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(email.from,
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                      Text(email.subject,
                          style: GoogleFonts.outfit(
                              color: Colors.white54,
                              fontSize: 11,
                              fontStyle: FontStyle.italic),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: sentimentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_sentimentEmoji(email.sentiment),
                          style: const TextStyle(fontSize: 10)),
                      const SizedBox(width: 4),
                      Text(email.sentiment,
                          style: GoogleFonts.outfit(
                              color: sentimentColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
            if (isAnalyzed) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: _accent.withValues(alpha: 0.15)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline_rounded,
                        color: _accent, size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(email.summary,
                          style: GoogleFonts.outfit(
                              color: Colors.white70,
                              fontSize: 12,
                              height: 1.4)),
                    ),
                  ],
                ),
              ),
              if (email.actionItems.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text('Action Items:',
                    style: GoogleFonts.outfit(
                        color: Colors.white54,
                        fontWeight: FontWeight.w600,
                        fontSize: 11)),
                const SizedBox(height: 6),
                ...email.actionItems.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('•',
                              style: TextStyle(
                                  color: _accent, fontSize: 14, height: 1.2)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(item,
                                style: GoogleFonts.outfit(
                                    color: Colors.white70, fontSize: 12)),
                          ),
                        ],
                      ),
                    )),
              ],
            ] else ...[
              const SizedBox(height: 12),
              Center(
                child: Text('Tap Analyze to summarize',
                    style: GoogleFonts.outfit(
                        color: Colors.white30,
                        fontStyle: FontStyle.italic,
                        fontSize: 12)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionItemsTab() {
    final actionItems = _service.getActionItems();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (actionItems.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(children: [
              const Text('✅', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              Text('No action items',
                  style: GoogleFonts.outfit(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                      fontSize: 16)),
              const SizedBox(height: 8),
              Text('Analyze emails to extract action items',
                  style: GoogleFonts.outfit(color: Colors.white38, fontSize: 13)),
            ]),
          ),

        if (actionItems.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _accent.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.flag_rounded, color: _accent, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('${actionItems.length} action items found',
                      style: GoogleFonts.outfit(
                          color: Colors.white70, fontSize: 13, height: 1.4)),
                ),
              ],
            ),
          ),

        const SizedBox(height: 12),

        ...actionItems.map((item) {
          final pColor = _priorityColor(item.priority);
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: pColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Text(_priorityIcon(item.priority),
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.description,
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                      const SizedBox(height: 4),
                      Text('From: ${item.from}',
                          style: GoogleFonts.outfit(
                              color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: pColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(item.priority,
                      style: GoogleFonts.outfit(
                          color: pColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 10)),
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildRepliesTab() {
    final replies = _service.getSuggestedReplies();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (replies.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(children: [
              const Text('💬', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              Text('No suggested replies',
                  style: GoogleFonts.outfit(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                      fontSize: 16)),
              const SizedBox(height: 8),
              Text('Analyze emails to generate reply suggestions',
                  style: GoogleFonts.outfit(color: Colors.white38, fontSize: 13)),
            ]),
          ),

        if (replies.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _accent.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.reply_rounded, color: _accent, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('${replies.length} suggested replies ready',
                      style: GoogleFonts.outfit(
                          color: Colors.white70, fontSize: 13, height: 1.4)),
                ),
              ],
            ),
          ),

        const SizedBox(height: 12),

        ...replies.map((reply) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.reply_rounded,
                            color: _accent, size: 14),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('To: ${reply.to}',
                                style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                            Text(reply.subject,
                                style: GoogleFonts.outfit(
                                    color: Colors.white54, fontSize: 11)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(reply.tone,
                            style: GoogleFonts.outfit(
                                color: Colors.white54, fontSize: 10)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06)),
                    ),
                    child: Text(reply.body,
                        style: GoogleFonts.outfit(
                            color: Colors.white70,
                            fontSize: 12,
                            height: 1.5)),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        Clipboard.setData(ClipboardData(text: reply.body));
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Reply copied!',
                              style: GoogleFonts.outfit(color: Colors.white)),
                          backgroundColor: _accent,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          duration: const Duration(seconds: 1),
                        ));
                      },
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: Text('Copy Reply',
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _accent,
                        side: BorderSide(
                            color: _accent.withValues(alpha: 0.4)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),

        const SizedBox(height: 32),
      ],
    );
  }
}
