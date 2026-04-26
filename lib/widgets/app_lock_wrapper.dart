import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  bool _isAuthenticating = false;
  bool _didPrecacheBackground = false;
  int _authGeneration = 0;
  String? _authError;
  final LocalAuthentication _auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLockStatus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrecacheBackground) return;
    _didPrecacheBackground = true;
    unawaited(precacheImage(const AssetImage('assets/img/z12.jpg'), context));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      if (_isLockEnabled && _isAuthenticated && mounted) {
        setState(() => _isAuthenticated = false);
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_isLockEnabled && !_isAuthenticated) {
        unawaited(_authenticate());
      }
    }
  }

  Future<void> _checkLockStatus() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _isLockEnabled = prefs.getBool('app_lock_enabled') ?? false;
      if (!_isLockEnabled) {
        _isAuthenticated = true;
      }
    });

    if (_isLockEnabled && !_isAuthenticated) {
      unawaited(_authenticate());
    }
  }

  void updateLockStatus(bool enabled) {
    if (_isLockEnabled == enabled) return;
    _authGeneration++;
    setState(() {
      _isLockEnabled = enabled;
      if (!enabled) {
        _isAuthenticated = true;
        _isAuthenticating = false;
        _authError = null;
      } else {
        _isAuthenticated = false;
      }
    });
    if (enabled) unawaited(_authenticate());
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;
    final generation = ++_authGeneration;

    setState(() {
      _isAuthenticating = true;
      _authError = null;
    });

    var authenticated = false;
    try {
      final isSupported = await _auth.isDeviceSupported();
      if (!isSupported) {
        authenticated = true;
      } else {
        authenticated = await _auth.authenticate(
          localizedReason: 'Please authenticate to access Zero Two',
        );
      }
    } on PlatformException catch (e) {
      _authError = _friendlyAuthError(e);
      if (kDebugMode) debugPrint('AppLock auth error: $e');
    } catch (e) {
      _authError = 'Authentication was interrupted. Try again.';
      if (kDebugMode) debugPrint('AppLock auth error: $e');
      authenticated = false;
    }

    if (!mounted || generation != _authGeneration || !_isLockEnabled) return;
    setState(() {
      _isAuthenticated = authenticated;
      _isAuthenticating = false;
      if (authenticated) _authError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLockEnabled || _isAuthenticated) {
      return widget.child;
    }

    final theme = Theme.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final entranceDuration =
        reduceMotion ? Duration.zero : const Duration(milliseconds: 720);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: Image.asset(
              'assets/img/z12.jpg',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.low,
              errorBuilder: (_, __, ___) => DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF14040A),
                      theme.colorScheme.surface,
                      const Color(0xFF250014),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withValues(alpha: 0.5)),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: entranceDuration,
                        curve: Curves.easeOutBack,
                        builder: (_, val, child) => Transform.scale(
                          scale: 0.72 + val * 0.28,
                          child: Opacity(opacity: val, child: child),
                        ),
                        child: Semantics(
                          label: 'App locked',
                          image: true,
                          child: Container(
                            width: 104,
                            height: 104,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Colors.pinkAccent, Color(0xFF9B59B6)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      Colors.pinkAccent.withValues(alpha: 0.38),
                                  blurRadius: 34,
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.lock_rounded,
                              size: 48,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'App Locked',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Authenticate to continue, Darling~',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: _authError == null
                            ? const SizedBox(height: 34)
                            : Padding(
                                key: ValueKey(_authError),
                                padding: const EdgeInsets.only(top: 14),
                                child: Text(
                                  _authError!,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.outfit(
                                    color: Colors.white.withValues(alpha: 0.78),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: _isAuthenticating ? null : _authenticate,
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: _isAuthenticating
                              ? const SizedBox.square(
                                  key: ValueKey('loading'),
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.fingerprint,
                                  key: ValueKey('fingerprint'),
                                ),
                        ),
                        label: Text(
                          _isAuthenticating ? 'Checking...' : 'Unlock',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.pinkAccent,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              Colors.pinkAccent.withValues(alpha: 0.55),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _friendlyAuthError(PlatformException error) {
    switch (error.code) {
      case 'LockedOut':
      case 'PermanentlyLockedOut':
        return 'Too many attempts. Use your device passcode or try again later.';
      case 'NotAvailable':
      case 'NotEnrolled':
      case 'PasscodeNotSet':
        return 'Set up a device screen lock to protect the app.';
      default:
        return 'Authentication failed. Try again.';
    }
  }
}
