import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/free_apis_service.dart';
import '../widgets/waifu_background.dart';
import '../services/affection_service.dart';

class RecipeRecommenderPage extends StatefulWidget {
  const RecipeRecommenderPage({super.key});
  @override
  State<RecipeRecommenderPage> createState() => _RecipeRecommenderPageState();
}

class _RecipeRecommenderPageState extends State<RecipeRecommenderPage>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _meal;
  bool _loading = false;
  late AnimationController _fadeCtrl;
  bool _showIngredients = true;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _loadMeal();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMeal() async {
    setState(() {
      _loading = true;
      _meal = null;
    });
    _fadeCtrl.reset();
    try {
      final meal = await FreeApisService.instance.getRandomMeal();
      if (mounted) {
        setState(() => _meal = meal);
        _fadeCtrl.forward();
        AffectionService.instance.addPoints(1);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A16),
      body: WaifuBackground(
        opacity: 0.10,
        tint: const Color(0xFF090710),
        child: SafeArea(
            child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new,
                      color: Colors.white60, size: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('RECIPE AI',
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5)),
                      Text('TheMealDB • Real recipes 🍜',
                          style: GoogleFonts.outfit(
                              color: Colors.orangeAccent.withOpacity(0.6),
                              fontSize: 10)),
                    ]),
              ),
              GestureDetector(
                onTap: _loadMeal,
                child: Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.orangeAccent.withOpacity(0.15),
                    border:
                        Border.all(color: Colors.orangeAccent.withOpacity(0.4)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.shuffle_rounded,
                        color: Colors.orangeAccent, size: 16),
                    const SizedBox(width: 6),
                    Text('Surprise me!',
                        style: GoogleFonts.outfit(
                            color: Colors.orangeAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
            ]),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: _loading
                ? Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                        const CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.orangeAccent),
                        const SizedBox(height: 14),
                        Text('Finding a recipe for you, Darling~',
                            style: GoogleFonts.outfit(color: Colors.white38)),
                      ]))
                : _meal == null
                    ? Center(
                        child: GestureDetector(
                            onTap: _loadMeal,
                            child: Text('Tap to load recipe 🍕',
                                style:
                                    GoogleFonts.outfit(color: Colors.white38))))
                    : FadeTransition(
                        opacity: _fadeCtrl,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Image
                                if (_meal!['image']?.isNotEmpty == true)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: Image.network(_meal!['image'],
                                        width: double.infinity,
                                        height: 220,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const SizedBox.shrink()),
                                  ),
                                const SizedBox(height: 14),

                                // Title + tags
                                Text(_meal!['name'] ?? '',
                                    style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900)),
                                const SizedBox(height: 6),
                                Row(children: [
                                  if (_meal!['category']?.isNotEmpty == true)
                                    _tag(_meal!['category'],
                                        Colors.orangeAccent),
                                  const SizedBox(width: 8),
                                  if (_meal!['area']?.isNotEmpty == true)
                                    _tag('🌍 ${_meal!['area']}',
                                        Colors.tealAccent),
                                ]),
                                const SizedBox(height: 16),

                                // Toggle tabs
                                Container(
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: Colors.white.withOpacity(0.08)),
                                  ),
                                  child: Row(children: [
                                    _tabBtn(
                                        'Ingredients 🥘',
                                        _showIngredients,
                                        () => setState(
                                            () => _showIngredients = true)),
                                    _tabBtn(
                                        'Instructions 📋',
                                        !_showIngredients,
                                        () => setState(
                                            () => _showIngredients = false)),
                                  ]),
                                ),
                                const SizedBox(height: 12),

                                // Content
                                if (_showIngredients) ...[
                                  ...(_meal!['ingredients'] as List<dynamic>? ??
                                          [])
                                      .map(
                                        (ing) => Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 8),
                                          child: Row(children: [
                                            Container(
                                              width: 6,
                                              height: 6,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.orangeAccent
                                                    .withOpacity(0.7),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(ing.toString(),
                                                  style: GoogleFonts.outfit(
                                                      color: Colors.white70,
                                                      fontSize: 13,
                                                      height: 1.4)),
                                            ),
                                          ]),
                                        ),
                                      )
                                ] else ...[
                                  Text(_meal!['instructions'] ?? '',
                                      style: GoogleFonts.outfit(
                                          color: Colors.white70,
                                          fontSize: 13,
                                          height: 1.7)),
                                ],
                              ]),
                        ),
                      ),
          ),
        ])),
      ),
    );
  }

  Widget _tag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(text,
          style: GoogleFonts.outfit(
              color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }

  Widget _tabBtn(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            color: active
                ? Colors.orangeAccent.withOpacity(0.15)
                : Colors.transparent,
          ),
          child: Center(
            child: Text(label,
                style: GoogleFonts.outfit(
                    color: active ? Colors.orangeAccent : Colors.white38,
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
          ),
        ),
      ),
    );
  }
}
