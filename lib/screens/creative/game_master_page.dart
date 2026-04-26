import 'package:flutter/material.dart';
import 'package:anime_waifu/services/creative/game_master_service.dart';

class GameMasterPage extends StatefulWidget {
  const GameMasterPage({super.key});

  @override
  State<GameMasterPage> createState() => _GameMasterPageState();
}

class _GameMasterPageState extends State<GameMasterPage> {
  final _service = GameMasterService.instance;

  @override
  void initState() {
    super.initState();
    _service.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎲 Game Master'),
        backgroundColor: Colors.brown.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              color: Colors.brown.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Campaign: Epic Adventure'),
              ),
            ),
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Quest ideas: Explore the dungeon, Find the artifact...'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
