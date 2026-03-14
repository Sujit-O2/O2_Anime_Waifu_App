import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ── QuickSettingsPanel ────────────────────────────────────────────────────────
// Swipe-down from top of home screen reveals this glassmorphic panel.
// Controls: brightness slider, ringer mode cycle, battery, Wi-Fi indicator.
// ─────────────────────────────────────────────────────────────────────────────

class QuickSettingsPanel extends StatefulWidget {
  final Color primaryColor;
  final VoidCallback? onDismiss;

  const QuickSettingsPanel({
    super.key,
    required this.primaryColor,
    this.onDismiss,
  });

  /// Show as an animated overlay that slides down from top.
  static OverlayEntry showOverlay(
    BuildContext context, {
    required Color primaryColor,
  }) {
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _QuickSettingsOverlay(
        primaryColor: primaryColor,
        onDismiss: () => entry.remove(),
      ),
    );
    Overlay.of(context).insert(entry);
    return entry;
  }

  @override
  State<QuickSettingsPanel> createState() => _QuickSettingsPanelState();
}

class _QuickSettingsOverlay extends StatefulWidget {
  final Color primaryColor;
  final VoidCallback onDismiss;
  const _QuickSettingsOverlay(
      {required this.primaryColor, required this.onDismiss});
  @override
  State<_QuickSettingsOverlay> createState() => _QuickSettingsOverlayState();
}

class _QuickSettingsOverlayState extends State<_QuickSettingsOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380));
    _slide = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _ctrl.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _dismiss,
      child: Material(
        color: Colors.black.withValues(alpha: 0.45),
        child: SlideTransition(
          position: _slide,
          child: FadeTransition(
            opacity: _fade,
            child: Align(
              alignment: Alignment.topCenter,
              child: GestureDetector(
                onTap: () {},
                child: QuickSettingsPanel(
                  primaryColor: widget.primaryColor,
                  onDismiss: _dismiss,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickSettingsPanelState extends State<QuickSettingsPanel> {
  static const _ch = MethodChannel('anime_waifu/assistant_mode');

  double _brightness = 0.5;
  int _ringerMode = 2; // 0=silent, 1=vibrate, 2=ring
  bool _wifi = false;
  int _battery = -1;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final batt = await _ch.invokeMethod<int>('getBatteryLevel') ?? -1;
      final wifi = await _ch.invokeMethod<bool>('isWifiConnected') ?? false;
      if (mounted) setState(() { _battery = batt; _wifi = wifi; });
    } catch (_) {}
  }

  Future<void> _setBrightness(double v) async {
    setState(() => _brightness = v);
    final level = (v * 100).toInt();
    try {
      await _ch.invokeMethod('setVolume', {'level': level});
    } catch (_) {}
  }

  void _cycleRinger() {
    setState(() => _ringerMode = (_ringerMode + 1) % 3);
    final action = ['mute', 'vibrate', 'normal'][_ringerMode];
    try { _ch.invokeMethod('mediaControl', {'action': action}); } catch (_) {}
  }

  String get _ringerLabel => ['Silent 🔇', 'Vibrate 📳', 'Ring 🔔'][_ringerMode];
  IconData get _ringerIcon =>
      [Icons.volume_off_rounded, Icons.vibration_rounded, Icons.volume_up_rounded][_ringerMode];

  @override
  Widget build(BuildContext context) {
    final pw = widget.primaryColor;
    final top = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: top, left: 0, right: 0),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF120820).withValues(alpha: 0.97),
            const Color(0xFF0D0514).withValues(alpha: 0.95),
          ],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        border: Border.all(color: pw.withValues(alpha: 0.25), width: 1),
        boxShadow: [BoxShadow(color: pw.withValues(alpha: 0.2), blurRadius: 30, offset: const Offset(0, 8))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Row(children: [
            Text('Quick Settings',
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
            const Spacer(),
            if (_battery >= 0)
              _Pill(
                icon: _battery > 20
                    ? Icons.battery_full_rounded
                    : Icons.battery_alert_rounded,
                label: '$_battery%',
                color: _battery > 20 ? Colors.greenAccent : Colors.redAccent,
              ),
            const SizedBox(width: 8),
            _Pill(
              icon: _wifi ? Icons.wifi_rounded : Icons.wifi_off_rounded,
              label: _wifi ? 'Wi-Fi' : 'No Wi-Fi',
              color: _wifi ? Colors.cyanAccent : Colors.white38,
            ),
          ]),
          const SizedBox(height: 16),

          // ── Brightness ──────────────────────────────────────────────────
          Row(children: [
            Icon(Icons.brightness_low_rounded, color: Colors.white38, size: 18),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: pw,
                  thumbColor: pw,
                  inactiveTrackColor: Colors.white12,
                  overlayColor: pw.withValues(alpha: 0.15),
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                ),
                child: Slider(
                  value: _brightness,
                  onChanged: _setBrightness,
                ),
              ),
            ),
            Icon(Icons.brightness_high_rounded, color: Colors.white54, size: 18),
          ]),
          const SizedBox(height: 12),

          // ── Quick tiles ─────────────────────────────────────────────────
          Row(children: [
            _QuickTile(
              icon: _ringerIcon,
              label: _ringerLabel,
              active: _ringerMode > 0,
              color: pw,
              onTap: _cycleRinger,
            ),
            const SizedBox(width: 10),
            _QuickTile(
              icon: Icons.do_not_disturb_on_rounded,
              label: 'DND',
              active: false,
              color: pw,
              onTap: () {},
            ),
            const SizedBox(width: 10),
            _QuickTile(
              icon: Icons.flashlight_on_rounded,
              label: 'Torch',
              active: false,
              color: pw,
              onTap: () {},
            ),
            const SizedBox(width: 10),
            _QuickTile(
              icon: Icons.keyboard_arrow_down_rounded,
              label: 'Dismiss',
              active: false,
              color: Colors.white38,
              onTap: widget.onDismiss ?? () {},
            ),
          ]),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Pill({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.outfit(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _QuickTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;
  const _QuickTile({
    required this.icon, required this.label,
    required this.active, required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? color.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active ? color.withValues(alpha: 0.40) : Colors.white12,
            ),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: active ? color : Colors.white54, size: 22),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: active ? color : Colors.white38,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                )),
          ]),
        ),
      ),
    );
  }
}
