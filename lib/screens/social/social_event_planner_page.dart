import 'dart:async';
import 'package:flutter/material.dart';
import 'package:anime_waifu/services/social/social_event_planner_service.dart';

class SocialEventPlannerPage extends StatefulWidget {
  const SocialEventPlannerPage({super.key});

  @override
  State<SocialEventPlannerPage> createState() => _SocialEventPlannerPageState();
}

class _SocialEventPlannerPageState extends State<SocialEventPlannerPage> with SingleTickerProviderStateMixin {
  final _service = SocialEventPlannerService.instance;
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  final _budgetController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  EventType _eventType = EventType.gathering;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    unawaited(_service.initialize());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _createEvent() async {
    if (!_formKey.currentState!.validate()) return;

    await _service.createEvent(
      title: _titleController.text,
      description: _descController.text,
      date: _selectedDate,
      type: _eventType,
      attendees: [],
      location: _locationController.text,
      budget: double.tryParse(_budgetController.text) ?? 0,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event created! 🎉')),
      );
      _titleController.clear();
      _descController.clear();
      _locationController.clear();
      _budgetController.clear();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎉 Event Planner'),
        backgroundColor: Colors.orange.shade700,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.add), text: 'Create'),
            Tab(icon: Icon(Icons.event), text: 'Events'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCreateTab(),
          _buildEventsTab(),
        ],
      ),
    );
  }

  Widget _buildCreateTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Event Title',
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 3,
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<EventType>(
                      value: _eventType,
                      decoration: const InputDecoration(
                        labelText: 'Event Type',
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: EventType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type.label),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _eventType = v!),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _budgetController,
                      decoration: const InputDecoration(
                        labelText: 'Budget (\$)',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Event Date'),
                      subtitle: Text(_selectedDate.toString().substring(0, 10)),
                      trailing: const Icon(Icons.edit),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() => _selectedDate = date);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _createEvent,
                      icon: const Icon(Icons.add),
                      label: const Text('Create Event'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsTab() {
    final upcoming = _service.getUpcomingEvents();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: Colors.orange.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(_service.getEventInsights()),
          ),
        ),
        const SizedBox(height: 16),
        if (upcoming.isNotEmpty) ...[
          Text(
            'Upcoming Events',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          ...upcoming.map((event) => Card(
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: Colors.orange.shade700,
                child: Icon(_getEventIcon(event.type), color: Colors.white),
              ),
              title: Text(event.title),
              subtitle: Text(
                '${event.type.label} • ${event.date.toString().substring(0, 10)}',
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('📍 ${event.location}'),
                      Text('💰 Budget: \$${event.budget.toStringAsFixed(2)}'),
                      Text('👥 Attendees: ${event.attendees.length}'),
                      const SizedBox(height: 8),
                      Text(event.description),
                      if (event.checklist.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'Checklist:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        ...event.checklist.take(5).map((task) => Padding(
                          padding: const EdgeInsets.only(left: 8, top: 4),
                          child: Text('□ $task'),
                        )),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          )),
        ] else
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'No upcoming events.\nStart planning gatherings! 🎉',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
      ],
    );
  }

  IconData _getEventIcon(EventType type) {
    switch (type) {
      case EventType.birthday:
        return Icons.cake;
      case EventType.dinner:
        return Icons.restaurant;
      case EventType.outing:
        return Icons.directions_walk;
      case EventType.vacation:
        return Icons.flight;
      case EventType.gathering:
        return Icons.people;
      case EventType.celebration:
        return Icons.celebration;
    }
  }
}
