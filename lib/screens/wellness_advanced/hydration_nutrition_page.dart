import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:anime_waifu/services/wellness/hydration_nutrition_service.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:anime_waifu/config/app_themes.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class HydrationNutritionPage extends StatefulWidget {
  const HydrationNutritionPage({super.key});
  @override
  State<HydrationNutritionPage> createState() => _HydrationNutritionPageState();
}

class _HydrationNutritionPageState extends State<HydrationNutritionPage> {
  final _service = HydrationNutritionService.instance;
  final _mealCtrl = TextEditingController();
  final _calCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController();
  bool _loading = true;
  bool _savingMeal = false;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _mealCtrl.dispose();
    _calCtrl.dispose();
    _proteinCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await _service.initialize();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _logWater(int ml) async {
    HapticFeedback.mediumImpact();
    await _service.logWaterIntake(ml);
    if (mounted) {
      setState(() {});
      showSuccessSnackbar(context, '+${ml}ml logged 💧');
    }
  }

  Future<void> _logMeal() async {
    final desc = _mealCtrl.text.trim();
    final cal = int.tryParse(_calCtrl.text.trim()) ?? 0;
    final protein = double.tryParse(_proteinCtrl.text.trim()) ?? 0;
    if (desc.isEmpty || cal <= 0) return;
    HapticFeedback.mediumImpact();
    setState(() => _savingMeal = true);
    await _service.logMeal(description: desc, calories: cal, protein: protein, carbs: 0, fat: 0, fiber: 0, sugar: 0);
    _mealCtrl.clear(); _calCtrl.clear(); _proteinCtrl.clear();
    if (mounted) {
      setState(() => _savingMeal = false);
      showSuccessSnackbar(context, 'Meal logged 🍽️');
    }
  }

  double get _waterProgress => (_service.getTodayWaterIntakeMl() / 2500).clamp(0.0, 1.0);
  double get _calProgress => (_service.getTodayCalories() / 2000).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.appTokens;
    // ignore: unused_local_variable
    final primary = theme.colorScheme.primary;
    final waterMl = _service.getTodayWaterIntakeMl();
    final calories = _service.getTodayCalories();
    final meals = _service.getRecentMeals();
    final waterLogs = _service.getRecentWaterLogs(limit: 5);

