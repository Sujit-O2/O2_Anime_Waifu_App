import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MiniGamesPage extends StatelessWidget {
  final Function(String) onGameSelected;

  const MiniGamesPage({super.key, required this.onGameSelected});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0816),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Mini Games Hub',
          style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white70, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F0816), Color(0xFF190D2A)],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            Text(
              'Select a game to play with me!',
              style: GoogleFonts.outfit(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            _buildGameCard(
              context,
              title: 'Tic-Tac-Toe',
              subtitle: 'Classic X and O strategy game',
              icon: Icons.grid_3x3_rounded,
              color: Colors.cyanAccent,
              command: 'tic tac toe',
            ),
            _buildGameCard(
              context,
              title: 'Rock Paper Scissors',
              subtitle: 'Test your luck and reading skills',
              icon: Icons.back_hand_rounded,
              color: Colors.orangeAccent,
              command: 'rock paper scissors',
            ),
            _buildGameCard(
              context,
              title: 'Anime Trivia',
              subtitle: 'How well do you know anime?',
              icon: Icons.quiz_rounded,
              color: Colors.pinkAccent,
              command: 'trivia',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String command,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pop(context); // Close games hub
            onGameSelected(command); // Trigger game in chat
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.outfit(
                          color: Colors.white60,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.play_arrow_rounded,
                    color: color.withValues(alpha: 0.6), size: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
