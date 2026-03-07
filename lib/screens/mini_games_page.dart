import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart'; // To access ChatHomePage

class MiniGamesPage extends StatelessWidget {
  final Function(String) onGameSelected;

  const MiniGamesPage({super.key, required this.onGameSelected});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const ChatHomePage()),
              (r) => false);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0816),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 200.0,
              floating: false,
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 22),
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const ChatHomePage()),
                        (r) => false);
                  }
                },
              ),
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                title: Text(
                  'ARCADE HUB',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    color: Colors.white,
                    letterSpacing: 2.0,
                    shadows: [
                      Shadow(color: Colors.purpleAccent, blurRadius: 10)
                    ],
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF2D1B69),
                        const Color(0xFF11113B)
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.sports_esports_rounded,
                        size: 80, color: Colors.white12),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverGrid.count(
                crossAxisCount: 2,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                childAspectRatio: 0.85,
                children: [
                  _buildGridCard(
                    context,
                    title: 'Tic-Tac-Toe',
                    subtitle: 'Classic X and O strategy',
                    icon: Icons.grid_3x3_rounded,
                    color: Colors.cyanAccent,
                    command: 'tic tac toe',
                  ),
                  _buildGridCard(
                    context,
                    title: 'Rock Paper Scissors',
                    subtitle: 'Test your luck',
                    icon: Icons.back_hand_rounded,
                    color: Colors.orangeAccent,
                    command: 'rock paper scissors',
                  ),
                  _buildGridCard(
                    context,
                    title: 'Anime Trivia',
                    subtitle: 'Weeb knowledge check',
                    icon: Icons.quiz_rounded,
                    color: Colors.pinkAccent,
                    command: 'trivia',
                  ),
                  _buildGridCard(
                    context,
                    title: 'Gacha Rolls',
                    subtitle: 'Pull iconic quotes',
                    icon: Icons.stars_rounded,
                    color: Colors.amberAccent,
                    command: 'roll quote',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String command,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context); // Close hub
          onGameSelected(command); // Trigger in chat
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.05),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 36),
              ),
              const Spacer(),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  color: Colors.white60,
                  fontSize: 11,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
