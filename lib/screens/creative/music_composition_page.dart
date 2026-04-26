import 'package:flutter/material.dart';
import 'package:anime_waifu/services/creative/music_composition_service.dart';

class MusicCompositionPage extends StatefulWidget {
  const MusicCompositionPage({super.key});

  @override
  State<MusicCompositionPage> createState() => _MusicCompositionPageState();
}

class _MusicCompositionPageState extends State<MusicCompositionPage> {
  final _service = MusicCompositionService.instance;

  @override
  void initState() {
    super.initState();
    _service.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎵 Music Composition'),
        backgroundColor: Colors.purple.shade800,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              color: Colors.purple.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Composition ideas: Try a minor key progression...'),
              ),
            ),
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Theory tips: Use the circle of fifths...'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
