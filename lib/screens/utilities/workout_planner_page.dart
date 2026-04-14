import 'dart:convert';

import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:anime_waifu/services/ai_personalization/ai_content_service.dart';
import 'package:anime_waifu/services/user_profile/affection_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WorkoutPlannerPage extends StatefulWidget {
  const WorkoutPlannerPage({super.key});

  @override
  State<WorkoutPlannerPage> createState() => _WorkoutPlannerPageState();
}

class _WorkoutPlannerPageState extends State<WorkoutPlannerPage> {
  static const String _cacheKey = 'workout_planner_cached_exercises';
  static const String _completedKey = 'workout_planner_completed';

  List<Map<String, dynamic>> _exercises = <Map<String, dynamic>>[];
  final Set<int> _completed = <int>{};
  bool _loading = true;

  double get _progress =>
      _exercises.isEmpty ? 0 : _completed.length / _exercises.length;

  String get _commentaryMood {
    if (_progress >= 1) {
      return 'achievement';
    }
    if (_progress > 0) {
      return 'motivated';
    }
    return 'neutral';
  }

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadCache() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_cacheKey);
    if (raw == null || raw.isEmpty) {
      return;
    }
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      _exercises = decoded
          .whereType<Map>()
          .map((Map entry) => entry.map(
                (dynamic key, dynamic value) =>
                    MapEntry(key.toString(), value),
              ))
          .toList();
      _completed
        ..clear()
        ..addAll(
          (prefs.getStringList(_completedKey) ?? <String>[])
              .map(int.tryParse)
              .whereType<int>(),
        );
    } catch (_) {}
  }

  Future<void> _saveCache() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(_exercises));
    await prefs.setStringList(
      _completedKey,
      _completed.map((int index) => index.toString()).toList(),
    );
  }

  Future<void> _loadExercises({bool forceRefresh = false}) async {
    if (mounted) {
      setState(() => _loading = true);
    }

    if (!forceRefresh) {
      await _loadCache();
      if (_exercises.isNotEmpty && mounted) {
        setState(() => _loading = false);
      }
    }

    try {
      final List<Map<String, dynamic>> exercises =
          await AiContentService.getWorkouts();
      if (!mounted) {
        return;
      }
      setState(() {
        _exercises = exercises;
        _completed.clear();
        _loading = false;
      });
      await _saveCache();
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    await _loadExercises(forceRefresh: true);
  }

  Future<void> _toggleComplete(int index) async {
    HapticFeedback.mediumImpact();
    setState(() {
      if (_completed.contains(index)) {
        _completed.remove(index);
      } else {
        _completed.add(index);
      }
    });
    await _saveCache();
    if (_completed.length == _exercises.length && _exercises.isNotEmpty) {
      AffectionService.instance.addPoints(5);
      if (mounted) {
        showSuccessSnackbar(context, 'Workout complete. +5 affection XP.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: V2Theme.surfaceDark,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: V2Theme.primaryColor,
          backgroundColor: V2Theme.surfaceLight,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            children: [
              Row(
                children: [
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
                      children: [
                        Text(
                          'WORKOUT PLANNER',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          _loading
                              ? 'Refreshing your routine'
                              : 'AI-built training session',
                          style: GoogleFonts.outfit(
                            color: Colors.redAccent.withValues(alpha: 0.8),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _loadExercises(forceRefresh: true),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.redAccent.withValues(alpha: 0.2),
                      foregroundColor: Colors.redAccent,
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Refresh'),
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
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Session progress',
                              style: GoogleFonts.outfit(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _exercises.isEmpty
                                  ? 'No routine loaded yet'
                                  : '${_completed.length} of ${_exercises.length} exercises done',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _exercises.isEmpty
                                  ? 'Pull to refresh and ask the AI planner for a fresh routine.'
                                  : 'Mark exercises as you finish them and the plan will keep your progress saved locally.',
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
                        progress: _progress,
                        foreground: Colors.redAccent,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.fitness_center_rounded,
                              color: Colors.redAccent,
                              size: 28,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${(_progress * 100).round()}%',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Done',
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
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Exercises',
                      value: '${_exercises.length}',
                      icon: Icons.list_alt_rounded,
                      color: Colors.redAccent,
                    ),
                  ),
                  Expanded(
                    child: StatCard(
                      title: 'Completed',
                      value: '${_completed.length}',
                      icon: Icons.check_circle_rounded,
                      color: Colors.greenAccent,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Progress',
                      value: '${(_progress * 100).round()}%',
                      icon: Icons.trending_up_rounded,
                      color: V2Theme.secondaryColor,
                    ),
                  ),
                  Expanded(
                    child: StatCard(
                      title: 'Source',
                      value: 'AI',
                      icon: Icons.auto_awesome_rounded,
                      color: Colors.amberAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (_loading && _exercises.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: V2Theme.primaryColor,
                    ),
                  ),
                )
              else if (_exercises.isEmpty)
                GlassCard(
                  margin: EdgeInsets.zero,
                  child: const EmptyState(
                    icon: Icons.fitness_center_rounded,
                    title: 'No workout ready',
                    subtitle:
                        'Pull to refresh and let the planner generate a new routine for the day.',
                  ),
                )
              else
                ..._exercises.asMap().entries.map(
                      (MapEntry<int, Map<String, dynamic>> entry) =>
                          AnimatedEntry(
                        index: entry.key + 2,
                        child: _buildExerciseCard(entry.value, entry.key),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseCard(Map<String, dynamic> exercise, int index) {
    final bool done = _completed.contains(index);
    final String name = exercise['name']?.toString() ?? 'Exercise';
    final String sets = exercise['sets']?.toString() ?? '';
    final String reps = exercise['reps']?.toString() ?? '';
    final String desc = exercise['desc']?.toString() ?? '';
    final String muscle = exercise['muscle']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: done
            ? Colors.greenAccent.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.04),
        border: Border.all(
          color: done
              ? Colors.greenAccent.withValues(alpha: 0.28)
              : Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _toggleComplete(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done
                    ? Colors.greenAccent.withValues(alpha: 0.2)
                    : Colors.redAccent.withValues(alpha: 0.12),
                border: Border.all(
                  color: done ? Colors.greenAccent : Colors.redAccent,
                ),
              ),
              child: Icon(
                done
                    ? Icons.check_rounded
                    : Icons.fitness_center_outlined,
                color: done ? Colors.greenAccent : Colors.redAccent,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.outfit(
                    color: done ? Colors.greenAccent : Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    decoration: done ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (sets.isNotEmpty || reps.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${sets.isNotEmpty ? 'Sets: $sets' : ''}${sets.isNotEmpty && reps.isNotEmpty ? ' | ' : ''}${reps.isNotEmpty ? 'Reps: $reps' : ''}',
                    style: GoogleFonts.outfit(
                      color: Colors.redAccent.withValues(alpha: 0.85),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (muscle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Target: $muscle',
                    style: GoogleFonts.outfit(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                ],
                if (desc.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: GoogleFonts.outfit(
                      color: Colors.white38,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            done ? Icons.star_rounded : Icons.star_border_rounded,
            color: done ? Colors.amberAccent : Colors.white24,
            size: 20,
          ),
        ],
      ),
    );
  }
}




