import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Reusable cached network image with consistent error/placeholder handling.
/// Caches images on disk so repeat visits load instantly without network calls.
/// Includes fade-in animation for a polished loading experience.
class AppCachedImage extends StatelessWidget {
  final String url;
  final double width;
  final double height;
  final BoxFit fit;
  final double borderRadius;
  final Color? placeholderColor;

  const AppCachedImage({
    super.key,
    required this.url,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 8,
    this.placeholderColor,
  });

  /// Computes the memory-efficient decode dimension.
  /// Clamps between 100–2000px and uses 2x for retina displays.
  int? _decodeDim(double size) {
    if (!size.isFinite || size <= 0) return null;
    return (size * 2).toInt().clamp(100, 2000);
  }

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
        memCacheWidth: _decodeDim(width),
        memCacheHeight: _decodeDim(height),
        fadeInDuration: const Duration(milliseconds: 250),
        fadeInCurve: Curves.easeOut,
        placeholder: (_, __) => _loadingPlaceholder(),
        errorWidget: (_, __, ___) => _placeholder(),
      ),
    );
  }

  Widget _loadingPlaceholder() => ClipRRect(
    borderRadius: BorderRadius.circular(borderRadius),
    child: Container(
      width: width,
      height: height,
      color: placeholderColor ?? Colors.grey.shade900,
      child: Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: Colors.white.withValues(alpha: 0.15),
          ),
        ),
      ),
    ),
  );

  Widget _placeholder() => ClipRRect(
    borderRadius: BorderRadius.circular(borderRadius),
    child: Container(
      width: width,
      height: height,
      color: placeholderColor ?? Colors.grey.shade900,
      child: Icon(
        Icons.image_outlined,
        color: Colors.grey.shade700,
        size: 20,
      ),
    ),
  );
}

