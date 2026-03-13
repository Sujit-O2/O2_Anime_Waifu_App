import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/achievements_service.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  List<String> _unlocked = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final svc = AchievementsService.instance;
    await svc.load();
    if (mounted) {
      setState(() {
        _unlocked = svc.unlocked;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = AchievementsService.all.length;
    final earned = _unlocked.length;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'ACHIEVEMENTS',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.pinkAccent))
          : Column(
              children: [
                // Progress header
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      colors: [
                        Colors.pinkAccent.withValues(alpha: 0.2),
                        Colors.deepPurple.withValues(alpha: 0.15),
                      ],
                    ),
                    border: Border.all(
                        color: Colors.pinkAccent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Text('🏆', style: TextStyle(fontSize: 32)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$earned / $total Earned',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: total > 0 ? earned / total : 0,
                                minHeight: 8,
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.1),
                                valueColor: const AlwaysStoppedAnimation(
                                    Colors.pinkAccent),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Badge grid
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: AchievementsService.all.length,
                    itemBuilder: (context, i) {
                      final def = AchievementsService.all[i];
                      final isUnlocked = _unlocked.contains(def.id);
                      return GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              backgroundColor: const Color(0xFF1A1A2E),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              title: Text(
                                '${def.emoji} ${def.title}',
                                style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                              content: Text(
                                '${def.description}\n\n${isUnlocked ? "✅ Earned!" : "🔒 Not yet earned"}',
                                style:
                                    GoogleFonts.outfit(color: Colors.white70),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('OK',
                                      style: GoogleFonts.outfit(
                                          color: Colors.pinkAccent)),
                                ),
                              ],
                            ),
                          );
                        },
                        child: AchievementBadge(def: def, unlocked: isUnlocked),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
