import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:anime_waifu/services/smart_features/smart_study_service.dart';

class SmartStudyPage extends StatefulWidget {
  const SmartStudyPage({super.key});

  @override
  State<SmartStudyPage> createState() => _SmartStudyPageState();
}

class _SmartStudyPageState extends State<SmartStudyPage>
    with SingleTickerProviderStateMixin {
  final _service = SmartStudyService.instance;
  late TabController _tabs;
  bool _loading = true;

  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();

  List<Flashcard> _flashcards = [];
  List<QuizResult> _quizResults = [];
  Map<String, dynamic> _progress = {};
  List<String> _weakTopics = [];
  int _streak = 0;

  int _currentCardIndex = 0;
  bool _showAnswer = false;

  Quiz? _activeQuiz;
  int _currentQuestionIndex = 0;
  int _quizScore = 0;
  String? _selectedAnswer;
  bool _quizFinished = false;
  List<String> _userAnswers = [];

  String _summary = '';
  bool _summaryLoading = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
    _init();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _subjectCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await _service.initialize();
    await _refreshData();
  }

  Future<void> _refreshData() async {
    final flashcards = _service.getFlashcards();
    final results = _service.getQuizResults();
    final progress = await _service.getStudyProgress();
    final weakTopics = await _service.getWeakTopics();
    final streak = progress['streak'] as int? ?? 0;
    if (mounted) {
      setState(() {
        _flashcards = List<Flashcard>.from(flashcards);
        _quizResults = List<QuizResult>.from(results);
        _progress = progress;
        _weakTopics = weakTopics;
        _streak = streak;
        _loading = false;
      });
    }
  }

  Future<void> _addMaterial() async {
    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();
    final subject = _subjectCtrl.text.trim();
    if (title.isEmpty || content.isEmpty) return;
    await _service.addStudyMaterial(
      title: title,
      content: content,
      subject: subject.isEmpty ? 'General' : subject,
    );
    _titleCtrl.clear();
    _contentCtrl.clear();
    _subjectCtrl.clear();
    await _refreshData();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'pdf', 'md'],
      );
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        if (mounted) {
          setState(() {
            _contentCtrl.text = content;
            _titleCtrl.text = result.files.single.name;
          });
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[SmartStudy] File pick error: $e');
    }
  }

  Future<void> _generateFlashcards() async {
    final content = _contentCtrl.text.trim();
    if (content.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() => _loading = true);
    await _service.generateFlashcards(content);
    await _refreshData();
    if (mounted) {
      setState(() {
        _loading = false;
        _currentCardIndex = 0;
        _showAnswer = false;
        _tabs.animateTo(1);
      });
    }
  }

  Future<void> _generateQuiz() async {
    final content = _contentCtrl.text.trim();
    if (content.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() => _loading = true);
    final quiz = await _service.generateQuiz(content);
    await _refreshData();
    if (quiz != null && mounted) {
      setState(() {
        _loading = false;
        _activeQuiz = quiz;
        _currentQuestionIndex = 0;
        _quizScore = 0;
        _selectedAnswer = null;
        _quizFinished = false;
        _userAnswers = [];
        _tabs.animateTo(2);
      });
    }
  }

  Future<void> _generateSummary() async {
    final content = _contentCtrl.text.trim();
    if (content.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      _summaryLoading = true;
      _summary = '';
    });
    final summary = await _service.generateSummary(content);
    if (mounted) {
      setState(() {
        _summary = summary;
        _summaryLoading = false;
        _tabs.animateTo(3);
      });
    }
  }

  void _nextCard() {
    HapticFeedback.lightImpact();
    if (_currentCardIndex < _flashcards.length - 1) {
      setState(() {
        _currentCardIndex++;
        _showAnswer = false;
      });
    }
  }

  void _prevCard() {
    HapticFeedback.lightImpact();
    if (_currentCardIndex > 0) {
      setState(() {
        _currentCardIndex--;
        _showAnswer = false;
      });
    }
  }

  Future<void> _markCardLearned(bool learned) async {
    HapticFeedback.lightImpact();
    final card = _flashcards[_currentCardIndex];
    if (learned) {
      await _service.markFlashcardLearned(card.id);
    }
    _nextCard();
    await _refreshData();
  }

  void _selectQuizAnswer(String answer) {
    HapticFeedback.lightImpact();
    setState(() => _selectedAnswer = answer);
  }

  Future<void> _submitQuizAnswer() async {
    if (_selectedAnswer == null || _activeQuiz == null) return;
    HapticFeedback.mediumImpact();
    final question = _activeQuiz!.questions[_currentQuestionIndex];
    final correct = _selectedAnswer == question.correctAnswer;
    if (correct) {
      setState(() => _quizScore++);
    }
    setState(() {
      _userAnswers.add(_selectedAnswer!);
      _selectedAnswer = null;
    });
    if (_currentQuestionIndex < _activeQuiz!.questions.length - 1) {
      setState(() => _currentQuestionIndex++);
    } else {
      await _service.recordQuizScore(
        quizId: _activeQuiz!.id,
        score: _quizScore,
        total: _activeQuiz!.questions.length,
      );
      await _refreshData();
      if (mounted) setState(() => _quizFinished = true);
    }
  }

  void _showAddMaterialSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddMaterialSheet(
        titleCtrl: _titleCtrl,
        contentCtrl: _contentCtrl,
        subjectCtrl: _subjectCtrl,
        onPickFile: _pickFile,
        onGenerateFlashcards: _generateFlashcards,
        onGenerateQuiz: _generateQuiz,
        onGenerateSummary: _generateSummary,
        onSubmit: _addMaterial,
      ),
    );
  }

  Widget _buildMaterialsTab() {
    final materials = _service.getMaterials();
    if (materials.isEmpty) {
      return const _EmptyState(
        icon: Icons.menu_book_outlined,
        message: 'No study materials yet.\nTap + to add your first material!',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: materials.length,
      itemBuilder: (_, i) => _MaterialCard(material: materials[i]),
    );
  }

  Widget _buildFlashcardsTab() {
    if (_flashcards.isEmpty) {
      return const _EmptyState(
        icon: Icons.style_outlined,
        message: 'No flashcards yet.\nGenerate flashcards from your study material!',
      );
    }
    final card = _flashcards[_currentCardIndex];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Card ${_currentCardIndex + 1}/${_flashcards.length}',
                  style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getDifficultyColor(card.difficulty).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(card.difficulty.toUpperCase(),
                    style: GoogleFonts.outfit(
                        fontSize: 10,
                        color: _getDifficultyColor(card.difficulty),
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _showAnswer = !_showAnswer);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_showAnswer ? 'ANSWER' : 'QUESTION',
                        style: GoogleFonts.outfit(
                            color: const Color(0xFF00BCD4),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5)),
                    const SizedBox(height: 16),
                    Text(
                      _showAnswer ? card.answer : card.question,
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                    if (_showAnswer) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 16),
                            const SizedBox(width: 8),
                            Text('Deck: ${card.deck}',
                                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text('Tap to ${_showAnswer ? "see question" : "reveal answer"}',
                        style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _prevCard,
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white60),
              ),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () => _markCardLearned(false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.withValues(alpha: 0.15),
                      foregroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Still Learning', style: GoogleFonts.outfit(fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _markCardLearned(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.withValues(alpha: 0.15),
                      foregroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('I Know This', style: GoogleFonts.outfit(fontSize: 12)),
                  ),
                ],
              ),
              IconButton(
                onPressed: _nextCard,
                icon: const Icon(Icons.arrow_forward_ios, color: Colors.white60),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuizTab() {
    if (_activeQuiz == null) {
      final quizzes = _service.getQuizzes();
      if (quizzes.isEmpty) {
        return const _EmptyState(
          icon: Icons.quiz_outlined,
          message: 'No quizzes yet.\nGenerate a quiz from your study material!',
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: quizzes.length,
        itemBuilder: (_, i) => _QuizCard(
          quiz: quizzes[i],
          onStart: () {
            setState(() {
              _activeQuiz = quizzes[i];
              _currentQuestionIndex = 0;
              _quizScore = 0;
              _selectedAnswer = null;
              _quizFinished = false;
              _userAnswers = [];
            });
          },
        ),
      );
    }

    if (_quizFinished) {
      return _QuizResultView(
        quiz: _activeQuiz!,
        score: _quizScore,
        userAnswers: _userAnswers,
        onRetry: () {
          setState(() {
            _activeQuiz = null;
            _quizFinished = false;
          });
        },
      );
    }

    final question = _activeQuiz!.questions[_currentQuestionIndex];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Question ${_currentQuestionIndex + 1}/${_activeQuiz!.questions.length}',
                  style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
              const Spacer(),
              Text('Score: $_quizScore',
                  style: GoogleFonts.outfit(color: const Color(0xFF00BCD4), fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / _activeQuiz!.questions.length,
            backgroundColor: Colors.white12,
            color: const Color(0xFF00BCD4),
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Text(question.question,
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
          ),
          const SizedBox(height: 20),
          ...question.options.map((opt) => _QuizOption(
                option: opt,
                selected: _selectedAnswer == opt,
                correct: opt == question.correctAnswer,
                onTap: () => _selectQuizAnswer(opt),
              )),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _selectedAnswer != null ? _submitQuizAnswer : null,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00BCD4),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                _currentQuestionIndex < _activeQuiz!.questions.length - 1 ? 'Next Question' : 'Finish Quiz',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTab() {
    if (_summaryLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF00BCD4)));
    }
    if (_summary.isEmpty) {
      return const _EmptyState(
        icon: Icons.summarize_outlined,
        message: 'No summary generated yet.\nUse the Generate button to create a summary!',
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: SingleChildScrollView(
          child: Text(_summary,
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, height: 1.6)),
        ),
      ),
    );
  }

  Widget _buildProgressTab() {
    final materialsCount = _progress['totalMaterials'] as int? ?? 0;
    final flashcardsCount = _progress['totalFlashcards'] as int? ?? 0;
    final learned = _progress['learnedFlashcards'] as int? ?? 0;
    final avgScore = _progress['avgScore'] as int? ?? 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.local_fire_department,
                value: '$_streak',
                label: 'Day Streak',
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.quiz,
                value: '$avgScore%',
                label: 'Avg Score',
                color: const Color(0xFF00BCD4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.menu_book,
                value: '$materialsCount',
                label: 'Materials',
                color: Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.style,
                value: '$learned/$flashcardsCount',
                label: 'Cards Learned',
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text('Quiz Performance',
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: _quizResults.isEmpty
              ? Center(child: Text('No quiz data yet', style: GoogleFonts.outfit(color: Colors.white38)))
              : LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: _quizResults.asMap().entries.map((e) {
                          final r = e.value;
                          return FlSpot(e.key.toDouble(), r.percentage.toDouble());
                        }).toList(),
                        isCurved: true,
                        color: const Color(0xFF00BCD4),
                        barWidth: 3,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                            radius: 4,
                            color: const Color(0xFF00BCD4),
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          ),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: const Color(0xFF00BCD4).withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 20),
        if (_weakTopics.isNotEmpty) ...[
          Text('Topics Needing Revision',
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ..._weakTopics.map((topic) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.orange, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(topic,
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 14)),
                    ),
                  ],
                ),
              )),
        ],
      ],
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return Colors.green;
      case 'hard':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0B14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white60, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('SMART STUDY',
            style: GoogleFonts.outfit(
                color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_fire_department, color: Colors.orange, size: 16),
                const SizedBox(width: 4),
                Text('$_streak',
                    style: GoogleFonts.outfit(
                        color: Colors.orange, fontWeight: FontWeight.w700, fontSize: 13)),
              ],
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: const Color(0xFF00BCD4),
          labelColor: const Color(0xFF00BCD4),
          unselectedLabelColor: Colors.white54,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: GoogleFonts.outfit(fontSize: 12),
          isScrollable: true,
          tabs: const [
            Tab(text: 'Materials'),
            Tab(text: 'Flashcards'),
            Tab(text: 'Quiz'),
            Tab(text: 'Summary'),
            Tab(text: 'Progress'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00BCD4)))
          : TabBarView(
              controller: _tabs,
              children: [
                _buildMaterialsTab(),
                _buildFlashcardsTab(),
                _buildQuizTab(),
                _buildSummaryTab(),
                _buildProgressTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMaterialSheet,
        icon: const Icon(Icons.add),
        label: Text('Add Material', style: GoogleFonts.outfit()),
        backgroundColor: const Color(0xFF00BCD4),
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _AddMaterialSheet extends StatefulWidget {
  const _AddMaterialSheet({
    required this.titleCtrl,
    required this.contentCtrl,
    required this.subjectCtrl,
    required this.onPickFile,
    required this.onGenerateFlashcards,
    required this.onGenerateQuiz,
    required this.onGenerateSummary,
    required this.onSubmit,
  });
  final TextEditingController titleCtrl;
  final TextEditingController contentCtrl;
  final TextEditingController subjectCtrl;
  final VoidCallback onPickFile;
  final VoidCallback onGenerateFlashcards;
  final VoidCallback onGenerateQuiz;
  final VoidCallback onGenerateSummary;
  final VoidCallback onSubmit;

  @override
  State<_AddMaterialSheet> createState() => _AddMaterialSheetState();
}

class _AddMaterialSheetState extends State<_AddMaterialSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1B2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Add Study Material',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 16),
          TextField(
            controller: widget.titleCtrl,
            style: GoogleFonts.outfit(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Title',
              labelStyle: GoogleFonts.outfit(color: Colors.white54),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.04),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.title, color: Color(0xFF00BCD4)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: widget.subjectCtrl,
            style: GoogleFonts.outfit(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Subject (optional)',
              labelStyle: GoogleFonts.outfit(color: Colors.white54),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.04),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.category_outlined, color: Color(0xFF00BCD4)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: widget.onPickFile,
                  icon: const Icon(Icons.attach_file, size: 16),
                  label: Text('Import File', style: GoogleFonts.outfit(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.06),
                    foregroundColor: Colors.white70,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: widget.contentCtrl,
            style: GoogleFonts.outfit(color: Colors.white),
            maxLines: 6,
            decoration: InputDecoration(
              labelText: 'Content (text or paste from file)',
              labelStyle: GoogleFonts.outfit(color: Colors.white54),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.04),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.onGenerateFlashcards,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.withValues(alpha: 0.15),
                    foregroundColor: Colors.purpleAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Flashcards', style: GoogleFonts.outfit(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.onGenerateQuiz,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.withValues(alpha: 0.15),
                    foregroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Quiz', style: GoogleFonts.outfit(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.onGenerateSummary,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.withValues(alpha: 0.15),
                    foregroundColor: Colors.greenAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Summary', style: GoogleFonts.outfit(fontSize: 12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: widget.onSubmit,
              icon: const Icon(Icons.save),
              label: Text('Save Material', style: GoogleFonts.outfit()),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00BCD4),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MaterialCard extends StatelessWidget {
  const _MaterialCard({required this.material});
  final StudyMaterial material;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(material.title,
                    style: GoogleFonts.outfit(
                        color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
              ),
              if (material.subject.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00BCD4).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(material.subject,
                      style: GoogleFonts.outfit(
                          color: const Color(0xFF00BCD4), fontSize: 11, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(material.content,
              style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13),
              maxLines: 3,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 14, color: Colors.white38),
              const SizedBox(width: 4),
              Text(
                  '${material.createdAt.day}/${material.createdAt.month}/${material.createdAt.year}',
                  style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11)),
              const Spacer(),
              if (material.flashcardsGenerated)
                const Icon(Icons.style, size: 14, color: Colors.purpleAccent),
              if (material.quizzesGenerated) ...[
                const SizedBox(width: 8),
                const Icon(Icons.quiz, size: 14, color: Colors.blueAccent),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _QuizCard extends StatelessWidget {
  const _QuizCard({required this.quiz, required this.onStart});
  final Quiz quiz;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(quiz.title,
                    style: GoogleFonts.outfit(
                        color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
              ),
              if (quiz.completed)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('Score: ${quiz.score}/${quiz.questions.length}',
                      style: GoogleFonts.outfit(
                          color: Colors.green, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text('${quiz.questions.length} questions',
              style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onStart,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BCD4).withValues(alpha: 0.15),
                foregroundColor: const Color(0xFF00BCD4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(quiz.completed ? 'Retake Quiz' : 'Start Quiz',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizOption extends StatelessWidget {
  const _QuizOption({
    required this.option,
    required this.selected,
    required this.correct,
    required this.onTap,
  });
  final String option;
  final bool selected;
  final bool correct;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color? borderColor;
    Color? bgColor;
    if (selected) {
      if (correct) {
        borderColor = Colors.green;
        bgColor = Colors.green.withValues(alpha: 0.1);
      } else {
        borderColor = Colors.red;
        bgColor = Colors.red.withValues(alpha: 0.1);
      }
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor ?? Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor ?? Colors.white12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(option,
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 14)),
            ),
            if (selected)
              Icon(correct ? Icons.check_circle : Icons.cancel,
                  color: correct ? Colors.green : Colors.red, size: 18),
          ],
        ),
      ),
    );
  }
}

class _QuizResultView extends StatelessWidget {
  const _QuizResultView({
    required this.quiz,
    required this.score,
    required this.userAnswers,
    required this.onRetry,
  });
  final Quiz quiz;
  final int score;
  final List<String> userAnswers;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final percentage = (score / quiz.questions.length * 100).round();
    final Color resultColor = percentage >= 70 ? Colors.green : Colors.orange;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          Column(
            children: [
              Icon(percentage >= 70 ? Icons.emoji_events : Icons.refresh,
                  size: 64, color: resultColor),
              const SizedBox(height: 16),
              Text('Quiz Complete!',
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: resultColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: resultColor.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    Text('$score/${quiz.questions.length}',
                        style: GoogleFonts.outfit(
                            color: resultColor, fontSize: 36, fontWeight: FontWeight.w800)),
                    Text('$percentage%',
                        style: GoogleFonts.outfit(color: resultColor, fontSize: 18, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...quiz.questions.asMap().entries.map((e) {
            final q = e.value;
            final userAns = e.key < userAnswers.length ? userAnswers[e.key] : 'No answer';
            final correct = userAns == q.correctAnswer;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Q${e.key + 1}: ${q.question}',
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text('Your answer: $userAns',
                      style: GoogleFonts.outfit(
                          color: correct ? Colors.green : Colors.red, fontSize: 12)),
                  if (!correct)
                    Text('Correct: ${q.correctAnswer}',
                        style: GoogleFonts.outfit(color: Colors.green, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(q.explanation,
                      style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11)),
                ],
              ),
            );
          }),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00BCD4),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Back to Quizzes', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value,
              style: GoogleFonts.outfit(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
          Text(label,
              style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 15, color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}
