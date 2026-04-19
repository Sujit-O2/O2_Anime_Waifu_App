import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Premium floating glassmorphic bottom navigation bar.
/// Modern, responsive design with smooth micro-animations.
class MainBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color accentColor;

  const MainBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.accentColor,
  });

  static const _items = [
    _NavItem(icon: Icons.chat_bubble_outline_rounded, activeIcon: Icons.chat_bubble_rounded, label: 'Chat'),
    _NavItem(icon: Icons.explore_outlined, activeIcon: Icons.explore_rounded, label: 'Explore'),
    _NavItem(icon: Icons.menu_book_outlined, activeIcon: Icons.menu_book_rounded, label: 'Manga'),
    _NavItem(icon: Icons.music_note_outlined, activeIcon: Icons.music_note_rounded, label: 'Music'),
    _NavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings_rounded, label: 'More'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding > 0 ? bottomPadding : 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: const Color(0xFF0D0D1A).withValues(alpha: 0.85),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.08),
                  blurRadius: 32,
                  offset: const Offset(0, -4),
                  spreadRadius: -4,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: List.generate(_items.length, (i) => Expanded(
                child: _NavButton(
                  item: _items[i],
                  isSelected: currentIndex == i,
                  accentColor: accentColor,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onTap(i);
                  },
                ),
              )),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}

class _NavButton extends StatefulWidget {
  final _NavItem item;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;
  const _NavButton({
    required this.item,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });
  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _scale = Tween<double>(begin: 1.0, end: 1.18).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _glow = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    if (widget.isSelected) _ctrl.forward();
  }

  @override
  void didUpdateWidget(covariant _NavButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _ctrl.forward(from: 0);
    } else if (!widget.isSelected && oldWidget.isSelected) {
      _ctrl.reverse();
    }
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
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Animated glow indicator pill
                AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  width: widget.isSelected ? 52 : 0,
                  height: widget.isSelected ? 34 : 0,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(17),
                    gradient: widget.isSelected
                        ? LinearGradient(
                            colors: [
                              widget.accentColor.withValues(alpha: 0.25),
                              widget.accentColor.withValues(alpha: 0.08),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          )
                        : null,
                    boxShadow: widget.isSelected
                        ? [
                            BoxShadow(
                              color: widget.accentColor.withValues(alpha: 0.3 * _glow.value),
                              blurRadius: 20,
                              spreadRadius: -2,
                            ),
                          ]
                        : null,
                  ),
                ),
                Transform.scale(
                  scale: _scale.value,
                  child: Icon(
                    widget.isSelected ? widget.item.activeIcon : widget.item.icon,
                    color: widget.isSelected
                        ? widget.accentColor
                        : Colors.white.withValues(alpha: 0.35),
                    size: 22,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: GoogleFonts.outfit(
                color: widget.isSelected
                    ? widget.accentColor
                    : Colors.white.withValues(alpha: 0.3),
                fontSize: widget.isSelected ? 10.5 : 10,
                fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w400,
                letterSpacing: widget.isSelected ? 0.5 : 0,
              ),
              child: Text(widget.item.label),
            ),
          ],
        ),
      ),
    );
  }
}
