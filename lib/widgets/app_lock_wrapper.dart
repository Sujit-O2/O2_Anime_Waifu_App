import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';

class AppLockWrapper extends StatefulWidget {
  final Widget child;
  const AppLockWrapper({super.key, required this.child});

  @override
  State<AppLockWrapper> createState() => AppLockWrapperState();
}

class AppLockWrapperState extends State<AppLockWrapper>
    with WidgetsBindingObserver {
  bool _isAuthenticated = false;
  bool _isLockEnabled = false;
  final LocalAuthentication _auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLockStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_isLockEnabled) {
        setState(() {
          _isAuthenticated = false;
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_isLockEnabled && !_isAuthenticated) {
        _authenticate();
      }
    }
  }

  Future<void> _checkLockStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isLockEnabled = prefs.getBool('app_lock_enabled') ?? false;
      if (!_isLockEnabled) {
        _isAuthenticated = true;
      }
    });

    if (_isLockEnabled && !_isAuthenticated) {
      _authenticate();
    }
  }

  void updateLockStatus(bool enabled) {
    setState(() {
      _isLockEnabled = enabled;
      if (!enabled) {
        _isAuthenticated = true;
      }
    });
  }

  Future<void> _authenticate() async {
    bool authenticated = false;
    try {
      authenticated = await _auth.authenticate(
        localizedReason: 'Please authenticate to access Zero Two',
      );
    } catch (e) {
      // Fallback if no auth is set up on device
      authenticated = true;
    }

    if (mounted) {
      setState(() {
        _isAuthenticated = authenticated;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLockEnabled || _isAuthenticated) {
      return widget.child;
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/img/z12.jpg',
            fit: BoxFit.cover,
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withOpacity(0.5)),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_rounded,
                  size: 80, color: Colors.pinkAccent),
              const SizedBox(height: 20),
              Text(
                'App Locked',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: _authenticate,
                icon: const Icon(Icons.fingerprint, color: Colors.white),
                label: Text('Unlock',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
