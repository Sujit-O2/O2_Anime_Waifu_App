import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:anime_waifu/services/productivity/project_management_service.dart';
import 'package:anime_waifu/services/database_storage/app_db.dart';

class ProjectManagementPage extends StatefulWidget {
  const ProjectManagementPage({super.key});

  @override
  State<ProjectManagementPage> createState() => _ProjectManagementPageState();
}

class _ProjectManagementPageState extends State<ProjectManagementPage>
    with SingleTickerProviderStateMixin {
  final _service = ProjectManagementService.instance;
  late TabController _tabs;
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _taskTitleCtrl = TextEditingController();
  final _taskDescCtrl = TextEditingController();
  DateTime _deadline = DateTime.now().add(const Duration(days: 30));
  DateTime _taskDue = DateTime.now().add(const Duration(days: 7));
  ProjectPriority _priority = ProjectPriority.medium;
  TaskPriority _taskPriority = TaskPriority.medium;
  String? _selectedProjectId;
  bool _loading = true;
  bool _creating = false;

  static const _bg = Color(0xFF0A0B14);
  static const _accent = Color(0xFF00BCD4);

  static const _priorityColors = {
    ProjectPriority.low: Color(0xFF81C784),
    ProjectPriority.medium: Color(0xFFFFB74D),
    ProjectPriority.high: Color(0xFFFF7043),
    ProjectPriority.critical: Color(0xFFEF5350),
  };

  static const _priorityEmojis = {
    ProjectPriority.low: '🟢',
    ProjectPriority.medium: '🟡',
    ProjectPriority.high: '🟠',
    ProjectPriority.critical: '🔴',
  };

  @override
  void initState() {
    super.initState();
    unawaited(AppDB.instance.recordUsage('project_mgmt'));
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _taskTitleCtrl.dispose();
    _taskDescCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await _service.initialize();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _createProject() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() => _creating = true);
    await _service.createProject(
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty
          ? 'No description'
          : _descCtrl.text.trim(),
      deadline: _deadline,
      priority: _priority,
      milestones: [],
    );
    _titleCtrl.clear();
    _descCtrl.clear();
    if (mounted) {
      setState(() => _creating = false);
      _tabs.animateTo(1);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Project created! 📋',
            style: GoogleFonts.outfit(color: Colors.white)),
        backgroundColor: _accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  Future<void> _createTask() async {
    if (_taskTitleCtrl.text.trim().isEmpty || _selectedProjectId == null) {
      return;
    }
    HapticFeedback.mediumImpact();
    await _service.createTask(
      projectId: _selectedProjectId!,
      title: _taskTitleCtrl.text.trim(),
      description: _taskDescCtrl.text.trim().isEmpty
          ? 'No description'
          : _taskDescCtrl.text.trim(),
      priority: _taskPriority,
      dueDate: _taskDue,
      subtasks: [],
    );
    _taskTitleCtrl.clear();
    _taskDescCtrl.clear();
    if (mounted) setState(() {});
  }

  Future<void> _pickDate(bool isProject) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isProject ? _deadline : _taskDue,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: _accent),
        ),
        child: child!,
      ),
    );
    if (date != null) {
      setState(() {
        if (isProject) {
          _deadline = date;
        } else {
          _taskDue = date;
        }
      });
    }
  }

  Color _pColor(ProjectPriority p) => _priorityColors[p] ?? Colors.cyanAccent;
  String _pEmoji(ProjectPriority p) => _priorityEmojis[p] ?? '⚪';

  String _daysUntil(DateTime dt) {
    final diff = dt.difference(DateTime.now()).inDays;
    if (diff < 0) return 'Overdue';
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    return 'In $diff days';
  }

  Color _statusColor(ProjectStatus s) {
    switch (s) {
      case ProjectStatus.active:
        return Colors.cyanAccent;
      case ProjectStatus.completed:
        return Colors.greenAccent;
      case ProjectStatus.onHold:
        return Colors.amberAccent;
      case ProjectStatus.cancelled:
        return Colors.redAccent;
    }
  }

  Color _taskStatusColor(TaskStatus s) {
    switch (s) {
      case TaskStatus.todo:
        return Colors.white38;
      case TaskStatus.inProgress:
        return Colors.cyanAccent;
      case TaskStatus.completed:
        return Colors.greenAccent;
      case TaskStatus.blocked:
        return Colors.redAccent;
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
        title: Text('📋 Project Management',
            style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              controller: _tabs,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: _accent.withValues(alpha: 0.2),
                border: Border.all(color: _accent.withValues(alpha: 0.4)),
              ),
              labelColor: _accent,
              unselectedLabelColor: Colors.white38,
              labelStyle:
                  GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13),
              tabs: const [
                Tab(text: 'New'),
                Tab(text: 'Projects'),
                Tab(text: 'Tasks'),
              ],
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : TabBarView(
              controller: _tabs,
              children: [
                _buildCreateTab(),
                _buildProjectsTab(),
                _buildTasksTab(),
              ],
            ),
    );
  }

  Widget _buildCreateTab() {
    final activeColor = _pColor(_priority);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Insights
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              _accent.withValues(alpha: 0.1),
              Colors.transparent,
            ]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _accent.withValues(alpha: 0.3)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.insights_rounded, color: _accent, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(_service.getProjectInsights(),
                  style: GoogleFonts.outfit(
                      color: Colors.white70, fontSize: 13, height: 1.4)),
            ),
          ]),
        ),
        const SizedBox(height: 16),

        // Form
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Create Project',
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
            const SizedBox(height: 16),

            _field(_titleCtrl, 'Project Title *', Icons.folder_rounded),
            const SizedBox(height: 12),
            _field(_descCtrl, 'Description', Icons.description_rounded,
                maxLines: 3),
            const SizedBox(height: 16),

            // Priority
            Text('Priority',
                style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 8),
            Row(
              children: ProjectPriority.values.map((p) {
                final sel = _priority == p;
                final c = _pColor(p);
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _priority = p);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: sel
                            ? c.withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color:
                                sel ? c.withValues(alpha: 0.5) : Colors.white12,
                            width: 1.5),
                      ),
                      child: Column(children: [
                        Text(_pEmoji(p), style: const TextStyle(fontSize: 18)),
                        const SizedBox(height: 4),
                        Text(p.name.toUpperCase(),
                            style: GoogleFonts.outfit(
                                color: sel ? c : Colors.white38,
                                fontSize: 9,
                                fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Deadline
            GestureDetector(
              onTap: () => _pickDate(true),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: activeColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: activeColor.withValues(alpha: 0.4)),
                ),
                child: Row(children: [
                  Icon(Icons.calendar_today_rounded,
                      color: activeColor, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Target Deadline',
                              style: GoogleFonts.outfit(
                                  color: Colors.white38, fontSize: 10)),
                          Text(
                            '${_deadline.day}/${_deadline.month}/${_deadline.year}  •  ${_daysUntil(_deadline)}',
                            style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14),
                          ),
                        ]),
                  ),
                  Icon(Icons.edit_rounded,
                      color: activeColor.withValues(alpha: 0.6), size: 18),
                ]),
              ),
            ),
            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00BCD4), Color(0xFF008BA3)],
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: _accent.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _creating ? null : _createProject,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(_creating ? 'CREATING...' : 'CREATE PROJECT',
                      style: GoogleFonts.outfit(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          letterSpacing: 1.2)),
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildProjectsTab() {
    final projects = _service.getProjects();
    if (projects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📋', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text('No projects yet',
                style: GoogleFonts.outfit(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                    fontSize: 16)),
            const SizedBox(height: 8),
            Text('Create your first project in the New tab',
                style: GoogleFonts.outfit(color: Colors.white38, fontSize: 13)),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...projects.map((p) {
          final c = _pColor(p.priority);
          final sc = _statusColor(p.status);
          final tasks = _service.getTasksForProject(p.id);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.withValues(alpha: 0.2)),
            ),
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(_pEmoji(p.priority),
                            style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(p.title,
                              style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: sc.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(p.status.name,
                              style:
                                  GoogleFonts.outfit(color: sc, fontSize: 10)),
                        ),
                      ]),
                      const SizedBox(height: 6),
                      Text(p.description,
                          style: GoogleFonts.outfit(
                              color: Colors.white54, fontSize: 12, height: 1.4),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 10),
                      // Progress bar
                      Row(children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: p.progress.clamp(0.0, 1.0),
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.08),
                              valueColor: AlwaysStoppedAnimation(c),
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text('${(p.progress * 100).toStringAsFixed(0)}%',
                            style: GoogleFonts.outfit(
                                color: c,
                                fontWeight: FontWeight.w700,
                                fontSize: 12)),
                      ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        const Icon(Icons.calendar_today_rounded,
                            color: Colors.white38, size: 12),
                        const SizedBox(width: 4),
                        Text(_daysUntil(p.deadline),
                            style: GoogleFonts.outfit(
                                color: Colors.white38, fontSize: 11)),
                        const Spacer(),
                        const Icon(Icons.task_alt_rounded,
                            color: Colors.white38, size: 12),
                        const SizedBox(width: 4),
                        Text('${tasks.length} tasks',
                            style: GoogleFonts.outfit(
                                color: Colors.white38, fontSize: 11)),
                      ]),
                    ]),
              ),
            ]),
          );
        }),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildTasksTab() {
    final projects = _service.getProjects();
    final overdue = _service.getOverdueTasks();
    final upcoming = _service.getUpcomingTasks();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Add task form
        if (projects.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Add Task',
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
              const SizedBox(height: 12),

              // Project selector
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedProjectId,
                    hint: Text('Select Project',
                        style: GoogleFonts.outfit(
                            color: Colors.white30, fontSize: 13)),
                    dropdownColor: const Color(0xFF1A1B2E),
                    style:
                        GoogleFonts.outfit(color: Colors.white, fontSize: 13),
                    icon: const Icon(Icons.expand_more_rounded,
                        color: Colors.white38),
                    isExpanded: true,
                    items: projects
                        .map((p) => DropdownMenuItem(
                              value: p.id,
                              child: Text(p.title),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedProjectId = v),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _field(_taskTitleCtrl, 'Task Title *',
                  Icons.check_circle_outline_rounded),
              const SizedBox(height: 10),
              _field(_taskDescCtrl, 'Description', Icons.description_rounded,
                  maxLines: 2),
              const SizedBox(height: 10),

              // Task priority
              Row(
                children: TaskPriority.values.map((p) {
                  final sel = _taskPriority == p;
                  const colors = {
                    TaskPriority.low: Colors.greenAccent,
                    TaskPriority.medium: Colors.amberAccent,
                    TaskPriority.high: Colors.orangeAccent,
                    TaskPriority.urgent: Colors.redAccent,
                  };
                  final c = colors[p] ?? Colors.white;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _taskPriority = p);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: sel
                              ? c.withValues(alpha: 0.15)
                              : Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: sel
                                  ? c.withValues(alpha: 0.5)
                                  : Colors.white12),
                        ),
                        child: Center(
                          child: Text(p.name,
                              style: GoogleFonts.outfit(
                                  color: sel ? c : Colors.white38,
                                  fontSize: 10,
                                  fontWeight: sel
                                      ? FontWeight.w700
                                      : FontWeight.normal)),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),

              // Due date
              GestureDetector(
                onTap: () => _pickDate(false),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _accent.withValues(alpha: 0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.event_rounded, color: _accent, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Due: ${_taskDue.day}/${_taskDue.month}/${_taskDue.year}  •  ${_daysUntil(_taskDue)}',
                      style: GoogleFonts.outfit(
                          color: Colors.white70, fontSize: 12),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _createTask,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text('Add Task',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),
        ],

        // Overdue tasks
        if (overdue.isNotEmpty) ...[
          _sectionLabel('⚠️ Overdue (${overdue.length})'),
          const SizedBox(height: 8),
          ...overdue.map((t) => _taskCard(t, Colors.redAccent)),
          const SizedBox(height: 12),
        ],

        // Upcoming tasks
        if (upcoming.isNotEmpty) ...[
          _sectionLabel('📅 Due This Week (${upcoming.length})'),
          const SizedBox(height: 8),
          ...upcoming.map((t) => _taskCard(t, Colors.amberAccent)),
          const SizedBox(height: 12),
        ],

        if (overdue.isEmpty && upcoming.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(children: [
              const Text('✅', style: TextStyle(fontSize: 36)),
              const SizedBox(height: 12),
              Text('All caught up!',
                  style: GoogleFonts.outfit(
                      color: Colors.white70, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('No overdue or upcoming tasks',
                  style:
                      GoogleFonts.outfit(color: Colors.white38, fontSize: 12)),
            ]),
          ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _taskCard(Task t, Color accentColor) {
    final sc = _taskStatusColor(t.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: sc.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.task_alt_rounded, color: sc, size: 14),
        ),
        const SizedBox(width: 10),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t.title,
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
            Text(_daysUntil(t.dueDate),
                style: GoogleFonts.outfit(color: accentColor, fontSize: 11)),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: sc.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(t.status.name,
              style: GoogleFonts.outfit(color: sc, fontSize: 10)),
        ),
      ]),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(label,
        style: GoogleFonts.outfit(
            color: Colors.white54,
            fontWeight: FontWeight.w700,
            fontSize: 12,
            letterSpacing: 0.8));
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon,
      {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.outfit(color: Colors.white30, fontSize: 12),
        prefixIcon:
            maxLines == 1 ? Icon(icon, color: Colors.white38, size: 18) : null,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.04),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                BorderSide(color: Colors.white.withValues(alpha: 0.08))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: _accent.withValues(alpha: 0.5))),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}
