import 'package:flutter/material.dart';
import 'package:anime_waifu/services/creative/art_direction_service.dart';

class ArtDirectionPage extends StatefulWidget {
  const ArtDirectionPage({super.key});

  @override
  State<ArtDirectionPage> createState() => _ArtDirectionPageState();
}

class _ArtDirectionPageState extends State<ArtDirectionPage> {
  final _service = ArtDirectionService.instance;

  @override
  void initState() {
    super.initState();
    _service.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎨 Art Direction'),
        backgroundColor: Colors.pink.shade600,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              color: Colors.pink.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Art Direction Service\n\nCreate stunning visual concepts and style guides for your creative projects.'),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Style Guide', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('• Color palette suggestions'),
                    Text('• Typography recommendations'),
                    Text('• Layout composition tips'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
