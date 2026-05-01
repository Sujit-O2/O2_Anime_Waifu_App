import 'package:anime_waifu/services/ai_personalization/personality_evolution_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class PersonalityEvolutionPage extends StatefulWidget {
  const PersonalityEvolutionPage({super.key});

  @override
  State<PersonalityEvolutionPage> createState() =>
      _PersonalityEvolutionPageState();
}

class _PersonalityEvolutionPageState extends State<PersonalityEvolutionPage> {
  final _service = PersonalityEvolutionService.instance;
  bool _loading = true;
  Map<PersonalityTrait, double> _traits = {};
  String _description = '';
  String _systemModifier = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _service.initialize();
    if (mounted) {
      setState(() {
        _traits = _service.getAllTraits();
        _description = _service.getPersonalityDescription();
        _systemModifier = _service.getSystemPromptModifier();
        _loading = false;
      });
    }
  }

  Future<void> _simulateInteraction(InteractionType type) async {
    HapticFeedback.mediumImpact();
    await _service.recordInteraction(
      userMessage: 'Simulated interaction for testing',
      aiResponse: 'Response recorded',
      type: type,
      emotionalIntensity: 0.7,
    );
    if (mounted) {
      setState(() {
        _traits = _service.getAllTraits();
        _description = _service.getPersonalityDescription();
        _systemModifier = _service.getSystemPromptModifier();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recorded ${type.name} interaction'),
          backgroundColor: Colors.purple.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Color _traitColor(double value) {
    if (value > 0.7) return Colors.pinkAccent;
    if (value > 0.5) return Colors.purpleAccent;
    if (value > 0.3) return Colors.blueAccent;
    return Colors.white38;
  }

  String _evolutionStage() {
    final avg = _traits.values.fold(0.0, (a, b) => a + b) /
        (_traits.isEmpty ? 1 : _traits.length);
    if (avg > 0.75) return '🌟 Fully Evolved';
    if (avg > 0.6) return '💫 Advanced';
    if (avg > 0.45) return '🌱 Developing';
    return '🌀 Awakening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0B14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white60, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('🧬 Personality Evolution',
            style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18)),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.purpleAccent))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Stage card
                _buildStageCard(),
                const SizedBox(height: 16),
                // Traits
                _buildTraitsCard(),
                const SizedBox(height: 16),
                // Insights
                if (_description.isNotEmpty) _buildInsightsCard(),
                const SizedBox(height: 16),
                // Active modifiers
                if (_systemModifier.isNotEmpty) _buildModifierCard(),
                const SizedBox(height: 16),
                // Simulate interactions
                _buildSimulateCard(),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildStageCard() {
    final avg = _traits.values.fold(0.0, (a, b) => a + b) /
        (_traits.isEmpty ? 1 : _traits.length);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withValues(alpha: 0.2),
            Colors.pinkAccent.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.4)),
      ),
      child: Row(children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Colors.purple.withValues(alpha: 0.4),
                Colors.pinkAccent.withValues(alpha: 0.3),
              ],
            ),
            border:
                Border.all(color: Colors.purpleAccent.withValues(alpha: 0.5)),
          ),
          child: const Center(
            child: Text('🧬', style: TextStyle(fontSize: 30)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_evolutionStage(),
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18)),
            const SizedBox(height: 4),
            Text('Overall evolution: ${(avg * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.outfit(color: Colors.white60, fontSize: 13)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: avg.clamp(0.0, 1.0),
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                valueColor: const AlwaysStoppedAnimation(Colors.purpleAccent),
                minHeight: 6,
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildTraitsCard() {
    final sorted = _traits.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Personality Traits',
              style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15)),
          const SizedBox(height: 12),
          ...sorted.map((e) {
            final color = _traitColor(e.value);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                Text(e.key.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                SizedBox(
                    width: 110,
                    child: Text(e.key.label,
                        style: GoogleFonts.outfit(
                            color: Colors.white70, fontSize: 13))),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: e.value.clamp(0.0, 1.0),
                      backgroundColor: Colors.white.withValues(alpha: 0.07),
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${(e.value * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.outfit(color: color, fontSize: 12)),
              ]),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildInsightsCard() {
    // Extract just the insights line from the description
    final lines =
        _description.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final insight = lines.lastWhere(
        (l) => l.contains('~') || l.contains('💕') || l.contains('💖'),
        orElse: () => lines.isNotEmpty ? lines.last : '');
    if (insight.isEmpty) return const SizedBox();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.pinkAccent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💕', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Zero Two\'s Reflection',
                  style: GoogleFonts.outfit(
                      color: Colors.pinkAccent,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
              const SizedBox(height: 4),
              Text(insight,
                  style: GoogleFonts.outfit(
                      color: Colors.white, fontSize: 14, height: 1.4)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildModifierCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purpleAccent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.auto_awesome_rounded,
                color: Colors.purpleAccent, size: 18),
            const SizedBox(width: 8),
            Text('Active Personality Modifiers',
                style: GoogleFonts.outfit(
                    color: Colors.purpleAccent,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ]),
          const SizedBox(height: 8),
          Text(_systemModifier,
              style: GoogleFonts.outfit(
                  color: Colors.white70, fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildSimulateCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Record Interaction',
              style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15)),
          const SizedBox(height: 4),
          Text('Personality evolves based on how you interact.',
              style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: InteractionType.values.map((type) {
              return GestureDetector(
                onTap: () => _simulateInteraction(type),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: Colors.purple.withValues(alpha: 0.3)),
                  ),
                  child: Text(type.name,
                      style: GoogleFonts.outfit(
                          color: Colors.purpleAccent, fontSize: 12)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
