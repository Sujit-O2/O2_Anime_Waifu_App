import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GifViewerPage extends StatefulWidget {
  const GifViewerPage({super.key});

  @override
  State<GifViewerPage> createState() => _GifViewerPageState();
}

class _GifViewerPageState extends State<GifViewerPage> {
  final List<Map<String, String>> _gifs = [
    {
      'path': 'assets/gif/add_incircular_mode_app_oppening style.gif',
      'title': 'App Opening',
      'description': 'Circular mode opening animation'
    },
    {
      'path': 'assets/gif/sidebar_top.gif',
      'title': 'Sidebar Top',
      'description': 'Animated sidebar header'
    },
    {
      'path': 'assets/gif/sidebar_bg.gif',
      'title': 'Sidebar Background',
      'description': 'Dynamic sidebar background'
    },
    {
      'path': 'assets/gif/notification.gif',
      'title': 'Notification',
      'description': 'Notification animation'
    },
    {
      'path': 'assets/gif/debug_area.gif',
      'title': 'Debug Area',
      'description': 'Debug section animation'
    },
    {
      'path': 'assets/gif/background_of_about_section_blurry.gif',
      'title': 'About Background',
      'description': 'Blurred about section background'
    },
  ];

  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: primary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.gif_box_rounded, color: primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'GIF Gallery',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1A0B2E),
              const Color(0xFF2D1B3D),
              primary.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: _selectedIndex == null
              ? _buildGalleryGrid()
              : _buildFullscreenView(),
        ),
      ),
    );
  }

  Widget _buildGalleryGrid() {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primary.withValues(alpha: 0.15),
                  primary.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tap any GIF to view fullscreen',
                    style: GoogleFonts.outfit(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.75,
            ),
            itemCount: _gifs.length,
            itemBuilder: (context, index) {
              final gif = _gifs[index];
              return _buildGifCard(gif, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGifCard(Map<String, String> gif, int index) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black.withValues(alpha: 0.4),
              Colors.black.withValues(alpha: 0.2),
            ],
          ),
          border: Border.all(
            color: primary.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.2),
              blurRadius: 12,
              spreadRadius: -2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      gif['path']!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.black26,
                        child: const Icon(
                          Icons.broken_image_rounded,
                          color: Colors.white30,
                          size: 48,
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.black.withValues(alpha: 0.6),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gif['title']!,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      gif['description']!,
                      style: GoogleFonts.outfit(
                        color: Colors.white60,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFullscreenView() {
    final gif = _gifs[_selectedIndex!];
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Stack(
      children: [
        Center(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Image.asset(
              gif['path']!,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.black26,
                child: const Icon(
                  Icons.broken_image_rounded,
                  color: Colors.white30,
                  size: 64,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              onPressed: () => setState(() => _selectedIndex = null),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.9),
                  Colors.transparent,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primary.withValues(alpha: 0.3),
                            primary.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: primary.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${_selectedIndex! + 1} / ${_gifs.length}',
                        style: GoogleFonts.outfit(
                          color: primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (_selectedIndex! > 0)
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_rounded,
                            color: Colors.white),
                        onPressed: () =>
                            setState(() => _selectedIndex = _selectedIndex! - 1),
                      ),
                    if (_selectedIndex! < _gifs.length - 1)
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios_rounded,
                            color: Colors.white),
                        onPressed: () =>
                            setState(() => _selectedIndex = _selectedIndex! + 1),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  gif['title']!,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  gif['description']!,
                  style: GoogleFonts.outfit(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
