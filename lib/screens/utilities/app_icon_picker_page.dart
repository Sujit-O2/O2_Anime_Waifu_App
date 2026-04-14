import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:anime_waifu/core/v2_upgrade_kit.dart';

class AppIconPickerPage extends StatefulWidget {
  const AppIconPickerPage({super.key});

  @override
  State<AppIconPickerPage> createState() => _AppIconPickerPageState();
}

class _AppIconPickerPageState extends State<AppIconPickerPage> {
  static const MethodChannel _channel =
      MethodChannel('anime_waifu/assistant_mode');
  static const String _queryKey = 'app_icon_picker_query_v2';
  static const String _filterKey = 'app_icon_picker_filter_v2';

  String _currentVariant = 'old';
  String _query = '';
  String _filter = 'All';
  bool _switching = false;

  @override
  void initState() {
    super.initState();
    _restoreState();
    _loadCurrent();
  }

  Future<void> _restoreState() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }
    setState(() {
      _query = prefs.getString(_queryKey) ?? '';
      _filter = prefs.getString(_filterKey) ?? 'All';
    });
  }

  Future<void> _persistState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_queryKey, _query);
    await prefs.setString(_filterKey, _filter);
  }

  Future<void> _loadCurrent() async {
    try {
      final variant =
          await _channel.invokeMethod<String>('getLauncherIconVariant');
      if (!mounted) {
        return;
      }
      setState(() => _currentVariant = variant ?? 'old');
    } catch (_) {}
  }

  Future<void> _switchIcon(String variant) async {
    if (_switching || variant == _currentVariant) {
      return;
    }

    setState(() => _switching = true);
    try {
      await _channel.invokeMethod('setLauncherIconVariant', <String, String>{
        'variant': variant,
      });
      HapticFeedback.mediumImpact();
      if (!mounted) {
        return;
      }
      setState(() {
        _currentVariant = variant;
        _switching = false;
      });
      showSuccessSnackbar(
        context,
        'App icon updated. Your launcher may take a moment to refresh.',
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _currentVariant = variant;
        _switching = false;
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            backgroundColor: V2Theme.surfaceLight,
            content: const Text(
              'Only Classic and Neon are registered launcher aliases. The rest are preview presets.',
            ),
          ),
        );
    }
  }

  List<_IconOption> get _visibleIcons {
    final query = _query.trim().toLowerCase();
    return _icons.where((icon) {
      final filterMatch = switch (_filter) {
        'Live' => icon.isLiveAlias,
        'Preview' => !icon.isLiveAlias,
        _ => true,
      };
      final queryMatch = query.isEmpty ||
          icon.name.toLowerCase().contains(query) ||
          icon.description.toLowerCase().contains(query);
      return filterMatch && queryMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleIcons;
    final liveCount = _icons.where((icon) => icon.isLiveAlias).length;
    final mood = _currentVariant == 'old' || _currentVariant == 'new'
        ? 'achievement'
        : 'motivated';

    return Scaffold(
      backgroundColor: V2Theme.surfaceDark,
      body: WaifuBackground(
        opacity: 0.08,
        tint: V2Theme.surfaceDark,
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              await _restoreState();
              await _loadCurrent();
            },
            color: V2Theme.primaryColor,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white70,
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    'App Icon Picker',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    'Switch launcher looks and preview alternate skins.',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        WaifuCommentary(mood: mood),
                        const SizedBox(height: 12),
                        if (_switching)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: LinearProgressIndicator(
                              color: V2Theme.primaryColor,
                              backgroundColor: Colors.white10,
                            ),
                          ),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: StatCard(
                                title: 'Variants',
                                value: '${_icons.length}',
                                icon: Icons.apps_rounded,
                                color: V2Theme.primaryColor,
                              ),
                            ),
                            Expanded(
                              child: StatCard(
                                title: 'Live Aliases',
                                value: '$liveCount',
                                icon: Icons.check_circle_rounded,
                                color: V2Theme.secondaryColor,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: StatCard(
                                title: 'Visible',
                                value: '${visible.length}',
                                icon: Icons.visibility_rounded,
                                color: Colors.orangeAccent,
                              ),
                            ),
                            Expanded(
                              child: StatCard(
                                title: 'Active',
                                value: _icons
                                    .firstWhere(
                                      (icon) => icon.id == _currentVariant,
                                      orElse: () => _icons.first,
                                    )
                                    .shortLabel,
                                icon: Icons.star_rounded,
                                color: Colors.lightGreenAccent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        V2SearchBar(
                          hintText: 'Search icon style...',
                          onChanged: (value) {
                            setState(() => _query = value);
                            _persistState();
                          },
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: const <String>['All', 'Live', 'Preview']
                              .map((filter) {
                            final selected = _filter == filter;
                            return ChoiceChip(
                              selected: selected,
                              onSelected: (_) {
                                setState(() => _filter = filter);
                                _persistState();
                              },
                              selectedColor:
                                  V2Theme.primaryColor.withValues(alpha: 0.22),
                              backgroundColor: Colors.white10,
                              label: Text(filter),
                              labelStyle: GoogleFonts.outfit(
                                color: selected ? Colors.white : Colors.white70,
                                fontWeight: FontWeight.w600,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                                side: BorderSide(
                                  color: selected
                                      ? V2Theme.primaryColor
                                      : Colors.white12,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                if (visible.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.image_not_supported_outlined,
                      title: 'No icon variants found',
                      subtitle:
                          'Try a different search or switch the filter to see more icon styles.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final icon = visible[index];
                          final isSelected = _currentVariant == icon.id;
                          return AnimatedEntry(
                            index: index,
                            child: GestureDetector(
                              onTap: () => _switchIcon(icon.id),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: <Color>[
                                      icon.gradient.first.withValues(
                                        alpha: isSelected ? 0.4 : 0.18,
                                      ),
                                      icon.gradient.last.withValues(
                                        alpha: isSelected ? 0.22 : 0.08,
                                      ),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white10,
                                    width: isSelected ? 1.8 : 1,
                                  ),
                                  boxShadow: isSelected
                                      ? <BoxShadow>[
                                          BoxShadow(
                                            color: icon.gradient.first
                                                .withValues(alpha: 0.22),
                                            blurRadius: 18,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Row(
                                      children: <Widget>[
                                        Container(
                                          width: 54,
                                          height: 54,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(18),
                                            gradient: LinearGradient(
                                              colors: icon.gradient,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              icon.emoji,
                                              style: const TextStyle(
                                                fontSize: 26,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        if (icon.isLiveAlias)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.greenAccent
                                                  .withValues(alpha: 0.16),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              'Live',
                                              style: GoogleFonts.outfit(
                                                color: Colors.greenAccent,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const Spacer(),
                                    Text(
                                      icon.name,
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      icon.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.outfit(
                                        color: Colors.white70,
                                        fontSize: 12,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      isSelected
                                          ? 'Active now'
                                          : 'Tap to apply',
                                      style: GoogleFonts.outfit(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.white54,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: visible.length,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.86,
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

class _IconOption {
  const _IconOption({
    required this.id,
    required this.name,
    required this.shortLabel,
    required this.emoji,
    required this.description,
    required this.gradient,
    required this.isLiveAlias,
  });

  final String id;
  final String name;
  final String shortLabel;
  final String emoji;
  final String description;
  final List<Color> gradient;
  final bool isLiveAlias;
}

const List<_IconOption> _icons = <_IconOption>[
  _IconOption(
    id: 'old',
    name: 'Classic Zero Two',
    shortLabel: 'Classic',
    emoji: '🌸',
    description: 'The original pink launcher identity.',
    gradient: <Color>[Color(0xFFE91E63), Color(0xFFAD1457)],
    isLiveAlias: true,
  ),
  _IconOption(
    id: 'new',
    name: 'Neon Zero Two',
    shortLabel: 'Neon',
    emoji: '⚡',
    description: 'A bright cyber-style launcher variant.',
    gradient: <Color>[Color(0xFF6200EA), Color(0xFFAA00FF)],
    isLiveAlias: true,
  ),
  _IconOption(
    id: 'dark',
    name: 'Shadow Mode',
    shortLabel: 'Shadow',
    emoji: '🌙',
    description: 'Dark, minimal, and stealthy preview styling.',
    gradient: <Color>[Color(0xFF1A1A2E), Color(0xFF16213E)],
    isLiveAlias: false,
  ),
  _IconOption(
    id: 'sakura',
    name: 'Sakura Bloom',
    shortLabel: 'Sakura',
    emoji: '🌸',
    description: 'Soft cherry blossom pastel preview.',
    gradient: <Color>[Color(0xFFF48FB1), Color(0xFFF06292)],
    isLiveAlias: false,
  ),
  _IconOption(
    id: 'ocean',
    name: 'Ocean Wave',
    shortLabel: 'Ocean',
    emoji: '🌊',
    description: 'Cool blue gradients for a calmer look.',
    gradient: <Color>[Color(0xFF00BCD4), Color(0xFF0097A7)],
    isLiveAlias: false,
  ),
  _IconOption(
    id: 'fire',
    name: 'Flame Spirit',
    shortLabel: 'Flame',
    emoji: '🔥',
    description: 'Hot orange-red energy for a bold launcher.',
    gradient: <Color>[Color(0xFFFF5722), Color(0xFFE64A19)],
    isLiveAlias: false,
  ),
];



