import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:anime_waifu/widgets/app_cached_image.dart';
import 'package:anime_waifu/widgets/shimmer_loading.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:anime_waifu/main.dart';
class ImagePack {
  final String name;
  final String previewUrl;
  final String description;
  int usage;

  ImagePack({required this.name, required this.previewUrl, required this.description, this.usage = 0});

  Map<String, dynamic> toJson() => {'name': name, 'previewUrl': previewUrl, 'description': description, 'usage': usage};

  factory ImagePack.fromJson(Map<String, dynamic> json) => ImagePack(
    name: json['name'],
    previewUrl: json['previewUrl'],
    description: json['description'],
    usage: json['usage'] ?? 0,
  );
}

class ImagePackPage extends StatefulWidget {
  const ImagePackPage({super.key});

  @override
  State<ImagePackPage> createState() => _ImagePackPageState();
}

class _ImagePackPageState extends State<ImagePackPage> with SingleTickerProviderStateMixin {
  String? _currentBgUrl;
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  List<ImagePack> _allPacks = [];
  List<ImagePack> _filteredPacks = [];
  bool _isLoading = true;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _currentBgUrl = customBackgroundUrlNotifier.value;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _urlController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1)); // Simulate loading
    final prefs = await SharedPreferences.getInstance();
    final packsJson = prefs.getString('image_packs');
    if (packsJson != null) {
      final List<dynamic> packsData = json.decode(packsJson);
      _allPacks = packsData.map((e) => ImagePack.fromJson(e)).toList();
    } else {
      // Default packs
      _allPacks = [
        ImagePack(name: 'Anime Waifu 1', previewUrl: 'https://example.com/waifu1.jpg', description: 'Beautiful anime waifu backgrounds'),
        ImagePack(name: 'Cyberpunk', previewUrl: 'https://example.com/cyber.jpg', description: 'Futuristic cyberpunk themes'),
        ImagePack(name: 'Nature', previewUrl: 'https://example.com/nature.jpg', description: 'Serene nature landscapes'),
      ];
    }
    _filteredPacks = List.from(_allPacks);
    _animationController.forward();
    setState(() => _isLoading = false);
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  void _filterPacks(String query) {
    setState(() {
      _filteredPacks = _allPacks.where((pack) => pack.name.toLowerCase().contains(query.toLowerCase())).toList();
    });
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

  Future<void> _selectPack(ImagePack pack) async {
    await _setBg(pack.previewUrl);
    setState(() {
      pack.usage++;
    });
    _savePacks();
    _showAICommentary(pack);
  }

  void _savePacks() async {
    final prefs = await SharedPreferences.getInstance();
    final packsJson = json.encode(_allPacks.map((e) => e.toJson()).toList());
    await prefs.setString('image_packs', packsJson);
  }

  void _showAICommentary(ImagePack pack) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('AI Commentary', style: GoogleFonts.outfit(color: Colors.white)),
        content: Text('This ${pack.name} pack brings a ${pack.description}. It\'s been used ${pack.usage} times!', style: GoogleFonts.outfit(color: Colors.white70)),
        backgroundColor: Colors.black54,
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('OK', style: GoogleFonts.outfit())),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FeaturePageV2(
      title: 'IMAGE PACKS',
      subtitle: 'Customize Zero Two\'s aesthetics',
      onBack: () => Navigator.pop(context),
      content: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  style: GoogleFonts.outfit(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search image packs...',
                    hintStyle: GoogleFonts.outfit(color: Colors.white30),
                    prefixIcon: Icon(Icons.search, color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onChanged: _filterPacks,
                ),
                const SizedBox(height: 24),

                // Statistics Chart
                Text('Usage Statistics', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      barGroups: _filteredPacks.map((pack) => BarChartGroupData(
                        x: _filteredPacks.indexOf(pack),
                        barRods: [BarChartRodData(toY: pack.usage.toDouble(), color: Colors.blueAccent)],
                      )).toList(),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) => Text(_filteredPacks[value.toInt()].name, style: GoogleFonts.outfit(color: Colors.white, fontSize: 10)),
                          ),
                        ),
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(show: false),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Current Preview
                Text('Current Background', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _currentBgUrl == null
                      ? Center(child: Text('Default Animated Gradient', style: GoogleFonts.outfit(color: Colors.white54)))
                      : _currentBgUrl!.startsWith('http')
                          ? AppCachedImage(url: _currentBgUrl!, width: double.infinity, height: double.infinity, fit: BoxFit.cover)
                          : Image.file(File(_currentBgUrl!), fit: BoxFit.cover),
                ),
                const SizedBox(height: 32),

                // Image Packs List
                Text('Available Packs', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 16),
                _isLoading
                    ? ShimmerLoading(itemCount: 6, crossAxisCount: 2)
                    : AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.75,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: _filteredPacks.length,
                            itemBuilder: (context, index) {
                              final pack = _filteredPacks[index];
                              final delay = index * 0.1;
                              final animation = Tween<double>(begin: 0, end: 1).animate(
                                CurvedAnimation(
                                  parent: _animationController,
                                  curve: Interval(delay, delay + 0.5, curve: Curves.easeOut),
                                ),
                              );
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: animation.drive(Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)),
                                  child: _buildPackCard(pack),
                                ),
                              );
                            },
                          );
                        },
                      ),

                const SizedBox(height: 32),

                // Original options
                _buildOptionButton(
                  icon: Icons.refresh,
                  label: 'Restore Default Gradient',
                  color: Colors.redAccent,
                  onTap: () => _setBg(null),
                ),
                const SizedBox(height: 16),
                _buildOptionButton(
                  icon: Icons.photo_library_outlined,
                  label: 'Choose from Gallery',
                  color: Colors.blueAccent,
                  onTap: _pickFromGallery,
                ),
                const SizedBox(height: 32),
                Text('Use Web URL', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white70)),
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
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

  Widget _buildPackCard(ImagePack pack) {
    return GestureDetector(
      onTap: () => _selectPack(pack),
      child: GlassCard(
        margin: EdgeInsets.zero,
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: AppCachedImage(url: pack.previewUrl, width: double.infinity, height: double.infinity, fit: BoxFit.cover),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pack.name, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(pack.description, style: GoogleFonts.outfit(fontSize: 12, color: Colors.white70), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('Used: ${pack.usage} times', style: GoogleFonts.outfit(fontSize: 10, color: Colors.white54)),
                ],
              ),
            ),
          ],
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
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
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



