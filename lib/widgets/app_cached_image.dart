import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Reusable cached network image with consistent error/placeholder handling.
/// Caches images on disk so repeat visits load instantly without network calls.
class AppCachedImage extends StatelessWidget {
  final String url;
  final double width;
  final double height;
  final BoxFit fit;
  final double borderRadius;

  const AppCachedImage({
    super.key,
    required this.url,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return _placeholder();

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: width.isFinite && width > 0 ? (width * 2).toInt().clamp(100, 2000) : null, // Memory-efficient — scale to 2x for retina
        placeholder: (_, __) => Container(
          width: width,
          height: height,
          color: Colors.grey.shade900,
          child: const Center(
            child: SizedBox(width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white24)),
          ),
        ),
        errorWidget: (_, __, ___) => _placeholder(),
      ),
    );
  }

  Widget _placeholder() => ClipRRect(
    borderRadius: BorderRadius.circular(borderRadius),
    child: Container(
      width: width, height: height,
      color: Colors.grey.shade900,
      child: const Icon(Icons.image_outlined, color: Colors.grey, size: 20),
    ),
  );
}


