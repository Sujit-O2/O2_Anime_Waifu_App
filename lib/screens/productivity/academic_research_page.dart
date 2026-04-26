import 'package:flutter/material.dart';
import 'package:anime_waifu/services/productivity/academic_research_service.dart';

class AcademicResearchPage extends StatefulWidget {
  const AcademicResearchPage({super.key});

  @override
  State<AcademicResearchPage> createState() => _AcademicResearchPageState();
}

class _AcademicResearchPageState extends State<AcademicResearchPage> with SingleTickerProviderStateMixin {
  final _service = AcademicResearchService.instance;
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _topicController = TextEditingController();
  final _descController = TextEditingController();
  DateTime _deadline = DateTime.now().add(const Duration(days: 90));
  ResearchLevel _level = ResearchLevel.undergraduate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _service.initialize();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _topicController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _createProject() async {
    if (!_formKey.currentState!.validate()) return;

    await _service.createResearchProject(
      title: _titleController.text,
      topic: _topicController.text,
      description: _descController.text,
      deadline: _deadline,
      level: _level,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Research project created! 📚')),
      );
      _titleController.clear();
      _topicController.clear();
      _descController.clear();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📚 Academic Research'),
        backgroundColor: Colors.indigo.shade700,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.add), text: 'New Project'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCreateTab(),
          _buildAnalyticsTab(),
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
                        labelText: 'Project Title',
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _topicController,
                      decoration: const InputDecoration(
                        labelText: 'Research Topic',
                        prefixIcon: Icon(Icons.topic),
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
                    const SizedBox(height: 16),
                    DropdownButtonFormField<ResearchLevel>(
                      value: _level,
                      decoration: const InputDecoration(
                        labelText: 'Research Level',
                        prefixIcon: Icon(Icons.school),
                      ),
                      items: ResearchLevel.values.map((level) {
                        return DropdownMenuItem(
                          value: level,
                          child: Text(level.name.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _level = v!),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Deadline'),
                      subtitle: Text(_deadline.toString().substring(0, 10)),
                      trailing: const Icon(Icons.edit),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _deadline,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 730)),
                        );
                        if (date != null) {
                          setState(() => _deadline = date);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _createProject,
                      icon: const Icon(Icons.add),
                      label: const Text('Create Research Project'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo.shade700,
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

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            color: Colors.indigo.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_service.getStudyAnalytics()),
            ),
          ),
        ],
      ),
    );
  }
}
