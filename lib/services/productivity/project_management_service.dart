import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 📋 Project Management Assistant Service
///
/// Break down complex tasks, set milestones, and track progress.
class ProjectManagementService {
  ProjectManagementService._();
  static final ProjectManagementService instance = ProjectManagementService._();

  final List<Project> _projects = [];
  final List<Task> _tasks = [];

  int _totalProjects = 0;
  int _totalTasks = 0;
  int _completedTasks = 0;
  DateTime? _lastUpdate;

  static const String _storageKey = 'project_management_v1';

  Future<void> initialize() async {
    await _loadData();
    if (kDebugMode)
      debugPrint(
          '[ProjectManagement] Initialized with $_totalProjects projects');
  }

  Future<Project> createProject({
    required String title,
    required String description,
    required DateTime deadline,
    required ProjectPriority priority,
    required List<String> milestones,
  }) async {
    final project = Project(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      deadline: deadline,
      priority: priority,
      milestones:
          milestones.map((m) => Milestone(title: m, completed: false)).toList(),
      status: ProjectStatus.active,
      progress: 0.0,
      createdAt: DateTime.now(),
    );

    _projects.add(project);
    _totalProjects++;
    _lastUpdate = DateTime.now();

    await _saveData();

    if (kDebugMode) debugPrint('[ProjectManagement] Created project: $title');
    return project;
  }

  Future<Task> createTask({
    required String projectId,
    required String title,
    required String description,
    required TaskPriority priority,
    required DateTime dueDate,
    required List<String> subtasks,
  }) async {
    final task = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      projectId: projectId,
      title: title,
      description: description,
      priority: priority,
      dueDate: dueDate,
      subtasks:
          subtasks.map((s) => Subtask(title: s, completed: false)).toList(),
      status: TaskStatus.todo,
      progress: 0.0,
      createdAt: DateTime.now(),
    );

    _tasks.add(task);
    _totalTasks++;
    _lastUpdate = DateTime.now();

    await _saveData();

