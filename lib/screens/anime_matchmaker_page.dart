import 'package:flutter/material.dart';

/// Anime Matchmaker — "Based on what you watch, you'd vibe with these users"
class AnimeMatchmakerPage extends StatefulWidget {
  const AnimeMatchmakerPage({super.key});

  @override
  State<AnimeMatchmakerPage> createState() => _AnimeMatchmakerPageState();
}

class _AnimeMatchmakerPageState extends State<AnimeMatchmakerPage> {
  final List<Map<String, dynamic>> _matches = [
    {
      'name': 'Kira',
      'avatar': '👑', 
      'similarity': 94,
      'common': ['Death Note', 'Code Geass', 'Monster'],
      'bio': 'I will become the god of the new world layer.',
    },
    {
      'name': 'Gintoki Fan',
      'avatar': '🍓', 
      'similarity': 88,
      'common': ['Gintama', 'Jujutsu Kaisen', 'One Punch Man'],
      'bio': 'Strawberry milk solves all problems.',
    },
    {
      'name': 'El Psy Kongroo',
      'avatar': '📱', 
      'similarity': 82,
      'common': ['Steins;Gate', 'Re:Zero', 'Erased'],
      'bio': 'Mad scientist looking for lab members.',
    },
    {
      'name': 'Nakama',
      'avatar': '👒', 
      'similarity': 76,
      'common': ['One Piece', 'Naruto', 'Bleach'],
      'bio': 'The One Piece is real!',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F15),
      appBar: AppBar(
        title: const Text('💘 Anime Matchmaker', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.pinkAccent.withValues(alpha: 0.3), Colors.black]),
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            alignment: Alignment.center,
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(width: 80, height: 80, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.pinkAccent, width: 2))),
                    const Text('💕', style: TextStyle(fontSize: 40)),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Finding Your Perfect Waifu/Husbando Fan...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                Text('Based on your watch history', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              ],
            ),
          ),
          
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _matches.length,
              itemBuilder: (context, index) {
                final match = _matches[index];
                return Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C24),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(radius: 24, backgroundColor: Colors.white10, child: Text(match['avatar'], style: const TextStyle(fontSize: 24))),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(match['name'], style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(match['bio'], style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text('Common Anime:', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8, runSpacing: 8,
                            children: (match['common'] as List).map((anime) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: Colors.pinkAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.3))),
                              child: Text(anime, style: const TextStyle(color: Colors.pinkAccent, fontSize: 11, fontWeight: FontWeight.w600)),
                            )).toList(),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sent match request to ${match['name']}!')));
                              },
                              icon: const Icon(Icons.favorite),
                              label: const Text('Match & Chat'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.pinkAccent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Similarity Badge
                    Positioned(
                      top: 10, right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.auto_graph, color: Colors.greenAccent, size: 14),
                            const SizedBox(width: 4),
                            Text('${match['similarity']}% Match', style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
