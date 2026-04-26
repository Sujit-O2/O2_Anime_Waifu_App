import 'package:flutter/material.dart';
import 'package:anime_waifu/services/productivity/project_management_service.dart';

class ProjectManagementPage extends StatefulWidget {
  const ProjectManagementPage({super.key});

  @override
  State<ProjectManagementPage> createState() => _ProjectManagementPageState();
}

class _ProjectManagementPageState extends State<ProjectManagementPage> {
  final _service = ProjectManagementService.instance;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime _deadline = DateTime.now().add(const Duration(days: 30));
  ProjectPriority _priority = ProjectPriority.medium;

  @override
  void initState() {
    super.initState();
    _service.initialize();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📋 Project Management'),
        backgroundColor: Colors.cyan.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              color: Colors.cyan.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_service.getProjectInsights()),
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
                          labelText: 'Project Title',
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
                      const SizedBox(height: 16),
                      DropdownButtonFormField<ProjectPriority>(
                        value: _priority,
                        decoration: const InputDecoration(
                          labelText: 'Priority',
                          prefixIcon: Icon(Icons.priority_high),
                        ),
                        items: ProjectPriority.values.map((p) {
                          return DropdownMenuItem(
                            value: p,
                            child: Text(p.name.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _priority = v!),
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
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) setState(() => _deadline = date);
                        },
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            await _service.createProject(
                              title: _titleController.text,
                              description: _descController.text,
                              deadline: _deadline,
                              priority: _priority,
                              milestones: [],
                            );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Project created! 📋')),
                              );
                              _titleController.clear();
                              _descController.clear();
                              setState(() {});
                            }
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Create Project'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyan.shade700,
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
