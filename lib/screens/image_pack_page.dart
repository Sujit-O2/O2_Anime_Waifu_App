import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

class ImagePackPage extends StatefulWidget {
  const ImagePackPage({super.key});

  @override
  State<ImagePackPage> createState() => _ImagePackPageState();
}

class _ImagePackPageState extends State<ImagePackPage> {
  String? _currentBgUrl;
  final TextEditingController _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentBgUrl = customBackgroundUrlNotifier.value;
  }

  Future<void> _setBg(String? pathOrUrl) async {
    final prefs = await SharedPreferences.getInstance();
    if (pathOrUrl == null || pathOrUrl.isEmpty) {
      await prefs.remove('flutter.custom_bg_url');
      customBackgroundUrlNotifier.value = null;
    } else {
      await prefs.setString('flutter.custom_bg_url', pathOrUrl);
      customBackgroundUrlNotifier.value = pathOrUrl;
    }
    setState(() {
      _currentBgUrl = pathOrUrl;
    });
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      await _setBg(picked.path);
    }
  }

  void _submitUrl() {
    final url = _urlController.text.trim();
    if (url.isNotEmpty) {
      _setBg(url);
      _urlController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Image Pack', style: GoogleFonts.outfit()),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Custom Background',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Override the default animated gradient with your own image or GIF. It will be layered behind the cinematic lighting and particles.',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: Colors.white60,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),

              // Current Preview
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24),
                ),
                clipBehavior: Clip.antiAlias,
                child: _currentBgUrl == null
                    ? Center(
                        child: Text(
                          'Default Animated Gradient',
                          style: GoogleFonts.outfit(color: Colors.white54),
                        ),
                      )
                    : _currentBgUrl!.startsWith('http')
                        ? Image.network(_currentBgUrl!, fit: BoxFit.cover)
                        : Image.file(File(_currentBgUrl!), fit: BoxFit.cover),
              ),

              const SizedBox(height: 32),

              // Reset to Default
              _buildOptionButton(
                icon: Icons.refresh,
                label: 'Restore Default Gradient',
                color: Colors.redAccent,
                onTap: () => _setBg(null),
              ),
              const SizedBox(height: 16),

              // Pick from Gallery
              _buildOptionButton(
                icon: Icons.photo_library_outlined,
                label: 'Choose from Gallery',
                color: Colors.blueAccent,
                onTap: _pickFromGallery,
              ),

              const SizedBox(height: 32),
              Text(
                'Use Web URL',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _urlController,
                      style: GoogleFonts.outfit(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'https://example.com/waifu.gif',
                        hintStyle: GoogleFonts.outfit(color: Colors.white30),
                        filled: true,
                        fillColor: Colors.white10,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                      onSubmitted: (_) => _submitUrl(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _submitUrl,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.send, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 16),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