    if (kDebugMode) debugPrint('[ProjectManagement] Created task: $title');
    return task;
  }

  Future<void> updateTaskProgress(String taskId, double progress) async {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) return;

    final task = _tasks[taskIndex];
    _tasks[taskIndex] = task.copyWith(progress: progress.clamp(0.0, 1.0));

    if (progress >= 1.0) {
      _tasks[taskIndex] =
          _tasks[taskIndex].copyWith(status: TaskStatus.completed);
      _completedTasks++;
    }

    _updateProjectProgress(task.projectId);
    _lastUpdate = DateTime.now();
    await _saveData();
  }

  Future<void> completeSubtask(String taskId, String subtaskTitle) async {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) return;

    final task = _tasks[taskIndex];
    final updatedSubtasks = task.subtasks.map((s) {
      if (s.title == subtaskTitle) {
        return Subtask(title: s.title, completed: true);
      }
      return s;
    }).toList();

    final completedCount = updatedSubtasks.where((s) => s.completed).length;
    final progress = completedCount / updatedSubtasks.length;

    _tasks[taskIndex] = task.copyWith(
      subtasks: updatedSubtasks,
      progress: progress,
      status: progress >= 1.0 ? TaskStatus.completed : TaskStatus.inProgress,
    );

    if (progress >= 1.0) {
      _completedTasks++;
    }

    _updateProjectProgress(task.projectId);
    _lastUpdate = DateTime.now();
    await _saveData();
  }

  Future<void> completeMilestone(
      String projectId, String milestoneTitle) async {
    final projectIndex = _projects.indexWhere((p) => p.id == projectId);
    if (projectIndex == -1) return;

    final project = _projects[projectIndex];
    final updatedMilestones = project.milestones.map((m) {
      if (m.title == milestoneTitle) {
        return Milestone(title: m.title, completed: true);
      }
      return m;
    }).toList();

    _projects[projectIndex] = project.copyWith(milestones: updatedMilestones);
    _updateProjectProgress(projectId);
    _lastUpdate = DateTime.now();
    await _saveData();
  }

  void _updateProjectProgress(String projectId) {
    final projectIndex = _projects.indexWhere((p) => p.id == projectId);
    if (projectIndex == -1) return;

    final projectTasks = _tasks.where((t) => t.projectId == projectId).toList();
    if (projectTasks.isEmpty) return;

    final avgProgress =
        projectTasks.fold<double>(0, (sum, t) => sum + t.progress) /
            projectTasks.length;

    final project = _projects[projectIndex];
    _projects[projectIndex] = project.copyWith(progress: avgProgress);

    // Update project status
    if (avgProgress >= 1.0) {
      _projects[projectIndex] =
          _projects[projectIndex].copyWith(status: ProjectStatus.completed);
    } else if (avgProgress > 0) {
      _projects[projectIndex] =
          _projects[projectIndex].copyWith(status: ProjectStatus.active);
    }
  }

  List<Task> getTasksForProject(String projectId) {
    return _tasks.where((t) => t.projectId == projectId).toList();
  }

  List<Task> getOverdueTasks() {
    final now = DateTime.now();
    return _tasks
        .where(
            (t) => t.dueDate.isBefore(now) && t.status != TaskStatus.completed)
        .toList();
  }

  List<Task> getUpcomingTasks({int days = 7}) {
    final now = DateTime.now();
    final future = now.add(Duration(days: days));
    return _tasks
        .where((t) =>
            t.dueDate.isAfter(now) &&
            t.dueDate.isBefore(future) &&
            t.status != TaskStatus.completed)
        .toList();
  }

  String getProjectInsights() {
    if (_projects.isEmpty) {
      return 'Create your first project to get started!';
    }

    final activeProjects =
        _projects.where((p) => p.status == ProjectStatus.active).length;
    final completedProjects =
        _projects.where((p) => p.status == ProjectStatus.completed).length;
    final avgProgress =
        _projects.fold<double>(0, (sum, p) => sum + p.progress) /
            _projects.length;

    final overdueTasks = getOverdueTasks();
    final upcomingTasks = getUpcomingTasks();

    final buffer = StringBuffer();
    buffer.writeln('📋 Project Overview:');
    buffer.writeln('• Total Projects: $_totalProjects');
    buffer.writeln('• Active: $activeProjects | Completed: $completedProjects');
    buffer.writeln(
        '• Overall Progress: ${(avgProgress * 100).toStringAsFixed(0)}%');
    buffer.writeln('• Tasks Completed: $_completedTasks/$_totalTasks');

    if (overdueTasks.isNotEmpty) {
      buffer.writeln(
          '\n⚠️ ${overdueTasks.length} overdue task(s) need attention!');
    }

    if (upcomingTasks.isNotEmpty) {
      buffer.writeln(
          '\n📅 ${upcomingTasks.length} task(s) due in the next 7 days');
    }

    return buffer.toString();
  }

  String getTaskBreakdown(String projectId) {
    final project = _projects.firstWhere((p) => p.id == projectId);
    final projectTasks = getTasksForProject(projectId);

    final todoTasks =
        projectTasks.where((t) => t.status == TaskStatus.todo).length;
    final inProgressTasks =
        projectTasks.where((t) => t.status == TaskStatus.inProgress).length;
    final completedTasks =
        projectTasks.where((t) => t.status == TaskStatus.completed).length;

    final buffer = StringBuffer();
    buffer.writeln('📊 Task Breakdown for "${project.title}":');
    buffer.writeln('• To Do: $todoTasks');
    buffer.writeln('• In Progress: $inProgressTasks');
    buffer.writeln('• Completed: $completedTasks');
    buffer.writeln(
        '• Project Progress: ${(project.progress * 100).toStringAsFixed(0)}%');

    // Milestone status
    final completedMilestones =
        project.milestones.where((m) => m.completed).length;
    buffer.writeln(
        '\n🎯 Milestones: $completedMilestones/${project.milestones.length} completed');

    return buffer.toString();
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'projects': _projects.map((p) => p.toJson()).toList(),
        'tasks': _tasks.map((t) => t.toJson()).toList(),
        'totalProjects': _totalProjects,
        'totalTasks': _totalTasks,
        'completedTasks': _completedTasks,
        'lastUpdate': _lastUpdate?.toIso8601String(),
      };
      await prefs.setString(_storageKey, jsonEncode(data));
    } catch (e) {
      if (kDebugMode) debugPrint('[ProjectManagement] Save error: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString != null && jsonString.isNotEmpty) {
        final data = jsonDecode(jsonString) as Map<String, dynamic>;

        _projects.clear();
        _projects.addAll((data['projects'] as List<dynamic>)
            .map((p) => Project.fromJson(p as Map<String, dynamic>)));

        _tasks.clear();
        _tasks.addAll((data['tasks'] as List<dynamic>)
            .map((t) => Task.fromJson(t as Map<String, dynamic>)));

        _totalProjects = data['totalProjects'] as int;
        _totalTasks = data['totalTasks'] as int;
        _completedTasks = data['completedTasks'] as int;

        if (data['lastUpdate'] != null) {
          _lastUpdate = DateTime.parse(data['lastUpdate'] as String);
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[ProjectManagement] Load error: $e');
    }
  }
}

