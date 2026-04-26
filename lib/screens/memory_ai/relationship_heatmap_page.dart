import 'package:flutter/material.dart';
import 'package:anime_waifu/services/ai_personalization/relationship_heatmap_service.dart';

class RelationshipHeatmapPage extends StatefulWidget {
  const RelationshipHeatmapPage({super.key});

  @override
  State<RelationshipHeatmapPage> createState() => _RelationshipHeatmapPageState();
}

class _RelationshipHeatmapPageState extends State<RelationshipHeatmapPage> {
  final _service = RelationshipHeatmapService.instance;

  @override
  void initState() {
    super.initState();
    _service.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Relationship Heatmap'),
        backgroundColor: Colors.pink.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              color: Colors.pink.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: const Text("Heatmap data visualization"),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text("Interaction insights: Most active on weekends"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
