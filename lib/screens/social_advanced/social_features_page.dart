import 'package:flutter/material.dart';
import '../../services/integrations/social_features_service.dart';

class SocialFeaturesPage extends StatefulWidget {
  const SocialFeaturesPage({super.key});

  @override
  State<SocialFeaturesPage> createState() => _SocialFeaturesPageState();
}

class _SocialFeaturesPageState extends State<SocialFeaturesPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🌐 Social Features'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: ListTile(
                title: const Text('Social Score'),
                subtitle: const LinearProgressIndicator(value: 0.75),
                trailing: const Text('75'),
              ),
            ),
            const SizedBox(height: 16),
            const Card(
              child: ListTile(
                title: Text('Friend Suggestions'),
                subtitle: Text('5 available'),
                trailing: Icon(Icons.people),
              ),
            ),
            const SizedBox(height: 16),
            ...['Feature 1', 'Feature 2', 'Feature 3'].map((feature) => Card(
              child: ListTile(
                title: Text(feature),
                subtitle: const Text('Social feature description'),
                trailing: Switch(
                  value: true,
                  onChanged: (val) => setState(() {}),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}
