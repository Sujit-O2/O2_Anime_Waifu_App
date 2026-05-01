import 'package:anime_waifu/services/wellness/hydration_nutrition_service.dart';
import 'package:flutter/material.dart';
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
  int _tab = 0; // 0 = water, 1 = nutrition

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
    if (mounted) setState(() {});
  }

  Future<void> _logMeal() async {
    final desc = _mealCtrl.text.trim();
    final cal = int.tryParse(_calCtrl.text.trim()) ?? 0;
    final protein = double.tryParse(_proteinCtrl.text.trim()) ?? 0;
    if (desc.isEmpty || cal <= 0) return;
    HapticFeedback.mediumImpact();
    setState(() => _savingMeal = true);
    await _service.logMeal(
      description: desc,
      calories: cal,
      protein: protein,
      carbs: 0,
      fat: 0,
      fiber: 0,
      sugar: 0,
    );
    _mealCtrl.clear();
    _calCtrl.clear();
    _proteinCtrl.clear();
    if (mounted) setState(() => _savingMeal = false);
  }

  double get _waterProgress {
    final ml = _service.getTodayWaterIntakeMl();
    return (ml / 2500).clamp(0.0, 1.0); // goal: 2500ml
  }

  double get _calProgress {
    final cal = _service.getTodayCalories();
    return (cal / 2000).clamp(0.0, 1.0); // goal: 2000kcal
  }

  @override
  Widget build(BuildContext context) {
    final waterMl = _service.getTodayWaterIntakeMl();
    final calories = _service.getTodayCalories();
    final meals = _service.getRecentMeals();
    final waterLogs = _service.getRecentWaterLogs(limit: 5);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0B14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white60, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('💧 Hydration & Nutrition',
            style: GoogleFonts.outfit(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white38),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.lightBlueAccent))
          : Column(children: [
              // Tab bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(children: [
                  Expanded(child: _tabBtn('💧 Water', 0, Colors.lightBlueAccent)),
                  const SizedBox(width: 8),
                  Expanded(child: _tabBtn('🍽️ Nutrition', 1, Colors.orangeAccent)),
                ]),
              ),

              Expanded(
                child: _tab == 0
                    ? _buildWaterTab(waterMl, waterLogs)
                    : _buildNutritionTab(calories, meals),
              ),
            ]),
    );
  }

  Widget _buildWaterTab(int waterMl, List<dynamic> logs) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Water gauge
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.lightBlueAccent.withValues(alpha: 0.15),
                Colors.cyanAccent.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: Colors.lightBlueAccent.withValues(alpha: 0.4)),
          ),
          child: Column(children: [
            Row(children: [
              const Text('💧', style: TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Today\'s Water',
                      style: GoogleFonts.outfit(
                          color: Colors.white54, fontSize: 12)),
                  Text('$waterMl ml',
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 28)),
                  Text('Goal: 2500 ml',
                      style: GoogleFonts.outfit(
                          color: Colors.white38, fontSize: 11)),
                ]),
              ),
              Text('${(_waterProgress * 100).toStringAsFixed(0)}%',
                  style: GoogleFonts.outfit(
                      color: Colors.lightBlueAccent,
                      fontWeight: FontWeight.w800,
                      fontSize: 20)),
            ]),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _waterProgress,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                valueColor: const AlwaysStoppedAnimation(Colors.lightBlueAccent),
                minHeight: 10,
              ),
            ),
          ]),
        ),
        const SizedBox(height: 16),

        // Insights
        _infoCard(Icons.water_drop_rounded, 'Hydration Insights',
            _service.getHydrationInsights(), Colors.lightBlueAccent),
        const SizedBox(height: 16),

        // Quick add buttons
        Text('Quick Add',
            style: GoogleFonts.outfit(
                color: Colors.white54,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: 1)),
        const SizedBox(height: 10),
        Row(children: [
          _waterBtn('☕ 150ml', 150, Colors.amberAccent),
          const SizedBox(width: 8),
          _waterBtn('🥤 250ml', 250, Colors.lightBlueAccent),
          const SizedBox(width: 8),
          _waterBtn('🍶 500ml', 500, Colors.cyanAccent),
          const SizedBox(width: 8),
          _waterBtn('🫙 750ml', 750, Colors.tealAccent),
        ]),
        const SizedBox(height: 16),

        // Log history
        if (logs.isNotEmpty) ...[
          Text('Today\'s Log',
              style: GoogleFonts.outfit(
                  color: Colors.white54,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: 1)),
          const SizedBox(height: 8),
          ...logs.map((log) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.lightBlueAccent.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.lightBlueAccent.withValues(alpha: 0.2)),
                ),
                child: Row(children: [
                  const Icon(Icons.water_drop_rounded,
                      color: Colors.lightBlueAccent, size: 18),
                  const SizedBox(width: 10),
                  Text('${log.amountMl} ml',
                      style: GoogleFonts.outfit(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text('+${log.amountMl}ml',
                      style: GoogleFonts.outfit(
                          color: Colors.lightBlueAccent, fontSize: 11)),
                ]),
              )),
        ],
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildNutritionTab(int calories, List<dynamic> meals) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Calorie gauge
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.orangeAccent.withValues(alpha: 0.15),
                Colors.amberAccent.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: Colors.orangeAccent.withValues(alpha: 0.4)),
          ),
          child: Column(children: [
            Row(children: [
              const Text('🔥', style: TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Today\'s Calories',
                      style: GoogleFonts.outfit(
                          color: Colors.white54, fontSize: 12)),
                  Text('$calories kcal',
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 28)),
                  Text('Goal: 2000 kcal',
                      style: GoogleFonts.outfit(
                          color: Colors.white38, fontSize: 11)),
                ]),
              ),
              Text('${(_calProgress * 100).toStringAsFixed(0)}%',
                  style: GoogleFonts.outfit(
                      color: Colors.orangeAccent,
                      fontWeight: FontWeight.w800,
                      fontSize: 20)),
            ]),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _calProgress,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                valueColor: const AlwaysStoppedAnimation(Colors.orangeAccent),
                minHeight: 10,
              ),
            ),
          ]),
        ),
        const SizedBox(height: 16),

        // Insights
        _infoCard(Icons.restaurant_rounded, 'Nutrition Insights',
            _service.getNutritionInsights(), Colors.orangeAccent),
        const SizedBox(height: 10),
        _infoCard(Icons.tips_and_updates_rounded, 'Daily Recommendations',
            _service.getDailyRecommendations(), Colors.amberAccent),
        const SizedBox(height: 16),

        // Log meal form
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: Colors.orangeAccent.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Log a Meal',
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
              const SizedBox(height: 10),
              _inputField(_mealCtrl, 'Meal description', Icons.lunch_dining_rounded),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                    child: _inputField(_calCtrl, 'Calories',
                        Icons.local_fire_department_rounded,
                        type: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(
                    child: _inputField(_proteinCtrl, 'Protein (g)',
                        Icons.fitness_center_rounded,
                        type: TextInputType.number)),
              ]),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _savingMeal ? null : _logMeal,
                  icon: _savingMeal
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black))
                      : const Icon(Icons.add_rounded, size: 18),
                  label: Text(_savingMeal ? 'Saving...' : 'Log Meal',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Meal history
        if (meals.isNotEmpty) ...[
          Text('Today\'s Meals',
              style: GoogleFonts.outfit(
                  color: Colors.white54,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: 1)),
          const SizedBox(height: 8),
          ...meals.map((m) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.orangeAccent.withValues(alpha: 0.2)),
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.restaurant_rounded,
                        color: Colors.orangeAccent, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(m.description,
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                      Text(
                        '${m.calories} kcal  •  ${m.protein.toStringAsFixed(1)}g protein',
                        style: GoogleFonts.outfit(
                            color: Colors.white54, fontSize: 11),
                      ),
                    ]),
                  ),
                ]),
              )),
        ],
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _tabBtn(String label, int idx, Color color) {
    final sel = _tab == idx;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _tab = idx);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: sel ? color.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: sel ? color.withValues(alpha: 0.5) : Colors.white12,
              width: sel ? 1.5 : 1),
        ),
        child: Center(
          child: Text(label,
              style: GoogleFonts.outfit(
                  color: sel ? color : Colors.white54,
                  fontWeight: sel ? FontWeight.w700 : FontWeight.normal,
                  fontSize: 13)),
        ),
      ),
    );
  }

  Widget _waterBtn(String label, int ml, Color color) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _logWater(ml),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(children: [
            Text(label.split(' ')[0], style: const TextStyle(fontSize: 18)),
            Text(label.split(' ')[1],
                style: GoogleFonts.outfit(color: color, fontSize: 10)),
          ]),
        ),
      ),
    );
  }

  Widget _infoCard(IconData icon, String title, String body, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(title,
              style: GoogleFonts.outfit(
                  color: color, fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
        const SizedBox(height: 8),
        Text(body,
            style: GoogleFonts.outfit(
                color: Colors.white70, fontSize: 13, height: 1.4)),
      ]),
    );
  }

  Widget _inputField(TextEditingController ctrl, String hint, IconData icon,
      {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.outfit(color: Colors.white30, fontSize: 12),
        prefixIcon: Icon(icon, color: Colors.white38, size: 18),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.04),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}
