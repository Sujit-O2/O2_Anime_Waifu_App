import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:anime_waifu/services/ai_personalization/ai_content_service.dart';
import 'package:anime_waifu/core/v2_upgrade_kit.dart';

class DailyAffirmationsPage extends StatefulWidget {
  const DailyAffirmationsPage({super.key});
  @override
  State<DailyAffirmationsPage> createState() => _DailyAffirmationsPageState();
}

class _DailyAffirmationsPageState extends State<DailyAffirmationsPage>
    with SingleTickerProviderStateMixin {
  List<String> _affirmations = [];
  int _idx = 0;
  bool _liked = false;
  bool _loading = true;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _load();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final list = await AiContentService.getAffirmations();
      if (mounted) {
        setState(() { _affirmations = list; _loading = false; });
        _fadeCtrl.forward();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _next() {
    if (_affirmations.isEmpty) return;
    HapticFeedback.selectionClick();
    _fadeCtrl.reset();
    setState(() { _idx = (_idx + 1) % _affirmations.length; _liked = false; });
    _fadeCtrl.forward();
  }

  void _prev() {
    if (_affirmations.isEmpty) return;
    HapticFeedback.selectionClick();
    _fadeCtrl.reset();
    setState(() { _idx = (_idx - 1 + _affirmations.length) % _affirmations.length; _liked = false; });
    _fadeCtrl.forward();
  }

  void _toggleLike() {
    HapticFeedback.mediumImpact();
    setState(() => _liked = !_liked);
  }

  @override
  Widget build(BuildContext context) {
    return FeaturePageV2(
      title: 'DAILY AFFIRMATIONS',
      onBack: () => Navigator.pop(context),
      content: GestureDetector(
        onHorizontalDragEnd: (d) {
          if ((d.primaryVelocity ?? 0) < -200) { _next(); }
          else if ((d.primaryVelocity ?? 0) > 200) { _prev(); }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimatedEntry(
              index: 1,
              child: WaifuCommentary(
                mood: _liked ? 'achievement' : 'neutral',
              ),
            ),
            const SizedBox(height: 12),
            AnimatedEntry(
              index: 2,
              child: Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Index',
                      value: _affirmations.isEmpty ? '0' : '${_idx + 1}',
                      icon: Icons.format_quote_rounded,
                      color: V2Theme.accentColor,
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: _toggleLike,
                      child: StatCard(
                        title: 'Saved',
                        value: _liked ? 'Yes' : 'No',
                        icon: _liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: _liked ? Colors.pinkAccent : Colors.white38,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (_loading)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.pinkAccent),
                      SizedBox(height: 16),
                      Text('Generating affirmations with AI...',
                          style: TextStyle(color: Colors.white54)),
                    ],
                  ),
                ),
              )
            else if (_affirmations.isEmpty)
              const Expanded(
                child: Center(
                  child: Text('Could not load affirmations. Try again later.',
                      style: TextStyle(color: Colors.white54)),
                ),
              )
            else ...[
              const SizedBox(height: 16),
              AnimatedEntry(
                index: 3,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_affirmations.length.clamp(0, 20), (i) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: i == _idx ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: i == _idx ? Colors.pinkAccent : Colors.white.withValues(alpha: 0.15),
                      ),
                    );
                  }),
                ),
              ),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.pinkAccent.withValues(alpha: 0.1),
                            border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.3)),
                          ),
                          child: Center(
                            child: Icon(
                              _liked ? Icons.auto_awesome : Icons.favorite,
                              color: Colors.pinkAccent,
                              size: 36,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        GlassCard(
                          margin: EdgeInsets.zero,
                          glow: true,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              _affirmations[_idx],
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 17,
                                height: 1.7,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _navBtn(Icons.arrow_back_ios_rounded, _prev),
                            const SizedBox(width: 16),
                            GestureDetector(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: _affirmations[_idx]));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Affirmation copied!', style: GoogleFonts.outfit()),
                                    backgroundColor: V2Theme.primaryColor,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: Container(
                                height: 44,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                decoration: BoxDecoration(
                                  color: V2Theme.primaryColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: V2Theme.primaryColor.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.copy_outlined, color: V2Theme.primaryColor, size: 16),
                                    const SizedBox(width: 8),
                                    Text('Copy', style: GoogleFonts.outfit(color: V2Theme.primaryColor, fontSize: 13, fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            _navBtn(Icons.arrow_forward_ios_rounded, _next),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  '${_idx + 1} / ${_affirmations.length}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(color: Colors.white24, fontSize: 11),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _navBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Icon(icon, color: Colors.white54, size: 18),
      ),
    );
  }
}




