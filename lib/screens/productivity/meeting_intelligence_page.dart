import 'package:flutter/material.dart';
import 'package:anime_waifu/services/productivity/meeting_intelligence_service.dart';

class MeetingIntelligencePage extends StatefulWidget {
  const MeetingIntelligencePage({super.key});

  @override
  State<MeetingIntelligencePage> createState() => _MeetingIntelligencePageState();
}

class _MeetingIntelligencePageState extends State<MeetingIntelligencePage> {
  final _service = MeetingIntelligenceService.instance;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _participantsController = TextEditingController();
  final DateTime _startTime = DateTime.now();
  final DateTime _endTime = DateTime.now().add(const Duration(hours: 1));
  MeetingType _type = MeetingType.teamSync;

  @override
  void initState() {
    super.initState();
    _service.initialize();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _participantsController.dispose();
    super.dispose();
  }

  Future<void> _createMeeting() async {
    if (!_formKey.currentState!.validate()) return;

    await _service.createMeeting(
      title: _titleController.text,
      participants: _participantsController.text,
      startTime: _startTime,
      endTime: _endTime,
      type: _type,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meeting created! 🤝')),
      );
      _titleController.clear();
      _participantsController.clear();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🤝 Meeting Intelligence'),
        backgroundColor: Colors.deepPurple.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              color: Colors.deepPurple.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_service.getMeetingInsights()),
              ),
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Meeting Title',
                          prefixIcon: Icon(Icons.title),
                        ),
                        validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _participantsController,
                        decoration: const InputDecoration(
                          labelText: 'Participants',
                          prefixIcon: Icon(Icons.people),
                        ),
                        validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<MeetingType>(
                        value: _type,
                        decoration: const InputDecoration(
                          labelText: 'Meeting Type',
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: MeetingType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type.name.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _type = v!),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _createMeeting,
                        icon: const Icon(Icons.add),
                        label: const Text('Create Meeting'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
