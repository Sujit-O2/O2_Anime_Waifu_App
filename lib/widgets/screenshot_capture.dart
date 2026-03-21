import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// Screenshot Mode — captures any widget and shares it.
/// Wrap a widget in ScreenshotCapture, then call capture() to
/// save and share the screenshot.
class ScreenshotCapture extends StatelessWidget {
  final Widget child;
  final GlobalKey captureKey;

  const ScreenshotCapture({
    super.key,
    required this.child,
    required this.captureKey,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: captureKey,
      child: child,
    );
  }

  /// Capture the widget as an image and share it.
  static Future<void> captureAndShare(GlobalKey key, String filename) async {
    try {
      final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename.png');
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Check out this anime! 🌸 — Shared from Anime Waifu',
      );
    } catch (e) {
      debugPrint('Screenshot capture failed: $e');
    }
  }
}

/// Floating screenshot button — place in a Stack to overlay on content.
class ScreenshotButton extends StatelessWidget {
  final GlobalKey captureKey;
  final String filename;

  const ScreenshotButton({
    super.key,
    required this.captureKey,
    this.filename = 'anime_screenshot',
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 16,
      right: 16,
      child: GestureDetector(
        onTap: () async {
          await ScreenshotCapture.captureAndShare(captureKey, filename);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('📸 Screenshot shared!'),
                backgroundColor: Colors.deepPurple,
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.deepPurple, Colors.pinkAccent]),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.deepPurple.withValues(alpha: 0.5),
                blurRadius: 12, spreadRadius: 2),
            ],
          ),
          child: const Icon(Icons.camera_alt, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
