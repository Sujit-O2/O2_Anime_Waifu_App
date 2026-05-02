import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UltimatesHubPage extends StatelessWidget {
  const UltimatesHubPage({super.key});

  static const List<Map<String, dynamic>> _ultimates = [
    {
      'title': 'Orbital Strike',
      'subtitle': 'Catastrophic AoE bombardment',
      'icon': Icons.rocket_launch,
      'color': 0xFFFF4500,
      'route': '/orbital-strike',
      'impact': 'Very High',
      'tags': ['Offense', 'AoE'],
    },
    {
      'title': 'Battle Cry',
      'subtitle': 'Team-wide damage & speed buff',
      'icon': Icons.campaign,
      'color': 0xFF00FF88,
      'route': '/battle-cry',
      'impact': 'High',
      'tags': ['Support', 'Buff'],
    },
    {
      'title': 'Guardian Summon',
      'subtitle': 'Conjure a powerful ally',
      'icon': Icons.shield,
      'color': 0xFF8844FF,
      'route': '/guardian-summon',
      'impact': 'High',
      'tags': ['Summon', 'Strategy'],
    },
    {
      'title': 'Time Freeze',
      'subtitle': 'Halt all enemies in a temporal rift',
      'icon': Icons.schedule,
      'color': 0xFF00CCFF,
      'route': '/time-freeze',
      'impact': 'Extreme',
      'tags': ['Control', 'CC'],
    },
    {
      'title': 'Phantom Echo',
      'subtitle': 'Spawn deceptive clone illusions',
      'icon': Icons.copy,
      'color': 0xFFCC44FF,
      'route': '/phantom-echo',
      'impact': 'Medium-High',
      'tags': ['Deception', 'Action'],
    },
    {
      'title': 'Quantum Leap',
      'subtitle': 'Instant teleportation anywhere',
      'icon': Icons.flash_on,
      'color': 0xFF44DDFF,
      'route': '/quantum-leap',
      'impact': 'Medium',
      'tags': ['Mobility', 'Utility'],
    },
    {
      'title': 'Berserker Fury',
      'subtitle': 'Transform into a killing machine',
      'icon': Icons.whatshot,
      'color': 0xFFFF4400,
      'route': '/berserker-fury',
      'impact': 'High',
      'tags': ['Self-Buff', 'Power'],
    },
    {
      'title': 'Null Zone',
      'subtitle': 'AoE crowd control field',
      'icon': Icons.block,
      'color': 0xFFFFDD00,
      'route': '/null-zone',
      'impact': 'Medium',
      'tags': ['Control', 'AoE'],
    },
    {
      'title': 'Mass Resurgence',
      'subtitle': 'Revive all fallen allies',
      'icon': Icons.auto_awesome,
      'color': 0xFFFFDD44,
      'route': '/mass-resurgence',
      'impact': 'High',
      'tags': ['Support', 'Revive'],
    },
    {
      'title': 'Final Judgment',
      'subtitle': 'Cinematic execution finisher',
      'icon': Icons.gavel,
      'color': 0xFFFF2244,
      'route': '/final-judgment',
      'impact': 'High',
      'tags': ['Execute', 'Single-Target'],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080810),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080810),
        title: Text('⚡ Ultimate Abilities',
            style: GoogleFonts.orbitron(
                color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.white12),
        ),
      ),
      body: Column(children: [
        _buildHeader(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _ultimates.length,
            itemBuilder: (context, i) => _buildCard(context, _ultimates[i], i),
          ),
        ),
      ]),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A0A2A), Color(0xFF080810)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(children: [
        const Icon(Icons.bolt, color: Color(0xFFFFDD44), size: 18),
        const SizedBox(width: 8),
        Text(
          '${_ultimates.length} Ultimate Abilities — Tap to play',
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
      ]),
    );
  }

  Widget _buildCard(BuildContext context, Map<String, dynamic> ult, int index) {
    final color = Color(ult['color'] as int);
    final tags = ult['tags'] as List<String>;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, ult['route'] as String),
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF111122),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withAlpha(80)),
              gradient: LinearGradient(
                colors: [color.withAlpha(20), const Color(0xFF111122)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: Row(children: [
              // Index badge
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withAlpha(30),
                  border: Border.all(color: color.withAlpha(120)),
                ),
                child: Center(
                  child: Text('${index + 1}',
                      style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withAlpha(25),
                ),
                child: Icon(ult['icon'] as IconData, color: color, size: 26),
              ),
              const SizedBox(width: 14),
              // Text
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(ult['title'] as String,
                      style: GoogleFonts.orbitron(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 3),
                  Text(ult['subtitle'] as String,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 11)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    children: [
                      _tag('Impact: ${ult['impact']}', color),
                      ...tags.map((t) => _tag(t, Colors.white24)),
                    ],
                  ),
                ]),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: color.withAlpha(150), size: 20),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _tag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color == Colors.white24 ? Colors.white38 : color,
              fontSize: 9,
              fontWeight: FontWeight.bold)),
    );
  }
}
