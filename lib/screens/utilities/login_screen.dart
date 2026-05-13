import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback? onDone;
  const LoginScreen({super.key, this.onDone});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  late final AnimationController _enterCtrl;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _cardSlide;
  late final Animation<double> _heroFade;
  late final Animation<double> _pulse;

  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _enterCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _cardSlide = CurvedAnimation(
        parent: _enterCtrl,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic));
    _heroFade = CurvedAnimation(
        parent: _enterCtrl,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut));

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.6, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _enterCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _enterCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Auth methods ──────────────────────────────────────────────────────────

  Future<void> _signIn() async {
    if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please fill in all fields.');
      return;
    }
    _setLoading(true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailCtrl.text.trim(), password: _passCtrl.text.trim());
      if (mounted) widget.onDone?.call();
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = e.message ?? 'Login failed.');
    } catch (_) {
      if (mounted) setState(() => _error = 'Unexpected error.');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _signInWithGoogle() async {
    _setLoading(true);
    try {
      try { await _googleSignIn.signOut(); } catch (_) {}
      final user = await _googleSignIn.signIn();
      if (user == null) { _setLoading(false); return; }
      final auth = await user.authentication;
      await FirebaseAuth.instance.signInWithCredential(
          GoogleAuthProvider.credential(
              accessToken: auth.accessToken, idToken: auth.idToken));
      if (mounted) widget.onDone?.call();
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = e.message ?? 'Google sign-in failed.');
    } catch (e) {
      final msg = e.toString();
      if (mounted) setState(() => _error = msg.contains('network') ? 'Network error.' : 'Google sign-in failed.');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _signInAnonymously() async {
    _setLoading(true);
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } catch (_) {}
    if (mounted) widget.onDone?.call();
  }

  void _setLoading(bool v) {
    if (mounted) setState(() { _loading = v; if (v) _error = null; });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFF08000F),
        resizeToAvoidBottomInset: true,
        body: SingleChildScrollView(
          child: SizedBox(
            height: size.height,
            child: Stack(
              children: [
                // ── Full-bleed character art ──────────────────────────────────
                FadeTransition(
                  opacity: _heroFade,
                  child: SizedBox.expand(
                    child: Image.asset(
                      'assets/img/z2s.jpg',
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      errorBuilder: (_, __, ___) => Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF2A0030), Color(0xFF08000F)],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Gradient fade — top subtle, bottom heavy ──────────────────
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.0, 0.35, 0.62, 1.0],
                      colors: [
                        Color(0x00000000),
                        Color(0x22000000),
                        Color(0xCC08000F),
                        Color(0xFF08000F),
                      ],
                    ),
                  ),
                ),

                // ── Animated neon glow orbs ───────────────────────────────────
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, __) => Stack(children: [
                    Positioned(
                      top: size.height * 0.28,
                      left: -40,
                      child: _glowOrb(const Color(0xFFFF0057), 200, _pulse.value * 0.18),
                    ),
                    Positioned(
                      top: size.height * 0.18,
                      right: -30,
                      child: _glowOrb(const Color(0xFF00D1FF), 160, _pulse.value * 0.12),
                    ),
                  ]),
                ),

                // ── Top badge ────────────────────────────────────────────────
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: FadeTransition(
                      opacity: _heroFade,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Colors.white.withValues(alpha: 0.08),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6, height: 6,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF00FF88),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text('NEURAL CORE ONLINE',
                                    style: GoogleFonts.jetBrainsMono(
                                      color: Colors.white.withValues(alpha: 0.6),
                                      fontSize: 9,
                                      letterSpacing: 1.5,
                                    )),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Bottom login card ─────────────────────────────────────────
                Positioned(
                  left: 0, right: 0, bottom: 0,
                  child: AnimatedBuilder(
                    animation: _cardSlide,
                    builder: (_, child) => Transform.translate(
                      offset: Offset(0, 60 * (1 - _cardSlide.value)),
                      child: Opacity(opacity: _cardSlide.value, child: child),
                    ),
                    child: _buildCard(size),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _glowOrb(Color color, double size, double alpha) => Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: color.withValues(alpha: alpha), blurRadius: size * 0.8, spreadRadius: size * 0.3)],
        ),
      );

  Widget _buildCard(Size size) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1A0025).withValues(alpha: 0.92),
                const Color(0xFF0D0018).withValues(alpha: 0.96),
              ],
            ),
            border: const Border(
              top: BorderSide(color: Color(0x33FF0057), width: 1.2),
              left: BorderSide(color: Color(0x22FF0057), width: 0.8),
              right: BorderSide(color: Color(0x22FF0057), width: 0.8),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                28, 28, 28, MediaQuery.viewInsetsOf(context).bottom + 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                ),

                // Title
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [Color(0xFFFF0057), Color(0xFFFF6BA8)],
                  ).createShader(b),
                  child: Text('Welcome back,',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      )),
                ),
                Text('Darling 💕',
                    style: GoogleFonts.outfit(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    )),
                const SizedBox(height: 28),

                // Email field
                _field(
                  controller: _emailCtrl,
                  hint: 'Email address',
                  icon: Icons.alternate_email_rounded,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),

                // Password field
                _field(
                  controller: _passCtrl,
                  hint: 'Password',
                  icon: Icons.lock_outline_rounded,
                  obscure: _obscure,
                  suffix: GestureDetector(
                    onTap: () => setState(() => _obscure = !_obscure),
                    child: Icon(
                      _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: Colors.white30, size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Error
                if (_error != null) ...[
                  _errorBanner(),
                  const SizedBox(height: 16),
                ],

                // Sign in button
                _primaryButton('SIGN IN', _signIn),
                const SizedBox(height: 16),

                // Divider
                Row(children: [
                  Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.08))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text('or continue with',
                        style: GoogleFonts.outfit(
                            color: Colors.white.withValues(alpha: 0.25),
                            fontSize: 12)),
                  ),
                  Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.08))),
                ]),
                const SizedBox(height: 16),

                // Google + Guest row
                Row(children: [
                  Expanded(child: _googleButton()),
                  const SizedBox(width: 12),
                  Expanded(child: _guestButton()),
                ]),

                const SizedBox(height: 20),
                Center(
                  child: Text('v11.0.2 · O2-WAIFU',
                      style: GoogleFonts.jetBrainsMono(
                        color: Colors.white.withValues(alpha: 0.12),
                        fontSize: 9,
                        letterSpacing: 2,
                      )),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
        cursorColor: const Color(0xFFFF0057),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.outfit(
              color: Colors.white.withValues(alpha: 0.22), fontSize: 14),
          prefixIcon: Icon(icon,
              color: const Color(0xFFFF0057).withValues(alpha: 0.7), size: 20),
          suffixIcon: suffix != null
              ? Padding(padding: const EdgeInsets.only(right: 12), child: suffix)
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 18, horizontal: 4),
        ),
      ),
    );
  }

  Widget _errorBanner() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.redAccent.withValues(alpha: 0.08),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          const Icon(Icons.error_outline_rounded,
              color: Colors.redAccent, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(_error!,
                style: GoogleFonts.outfit(
                    color: Colors.redAccent.withValues(alpha: 0.9),
                    fontSize: 12)),
          ),
        ]),
      );

  Widget _primaryButton(String label, VoidCallback onTap) => SizedBox(
        width: double.infinity,
        height: 56,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
                colors: [Color(0xFFFF0057), Color(0xFFAA00FF)]),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF0057).withValues(alpha: 0.4),
                blurRadius: 24,
                offset: const Offset(0, 8),
                spreadRadius: -4,
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _loading ? null : onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: _loading
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white))
                : Text(label,
                    style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        color: Colors.white)),
          ),
        ),
      );

  Widget _googleButton() => SizedBox(
        height: 52,
        child: ElevatedButton(
          onPressed: _loading ? null : _signInWithGoogle,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.06),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RichText(
                text: const TextSpan(
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  children: [
                    TextSpan(text: 'G', style: TextStyle(color: Color(0xFF4285F4))),
                    TextSpan(text: 'o', style: TextStyle(color: Color(0xFFEA4335))),
                    TextSpan(text: 'o', style: TextStyle(color: Color(0xFFFBBC05))),
                    TextSpan(text: 'g', style: TextStyle(color: Color(0xFF4285F4))),
                    TextSpan(text: 'l', style: TextStyle(color: Color(0xFF34A853))),
                    TextSpan(text: 'e', style: TextStyle(color: Color(0xFFEA4335))),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text('Google',
                  style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.8))),
            ],
          ),
        ),
      );

  Widget _guestButton() => SizedBox(
        height: 52,
        child: ElevatedButton(
          onPressed: _loading ? null : _signInAnonymously,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.04),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_outline_rounded,
                  size: 16, color: Colors.white.withValues(alpha: 0.5)),
              const SizedBox(width: 6),
              Text('Guest',
                  style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.5))),
            ],
          ),
        ),
      );
}
