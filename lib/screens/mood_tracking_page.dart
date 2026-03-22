import 'package:flutter/material.dart';
import 'package:o2_waifu/config/app_themes.dart';
import 'package:o2_waifu/models/waifu_mood.dart';
import 'package:o2_waifu/services/mood_service.dart';
import 'package:o2_waifu/widgets/glass_container.dart';

/// Mood tracking page with Firestore cloud sync.
class MoodTrackingPage extends StatefulWidget {
  final AppThemeConfig themeConfig;
  final MoodService moodService;

  const MoodTrackingPage({
    super.key,
    required this.themeConfig,
    required this.moodService,
  });

  @override
  State<MoodTrackingPage> createState() => _MoodTrackingPageState();
}

class _MoodTrackingPageState extends State<MoodTrackingPage> {
  WaifuMood _selectedMood = WaifuMood.neutral;
  double _sentimentSlider = 0.5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mood Tracking')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Current mood summary
          GlassContainer(
            child: Column(
              children: [
                Text(
                  'How is Zero Two feeling?',
                  style: TextStyle(
                    color: widget.themeConfig.primaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.moodService.dominantMood.emoji,
                      style: const TextStyle(fontSize: 48),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.moodService.dominantMood.displayName,
                          style: TextStyle(
                            color: widget.themeConfig.textColor,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Avg sentiment: ${widget.moodService.averageSentiment.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: widget.themeConfig.textColor
                                .withValues(alpha: 0.6),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Record new mood
          GlassContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Record Your Mood',
                  style: TextStyle(
                    color: widget.themeConfig.primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: WaifuMood.values.map((mood) {
                    final isSelected = mood == _selectedMood;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedMood = mood),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? widget.themeConfig.primaryColor
                                  .withValues(alpha: 0.3)
                              : widget.themeConfig.surfaceColor
                                  .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? widget.themeConfig.primaryColor
                                : Colors.transparent,
                          ),
                        ),
                        child: Text(
                          '${mood.emoji} ${mood.displayName}',
                          style: TextStyle(
                            color: widget.themeConfig.textColor,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text(
                  'Sentiment: ${_sentimentSlider.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: widget.themeConfig.textColor
                        .withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
                Slider(
                  value: _sentimentSlider,
                  onChanged: (v) =>
                      setState(() => _sentimentSlider = v),
                  activeColor: widget.themeConfig.primaryColor,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.moodService
                          .recordMood(_selectedMood, _sentimentSlider);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Mood recorded!')),
                      );
                      setState(() {});
                    },
                    child: const Text('Record Mood'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
