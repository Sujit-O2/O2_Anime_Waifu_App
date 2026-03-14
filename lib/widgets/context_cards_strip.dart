import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/weather_service.dart';

// ── ContextCardsStrip ─────────────────────────────────────────────────────────
// Horizontal scroll of animated smart cards shown above the chat input.
// Cards: battery, weather, unread notifications, now playing, greeting.
// ─────────────────────────────────────────────────────────────────────────────

class ContextCardsStrip extends StatefulWidget {
  final Color primaryColor;
  final int unreadNotifCount;
  final String? nowPlaying;
  final VoidCallback? onBatteryTap;
  final VoidCallback? onWeatherTap;
  final VoidCallback? onMusicTap;

  const ContextCardsStrip({
    super.key,
    required this.primaryColor,
    this.unreadNotifCount = 0,
    this.nowPlaying,
    this.onBatteryTap,
    this.onWeatherTap,
    this.onMusicTap,
  });

  @override
  State<ContextCardsStrip> createState() => _ContextCardsStripState();
}

class _ContextCardsStripState extends State<ContextCardsStrip>
    with TickerProviderStateMixin {
  static const _ch = MethodChannel('anime_waifu/assistant_mode');
  int _battery = -1;
  late List<AnimationController> _entryCtrls;
  late List<Animation<double>> _entryFades;
  late List<Animation<Offset>> _entrySlides;

  @override
  void initState() {
    super.initState();
    _loadBattery();
    _entryCtrls = List.generate(
      5,
      (i) => AnimationController(
          vsync: this, duration: const Duration(milliseconds: 400)),
    );
    _entryFades = _entryCtrls
        .map((c) =>
            Tween<double>(begin: 0, end: 1).animate(
                CurvedAnimation(parent: c, curve: Curves.easeOut)))
        .toList();
    _entrySlides = _entryCtrls
        .map((c) =>
            Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
                .animate(CurvedAnimation(parent: c, curve: Curves.easeOutCubic)))
        .toList();
    // Staggered entry
    for (int i = 0; i < _entryCtrls.length; i++) {
      Future.delayed(Duration(milliseconds: 120 + i * 80), () {
        if (mounted) _entryCtrls[i].forward();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _entryCtrls) c.dispose();
    super.dispose();
  }

  Future<void> _loadBattery() async {
    try {
      final b = await _ch.invokeMethod<int>('getBatteryLevel') ?? -1;
      if (mounted) setState(() => _battery = b);
    } catch (_) {}
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 12) return '🌅 Morning, Darling~';
    if (h >= 12 && h < 17) return '☀️ Good Afternoon!';
    if (h >= 17 && h < 21) return '🌸 Good Evening~';
    return '🌙 Still up, Darling?';
  }

  @override
  Widget build(BuildContext context) {
    final weather = WeatherService.instance.current;
    final cards = <_CardData>[
      _CardData(
        index: 0,
        icon: Icons.waving_hand_rounded,
        title: _greeting,
        subtitle: 'Tap to chat',
        color: widget.primaryColor,
        onTap: null,
      ),
      if (_battery >= 0)
        _CardData(
          index: 1,
          icon: _battery > 20
              ? Icons.battery_full_rounded
              : Icons.battery_alert_rounded,
          title: '$_battery%',
          subtitle: _battery < 20 ? 'Low battery!' : 'Battery',
          color: _battery < 20 ? Colors.redAccent : Colors.greenAccent,
          onTap: widget.onBatteryTap,
        ),
      if (weather != null)
        _CardData(
          index: 2,
          icon: Icons.wb_sunny_rounded,
          title: weather.summary,
          subtitle: 'Tap for details',
          color: Colors.orangeAccent,
          onTap: widget.onWeatherTap,
        ),
      if (widget.unreadNotifCount > 0)
        _CardData(
          index: 3,
          icon: Icons.notifications_rounded,
          title: '${widget.unreadNotifCount} unread',
          subtitle: 'Notifications',
          color: Colors.purpleAccent,
          onTap: null,
        ),
      if (widget.nowPlaying != null)
        _CardData(
          index: 4,
          icon: Icons.music_note_rounded,
          title: widget.nowPlaying!,
          subtitle: 'Now playing',
          color: Colors.cyanAccent,
          onTap: widget.onMusicTap,
        ),
    ];

    if (cards.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final card = cards[i];
          final idx = card.index.clamp(0, _entryCtrls.length - 1);
          return SlideTransition(
            position: _entrySlides[idx],
            child: FadeTransition(
              opacity: _entryFades[idx],
              child: _ContextCard(data: card),
            ),
          );
        },
      ),
    );
  }
}

class _CardData {
  final int index;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;
  const _CardData({
    required this.index,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
  });
}

class _ContextCard extends StatefulWidget {
  final _CardData data;
  const _ContextCard({required this.data});
  @override
  State<_ContextCard> createState() => _ContextCardState();
}

class _ContextCardState extends State<_ContextCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _pressScale;
  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _pressScale = Tween<double>(begin: 1.0, end: 0.93)
        .animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) { _pressCtrl.reverse(); d.onTap?.call(); },
      onTapCancel: () => _pressCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _pressScale,
        builder: (_, child) =>
            Transform.scale(scale: _pressScale.value, child: child),
        child: Container(
          width: 140,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: d.color.withValues(alpha: 0.10),
            border: Border.all(color: d.color.withValues(alpha: 0.28), width: 1),
            boxShadow: [
              BoxShadow(
                  color: d.color.withValues(alpha: 0.12), blurRadius: 10)
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: d.color.withValues(alpha: 0.18),
                ),
                child: Icon(d.icon, color: d.color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(d.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                    Text(d.subtitle,
                        style: GoogleFonts.outfit(
                            color: Colors.white38, fontSize: 9)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
