import 'package:flutter/material.dart';
import 'package:anime_waifu/services/memory_context/smart_photo_memory_service.dart';

class SmartPhotoMemoryPage extends StatefulWidget {
  const SmartPhotoMemoryPage({super.key});

  @override
  State<SmartPhotoMemoryPage> createState() => _SmartPhotoMemoryPageState();
}

class _SmartPhotoMemoryPageState extends State<SmartPhotoMemoryPage> {
  final _service = SmartPhotoMemoryService.instance;

  @override
  void initState() {
    super.initState();
    _service.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📸 Smart Photo Memory'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text("Photo memories: 25 photos organized"),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text("Memory insights: Happy moments captured"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
