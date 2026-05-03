import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:anime_waifu/widgets/animated_background.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback? onDone;
  const LoginScreen({super.key, this.onDone});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late AnimationController _animCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _floatCtrl;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;
  late Animation<double> _pulse;
  late Animation<double> _float;

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    _float = Tween<double>(
      begin: -6,
      end: 6,
    ).animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

    _animCtrl.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animCtrl.dispose();
    _pulseCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields.');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (mounted) widget.onDone?.call();
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.message ?? 'Login failed.');
      }
    } catch (_) {
      if (mounted) setState(() => _errorMessage = 'Unexpected error.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInAnonymously() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await FirebaseAuth.instance.signInAnonymously();
      if (mounted) widget.onDone?.call();
    } on FirebaseAuthException catch (_) {
      // If anonymous auth fails, still proceed as guest
      if (mounted) widget.onDone?.call();
    } catch (_) {
      if (mounted) widget.onDone?.call();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      try {
        await _googleSignIn.signOut();
      } catch (_) {}

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      if (mounted) widget.onDone?.call();
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.message ?? 'Google sign-in failed.');
      }
    } catch (e) {
      final msg = e.toString();
      String userMessage = 'Google sign-in failed. Try again.';
      if (msg.contains('network_error') || msg.contains('NetworkError')) {
        userMessage = 'Network error. Check your connection and try again.';
      } else if (msg.contains('sign_in_canceled') || msg.contains('canceled')) {
        userMessage = 'Sign-in was cancelled.';
      } else if (msg.contains('sign_in_failed')) {
        userMessage =
            'Google sign-in failed. Make sure Google Play Services is updated.';
      }
      if (mounted) {
        setState(() => _errorMessage = userMessage);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final isCompact = screenSize.height < 700;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Stack(
          children: [
            const AnimatedBackground(),

            // Dark cinematic overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.5),
                    const Color(0xFF0A0015).withValues(alpha: 0.85),
                    Colors.black.withValues(alpha: 0.95),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),

            // Animated glow orbs
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) => Stack(
                children: [
                  Positioned(
                    top: -80,
                    right: -60,
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.pinkAccent.withValues(
                              alpha: 0.12 * _pulse.value,
                            ),
                            blurRadius: 140,
                            spreadRadius: 50,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -100,
                    left: -50,
                    child: Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepPurple.withValues(
                              alpha: 0.18 * _pulse.value,
                            ),
                            blurRadius: 120,
                            spreadRadius: 40,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenSize.width > 400 ? 36 : 24,
                    vertical: 24,
                  ),
                  child: FadeTransition(
                    opacity: _fadeIn,
                    child: SlideTransition(
                      position: _slideUp,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLogo(isCompact),
                          SizedBox(height: isCompact ? 24 : 36),
                          _buildCard(),
                          const SizedBox(height: 20),
                          _buildFooter(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo(bool isCompact) {
    return AnimatedBuilder(
      animation: _float,
      builder: (_, child) =>
          Transform.translate(offset: Offset(0, _float.value), child: child),
      child: Column(
        children: [
          // Circular avatar with animated glow ring
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, __) => Container(
              width: isCompact ? 80 : 100,
              height: isCompact ? 80 : 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF4D8D), Color(0xFF9B59B6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.pinkAccent.withValues(
                      alpha: 0.35 * _pulse.value,
                    ),
                    blurRadius: 40,
                    spreadRadius: 8,
                  ),
                  BoxShadow(
                    color: Colors.deepPurple.withValues(
                      alpha: 0.2 * _pulse.value,
                    ),
                    blurRadius: 60,
                    spreadRadius: -4,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(3),
              child: ClipOval(
                child: Image.asset(
                  'assets/img/logi.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: isCompact ? 10 : 16),
          // Pixel-art title logo
          Image.asset(
            'assets/img/front.png',
            width: MediaQuery.sizeOf(context).width * 0.72,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [
                  Color(0xFFFF4D8D),
                  Color(0xFFB44FD6),
                  Color(0xFF5FE2FF),
                ],
              ).createShader(bounds),
              child: Text(
                'ZERO TWO',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 6,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Welcome back, Darling 💕',
            style: GoogleFonts.outfit(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.06),
            Colors.white.withValues(alpha: 0.02),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              // Email
              _buildField(
                controller: _emailController,
                hint: 'Email address',
                icon: Icons.alternate_email_rounded,
                obscure: false,
              ),
              const SizedBox(height: 16),

              // Password
              _buildField(
                controller: _passwordController,
                hint: 'Password',
                icon: Icons.lock_outline_rounded,
                obscure: _obscurePassword,
                suffix: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.white30,
                    size: 20,
                  ),
                  onPressed: () {
                    if (!mounted) return;
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Error
              if (_errorMessage != null) ...[
                _buildErrorBanner(),
                const SizedBox(height: 16),
              ],

              // Sign In button
              _buildSignInButton(),
              const SizedBox(height: 20),

              // Divider
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.white.withValues(alpha: 0.15),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'or',
                      style: GoogleFonts.outfit(
                        color: Colors.white24,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.15),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Google button
              _buildGoogleButton(),
              const SizedBox(height: 14),

              // Guest button
              _buildGuestButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool obscure,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
        cursorColor: Colors.pinkAccent,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.outfit(
            color: Colors.white.withValues(alpha: 0.25),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            icon,
            color: Colors.pinkAccent.withValues(alpha: 0.6),
            size: 20,
          ),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 4,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (_, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 8 * (1 - value)),
          child: child,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.redAccent.withValues(alpha: 0.1),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Colors.redAccent,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _errorMessage!,
                style: GoogleFonts.outfit(
                  color: Colors.redAccent.withValues(alpha: 0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignInButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFFFF4D8D), Color(0xFFB44FD6)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF4D8D).withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 8),
              spreadRadius: -4,
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _signIn,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Text(
                  'SIGN IN',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _signInWithGoogle,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.06),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                children: [
                  TextSpan(
                    text: 'G',
                    style: TextStyle(color: Color(0xFF4285F4)),
                  ),
                  TextSpan(
                    text: 'o',
                    style: TextStyle(color: Color(0xFFEA4335)),
                  ),
                  TextSpan(
                    text: 'o',
                    style: TextStyle(color: Color(0xFFFBBC05)),
                  ),
                  TextSpan(
                    text: 'g',
                    style: TextStyle(color: Color(0xFF4285F4)),
                  ),
                  TextSpan(
                    text: 'l',
                    style: TextStyle(color: Color(0xFF34A853)),
                  ),
                  TextSpan(
                    text: 'e',
                    style: TextStyle(color: Color(0xFFEA4335)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Continue with Google',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestButton() {
    return TextButton(
      onPressed: _isLoading ? null : _signInAnonymously,
      child: Text(
        'Continue as Guest',
        style: GoogleFonts.outfit(
          color: Colors.white.withValues(alpha: 0.45),
          fontSize: 13,
          fontWeight: FontWeight.w500,
          decoration: TextDecoration.underline,
          decorationColor: Colors.white.withValues(alpha: 0.25),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Text(
          'v8.0.0 · O2-WAIFU Production',
          style: GoogleFonts.jetBrainsMono(
            color: Colors.white.withValues(alpha: 0.15),
            fontSize: 10,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}
