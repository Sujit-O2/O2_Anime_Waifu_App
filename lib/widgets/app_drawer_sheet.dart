import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';


// ── App Info model ────────────────────────────────────────────────────────

class InstalledApp {
  final String packageName;
  final String appName;
  final Uint8List? icon;

  const InstalledApp({
    required this.packageName,
    required this.appName,
    this.icon,
  });
}

// ── Platform channel helper ───────────────────────────────────────────────

/// Calls native Android PackageManager to list launchable apps.
/// No extra package needed — uses the existing `android_intent_plus` infra.
class _AppLauncher {
  static const _channel = MethodChannel('com.example.anime_waifu/apps');

  static Future<List<InstalledApp>> getInstalledApps() async {
    try {
      final List result =
          await _channel.invokeMethod('getInstalledApps') as List? ?? [];
      return result.map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        final iconData = m['icon'];
        return InstalledApp(
          packageName: m['packageName'] as String? ?? '',
          appName: m['appName'] as String? ?? m['packageName'] as String? ?? '',
          icon: iconData is Uint8List ? iconData : null,
        );
      }).where((a) => a.packageName.isNotEmpty).toList()
        ..sort((a, b) => a.appName.compareTo(b.appName));
    } catch (e) {
      debugPrint('[AppDrawer] getInstalledApps error: $e');
      return [];
    }
  }

  static Future<void> launchApp(String packageName) async {
    try {
      await _channel.invokeMethod('launchApp', {'packageName': packageName});
    } catch (e) {
      debugPrint('[AppDrawer] launchApp error: $e');
    }
  }
}

// ────────────────────────────────────────────────────────────────────────────
// AppDrawerSheet
//
// A full-height DraggableScrollableSheet that slides up from the bottom.
// Decorate it with a frosted glassmorphic panel, search bar, animated
// grid of app icons, and waifu mascot header.
// ────────────────────────────────────────────────────────────────────────────

class AppDrawerSheet extends StatefulWidget {
  final Color primaryColor;
  final VoidCallback? onClose;
  /// Called when user long-presses an icon to pin it to the dock
  final void Function(InstalledApp)? onPin;

  const AppDrawerSheet({
    super.key,
    required this.primaryColor,
    this.onClose,
    this.onPin,
  });

  /// Show the drawer as a bottom sheet over the current context.
  static Future<void> show(
    BuildContext context, {
    Color primaryColor = const Color(0xFFFF4D8D),
    void Function(InstalledApp)? onPin,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => AppDrawerSheet(primaryColor: primaryColor, onPin: onPin),
    );
  }

  @override
  State<AppDrawerSheet> createState() => _AppDrawerSheetState();
}

