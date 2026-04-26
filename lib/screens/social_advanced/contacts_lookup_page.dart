import 'package:flutter/material.dart';
import '../../services/integrations/contacts_lookup_service.dart';

class ContactsLookupPage extends StatefulWidget {
  const ContactsLookupPage({super.key});

  @override
  State<ContactsLookupPage> createState() => _ContactsLookupPageState();
}

class _ContactsLookupPageState extends State<ContactsLookupPage> {
  final _controller = TextEditingController();
  List<Map<String, dynamic>> _results = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📇 Contacts Lookup'),
        backgroundColor: Colors.green.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Search Contacts',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() => _results = [
                  {'name': 'Contact 1', 'phone': '+1234567890'},
                  {'name': 'Contact 2', 'phone': '+0987654321'},
                ]);
              },
              child: const Text('Search'),
            ),
            const SizedBox(height: 16),
            ..._results.map((contact) => Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(contact['name'] ?? 'Unknown'),
                subtitle: Text(contact['phone'] ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.call),
                  onPressed: () {},
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}