    return FeaturePageV2(
      title: 'HYDRATION & NUTRITION',
      subtitle: _tab == 0 ? '${waterMl}ml today' : '${calories}kcal today',
      onBack: () => Navigator.pop(context),
      actions: [
        GestureDetector(
          onTap: _load,
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: tokens.panelMuted, borderRadius: BorderRadius.circular(10), border: Border.all(color: tokens.outlineStrong)),
            child: Icon(Icons.refresh_rounded, color: tokens.textMuted, size: 18),
          ),
        ),
      ],
      content: _loading
          ? const PremiumLoadingState(label: 'Loading health data…', icon: Icons.water_drop_rounded)
          : Column(children: [
              // ── Tab bar ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(children: [
                  Expanded(child: _tabBtn('💧 Water', 0, Colors.lightBlueAccent)),
                  const SizedBox(width: 8),
                  Expanded(child: _tabBtn('🍽️ Nutrition', 1, Colors.orangeAccent)),
                ]),
              ),
              const SizedBox(height: 8),

              Expanded(
                child: _tab == 0
                    ? _buildWaterTab(waterMl, waterLogs)
                    : _buildNutritionTab(calories, meals),
              ),
            ]),
    );
  }

  Widget _buildWaterTab(int waterMl, List<dynamic> logs) {
    final theme = Theme.of(context);
    final tokens = context.appTokens;
    // ignore: unused_local_variable
    final primary = theme.colorScheme.primary;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        AnimatedEntry(
          index: 0,
          child: GlassCard(
            margin: EdgeInsets.zero,
            glow: true,
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Daily hydration', style: GoogleFonts.outfit(color: tokens.textSoft, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text('$waterMl ml', style: GoogleFonts.outfit(color: theme.colorScheme.onSurface, fontSize: 24, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: _waterProgress),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) => ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(value: v, backgroundColor: tokens.outline, valueColor: const AlwaysStoppedAnimation(Colors.lightBlueAccent), minHeight: 10),
                  ),
                ),
                const SizedBox(height: 4),
                Text('Goal: 2500 ml  •  ${(_waterProgress * 100).toStringAsFixed(0)}% complete', style: GoogleFonts.outfit(color: tokens.textMuted, fontSize: 11)),
              ])),
              const SizedBox(width: 16),
              RepaintBoundary(
                child: ProgressRing(
                  progress: _waterProgress,
                  foreground: Colors.lightBlueAccent,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text('💧', style: TextStyle(fontSize: 24)),
                    const SizedBox(height: 4),
                    Text('${(_waterProgress * 100).toStringAsFixed(0)}%', style: GoogleFonts.outfit(color: theme.colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w800)),
                    Text('Done', style: GoogleFonts.outfit(color: tokens.textMuted, fontSize: 10)),
                  ]),
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        AnimatedEntry(
          index: 1,
          child: GlassCard(
            margin: EdgeInsets.zero,
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.water_drop_rounded, color: Colors.lightBlueAccent, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(_service.getHydrationInsights(), style: GoogleFonts.outfit(color: tokens.textMuted, fontSize: 13, height: 1.4))),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        AnimatedEntry(
          index: 2,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('QUICK ADD', style: GoogleFonts.outfit(color: tokens.textSoft, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
            const SizedBox(height: 10),
            Row(children: [
              _waterBtn('☕', '150ml', 150, Colors.amberAccent),
              const SizedBox(width: 8),
              _waterBtn('🥤', '250ml', 250, Colors.lightBlueAccent),
              const SizedBox(width: 8),
              _waterBtn('🍶', '500ml', 500, Colors.cyanAccent),
              const SizedBox(width: 8),
              _waterBtn('🫙', '750ml', 750, Colors.tealAccent),
            ]),
          ]),
        ),
        if (logs.isNotEmpty) ...[
          const SizedBox(height: 16),
          AnimatedEntry(
            index: 3,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('TODAY\'S LOG', style: GoogleFonts.outfit(color: tokens.textSoft, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
              const SizedBox(height: 10),
              ...logs.toList().asMap().entries.map((e) => AnimatedEntry(
                index: 4 + e.key,
                child: GlassCard(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  child: Row(children: [
                    const Icon(Icons.water_drop_rounded, color: Colors.lightBlueAccent, size: 18),
                    const SizedBox(width: 10),
                    Text('${e.value.amountMl} ml', style: GoogleFonts.outfit(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text('+${e.value.amountMl}ml', style: GoogleFonts.outfit(color: Colors.lightBlueAccent, fontSize: 11)),
                  ]),
                ),
              )),
            ]),
          ),
        ],
      ],
    );
  }

  Widget _buildNutritionTab(int calories, List<dynamic> meals) {
    final theme = Theme.of(context);
    final tokens = context.appTokens;
    final primary = theme.colorScheme.primary;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        AnimatedEntry(
          index: 0,
          child: GlassCard(
            margin: EdgeInsets.zero,
            glow: true,
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Daily calories', style: GoogleFonts.outfit(color: tokens.textSoft, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text('$calories kcal', style: GoogleFonts.outfit(color: theme.colorScheme.onSurface, fontSize: 24, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: _calProgress),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) => ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(value: v, backgroundColor: tokens.outline, valueColor: const AlwaysStoppedAnimation(Colors.orangeAccent), minHeight: 10),
                  ),
                ),
                const SizedBox(height: 4),
                Text('Goal: 2000 kcal  •  ${(_calProgress * 100).toStringAsFixed(0)}% complete', style: GoogleFonts.outfit(color: tokens.textMuted, fontSize: 11)),
              ])),
              const SizedBox(width: 16),
              RepaintBoundary(
                child: ProgressRing(
                  progress: _calProgress,
                  foreground: Colors.orangeAccent,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text('🔥', style: TextStyle(fontSize: 24)),
                    const SizedBox(height: 4),
                    Text('${(_calProgress * 100).toStringAsFixed(0)}%', style: GoogleFonts.outfit(color: theme.colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w800)),
                    Text('Done', style: GoogleFonts.outfit(color: tokens.textMuted, fontSize: 10)),
                  ]),
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        AnimatedEntry(
          index: 1,
          child: GlassCard(
            margin: EdgeInsets.zero,
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.restaurant_rounded, color: Colors.orangeAccent, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(_service.getNutritionInsights(), style: GoogleFonts.outfit(color: tokens.textMuted, fontSize: 13, height: 1.4))),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        AnimatedEntry(
          index: 2,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('LOG A MEAL', style: GoogleFonts.outfit(color: tokens.textSoft, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
            const SizedBox(height: 10),
            GlassCard(
              margin: EdgeInsets.zero,
              child: Column(children: [
                TextField(
                  controller: _mealCtrl,
                  style: GoogleFonts.outfit(color: theme.colorScheme.onSurface, fontSize: 13),
                  cursorColor: primary,
                  decoration: InputDecoration(hintText: 'Meal description', hintStyle: GoogleFonts.outfit(color: tokens.textSoft, fontSize: 12), prefixIcon: const Icon(Icons.lunch_dining_rounded, size: 18), isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: TextField(
                    controller: _calCtrl,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.outfit(color: theme.colorScheme.onSurface, fontSize: 13),
                    cursorColor: primary,
                    decoration: InputDecoration(hintText: 'Calories', hintStyle: GoogleFonts.outfit(color: tokens.textSoft, fontSize: 12), isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(
                    controller: _proteinCtrl,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.outfit(color: theme.colorScheme.onSurface, fontSize: 13),
                    cursorColor: primary,
                    decoration: InputDecoration(hintText: 'Protein (g)', hintStyle: GoogleFonts.outfit(color: tokens.textSoft, fontSize: 12), isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                  )),
                ]),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _savingMeal ? null : _logMeal,
                    icon: _savingMeal ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.add_rounded, size: 18),
                    label: Text(_savingMeal ? 'Saving…' : 'Log Meal', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                    style: FilledButton.styleFrom(backgroundColor: Colors.orangeAccent, foregroundColor: Colors.black),
                  ),
                ),
              ]),
            ),
          ]),
        ),
        if (meals.isNotEmpty) ...[
          const SizedBox(height: 16),
          AnimatedEntry(
            index: 3,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('TODAY\'S MEALS', style: GoogleFonts.outfit(color: tokens.textSoft, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
              const SizedBox(height: 10),
              ...meals.toList().asMap().entries.map((e) => AnimatedEntry(
                index: 4 + e.key,
                child: GlassCard(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.orangeAccent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.restaurant_rounded, color: Colors.orangeAccent, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(e.value.description, style: GoogleFonts.outfit(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600, fontSize: 13)),
                      Text('${e.value.calories} kcal  •  ${e.value.protein.toStringAsFixed(1)}g protein', style: GoogleFonts.outfit(color: tokens.textMuted, fontSize: 11)),
                    ])),
                  ]),
                ),
              )),
            ]),
          ),
        ],
      ],
    );
  }

  Widget _tabBtn(String label, int idx, Color color) {
    final tokens = context.appTokens;
    final sel = _tab == idx;    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); setState(() => _tab = idx); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: sel ? color.withValues(alpha: 0.12) : tokens.panelMuted,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: sel ? color.withValues(alpha: 0.4) : tokens.outline, width: sel ? 1.5 : 1),
        ),
        child: Center(child: Text(label, style: GoogleFonts.outfit(color: sel ? color : tokens.textMuted, fontWeight: sel ? FontWeight.w700 : FontWeight.normal, fontSize: 13))),
      ),
    );
  }

  Widget _waterBtn(String emoji, String label, int ml, Color color) {
    // ignore: unused_local_variable
    final tokens = context.appTokens;    return Expanded(
      child: GestureDetector(
        onTap: () => _logWater(ml),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.25))),
          child: Column(children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 2),
            Text(label, style: GoogleFonts.outfit(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
    );
  }
}
