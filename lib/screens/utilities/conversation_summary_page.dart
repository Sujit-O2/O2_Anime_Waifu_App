import 'package:anime_waifu/services/user_profile/affection_service.dart';
import 'package:anime_waifu/utils/api_call.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

class ConversationSummaryPage extends StatefulWidget {
  const ConversationSummaryPage({super.key});
  @override
  State<ConversationSummaryPage> createState() =>
      _ConversationSummaryPageState();
}

class _ConversationSummaryPageState extends State<ConversationSummaryPage>
    with SingleTickerProviderStateMixin {
  final _ctrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  String _summary = '';
  bool _loading = false;
  bool _shimmer = false;
  List<Map<String, dynamic>> _history = [];
  String _searchQuery = '';
  late AnimationController _floatCtrl;

  @override
  void initState() {
    super.initState();
    _floatCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat(reverse: true);
    _loadHistory();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _searchCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? 'anon';
  CollectionReference get _col => FirebaseFirestore.instance
      .collection('users')
      .doc(_uid)
      .collection('conversationSummaries');

  Future<void> _loadHistory() async {
    try {
      final snap = await _col.orderBy('ts', descending: true).get();
      if (mounted) {
        setState(() {
          _history = snap.docs
              .map((d) => {
                    'id': d.id,
                    'originalText': d['originalText']?.toString() ?? '',
                    'summary': d['summary']?.toString() ?? '',
                    'topics': List<String>.from(d['topics'] ?? []),
                    'ts': (d['ts'] as Timestamp?)?.toDate()
                  })
              .toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _saveSummary(String originalText, String summary, List<String> topics) async {
    final doc = _col.doc();
    final data = {
      'id': doc.id,
      'originalText': originalText,
      'summary': summary,
      'topics': topics,
      'ts': FieldValue.serverTimestamp()
    };
    setState(() {
      _history.insert(0, {...data, 'ts': DateTime.now()});
    });
    try {
      await doc.set(data);
    } catch (_) {}
  }

  List<Map<String, dynamic>> get _filteredHistory {
    if (_searchQuery.isEmpty) return _history;
    return _history.where((s) =>
        (s['summary']?.toString() ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (s['originalText']?.toString() ?? '').toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  Map<String, int> get _topicStats {
    final stats = <String, int>{};
    for (final s in _history) {
      for (final topic in s['topics'] ?? []) {
        stats[topic] = (stats[topic] ?? 0) + 1;
      }
    }
    return stats;
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
      _shimmer = true;
      _summary = '';
    });
    try {
      final prompt = 'You are Zero Two from DARLING in the FRANXX. '
          'Analyze this conversation and provide:\n\n'
          '1. **Key topics discussed** (list 3-5 main topics)\n'
          '2. **Detailed summary** with bullet points\n'
          '3. **Emotional insights** (how we connected, feelings)\n'
          '4. **Action items** (follow-ups, recommendations)\n\n'
          'Also, at the end, list the topics in a comma-separated list for data purposes.\n\n'
          'Conversation:\n'
          '$text\n\n'
          'Be warm, in Zero Two\'s voice, keep it concise but insightful.';
      final reply = await ApiService().sendConversation([
        {'role': 'user', 'content': prompt},
      ]);
      if (!mounted) return;
      final topics = _extractTopics(reply);
      setState(() => _summary = reply);
      await _saveSummary(text.length > 100 ? '${text.substring(0, 100)}...' : text, reply, topics);
      AffectionService.instance.addPoints(2);
    } catch (e) {
      setState(
          () => _summary = 'Something went wrong, Darling~ Please try again!');
    } finally {
      setState(() {
        _loading = false;
        _shimmer = false;
      });
    }
  }

  List<String> _extractTopics(String summary) {
    final lines = summary.split('\n');
    for (final line in lines) {
      if (line.contains('Topics:') || line.contains('topics:')) {
        return line.split(':').last.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
      }
    }
    // Fallback: extract from Key topics
    final topicSection = summary.split('**Key topics discussed**').last.split('**').first;
    return topicSection.split('\n').map((t) => t.replaceAll(RegExp(r'^[-\*]\s*'), '').trim()).where((t) => t.isNotEmpty).take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
            _shimmer
                ? Shimmer.fromColors(
                    baseColor: Colors.white.withValues(alpha: 0.1),
                    highlightColor: Colors.white.withValues(alpha: 0.2),
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  )
                : GlassmorphicContainer(
                    width: double.infinity,
                    height: 200,
                    borderRadius: 16,
                    blur: 20,
                    alignment: Alignment.bottomCenter,
                    border: 2,
                    linearGradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.1),
                          Colors.white.withValues(alpha: 0.05),
                        ],
                        stops: const [
                          0.1,
                          1,
                        ]),
                    borderGradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.5),
                        Colors.white.withValues(alpha: 0.2),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: SingleChildScrollView(
                        child: Text(_summary,
                            style: GoogleFonts.outfit(
                                color: Colors.white70, fontSize: 14, height: 1.7)),
                      ),
                    ),
                  ),
            const SizedBox(height: 8),
            Text('+2 XP 💕',
                style: GoogleFonts.outfit(
                    color: Colors.tealAccent.withValues(alpha: 0.5),
                    fontSize: 11)),
          ],
          const SizedBox(height: 32),
          Text('Search Summaries',
              style: GoogleFonts.outfit(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _searchQuery = v),
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
            cursorColor: Colors.tealAccent,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.tealAccent),
              ),
              contentPadding: const EdgeInsets.all(14),
              hintText: 'Search past summaries…',
              hintStyle: GoogleFonts.outfit(color: Colors.white24),
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
            ),
          ),
          const SizedBox(height: 16),
          Text('Past Summaries',
              style: GoogleFonts.outfit(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SizedBox(
            height: 300,
            child: RefreshIndicator(
              onRefresh: _loadHistory,
              color: Colors.tealAccent,
              child: _filteredHistory.isEmpty
                  ? Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                          AnimatedBuilder(
                              animation: _floatCtrl,
                              builder: (_, __) => Transform.translate(
                                    offset: Offset(0, -8 * _floatCtrl.value),
                                    child: const Text('📜',
                                        style: TextStyle(fontSize: 64)),
                                  )),
                          const SizedBox(height: 16),
                          Text('No summaries yet, Darling~',
                              style: GoogleFonts.outfit(
                                  color: Colors.white38, fontSize: 16)),
                        ]))
                  : ListView.builder(
                      itemCount: _filteredHistory.length,
                      itemBuilder: (_, i) {
                        final summary = _filteredHistory[i];
                        final ts = summary['ts'] as DateTime?;
                        return TweenAnimationBuilder<double>(
                          duration: Duration(milliseconds: 400 + i * 80),
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (_, v, child) => Opacity(
                              opacity: v,
                              child: Transform.scale(
                                  scale: 0.9 + 0.1 * v, child: child)),
                          child: GlassmorphicContainer(
                            width: double.infinity,
                            height: 120,
                            margin: const EdgeInsets.only(bottom: 12),
                            borderRadius: 12,
                            blur: 15,
                            alignment: Alignment.bottomCenter,
                            border: 2,
                            linearGradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.tealAccent.withValues(alpha: 0.1),
                                  Colors.cyan.withValues(alpha: 0.05),
                                ],
                                stops: const [
                                  0.1,
                                  1,
                                ]),
                            borderGradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.tealAccent.withValues(alpha: 0.5),
                                Colors.cyan.withValues(alpha: 0.2),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    summary['originalText']?.toString() ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  Expanded(
                                    child: Text(
                                      summary['summary']?.toString() ?? '',
                                      maxLines: 3,
                                      overflow: TextOverflow.fade,
                                      style: GoogleFonts.outfit(
                                          color: Colors.white70, fontSize: 12),
                                    ),
                                  ),
                                  if (ts != null)
                                    Text('${ts.day}/${ts.month}/${ts.year}',
                                        style: GoogleFonts.outfit(
                                            color: Colors.white38,
                                            fontSize: 10)),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(height: 32),
          Text('Topic Statistics',
              style: GoogleFonts.outfit(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: _topicStats.isEmpty
                ? Center(
                    child: Text('No data yet',
                        style: GoogleFonts.outfit(color: Colors.white38)))
                : PieChart(
                    PieChartData(
                      sections: _topicStats.entries.map((e) {
                        final colors = [Colors.teal, Colors.cyan, Colors.pink, Colors.purple, Colors.orange];
                        return PieChartSectionData(
                          value: e.value.toDouble(),
                          title: '${e.key}\n${e.value}',
                          color: colors[_topicStats.keys.toList().indexOf(e.key) % colors.length],
                          radius: 50,
                          titleStyle: GoogleFonts.outfit(color: Colors.white, fontSize: 12),
                        );
                      }).toList(),
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                    ),
                  ),
          ),
        ]),
      ),
    );
  }
}



