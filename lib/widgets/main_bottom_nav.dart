import 'dart:ui';
import 'package:anime_waifu/config/app_themes.dart';
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
    _NavItem(
        icon: Icons.chat_bubble_outline_rounded,
        activeIcon: Icons.chat_bubble_rounded,
        label: 'Chat'),
    _NavItem(
        icon: Icons.notifications_outlined,
        activeIcon: Icons.notifications_rounded,
        label: 'Alerts'),
    _NavItem(
        icon: Icons.explore_outlined,
        activeIcon: Icons.explore_rounded,
        label: 'Explore'),
    _NavItem(
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings_rounded,
        label: 'Settings'),
    _NavItem(
        icon: Icons.palette_outlined,
        activeIcon: Icons.palette_rounded,
        label: 'Themes'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final selectedIndex = currentIndex.clamp(0, _items.length - 1);
    final tokens = context.appTokens;
    final theme = Theme.of(context);

    return RepaintBoundary(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        margin: EdgeInsets.fromLTRB(
            14, 0, 14, bottomPadding > 0 ? bottomPadding + 4 : 14),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    tokens.panel.withValues(alpha: 0.78),
                    tokens.panelElevated.withValues(alpha: 0.68),
                  ],
                ),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.22),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.18),
                    blurRadius: 28,
                    offset: const Offset(0, -2),
                    spreadRadius: -6,
                  ),
                  BoxShadow(
                    color: theme.brightness == Brightness.dark
                        ? Colors.black.withValues(alpha: 0.2)
                        : tokens.shadowColor,
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                    spreadRadius: -12,
                  ),
                ],
              ),
              child: Row(
                children: List.generate(
                    _items.length,
                    (i) => Expanded(
                          child: _NavButton(
                            item: _items[i],
                            isSelected: selectedIndex == i,
                            accentColor: accentColor,
                            disableAnimations: disableAnimations,
                            onTap: () {
                              if (selectedIndex != i) {
                                HapticFeedback.selectionClick();
                              }
                              onTap(i);
                            },
                          ),
                        )),
              ),
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
  const _NavItem(
      {required this.icon, required this.activeIcon, required this.label});
}

class _NavButton extends StatefulWidget {
  final _NavItem item;
  final bool isSelected;
  final Color accentColor;
  final bool disableAnimations;
  final VoidCallback onTap;
  const _NavButton({
    required this.item,
    required this.isSelected,
    required this.accentColor,
    required this.disableAnimations,
    required this.onTap,
  });
  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: widget.disableAnimations
          ? Duration.zero
          : const Duration(milliseconds: 360),
      reverseDuration: widget.disableAnimations
          ? Duration.zero
          : const Duration(milliseconds: 220),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _glow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    if (widget.isSelected) _ctrl.value = 1;
  }

  @override
  void didUpdateWidget(covariant _NavButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.disableAnimations != oldWidget.disableAnimations) {
      _ctrl.duration = widget.disableAnimations
          ? Duration.zero
          : const Duration(milliseconds: 360);
      _ctrl.reverseDuration = widget.disableAnimations
          ? Duration.zero
          : const Duration(milliseconds: 220);
    }
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
    final duration = widget.disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 320);
    final tokens = context.appTokens;

    return Semantics(
      button: true,
      selected: widget.isSelected,
      label: widget.item.label,
      child: Tooltip(
        message: widget.item.label,
        waitDuration: const Duration(milliseconds: 500),
        child: InkResponse(
          onTap: widget.onTap,
          radius: 36,
          containedInkWell: true,
          highlightShape: BoxShape.rectangle,
          splashColor: widget.accentColor.withValues(alpha: 0.15),
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedContainer(
                      duration: duration,
                      curve: Curves.easeOutCubic,
                      width: widget.isSelected ? 48 : 0,
                      height: widget.isSelected ? 36 : 0,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: widget.isSelected
                            ? LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  widget.accentColor.withValues(alpha: 0.3),
                                  widget.accentColor.withValues(alpha: 0.1),
                                ],
                              )
                            : null,
                        boxShadow: widget.isSelected
                            ? [
                                BoxShadow(
                                  color: widget.accentColor
                                      .withValues(alpha: 0.4 * _glow.value),
                                  blurRadius: 16,
                                  spreadRadius: -2,
                                ),
                              ]
                            : null,
                      ),
                    ),
                    Transform.scale(
                      scale: _scale.value,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        transitionBuilder: (child, anim) => ScaleTransition(
                          scale: anim,
                          child: child,
                        ),
                        child: Icon(
                          widget.isSelected
                              ? widget.item.activeIcon
                              : widget.item.icon,
                          key: ValueKey(widget.isSelected),
                          color: widget.isSelected
                              ? widget.accentColor
                              : tokens.textMuted,
                          size: 22,
                          semanticLabel: widget.item.label,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                AnimatedDefaultTextStyle(
                  duration: duration,
                  curve: Curves.easeOutCubic,
                  style: GoogleFonts.outfit(
                    color: widget.isSelected
                        ? widget.accentColor
                        : tokens.textSoft,
                    fontSize: widget.isSelected ? 10.5 : 10,
                    fontWeight:
                        widget.isSelected ? FontWeight.w800 : FontWeight.w500,
                    letterSpacing: widget.isSelected ? 0.3 : 0,
                  ),
                  child: Text(
                    widget.item.label,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                  ),
                ),
                const SizedBox(height: 4),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: widget.isSelected ? 1.0 : 0.0),
                  duration: duration,
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => Transform.scale(
                    scale: value,
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.accentColor,
                        boxShadow: [
                          BoxShadow(
                            color: widget.accentColor.withValues(alpha: 0.5 * value),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
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
