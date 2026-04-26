import 'package:flutter/material.dart';
import 'package:anime_waifu/services/wellness/hydration_nutrition_service.dart';

class HydrationNutritionPage extends StatefulWidget {
  const HydrationNutritionPage({super.key});

  @override
  State<HydrationNutritionPage> createState() => _HydrationNutritionPageState();
}

class _HydrationNutritionPageState extends State<HydrationNutritionPage> {
  final _service = HydrationNutritionService.instance;

  @override
  void initState() {
    super.initState();
    _service.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('💧 Hydration & Nutrition'),
        backgroundColor: Colors.lightBlue.shade600,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              color: Colors.lightBlue.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Hydration status: Good'),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Nutrition tips: Eat balanced meals...'),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                await _service.logWaterIntake(250);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Water logged! 💧')),
                  );
                  setState(() {});
                }
              },
              icon: const Icon(Icons.local_drink),
              label: const Text('Log Water (250ml)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
