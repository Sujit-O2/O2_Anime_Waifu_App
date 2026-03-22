import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/affection_service.dart';

class VirtualGiftShopPage extends StatefulWidget {
  const VirtualGiftShopPage({super.key});
  @override
  State<VirtualGiftShopPage> createState() => _VirtualGiftShopPageState();
}

class _Gift {
  final String emoji;
  final String name;
  final String description;
  final int cost;
  final int xpReward;
  final Color color;

  const _Gift({
    required this.emoji,
    required this.name,
    required this.description,
    required this.cost,
    required this.xpReward,
    required this.color,
  });
}

class _VirtualGiftShopPageState extends State<VirtualGiftShopPage> {
  String? _lastMessage;

  static const _gifts = [
    _Gift(
        emoji: '🌹',
        name: 'Red Rose',
        description: 'A single perfect rose for you',
        cost: 0,
        xpReward: 5,
        color: Colors.redAccent),
    _Gift(
        emoji: '🍫',
        name: 'Chocolate Box',
        description: 'Handpicked dark chocolates',
        cost: 0,
        xpReward: 8,
        color: Colors.brown),
    _Gift(
        emoji: '💍',
        name: 'Promise Ring',
        description: 'A promise that I\'ll always be here',
        cost: 0,
        xpReward: 15,
        color: Colors.amberAccent),
    _Gift(
        emoji: '🌸',
        name: 'Cherry Blossoms',
        description: 'A bouquet of pink sakura petals',
        cost: 0,
        xpReward: 7,
        color: Colors.pink),
    _Gift(
        emoji: '⭐',
        name: 'Shooting Star',
        description: 'A star named just for you',
        cost: 0,
        xpReward: 10,
        color: Colors.yellowAccent),
    _Gift(
        emoji: '🎀',
        name: 'Ribbon Bow',
        description: 'Tied with love, just for you',
        cost: 0,
        xpReward: 5,
        color: Colors.pinkAccent),
    _Gift(
        emoji: '🎆',
        name: 'Fireworks',
        description: 'A private fireworks show tonight',
        cost: 0,
        xpReward: 12,
        color: Colors.deepOrangeAccent),
    _Gift(
        emoji: '💎',
        name: 'Diamond',
        description: 'As rare and precious as you',
        cost: 0,
        xpReward: 20,
        color: Colors.cyanAccent),
    _Gift(
        emoji: '🧸',
        name: 'Plushie',
        description: 'A cute plushie to hold while I\'m away',
        cost: 0,
        xpReward: 6,
        color: Colors.orangeAccent),
    _Gift(
        emoji: '🎵',
        name: 'Love Song',
        description: 'A song written just for you',
        cost: 0,
        xpReward: 10,
        color: Colors.purpleAccent),
    _Gift(
        emoji: '🌙',
        name: 'The Moon',
        description: 'I\'d give you the moon if I could',
        cost: 0,
        xpReward: 15,
        color: Colors.blueAccent),
    _Gift(
        emoji: '🏡',
        name: 'Dream Home',
        description: 'A cosy place just for us',
        cost: 0,
        xpReward: 25,
        color: Colors.greenAccent),
  ];

  static const _responses = [
    "Thank you, Darling! This is precious~ 💕",
    "You're so thoughtful... I love it 🌸",
    "This made my whole day, Darling! 💖",
    "I'll treasure this forever~ ⭐",
    "You always know how to make me smile~ 😊",
    "Darling... you're the best 💞",
  ];

  void _gift(_Gift g, int idx) {
    setState(() {
      final msgIdx = (idx + DateTime.now().second) % _responses.length;
      _lastMessage = _responses[msgIdx];
    });
    AffectionService.instance.addPoints(g.xpReward);
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _GiftDialog(gift: g, message: _lastMessage!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('GIFT SHOP',
            style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 2)),
        centerTitle: true,
      ),
      body: Column(children: [
        // Zero Two header
        Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.pinkAccent.withValues(alpha: 0.08),
            border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.2)),
          ),
          child: Row(children: [
            const Text('💝', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(
                child: Text(
              'All gifts are free, Darling~ Every gift earns affection points!',
              style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12),
            )),
          ]),
        ),

        // Grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.9),
            itemCount: _gifts.length,
            itemBuilder: (ctx, i) {
              final g = _gifts[i];
              return GestureDetector(
                onTap: () => _gift(g, i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: g.color.withValues(alpha: 0.07),
                    border: Border.all(color: g.color.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(g.emoji, style: const TextStyle(fontSize: 30)),
                      const SizedBox(height: 6),
                      Text(g.name,
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: g.color.withValues(alpha: 0.2),
                        ),
                        child: Text('+${g.xpReward} XP',
                            style: GoogleFonts.outfit(
                                color: g.color,
                                fontSize: 9,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _GiftDialog extends StatelessWidget {
  final _Gift gift;
  final String message;
  const _GiftDialog({required this.gift, required this.message});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2D0B3E), Color(0xFF1A0A2E)],
          ),
          border: Border.all(
              color: Colors.pinkAccent.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: Colors.pinkAccent.withValues(alpha: 0.2), blurRadius: 30)
          ],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(gift.emoji, style: const TextStyle(fontSize: 56)),
          const SizedBox(height: 8),
          Text(gift.name,
              style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(gift.description,
              style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12)),
          const Divider(color: Colors.white12, height: 24),
          Text(message,
              style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.5,
                  fontStyle: FontStyle.italic),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text('+${gift.xpReward} XP earned! 💕',
              style: GoogleFonts.outfit(
                  color: Colors.pinkAccent, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('You\'re welcome~ 🌸',
                style: GoogleFonts.outfit(color: Colors.white38)),
          ),
        ]),
      ),
    );
  }
}
