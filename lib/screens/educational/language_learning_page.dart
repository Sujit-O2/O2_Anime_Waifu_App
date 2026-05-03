import 'package:anime_waifu/services/educational/language_learning_service.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class LanguageLearningPage extends StatefulWidget {
  const LanguageLearningPage({super.key});

  @override
  State<LanguageLearningPage> createState() => _LanguageLearningPageState();
}

class _LanguageLearningPageState extends State<LanguageLearningPage>
    with SingleTickerProviderStateMixin {
  final _service = LanguageLearningService.instance;
  late final TabController _tabs;
  final _titleCtrl = TextEditingController();
  final _practiceCtrl = TextEditingController();
  Language _language = Language.japanese;
  LanguageCourse? _activeCourse;
  String _feedback = '';
  bool _loading = true;

  static const _langEmoji = {
    Language.english: '🇬🇧',
    Language.spanish: '🇪🇸',
    Language.french: '🇫🇷',
    Language.german: '🇩🇪',
    Language.japanese: '🇯🇵',
    Language.chinese: '🇨🇳',
  };

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _titleCtrl.dispose();
    _practiceCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await _service.initialize();
    if (mounted) {
      setState(() {
        _loading = false;
        final courses = _service.getCourses();
        if (courses.isNotEmpty) _activeCourse = courses.first;
      });
    }
  }

  Future<void> _createCourse() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    HapticFeedback.mediumImpact();
    final course = await _service.createCourse(
      title: _titleCtrl.text.trim(),
      language: _language,
      nativeLanguage: 'English',
      level: ProficiencyLevel.beginner,
      description: 'Practice course',
      goals: const ['Vocabulary', 'Conversation', 'Culture'],
    );
    _titleCtrl.clear();
    if (mounted) setState(() => _activeCourse = course);
  }

  void _practiceConversation() {
    final course = _activeCourse ??
        (_service.getCourses().isEmpty ? null : _service.getCourses().first);
    if (course == null || _practiceCtrl.text.trim().isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      _feedback = _service.getConversationPractice(
        userInput: _practiceCtrl.text.trim(),
        language: course.language,
        level: course.level,
        topic: 'daily life',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final courses = _service.getCourses();
    final active = _activeCourse ?? (courses.isEmpty ? null : courses.first);

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cs.primary, cs.tertiary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text('Language Learning',
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold, color: cs.onPrimary)),
        iconTheme: IconThemeData(color: cs.onPrimary),
        bottom: TabBar(
          controller: _tabs,
          labelColor: cs.onPrimary,
          unselectedLabelColor: cs.onPrimary.withAlpha(153),
          indicatorColor: cs.onPrimary,
          tabs: const [
            Tab(text: 'Courses'),
            Tab(text: 'Practice'),
            Tab(text: 'Tips'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabs,
              children: [
                _CoursesTab(
                  courses: courses,
                  active: active,
                  language: _language,
                  titleCtrl: _titleCtrl,
                  onLanguageChanged: (l) => setState(() => _language = l),
                  onActiveCourse: (c) => setState(() => _activeCourse = c),
                  onCreate: _createCourse,
                  service: _service,
                  langEmoji: _langEmoji,
                ),
                _PracticeTab(
                  active: active,
                  practiceCtrl: _practiceCtrl,
                  feedback: _feedback,
                  onPractice: _practiceConversation,
                ),
                _TipsTab(language: _language, service: _service),
              ],
            ),
    );
  }
}

class _CoursesTab extends StatelessWidget {
  final List<LanguageCourse> courses;
  final LanguageCourse? active;
  final Language language;
  final TextEditingController titleCtrl;
  final ValueChanged<Language> onLanguageChanged;
  final ValueChanged<LanguageCourse> onActiveCourse;
  final VoidCallback onCreate;
  final LanguageLearningService service;
  final Map<Language, String> langEmoji;

  const _CoursesTab({
    required this.courses,
    required this.active,
    required this.language,
    required this.titleCtrl,
    required this.onLanguageChanged,
    required this.onActiveCourse,
    required this.onCreate,
    required this.service,
    required this.langEmoji,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Stats card
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: cs.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              service.getLanguageInsights(),
              style: GoogleFonts.outfit(color: cs.onPrimaryContainer),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Create course card
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('New Course',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: 'Course title',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<Language>(
                  value: language,
                  decoration: InputDecoration(
                    labelText: 'Language',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  items: Language.values
                      .map((l) => DropdownMenuItem(
                            value: l,
                            child: Text(
                                '${langEmoji[l] ?? ''} ${l.name[0].toUpperCase()}${l.name.substring(1)}'),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) onLanguageChanged(v);
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onCreate,
                    icon: const Icon(Icons.school_rounded),
                    label: Text('Create Course',
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (courses.isEmpty)
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.translate_rounded,
                      size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text('No courses yet',
                      style: GoogleFonts.outfit(
                          fontSize: 16, color: Colors.grey)),
                  Text('Create your first language course above',
                      style: GoogleFonts.outfit(color: Colors.grey)),
                ],
              ),
            ),
          )
        else ...[
          Text('Your Courses',
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ...courses.map((course) => _CourseCard(
                course: course,
                isActive: active?.id == course.id,
                onTap: () => onActiveCourse(course),
                service: service,
                langEmoji: langEmoji,
              )),
        ],
      ],
    );
  }
}

class _CourseCard extends StatelessWidget {
  final LanguageCourse course;
  final bool isActive;
  final VoidCallback onTap;
  final LanguageLearningService service;
  final Map<Language, String> langEmoji;

  const _CourseCard({
    required this.course,
    required this.isActive,
    required this.onTap,
    required this.service,
    required this.langEmoji,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final progress = course.currentLesson / course.totalLessons;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isActive
            ? BorderSide(color: cs.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(langEmoji[course.language] ?? '🌍',
                      style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(course.title,
                            style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        Text(
                            '${course.level.name[0].toUpperCase()}${course.level.name.substring(1)} • ${course.conversationsCompleted} conversations',
                            style: GoogleFonts.outfit(
                                color: cs.onSurface.withAlpha(153),
                                fontSize: 12)),
                      ],
                    ),
                  ),
                  if (isActive)
                    Icon(Icons.check_circle_rounded, color: cs.primary),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: progress,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                      '${course.currentLesson}/${course.totalLessons}',
                      style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: cs.onSurface.withAlpha(153))),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: [
                  _Chip('📚 ${course.vocabularyLearned} words'),
                  _Chip(course.status.name),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: GoogleFonts.outfit(
              fontSize: 11, color: cs.onSurface.withAlpha(180))),
    );
  }
}

