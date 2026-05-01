import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:anime_waifu/services/productivity/academic_research_service.dart';

class AcademicResearchPage extends StatefulWidget {
  const AcademicResearchPage({super.key});

  @override
  State<AcademicResearchPage> createState() => _AcademicResearchPageState();
}

class _AcademicResearchPageState extends State<AcademicResearchPage>
    with SingleTickerProviderStateMixin {
  final _service = AcademicResearchService.instance;
  late TabController _tabs;
  final _titleCtrl = TextEditingController();
  final _topicCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime _deadline = DateTime.now().add(const Duration(days: 90));
  ResearchLevel _level = ResearchLevel.undergraduate;
  bool _loading = true;
  bool _saving = false;

  static const _bg = Color(0xFF0A0B14);
  static const _accent = Color(0xFF7C4DFF);

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _titleCtrl.dispose();
    _topicCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await _service.initialize();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _createProject() async {
    if (_titleCtrl.text.trim().isEmpty || _topicCtrl.text.trim().isEmpty) {
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _saving = true);
    await _service.createResearchProject(
      title: _titleCtrl.text.trim(),
      topic: _topicCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty
          ? 'Research project'
          : _descCtrl.text.trim(),
      deadline: _deadline,
      level: _level,
    );
    _titleCtrl.clear();
    _topicCtrl.clear();
    _descCtrl.clear();
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Research project created! 📚',
            style: GoogleFonts.outfit(color: Colors.white)),
        backgroundColor: _accent,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  Future<void> _pickDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: _accent),
        ),
        child: child!,
      ),
    );
    if (date != null) setState(() => _deadline = date);
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
        title: Text('📚 Academic Research',
            style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18)),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: _accent,
          labelColor: _accent,
          unselectedLabelColor: Colors.white38,
          labelStyle:
              GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: 'New Project'),
            Tab(text: 'Analytics'),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: _accent))
          : TabBarView(
              controller: _tabs,
              children: [_buildCreateTab(), _buildAnalyticsTab()],
            ),
    );
  }

  Widget _buildCreateTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header info card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _accent.withValues(alpha: 0.18),
                _accent.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _accent.withValues(alpha: 0.35)),
          ),
          child: Row(children: [
            const Text('🎓', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Research Assistant',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                Text(
                    'Organize your research projects, manage sources, and track progress.',
                    style: GoogleFonts.outfit(
                        color: Colors.white54,
                        fontSize: 12,
                        height: 1.4)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 16),

        // Form
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
            Text('Project Details',
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
            const SizedBox(height: 14),

            _field(_titleCtrl, 'Project Title *', Icons.title_rounded),
            const SizedBox(height: 10),
            _field(_topicCtrl, 'Research Topic *', Icons.topic_rounded),
            const SizedBox(height: 10),
            _field(_descCtrl, 'Description', Icons.description_rounded,
                maxLines: 3),
            const SizedBox(height: 14),

            // Level selector
            Text('Research Level',
                style: GoogleFonts.outfit(
                    color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ResearchLevel.values.map((l) {
                final sel = _level == l;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _level = l);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: sel
                          ? _accent.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: sel
                              ? _accent.withValues(alpha: 0.6)
                              : Colors.white12),
                    ),
                    child: Text(l.name,
                        style: GoogleFonts.outfit(
                            color: sel ? _accent : Colors.white54,
                            fontSize: 12,
                            fontWeight: sel
                                ? FontWeight.w700
                                : FontWeight.normal)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // Deadline picker
            GestureDetector(
              onTap: _pickDeadline,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: _accent.withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.calendar_today_rounded,
                      color: _accent, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('Deadline',
                          style: GoogleFonts.outfit(
                              color: Colors.white38, fontSize: 10)),
                      Text(
                        '${_deadline.day}/${_deadline.month}/${_deadline.year}',
                        style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13),
                      ),
                    ]),
                  ),
                  Icon(Icons.edit_rounded,
                      color: _accent.withValues(alpha: 0.5), size: 16),
                ]),
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _createProject,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.add_rounded, size: 18),
                label: Text(
                    _saving ? 'Creating...' : 'Create Research Project',
                    style:
                        GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildAnalyticsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _accent.withValues(alpha: 0.25)),
          ),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Row(children: [
              const Icon(Icons.analytics_rounded,
                  color: _accent, size: 16),
              const SizedBox(width: 8),
              Text('Study Analytics',
                  style: GoogleFonts.outfit(
                      color: _accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
            ]),
            const SizedBox(height: 10),
            Text(_service.getStudyAnalytics(),
                style: GoogleFonts.outfit(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.5)),
          ]),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon,
      {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.outfit(color: Colors.white30, fontSize: 12),
        prefixIcon: maxLines == 1
            ? Icon(icon, color: Colors.white38, size: 18)
            : null,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.04),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.08))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                BorderSide(color: _accent.withValues(alpha: 0.5))),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}
