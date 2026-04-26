import 'package:flutter/material.dart';
import 'package:anime_waifu/services/social/long_distance_relationship_service.dart';

class LongDistanceRelationshipPage extends StatefulWidget {
  const LongDistanceRelationshipPage({super.key});

  @override
  State<LongDistanceRelationshipPage> createState() => _LongDistanceRelationshipPageState();
}

class _LongDistanceRelationshipPageState extends State<LongDistanceRelationshipPage> with SingleTickerProviderStateMixin {
  final _service = LongDistanceRelationshipService.instance;
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _partnerController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  VirtualDateType _dateType = VirtualDateType.videoChat;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _service.initialize();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _partnerController.dispose();
    super.dispose();
  }

  Future<void> _scheduleDate() async {
    if (!_formKey.currentState!.validate()) return;

    await _service.scheduleVirtualDate(
      title: _titleController.text,
      partnerName: _partnerController.text,
      scheduledTime: _selectedDate,
      timezone1: 'UTC',
      timezone2: 'UTC',
      type: _dateType,
      activities: [],
      platform: 'Video Call',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Virtual date scheduled! 💕')),
      );
      _titleController.clear();
      _partnerController.clear();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('💕 Long Distance Love'),
        backgroundColor: Colors.purple.shade700,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.calendar_today), text: 'Schedule'),
            Tab(icon: Icon(Icons.list), text: 'Dates'),
            Tab(icon: Icon(Icons.lightbulb), text: 'Ideas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildScheduleTab(),
          _buildDatesTab(),
          _buildIdeasTab(),
        ],
      ),
    );
  }

  Widget _buildScheduleTab() {
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
                        labelText: 'Date Title',
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _partnerController,
                      decoration: const InputDecoration(
                        labelText: 'Partner Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<VirtualDateType>(
                      value: _dateType,
                      decoration: const InputDecoration(
                        labelText: 'Date Type',
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: VirtualDateType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type.label),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _dateType = v!),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: const Text('Date & Time'),
                      subtitle: Text(_selectedDate.toString().substring(0, 16)),
                      trailing: const Icon(Icons.edit),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null && mounted) {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(_selectedDate),
                          );
                          if (time != null) {
                            setState(() {
                              _selectedDate = DateTime(
                                date.year,
                                date.month,
                                date.day,
                                time.hour,
                                time.minute,
                              );
                            });
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _scheduleDate,
                      icon: const Icon(Icons.add),
                      label: const Text('Schedule Virtual Date'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade700,
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

  Widget _buildDatesTab() {
    final upcoming = _service.getUpcomingDates();
    final past = _service.getPastDates();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (upcoming.isNotEmpty) ...[
          Text(
            'Upcoming Dates',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          ...upcoming.map((date) => Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.purple.shade700,
                child: const Icon(Icons.favorite, color: Colors.white),
              ),
              title: Text(date.title),
              subtitle: Text(
                '${date.type.label} • ${date.scheduledTime.toString().substring(0, 16)}',
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            ),
          )),
        ],
        if (past.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Past Dates',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          ...past.map((date) => Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey.shade400,
                child: const Icon(Icons.check, color: Colors.white),
              ),
              title: Text(date.title),
              subtitle: Text(
                '${date.type.label} • Rating: ${'⭐' * date.rating}',
              ),
            ),
          )),
        ],
        if (upcoming.isEmpty && past.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'No virtual dates scheduled yet.\nStart planning special moments! 💕',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildIdeasTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            color: Colors.purple.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_service.getVirtualDateIdeas()),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: Colors.pink.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_service.getLongDistanceTips()),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_service.getLDRInsights()),
            ),
          ),
        ],
      ),
    );
  }
}
