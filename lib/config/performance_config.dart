import 'package:flutter/material.dart';

/// ⚡ PERFORMANCE OPTIMIZATION CONFIG
/// Central configuration for app-wide performance settings

class O2PerformanceConfig {
  // ── Particle System ──────────────────────────────────────────
  static const int maxParticlesRain = 6;
  static const int maxParticlesSnow = 8;
  static const int maxParticlesStars = 10;
  static const int maxParticlesBubbles = 8;
  static const int maxParticlesDefault = 12;
  
  // ── Animation Frame Budgets ──────────────────────────────────
  static const int targetFPS = 60;
  static const int frameTimeMs = 16; // 60fps = 16ms per frame
  static const int maxFrameTimeMs = 20; // Allow some slack
  
  // ── Image Caching ────────────────────────────────────────────
  static const int imageCacheWidth = 1920;
  static const int imageCacheHeight = 1920;
  static const FilterQuality defaultFilterQuality = FilterQuality.low;
  
  // ── Audio ────────────────────────────────────────────────────
  static const double bgmVolume = 0.6;
  static const double sfxVolume = 0.8;
  static const int audioInitDelayMs = 100;
  
  // ── List Performance ─────────────────────────────────────────
  static const int listCacheExtent = 500;
  static const bool addRepaintBoundaries = true;
  
  // ── Network ──────────────────────────────────────────────────
  static const Duration networkTimeout = Duration(seconds: 10);
  static const int maxConcurrentRequests = 3;
  
  // ── Memory ───────────────────────────────────────────────────
  static const int maxCachedImages = 50;
  static const int maxChatMessages = 100;
  
  // ── Debounce/Throttle ────────────────────────────────────────
  static const Duration searchDebounce = Duration(milliseconds: 300);
  static const Duration scrollThrottle = Duration(milliseconds: 100);
  static const Duration interactionThrottle = Duration(milliseconds: 33); // ~30fps
}
