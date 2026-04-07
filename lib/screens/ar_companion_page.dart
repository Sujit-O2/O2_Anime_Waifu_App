import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:google_fonts/google_fonts.dart';

class ArCompanionPage extends StatelessWidget {
  const ArCompanionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('AR Companion Mode', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Stack(
        children: [
          const ModelViewer(
            backgroundColor: Color.fromARGB(0xFF, 0x1A, 0x1B, 0x26), // Dark background matching app theme
            src: 'https://modelviewer.dev/shared-assets/models/RobotExpressive.glb', // A generic expressive 3D robot placeholder 
            alt: 'A 3D model of an interactive companion',
            ar: true,
            arModes: ['scene-viewer', 'webxr', 'quick-look'],
            autoRotate: true,
            cameraControls: true,
            disableZoom: false,
          ),
          Positioned(
            bottom: 32,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Spawn Zero Two in your room!',
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the AR icon in the bottom right corner of the viewer to project this model onto your physical floor or desk.',
                    style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.info_outline, color: Colors.orangeAccent, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Note: Replace the "src" URL in lib/screens/ar_companion_page.dart with your own Zero Two .glb or .gltf file link later.',
                          style: GoogleFonts.outfit(color: Colors.orangeAccent, fontSize: 11),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
