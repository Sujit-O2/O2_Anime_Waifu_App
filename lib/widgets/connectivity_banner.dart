import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A sleek connectivity banner that appears when the device goes offline.
/// Slides in from the top with a smooth animation and auto-dismisses
/// when the connection is restored.
///
/// Usage: Place at the top of your widget tree stack:
/// ```dart
/// Stack(children: [
///   YourMainContent(),
///   const ConnectivityBanner(),
/// ])
/// ```
class ConnectivityBanner extends StatefulWidget {
  const ConnectivityBanner({super.key});

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _isOffline = false;
  bool _wasOffline = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    // Subscribe to connectivity stream — no polling, no DNS queries
    _connectivitySub = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      _setOffline(!online);
    });

    // Check initial state once
    Connectivity().checkConnectivity().then((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      _setOffline(!online);
    });
  }

  void _setOffline(bool offline) {
    if (!mounted) return;
    if (_isOffline == offline) return;
    setState(() {
      _wasOffline = _isOffline;
      _isOffline = offline;
    });
    if (offline) {
      _ctrl.forward();
    } else {
      // Show "Back Online" for 2 seconds before hiding
      if (_wasOffline) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && !_isOffline) _ctrl.reverse();
        });
      } else {
        _ctrl.reverse();
      }
    }
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slide,
        child: SafeArea(
          bottom: false,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: _isOffline
                  ? const Color(0xCC2D1B1B)
                  : const Color(0xCC2D1020),
              border: Border.all(
                color: _isOffline
                    ? Colors.redAccent.withValues(alpha: 0.4)
                    : Colors.pinkAccent.withValues(alpha: 0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: (_isOffline ? Colors.redAccent : Colors.pinkAccent)
                      .withValues(alpha: 0.2),
                  blurRadius: 16,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  _isOffline
                      ? Icons.wifi_off_rounded
                      : Icons.wifi_rounded,
                  color: _isOffline ? Colors.redAccent : Colors.pinkAccent,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _isOffline
                        ? 'No internet connection — using offline mode'
                        : 'Back online ✨',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (_isOffline)
                  GestureDetector(
                    onTap: () => Connectivity().checkConnectivity().then((results) {
                      final online = results.any((r) => r != ConnectivityResult.none);
                      _setOffline(!online);
                    }),
                    child: const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white54,
                      size: 18,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
