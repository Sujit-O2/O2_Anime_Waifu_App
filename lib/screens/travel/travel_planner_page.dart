import 'package:flutter/material.dart';
import 'package:anime_waifu/services/travel/travel_planner_service.dart';

class TravelPlannerPage extends StatefulWidget {
  const TravelPlannerPage({super.key});

  @override
  State<TravelPlannerPage> createState() => _TravelPlannerPageState();
}

class _TravelPlannerPageState extends State<TravelPlannerPage> with SingleTickerProviderStateMixin {
  final _service = TravelPlannerService.instance;
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _destController = TextEditingController();
  final _budgetController = TextEditingController();
  DateTime _startDate = DateTime.now().add(const Duration(days: 30));
  DateTime _endDate = DateTime.now().add(const Duration(days: 37));
  int _travelers = 1;

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
    _destController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _createTrip() async {
    if (!_formKey.currentState!.validate()) return;

    await _service.createTrip(
      title: _titleController.text,
      destination: _destController.text,
      startDate: _startDate,
      endDate: _endDate,
      travelers: _travelers,
      budget: double.tryParse(_budgetController.text) ?? 0,
      interests: [],
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trip created! ✈️')),
      );
      _titleController.clear();
      _destController.clear();
      _budgetController.clear();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('✈️ Travel Planner'),
        backgroundColor: Colors.blue.shade700,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.add), text: 'Plan'),
            Tab(icon: Icon(Icons.flight_takeoff), text: 'Trips'),
            Tab(icon: Icon(Icons.explore), text: 'Destinations'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPlanTab(),
          _buildTripsTab(),
          _buildDestinationsTab(),
        ],
      ),
    );
  }

  Widget _buildPlanTab() {
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
                        labelText: 'Trip Title',
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _destController,
                      decoration: const InputDecoration(
                        labelText: 'Destination',
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
                      leading: const Icon(Icons.people),
                      title: const Text('Travelers'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () {
                              if (_travelers > 1) {
                                setState(() => _travelers--);
                              }
                            },
                          ),
                          Text('$_travelers'),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () => setState(() => _travelers++),
                          ),
                        ],
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Start Date'),
                      subtitle: Text(_startDate.toString().substring(0, 10)),
                      trailing: const Icon(Icons.edit),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _startDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 730)),
                        );
                        if (date != null) {
                          setState(() => _startDate = date);
                        }
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('End Date'),
                      subtitle: Text(_endDate.toString().substring(0, 10)),
                      trailing: const Icon(Icons.edit),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _endDate,
                          firstDate: _startDate,
                          lastDate: DateTime.now().add(const Duration(days: 730)),
                        );
                        if (date != null) {
                          setState(() => _endDate = date);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _createTrip,
                      icon: const Icon(Icons.add),
                      label: const Text('Create Trip'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
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

  Widget _buildTripsTab() {
    final upcoming = _service.getUpcomingTrips();
    final past = _service.getPastTrips();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: Colors.blue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(_service.getTravelInsights()),
          ),
        ),
        const SizedBox(height: 16),
        if (upcoming.isNotEmpty) ...[
          Text(
            'Upcoming Trips',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          ...upcoming.map((trip) => Card(
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade700,
                child: const Icon(Icons.flight, color: Colors.white),
              ),
              title: Text(trip.title),
              subtitle: Text(
                '${trip.destination} • ${trip.startDate.toString().substring(0, 10)}',
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('📍 ${trip.destination}'),
                      Text('📅 ${trip.startDate.toString().substring(0, 10)} - ${trip.endDate.toString().substring(0, 10)}'),
                      Text('👥 ${trip.travelers} traveler(s)'),
                      Text('💰 Budget: \$${trip.budget.toStringAsFixed(2)}'),
                      Text('📊 Status: ${trip.status.label}'),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
        if (past.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Past Trips',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          ...past.take(5).map((trip) => Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey.shade400,
                child: const Icon(Icons.check, color: Colors.white),
              ),
              title: Text(trip.title),
              subtitle: Text(trip.destination),
            ),
          )),
        ],
        if (upcoming.isEmpty && past.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'No trips planned yet.\nStart planning your adventure! ✈️',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDestinationsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: Colors.blue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(_service.getDestinationRecommendations()),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Popular Destinations',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        ...DestinationType.values.map((type) {
          final destinations = _service.getDestinationsByType(type);
          if (destinations.isEmpty) return const SizedBox.shrink();
          
          return Card(
            child: ExpansionTile(
              leading: Icon(_getDestinationIcon(type), color: Colors.blue.shade700),
              title: Text(type.label),
              children: destinations.map((dest) => ListTile(
                title: Text(dest.name),
                subtitle: Text(dest.description),
                trailing: Chip(
                  label: Text(dest.budget.label),
                  backgroundColor: _getBudgetColor(dest.budget),
                ),
              )).toList(),
            ),
          );
        }),
      ],
    );
  }

  IconData _getDestinationIcon(DestinationType type) {
    switch (type) {
      case DestinationType.city:
        return Icons.location_city;
      case DestinationType.beach:
        return Icons.beach_access;
      case DestinationType.mountain:
        return Icons.terrain;
      case DestinationType.countryside:
        return Icons.nature;
      case DestinationType.historical:
        return Icons.museum;
    }
  }

  Color _getBudgetColor(BudgetLevel budget) {
    switch (budget) {
      case BudgetLevel.low:
        return Colors.green.shade100;
      case BudgetLevel.medium:
        return Colors.orange.shade100;
      case BudgetLevel.high:
        return Colors.red.shade100;
    }
  }
}
