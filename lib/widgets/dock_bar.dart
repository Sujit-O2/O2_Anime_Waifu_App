import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_drawer_sheet.dart';

// ── DockBar ───────────────────────────────────────────────────────────────────
// Nova-Launcher-style pinned app dock. Persists to SharedPreferences.
// Long-press an icon in AppDrawerSheet → passes InstalledApp to DockBar.addApp
// ─────────────────────────────────────────────────────────────────────────────

const _kPrefKey = 'dock_pinned_packages';
const _kMaxDock = 5;

class DockBar extends StatefulWidget {
  final Color primaryColor;

  const DockBar({super.key, required this.primaryColor});

  @override
  State<DockBar> createState() => DockBarState();
}

class DockBarState extends State<DockBar> with SingleTickerProviderStateMixin {
  List<InstalledApp> _pinned = [];
  late AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _loadPinned();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  // ── Persistence ─────────────────────────────────────────────────────────────

  Future<void> _loadPinned() async {
    final prefs = await SharedPreferences.getInstance();
    final packages = prefs.getStringList(_kPrefKey) ?? [];
    if (packages.isEmpty) return;

    // Re-fetch icons from PackageManager for saved packages
    final allApps = await _AppLauncherBridge.getInstalledApps();
    final appMap = {for (final a in allApps) a.packageName: a};
    final pinned = packages
        .map((p) => appMap[p])
        .whereType<InstalledApp>()
        .toList();

    if (mounted) setState(() => _pinned = pinned);
  }

  Future<void> _savePinned() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _kPrefKey, _pinned.map((a) => a.packageName).toList());
  }

  /// Called from AppDrawerSheet long-press to pin an app
  Future<void> addApp(InstalledApp app) async {
    if (_pinned.any((a) => a.packageName == app.packageName)) return;
    setState(() {
      if (_pinned.length >= _kMaxDock) _pinned.removeLast();
      _pinned.insert(0, app);
    });
    await _savePinned();
  }

  Future<void> _removeApp(InstalledApp app) async {
    setState(() => _pinned.removeWhere((a) => a.packageName == app.packageName));
    await _savePinned();
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_pinned.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withValues(alpha: 0.07),
        border: Border.all(
          color: widget.primaryColor.withValues(alpha: 0.20),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.primaryColor.withValues(alpha: 0.12),
            blurRadius: 20,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _pinned
            .map((app) => _DockIcon(
                  app: app,
                  primaryColor: widget.primaryColor,
                  onLongPress: () => _showRemoveDialog(app),
                ))
            .toList(),
      ),
    );
  }

  void _showRemoveDialog(InstalledApp app) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A0A1E),
        title: Text('Remove from dock?',
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 15)),
        content: Text(app.appName,
            style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: GoogleFonts.outfit(color: Colors.white38))),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                _removeApp(app);
              },
              child: Text('Remove',
                  style: GoogleFonts.outfit(color: Colors.redAccent))),
        ],
      ),
    );
  }
}

// ── Dock Icon ─────────────────────────────────────────────────────────────────

class _DockIcon extends StatefulWidget {
  final InstalledApp app;
  final Color primaryColor;
  final VoidCallback onLongPress;

  const _DockIcon({
    required this.app,
    required this.primaryColor,
    required this.onLongPress,
  });

  @override
  State<_DockIcon> createState() => _DockIconState();
}

class _DockIconState extends State<_DockIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 110));
    _scale = Tween<double>(begin: 1.0, end: 0.85)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _launch() async {
    _ctrl.forward().then((_) => _ctrl.reverse());
    await _AppLauncherBridge.launchApp(widget.app.packageName);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _launch,
      onLongPress: widget.onLongPress,
      onTapDown: (_) => _ctrl.forward(),
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: Colors.white.withValues(alpha: 0.08),
                border: Border.all(
                    color: widget.primaryColor.withValues(alpha: 0.18)),
                boxShadow: [
                  BoxShadow(
                    color: widget.primaryColor.withValues(alpha: 0.15),
                    blurRadius: 12,
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: widget.app.icon != null
                    ? Image.memory(widget.app.icon!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _fallback(widget.app, widget.primaryColor))
                    : _fallback(widget.app, widget.primaryColor),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 52,
              child: Text(
                widget.app.appName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: Colors.white70,
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallback(InstalledApp app, Color color) => Container(
        color: color.withValues(alpha: 0.2),
        child: Center(
          child: Text(
            app.appName.isNotEmpty ? app.appName[0].toUpperCase() : '?',
            style: GoogleFonts.outfit(
                color: Colors.white70, fontSize: 20, fontWeight: FontWeight.w800),
          ),
        ),
      );
}

// ── Private bridge (mirrors _AppLauncher in app_drawer_sheet.dart) ────────────

class _AppLauncherBridge {
  static const _ch = MethodChannel('com.example.anime_waifu/apps');

  static Future<List<InstalledApp>> getInstalledApps() async {
    try {
      final list = await _ch.invokeMethod('getInstalledApps') as List? ?? [];
      return list.map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        final iconData = m['icon'];
        return InstalledApp(
          packageName: m['packageName'] as String? ?? '',
          appName: m['appName'] as String? ?? '',
          icon: iconData is Uint8List ? iconData : null,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> launchApp(String pkg) async {
    try {
      await _ch.invokeMethod('launchApp', {'packageName': pkg});
    } catch (_) {}
  }
}
