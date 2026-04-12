import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:anime_waifu/utils/api_call.dart';
import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:anime_waifu/services/user_profile/affection_service.dart';

class RelationshipAdvicePage extends StatefulWidget {
  const RelationshipAdvicePage({super.key});

  @override
  State<RelationshipAdvicePage> createState() => _RelationshipAdvicePageState();
}

class _RelationshipAdvicePageState extends State<RelationshipAdvicePage> with SingleTickerProviderStateMixin {
  static const String _historyKey = 'relationship_advice_history_v2';

  final TextEditingController _ctrl = TextEditingController();
  final List<String> _topics = <String>[
    'Communication',
    'Trust',
    'Long Distance',
    'Arguments',
    'Moving On',
    'Jealousy',
    'First Love',
    'Friendship to Love',
    'Self-worth',
  ];

  String _topic = 'Communication';
  String _result = '';
  bool _loading = false;
  List<Map<String, String>> _history = <Map<String, String>>[];

  String get _commentaryMood {
    if (_history.length >= 4) {
      return 'achievement';
    }
    if (_result.isNotEmpty) {
      return 'motivated';
    }
    return 'neutral';
  }
  late AnimationController _animCtrl;


  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
    _loadHistory();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String raw = prefs.getString(_historyKey) ?? '[]';
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      _history = decoded
          .whereType<Map>()
          .map(
            (Map entry) => entry.map(
              (dynamic key, dynamic value) =>
                  MapEntry(key.toString(), value.toString()),
            ),
          )
          .toList();
      if (mounted) {
        setState(() {});
      }
    } catch (_) {}
  }

  Future<void> _saveHistory() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_historyKey, jsonEncode(_history.take(8).toList()));
  }

  Future<void> _ask() async {
    final String question = _ctrl.text.trim();
    setState(() {
      _loading = true;
      _result = '';
    });
    try {
      final String chosen = question.isNotEmpty ? question : _topic;
      final String prompt =
          'You are Zero Two from DARLING in the FRANXX, giving thoughtful relationship advice. '
          'Topic: $chosen. '
          'Respond with real, actionable advice. Be warm, wise, and occasionally playful. '
          '3 concise paragraphs.';
      final String reply = await ApiService().sendConversation(
        <Map<String, String>>[
          <String, String>{'role': 'user', 'content': prompt},
        ],
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _result = reply;
        _history.insert(
          0,
          <String, String>{
            'topic': chosen,
            'answer': reply,
          },
        );
      });
      await _saveHistory();
      AffectionService.instance.addPoints(2);
    } catch (_) {
      if (mounted) {
        setState(
          () => _result = 'Hearts can be complicated. Try again, darling.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _clearHistory() {
    final List<Map<String, String>> removed =
        List<Map<String, String>>.from(_history);
    setState(() => _history.clear());
    _saveHistory();
    showUndoSnackbar(
      context,
      'Advice history cleared.',
      () {
        setState(() => _history = removed);
        _saveHistory();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: V2Theme.surfaceDark,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: <Widget>[
            Row(
              children: <Widget>[
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white70,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'RELATIONSHIP ADVICE',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        'Ask for warm, practical guidance',
                        style: GoogleFonts.outfit(
                          color: V2Theme.primaryColor,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_history.isNotEmpty)
                  TextButton.icon(
                    onPressed: _clearHistory,
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 16,
                    ),
                    label: const Text('Clear'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white54,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            AnimatedEntry(
              index: 0,
              child: GlassCard(
                margin: EdgeInsets.zero,
                glow: true,
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Heart check-in',
                            style: GoogleFonts.outfit(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _result.isEmpty
                                ? 'Tell Zero Two what is on your mind'
                                : 'Advice is ready for $_topic',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Pick a topic for a quick prompt or describe your exact situation for more personal advice.',
                            style: GoogleFonts.outfit(
                              color: Colors.white60,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    ProgressRing(
                      progress: (_history.length / 8).clamp(0, 1).toDouble(),
                      foreground: V2Theme.primaryColor,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(
                            Icons.favorite_rounded,
                            color: V2Theme.primaryColor,
                            size: 28,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${_history.length}',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Logs',
                            style: GoogleFonts.outfit(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            AnimatedEntry(
              index: 1,
              child: WaifuCommentary(mood: _commentaryMood),
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: StatCard(
                    title: 'Topics',
                    value: '${_topics.length}',
                    icon: Icons.forum_rounded,
                    color: V2Theme.primaryColor,
                  ),
                ),
                Expanded(
                  child: StatCard(
                    title: 'History',
                    value: '${_history.length}',
                    icon: Icons.history_rounded,
                    color: V2Theme.secondaryColor,
                  ),
                ),
              ],
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: StatCard(
                    title: 'Selected',
                    value: _topic,
                    icon: Icons.label_rounded,
                    color: Colors.amberAccent,
                  ),
                ),
                Expanded(
                  child: StatCard(
                    title: 'Mode',
                    value: _loading ? 'Thinking' : 'Ready',
                    icon: Icons.auto_awesome_rounded,
                    color: Colors.greenAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'QUICK TOPICS',
              style: GoogleFonts.outfit(
                color: Colors.white60,
                fontSize: 11,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _topics
                  .map(
                    (String topic) => GestureDetector(
                      onTap: () => setState(() => _topic = topic),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 140),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: topic == _topic
                              ? V2Theme.primaryColor.withValues(alpha: 0.18)
                              : Colors.white.withValues(alpha: 0.04),
                          border: Border.all(
                            color: topic == _topic
                                ? V2Theme.primaryColor.withValues(alpha: 0.55)
                                : Colors.white12,
                          ),
                        ),
                        child: Text(
                          topic,
                          style: GoogleFonts.outfit(
                            color: topic == _topic
                                ? V2Theme.primaryColor
                                : Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 14),
            GlassCard(
              margin: EdgeInsets.zero,
              child: TextField(
                controller: _ctrl,
                maxLines: 4,
                style: GoogleFonts.outfit(color: Colors.white),
                cursorColor: V2Theme.primaryColor,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  hintText: 'Describe your situation in detail...',
                  hintStyle: GoogleFonts.outfit(color: Colors.white24),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: V2Theme.primaryGradient,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: V2Theme.primaryColor.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _loading ? null : _ask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Ask Zero Two',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
            ),
            if (_result.isNotEmpty) ...<Widget>[
              const SizedBox(height: 20),
              GlassCard(
                margin: EdgeInsets.zero,
                child: Text(
                  _result,
                  style: GoogleFonts.outfit(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.7,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (_history.isEmpty)
              GlassCard(
                margin: EdgeInsets.zero,
                child: const EmptyState(
                  icon: Icons.favorite_border_rounded,
                  title: 'No advice history yet',
                  subtitle:
                      'Your recent relationship guidance sessions will show up here once you start asking.',
                ),
              )
            else ...<Widget>[
              Text(
                'RECENT SESSIONS',
                style: GoogleFonts.outfit(
                  color: Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 10),
              ..._history.take(4).map(
                (Map<String, String> entry) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        entry['topic'] ?? '',
                        style: GoogleFonts.outfit(
                          color: V2Theme.primaryColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        entry['answer'] ?? '',
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          color: Colors.white60,
                          fontSize: 12,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}




