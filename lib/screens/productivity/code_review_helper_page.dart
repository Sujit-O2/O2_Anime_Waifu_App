import 'package:flutter/material.dart';
import 'package:anime_waifu/services/productivity/code_review_service.dart';

class CodeReviewHelperPage extends StatefulWidget {
  const CodeReviewHelperPage({super.key});

  @override
  State<CodeReviewHelperPage> createState() => _CodeReviewHelperPageState();
}

class _CodeReviewHelperPageState extends State<CodeReviewHelperPage> {
  final _service = CodeReviewService.instance;
  final _codeController = TextEditingController();
  final _languageController = TextEditingController();
  CodeReviewResult? _result;

  @override
  void initState() {
    super.initState();
    _service.initialize();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _languageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('💻 Code Review'),
        backgroundColor: Colors.deepOrange.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _languageController,
                      decoration: const InputDecoration(
                        labelText: 'Language',
                        prefixIcon: Icon(Icons.code),
                        hintText: 'dart, python, javascript',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _codeController,
                      decoration: const InputDecoration(
                        labelText: 'Code',
                        prefixIcon: Icon(Icons.code_outlined),
                      ),
                      maxLines: 10,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final result = await _service.analyzeCode(
                          code: _codeController.text,
                          language: _languageController.text,
                          context: 'Manual review',
                        );
                        setState(() => _result = result);
                      },
                      icon: const Icon(Icons.search),
                      label: const Text('Analyze Code'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_result != null) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_result!.summary),
                      const Divider(height: 24),
                      Text(_result!.recommendations),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