class _PracticeTab extends StatelessWidget {
  final LanguageCourse? active;
  final TextEditingController practiceCtrl;
  final String feedback;
  final VoidCallback onPractice;

  const _PracticeTab({
    required this.active,
    required this.practiceCtrl,
    required this.feedback,
    required this.onPractice,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (active == null)
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            color: cs.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: cs.onErrorContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                        'Create a course first to start practicing',
                        style: GoogleFonts.outfit(
                            color: cs.onErrorContainer)),
                  ),
                ],
              ),
            ),
          )
        else
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            color: cs.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.school_rounded),
                  const SizedBox(width: 8),
                  Text('Practicing: ${active!.title}',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Conversation Practice',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                TextField(
                  controller: practiceCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Write a sentence to practice',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: active != null ? onPractice : null,
                    icon: const Icon(Icons.record_voice_over_rounded),
                    label: Text('Get Feedback',
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (feedback.isNotEmpty) ...[
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            color: cs.tertiaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded,
                          color: cs.onTertiaryContainer, size: 20),
                      const SizedBox(width: 8),
                      Text('AI Feedback',
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              color: cs.onTertiaryContainer)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(feedback,
                      style: GoogleFonts.outfit(
                          color: cs.onTertiaryContainer)),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _TipsTab extends StatelessWidget {
  final Language language;
  final LanguageLearningService service;

  const _TipsTab({required this.language, required this.service});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tips = service.getLanguageTips(language);
    final lines = tips.split('\n').where((l) => l.trim().isNotEmpty).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: cs.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    lines.isNotEmpty ? lines.first : 'Tips',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: cs.onPrimaryContainer)),
                const SizedBox(height: 12),
                ...lines.skip(1).map((line) {
                  final tip = line.startsWith('• ')
                      ? line.substring(2)
                      : line;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lightbulb_outline_rounded,
                            size: 18,
                            color: cs.onPrimaryContainer.withAlpha(180)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(tip,
                              style: GoogleFonts.outfit(
                                  color: cs.onPrimaryContainer)),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
