import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:anime_waifu/services/smart_features/decision_helper_service.dart';

class DecisionHelperPage extends StatefulWidget {
  const DecisionHelperPage({super.key});

  @override
  State<DecisionHelperPage> createState() => _DecisionHelperPageState();
}

class _DecisionHelperPageState extends State<DecisionHelperPage>
    with SingleTickerProviderStateMixin {
  final _service = DecisionHelperService.instance;
  final _questionCtrl = TextEditingController();
  final _optionCtrl = TextEditingController();
  final _prosCtrl = TextEditingController();
  final _consCtrl = TextEditingController();

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  final List<DecisionOption> _options = [];
  DecisionResult? _result;
  List<DecisionRecord> _history = [];
  bool _analyzing = false;

  static const _bg = Color(0xFF0A0B14);
  static const _accent = Color(0xFF00E676);
  static const _surface = Color(0xFF151620);

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
    _loadHistory();
  }

  @override
  void dispose() {
    _questionCtrl.dispose();
    _optionCtrl.dispose();
    _prosCtrl.dispose();
    _consCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final history = await _service.getHistory();
    if (mounted) setState(() => _history = history);
  }

  void _addOption() {
    final text = _optionCtrl.text.trim();
    if (text.isEmpty) return;

    final pros = _prosCtrl.text.isEmpty
        ? <String>[]
        : _prosCtrl.text.split(',').map((e) => e.trim()).toList();
    final cons = _consCtrl.text.isEmpty
        ? <String>[]
        : _consCtrl.text.split(',').map((e) => e.trim()).toList();

    setState(() {
      _options.add(DecisionOption(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text,
        pros: pros,
        cons: cons,
      ));
      _optionCtrl.clear();
      _prosCtrl.clear();
      _consCtrl.clear();
    });
    HapticFeedback.selectionClick();
  }

  void _removeOption(String id) {
    setState(() => _options.removeWhere((o) => o.id == id));
  }

  Future<void> _analyzeDecision() async {
    if (_questionCtrl.text.isEmpty || _options.length < 2) return;

    HapticFeedback.mediumImpact();
    setState(() => _analyzing = true);

    try {
      final result = await _service.analyzeDecision(_questionCtrl.text, _options);
      final record = DecisionRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        question: _questionCtrl.text,
        options: _options,
        result: result,
        createdAt: DateTime.now(),
        status: 'completed',
      );
      await _service.saveDecision(record);

      if (mounted) {
        setState(() {
          _result = result;
          _analyzing = false;
          _history.insert(0, record);
        });
        _animCtrl.reset();
        _animCtrl.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _analyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analysis failed', style: GoogleFonts.outfit()),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _clearAll() {
    setState(() {
      _questionCtrl.clear();
      _options.clear();
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text('AI Decision Helper',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: _bg,
        elevation: 0,
        actions: [
          if (_options.isNotEmpty || _result != null)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.grey),
              onPressed: _clearAll,
              tooltip: 'Clear All',
            ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildQuestionInput(),
            const SizedBox(height: 16),
            _buildOptionInput(),
            const SizedBox(height: 16),
            _buildOptionsList(),
            const SizedBox(height: 20),
            _buildAnalyzeButton(),
            if (_analyzing) ...[
              const SizedBox(height: 24),
              _buildAnalyzingIndicator(),
            ],
            if (_result != null) ...[
              const SizedBox(height: 24),
              _buildResultCard(),
            ],
            if (_history.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildHistorySection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.help_outline, color: _accent, size: 20),
              const SizedBox(width: 8),
              Text('Your Decision Question',
                  style: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _questionCtrl,
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 16),
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'e.g., Which laptop should I buy?',
              hintStyle: GoogleFonts.outfit(color: Colors.grey[600]),
              border: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.add_circle_outline, color: _accent, size: 20),
              const SizedBox(width: 8),
              Text('Add Options (min 2)',
                  style: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _optionCtrl,
            style: GoogleFonts.outfit(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Option name',
              hintStyle: GoogleFonts.outfit(color: Colors.grey[600]),
              filled: true,
              fillColor: _bg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _prosCtrl,
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Pros (comma-separated)',
                    hintStyle: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 11),
                    filled: true,
                    fillColor: _bg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _consCtrl,
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Cons (comma-separated)',
                    hintStyle: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 11),
                    filled: true,
                    fillColor: _bg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _addOption,
              icon: const Icon(Icons.add, size: 16),
              label: Text('Add Option', style: GoogleFonts.outfit(fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent.withOpacity(0.2),
                foregroundColor: _accent,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsList() {
    if (_options.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Options (${_options.length})',
            style: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 13)),
        const SizedBox(height: 8),
        ...List.generate(_options.length, (i) {
          final opt = _options[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text('${i + 1}',
                        style: GoogleFonts.outfit(
                            color: _accent, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(opt.text,
                          style: GoogleFonts.outfit(
                              color: Colors.white, fontWeight: FontWeight.w600)),
                      if (opt.pros.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('✅ ${opt.pros.join(", ")}',
                            style: GoogleFonts.outfit(color: Colors.green[400], fontSize: 11)),
                      ],
                      if (opt.cons.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text('⚠️ ${opt.cons.join(", ")}',
                            style: GoogleFonts.outfit(color: Colors.orange[400], fontSize: 11)),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey, size: 16),
                  onPressed: () => _removeOption(opt.id),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAnalyzeButton() {
    final canAnalyze = _questionCtrl.text.isNotEmpty && _options.length >= 2;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canAnalyze && !_analyzing ? _analyzeDecision : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _accent,
          disabledBackgroundColor: Colors.grey[800],
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(
          _analyzing ? 'Analyzing...' : 'Analyze with AI',
          style: GoogleFonts.outfit(
            color: canAnalyze ? Colors.black : Colors.grey[500],
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyzingIndicator() {
    return Column(
      children: [
        const LinearProgressIndicator(
          backgroundColor: Color(0xFF151620),
          valueColor: AlwaysStoppedAnimation<Color>(_accent),
        ),
        const SizedBox(height: 12),
        Text('AI is analyzing your options...',
            style: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 13)),
      ],
    );
  }

  Widget _buildResultCard() {
    final r = _result!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_accent.withOpacity(0.15), _surface],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _accent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 24),
              const SizedBox(width: 8),
              Text('Recommendation',
                  style: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 13)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: r.riskLevel == 'Low'
                      ? Colors.green.withOpacity(0.2)
                      : r.riskLevel == 'Medium'
                          ? Colors.orange.withOpacity(0.2)
                          : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                    '${_service.getRiskColor(r.riskLevel)} ${r.riskLevel} Risk',
                    style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(r.recommendation,
              style: GoogleFonts.outfit(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(r.reasoning,
              style: GoogleFonts.outfit(color: Colors.grey[300], fontSize: 13)),
          const SizedBox(height: 16),
          Text('Score Breakdown',
              style: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 12)),
          const SizedBox(height: 8),
          ...r.scores.entries.map((e) {
            final opt = _options.firstWhere((o) => o.id == e.key);
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(opt.text,
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 12)),
                  ),
                  Text('${e.value.toStringAsFixed(0)}/100',
                      style: GoogleFonts.outfit(
                          color: _accent, fontWeight: FontWeight.w600, fontSize: 12)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Decisions',
            style: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 13)),
        const SizedBox(height: 8),
        ...List.generate(_history.take(3).length, (i) {
          final rec = _history[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.history, color: Colors.grey, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rec.question,
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('${rec.options.length} options • ${rec.createdAt.day}/${rec.createdAt.month}',
                          style: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 11)),
                    ],
                  ),
                ),
                if (rec.result != null)
                  const Icon(Icons.check_circle, color: _accent, size: 16),
              ],
            ),
          );
        }),
      ],
    );
  }
}