class _AppDrawerSheetState extends State<AppDrawerSheet>
    with SingleTickerProviderStateMixin {
  // ── Animation ─────────────────────────────────────────────────────────────
  late AnimationController _entryCtrl;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  // ── Data ──────────────────────────────────────────────────────────────────
  List<InstalledApp> _all = [];
  List<InstalledApp> _filtered = [];
  bool _loading = true;
  final TextEditingController _search = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _entryCtrl, curve: const Interval(0.0, 0.6)),
    );
    _entryCtrl.forward();
    _search.addListener(_onSearch);
    _loadApps();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _loadApps() async {
    final apps = await _AppLauncher.getInstalledApps();
    if (!mounted) return;
    setState(() {
      _all = apps;
      _filtered = apps;
      _loading = false;
    });
  }

  void _onSearch() {
    final q = _search.text.toLowerCase().trim();
    setState(() {
      _filtered = q.isEmpty
          ? _all
          : _all.where((a) => a.appName.toLowerCase().contains(q)).toList();
    });
  }

  void _launch(InstalledApp app) async {
    await _entryCtrl.reverse();
    if (mounted) Navigator.of(context).pop();
    await _AppLauncher.launchApp(app.packageName);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return SlideTransition(
      position: _slideAnim,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Container(
          height: size.height * 0.88,
          decoration: BoxDecoration(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF1A0A1E).withValues(alpha: 0.96),
                const Color(0xFF0D0510).withValues(alpha: 0.98),
              ],
            ),
            border: Border.all(
              color: widget.primaryColor.withValues(alpha: 0.25),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.primaryColor.withValues(alpha: 0.18),
                blurRadius: 40,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHandle(),
              _buildHeader(),
              _buildSearchBar(),
              const SizedBox(height: 10),
              Expanded(child: _buildGrid()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
      child: Row(
        children: [
          // Waifu logo mark
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  widget.primaryColor.withValues(alpha: 0.9),
                  widget.primaryColor.withValues(alpha: 0.3),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.primaryColor.withValues(alpha: 0.5),
                  blurRadius: 14,
                ),
              ],
            ),
            child: const Center(
              child: Text('✦', style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'All Apps',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '${_all.length} apps installed',
                style: GoogleFonts.outfit(
                  color: Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon:
                Icon(Icons.close_rounded, color: Colors.white38, size: 22),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.primaryColor.withValues(alpha: 0.22),
          ),
        ),
        child: TextField(
          controller: _search,
          focusNode: _searchFocus,
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
          cursorColor: widget.primaryColor,
          decoration: InputDecoration(
            hintText: 'Search apps…',
            hintStyle:
                GoogleFonts.outfit(color: Colors.white30, fontSize: 14),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: Colors.white30,
              size: 20,
            ),
            suffixIcon: _search.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear_rounded,
                        color: Colors.white30, size: 18),
                    onPressed: () {
                      _search.clear();
                      _searchFocus.unfocus();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildGrid() {
    if (_loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                color: widget.primaryColor,
                strokeWidth: 2.5,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Loading apps…',
              style: GoogleFonts.outfit(color: Colors.white38, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('No apps found', style: GoogleFonts.outfit(color: Colors.white38)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 32),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.78,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: _filtered.length,
      itemBuilder: (context, i) => _AppIcon(
        app: _filtered[i],
        primaryColor: widget.primaryColor,
        onTap: _launch,
        index: i,
        onLongPress: widget.onPin != null
            ? (app) {
                widget.onPin!(app);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${app.appName} pinned to dock!'),
                    backgroundColor: widget.primaryColor.withValues(alpha: 0.9),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            : null,
      ),
    );
  }
}

// ── Single App Icon Cell ──────────────────────────────────────────────────

class _AppIcon extends StatefulWidget {
  final InstalledApp app;
  final Color primaryColor;
  final void Function(InstalledApp) onTap;
  final void Function(InstalledApp)? onLongPress;
  final int index;
  const _AppIcon({
    required this.app,
    required this.primaryColor,
    required this.onTap,
    required this.index,
    this.onLongPress,
  });

  @override
  State<_AppIcon> createState() => _AppIconState();
}

class _AppIconState extends State<_AppIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.88)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    // Staggered entrance fade+scale
    // Run entry animation with a stagger delay
    Future.delayed(Duration(milliseconds: 30 + widget.index * 18), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap(widget.app);
      },
      onTapCancel: () => _ctrl.reverse(),
      onLongPress: widget.onLongPress != null
          ? () => widget.onLongPress!(widget.app)
          : null,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            // Icon with notification badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.white.withValues(alpha: 0.07),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.primaryColor.withValues(alpha: 0.10),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: widget.app.icon != null
                        ? Image.memory(
                            widget.app.icon!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _fallbackIcon(),
                          )
                        : _fallbackIcon(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // App name
            Text(
              widget.app.appName,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 10,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _fallbackIcon() {
    return Container(
      color: widget.primaryColor.withValues(alpha: 0.20),
      child: Center(
        child: Text(
          widget.app.appName.isNotEmpty
              ? widget.app.appName[0].toUpperCase()
              : '?',
          style: GoogleFonts.outfit(
            color: Colors.white70,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

// ── Swipe-up trigger widget ───────────────────────────────────────────────

/// Drop this anywhere (e.g. bottom of the home screen) to detect an
/// upward swipe and open the app drawer automatically.
class SwipeUpDrawerTrigger extends StatelessWidget {
  final Color primaryColor;
  final Widget child;

  const SwipeUpDrawerTrigger({
    super.key,
    required this.primaryColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragEnd: (details) {
        // Swipe up with enough velocity
        if ((details.primaryVelocity ?? 0) < -300) {
          AppDrawerSheet.show(context, primaryColor: primaryColor);
        }
      },
      child: child,
    );
  }
}

// ── Animated Drawer Handle Bar ────────────────────────────────────────────

/// Animated pill at the bottom of the screen that pulses to hint
/// the user can swipe up.
class DrawerHandleBar extends StatefulWidget {
  final Color primaryColor;
  final VoidCallback? onTap;

  const DrawerHandleBar({
    super.key,
    required this.primaryColor,
    this.onTap,
  });

  @override
  State<DrawerHandleBar> createState() => _DrawerHandleBarState();
}

class _DrawerHandleBarState extends State<DrawerHandleBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _glow = Tween<double>(begin: 0.3, end: 0.9)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _glow,
        builder: (_, __) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Up arrow icon
            Icon(
              Icons.keyboard_arrow_up_rounded,
              color: widget.primaryColor.withValues(alpha: _glow.value),
              size: 20,
            ),
            const SizedBox(height: 2),
            // Pill
            Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: widget.primaryColor.withValues(alpha: _glow.value * 0.8),
                boxShadow: [
                  BoxShadow(
                    color: widget.primaryColor
                        .withValues(alpha: _glow.value * 0.5),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'APPS',
              style: GoogleFonts.outfit(
                color: widget.primaryColor.withValues(alpha: _glow.value * 0.7),
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