class Project {
  final String id;
  final String title;
  final String description;
  final DateTime deadline;
  final ProjectPriority priority;
  final List<Milestone> milestones;
  final ProjectStatus status;
  final double progress;
  final DateTime createdAt;

  Project({
    required this.id,
    required this.title,
    required this.description,
    required this.deadline,
    required this.priority,
    required this.milestones,
    required this.status,
    required this.progress,
    required this.createdAt,
  });

  Project copyWith({
    String? title,
    String? description,
    DateTime? deadline,
    ProjectPriority? priority,
    List<Milestone>? milestones,
    ProjectStatus? status,
    double? progress,
  }) {
    return Project(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline,
      priority: priority ?? this.priority,
      milestones: milestones ?? this.milestones,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'deadline': deadline.toIso8601String(),
        'priority': priority.name,
        'milestones': milestones.map((m) => m.toJson()).toList(),
        'status': status.name,
        'progress': progress,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        deadline: DateTime.parse(json['deadline']),
        priority: ProjectPriority.values.firstWhere(
          (e) => e.name == json['priority'],
          orElse: () => ProjectPriority.medium,
        ),
        milestones: (json['milestones'] as List<dynamic>)
            .map((m) => Milestone.fromJson(m as Map<String, dynamic>))
            .toList(),
        status: ProjectStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => ProjectStatus.active,
        ),
        progress: (json['progress'] as num).toDouble(),
        createdAt: DateTime.parse(json['createdAt']),
      );
}

class Task {
  final String id;
  final String projectId;
  final String title;
  final String description;
  final TaskPriority priority;
  final DateTime dueDate;
  final List<Subtask> subtasks;
  final TaskStatus status;
  final double progress;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.projectId,
    required this.title,
    required this.description,
    required this.priority,
    required this.dueDate,
    required this.subtasks,
    required this.status,
    required this.progress,
    required this.createdAt,
  });

  Task copyWith({
    String? title,
    String? description,
    TaskPriority? priority,
    DateTime? dueDate,
    List<Subtask>? subtasks,
    TaskStatus? status,
    double? progress,
  }) {
    return Task(
      id: id,
      projectId: projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      subtasks: subtasks ?? this.subtasks,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'title': title,
        'description': description,
        'priority': priority.name,
        'dueDate': dueDate.toIso8601String(),
        'subtasks': subtasks.map((s) => s.toJson()).toList(),
        'status': status.name,
        'progress': progress,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'],
        projectId: json['projectId'],
        title: json['title'],
        description: json['description'],
        priority: TaskPriority.values.firstWhere(
          (e) => e.name == json['priority'],
          orElse: () => TaskPriority.medium,
        ),
        dueDate: DateTime.parse(json['dueDate']),
        subtasks: (json['subtasks'] as List<dynamic>)
            .map((s) => Subtask.fromJson(s as Map<String, dynamic>))
            .toList(),
        status: TaskStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => TaskStatus.todo,
        ),
        progress: (json['progress'] as num).toDouble(),
        createdAt: DateTime.parse(json['createdAt']),
      );
}

class Milestone {
  final String title;
  final bool completed;

  Milestone({required this.title, required this.completed});

  Map<String, dynamic> toJson() => {
        'title': title,
        'completed': completed,
      };

  factory Milestone.fromJson(Map<String, dynamic> json) => Milestone(
        title: json['title'],
        completed: json['completed'],
      );
}

class Subtask {
  final String title;
  final bool completed;

  Subtask({required this.title, required this.completed});

  Map<String, dynamic> toJson() => {
        'title': title,
        'completed': completed,
      };

  factory Subtask.fromJson(Map<String, dynamic> json) => Subtask(
        title: json['title'],
        completed: json['completed'],
      );
}

enum ProjectPriority { low, medium, high, critical }

enum ProjectStatus { active, completed, onHold, cancelled }

enum TaskPriority { low, medium, high, urgent }

enum TaskStatus { todo, inProgress, completed, blocked }
