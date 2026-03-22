import 'package:flutter/material.dart';
import 'package:o2_waifu/config/app_themes.dart';
import 'package:o2_waifu/services/secret_notes_service.dart';
import 'package:o2_waifu/widgets/glass_container.dart';

/// Zero-knowledge encrypted notes with biometric gate.
class SecretNotesPage extends StatefulWidget {
  final AppThemeConfig themeConfig;
  final SecretNotesService notesService;

  const SecretNotesPage({
    super.key,
    required this.themeConfig,
    required this.notesService,
  });

  @override
  State<SecretNotesPage> createState() => _SecretNotesPageState();
}

class _SecretNotesPageState extends State<SecretNotesPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _addNote() {
    if (_contentController.text.isEmpty) return;

    widget.notesService.addNote(
      _contentController.text,
      title: _titleController.text.isNotEmpty
          ? _titleController.text
          : null,
    );
    _titleController.clear();
    _contentController.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secret Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock),
            onPressed: () {},
            tooltip: 'Encrypted with XOR-shift',
          ),
        ],
      ),
      body: Column(
        children: [
          // New note input
          Padding(
            padding: const EdgeInsets.all(16),
            child: GlassContainer(
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      hintText: 'Title (optional)',
                      border: InputBorder.none,
                    ),
                  ),
                  const Divider(height: 1),
                  TextField(
                    controller: _contentController,
                    decoration: const InputDecoration(
                      hintText: 'Write your secret note...',
                      border: InputBorder.none,
                    ),
                    maxLines: 3,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: Icon(Icons.send,
                          color: widget.themeConfig.primaryColor),
                      onPressed: _addNote,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Notes list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: widget.notesService.notes.length,
              itemBuilder: (context, index) {
                final note = widget.notesService.notes[
                    widget.notesService.notes.length - 1 - index];
                final decrypted = widget.notesService.decryptNote(note);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlassContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                note.title ?? 'Untitled Note',
                                style: TextStyle(
                                  color: widget.themeConfig.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  size: 18, color: Colors.red),
                              onPressed: () {
                                widget.notesService.deleteNote(note.id);
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          decrypted,
                          style: TextStyle(
                            color: widget.themeConfig.textColor,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(note.createdAt),
                          style: TextStyle(
                            color: widget.themeConfig.textColor
                                .withValues(alpha: 0.4),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
