import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:anime_waifu/config/app_themes.dart';
import 'package:anime_waifu/core/v2_upgrade_kit.dart';
// --- Models ------------------------------------------------------------------

class HubFeature {
  final String label;
  final IconData icon;
  final Color color;
  final String? badge;
  final VoidCallback onTap;

  const HubFeature({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.badge,
  });
}

class HubGroup {
  final String title;
  final String emoji;
  final Color accent;
  final List<HubFeature> features;

  const HubGroup({
    required this.title,
    required this.emoji,
    required this.accent,
    required this.features,
  });
}

// --- Hub Page -----------------------------------------------------------------

class HubPage extends StatefulWidget {
  final String hubTitle;
  final String hubEmoji;
  final Color hubColor;
  final List<HubGroup> groups;

  const HubPage({
    super.key,
    required this.hubTitle,
    required this.hubEmoji,
    required this.hubColor,
    required this.groups,
  });

  @override
  State<HubPage> createState() => _HubPageState();
}

class _HubPageState extends State<HubPage> with TickerProviderStateMixin {
  int? _openGroupIndex;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    _searchCtrl.addListener(() {
      setState(() {
        _searchQuery = _searchCtrl.text.trim().toLowerCase();
        // When searching, expand all groups with matches
        if (_searchQuery.isNotEmpty) _openGroupIndex = null;
      });
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _toggleGroup(int index) {
    HapticFeedback.lightImpact();
    setState(() => _openGroupIndex = _openGroupIndex == index ? null : index);
  }

  List<HubGroup> get _filteredGroups {
    if (_searchQuery.isEmpty) return widget.groups;
    return widget.groups
        .map((g) {
          final matchingFeatures = g.features
              .where((f) => f.label.toLowerCase().contains(_searchQuery))
              .toList();
          if (matchingFeatures.isEmpty &&
              !g.title.toLowerCase().contains(_searchQuery)) {
            return null;
          }
          return HubGroup(
            title: g.title,
            emoji: g.emoji,
            accent: g.accent,
            features: matchingFeatures.isEmpty ? g.features : matchingFeatures,
          );
        })
        .whereType<HubGroup>()
        .toList();
  }

  int get _totalFeatures =>
      widget.groups.fold<int>(0, (s, g) => s + g.features.length);

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredGroups;
    final isSearching = _searchQuery.isNotEmpty;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: WaifuBackground(
        opacity: 0.12,
        tint: theme.scaffoldBackgroundColor,
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              children: [
                _buildHeader(),
                _buildSearchBar(),
                _buildStats(filtered, isSearching),
                Expanded(
                  child: filtered.isEmpty
                      ? _buildEmpty()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: filtered.length,
                          itemBuilder: (ctx, i) =>
                              _buildGroupCard(i, filtered[i], isSearching),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    final tokens = context.appTokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: tokens.panelMuted,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: tokens.outlineStrong),
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: tokens.textMuted,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(widget.hubEmoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.hubTitle,
              style: GoogleFonts.outfit(
                color: theme.colorScheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: widget.hubColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: widget.hubColor.withValues(alpha: 0.34)),
            ),
            child: Text(
              '$_totalFeatures Features',
              style: GoogleFonts.outfit(
                color: widget.hubColor,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final theme = Theme.of(context);
    final tokens = context.appTokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          gradient: tokens.glassGradient,
          color: tokens.panel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _searchQuery.isNotEmpty
                ? widget.hubColor.withValues(alpha: 0.6)
                : tokens.outline,
            width: _searchQuery.isNotEmpty ? 1.2 : 1.0,
          ),
          boxShadow: _searchQuery.isNotEmpty
              ? [
                  BoxShadow(
                    color: widget.hubColor.withValues(alpha: 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: -8,
                  ),
                ]
              : [
                  BoxShadow(
                    color: tokens.shadowColor,
                    blurRadius: 20,
                    offset: const Offset(0, 12),
                    spreadRadius: -14,
                  ),
                ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Icon(Icons.search_rounded,
                color:
                    _searchQuery.isNotEmpty ? widget.hubColor : tokens.textSoft,
                size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                textDirection: TextDirection.ltr,
                style: GoogleFonts.outfit(
                  color: theme.colorScheme.onSurface,
                  fontSize: 14,
                ),
                cursorColor: widget.hubColor,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Search features...',
                  hintStyle:
                      GoogleFonts.outfit(color: tokens.textSoft, fontSize: 13),
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchCtrl.clear();
                  setState(() => _searchQuery = '');
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(Icons.close_rounded,
                      color: Colors.white38, size: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats(List<HubGroup> filtered, bool isSearching) {
    final tokens = context.appTokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(
        children: [
          Icon(
              isSearching ? Icons.filter_list_rounded : Icons.touch_app_rounded,
              color: tokens.textSoft,
              size: 13),
          const SizedBox(width: 6),
          Text(
            isSearching
                ? '${filtered.fold<int>(0, (s, g) => s + g.features.length)} results for "$_searchQuery"'
                : 'Tap a group to expand · ${widget.groups.length} groups',
            style: GoogleFonts.outfit(color: tokens.textSoft, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    final theme = Theme.of(context);
    final tokens = context.appTokens;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('??', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text('No features found',
              style: GoogleFonts.outfit(
                  color: theme.colorScheme.onSurface, fontSize: 16)),
          const SizedBox(height: 4),
          Text('Try a different search term',
              style: GoogleFonts.outfit(color: tokens.textSoft, fontSize: 12)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildGroupCard(int index, HubGroup group, bool isSearching) {
    final isOpen = isSearching || _openGroupIndex == index;
    final theme = Theme.of(context);
    final tokens = context.appTokens;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        gradient: isOpen
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  group.accent.withValues(alpha: 0.10),
                  group.accent.withValues(alpha: 0.04),
                ],
              )
            : LinearGradient(
                colors: [
                  tokens.panel.withValues(alpha: 0.92),
                  tokens.panelMuted.withValues(alpha: 0.78),
                ],
              ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOpen ? group.accent.withValues(alpha: 0.5) : tokens.outline,
          width: isOpen ? 1.4 : 1.0,
        ),
        boxShadow: isOpen
            ? [
                BoxShadow(
                    color: group.accent.withValues(alpha: 0.15),
                    blurRadius: 20,
                    spreadRadius: 2),
                BoxShadow(
                    color: group.accent.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                    spreadRadius: -1),
              ]
            : [
                BoxShadow(
                  color: tokens.shadowColor,
                  blurRadius: 16,
                  offset: const Offset(0, 10),
                  spreadRadius: -12,
                ),
              ],
      ),
      child: Column(
        children: [
          // Group header
          InkWell(
            onTap: isSearching ? null : () => _toggleGroup(index),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          group.accent.withValues(alpha: isOpen ? 0.25 : 0.12),
                          group.accent.withValues(alpha: isOpen ? 0.15 : 0.06),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: group.accent
                              .withValues(alpha: isOpen ? 0.5 : 0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: group.accent
                              .withValues(alpha: isOpen ? 0.2 : 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                        child: Text(group.emoji,
                            style: const TextStyle(fontSize: 18))),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(group.title,
                            style: GoogleFonts.outfit(
                              color: isOpen
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.onSurface
                                      .withValues(alpha: 0.84),
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            )),
                        Text(
                          '${group.features.length} features',
                          style: GoogleFonts.outfit(
                            color: isOpen
                                ? group.accent.withValues(alpha: 0.8)
                                : tokens.textSoft,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isSearching)
                    AnimatedRotation(
                      turns: isOpen ? 0.5 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: Icon(Icons.keyboard_arrow_down_rounded,
                          color: isOpen ? group.accent : tokens.textSoft,
                          size: 22),
                    ),
                ],
              ),
            ),
          ),

          // Features list
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildFeatureList(group),
            crossFadeState:
                isOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 260),
            sizeCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureList(HubGroup group) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        children: [
          Divider(color: group.accent.withValues(alpha: 0.2), height: 1),
          const SizedBox(height: 6),
          ...group.features.map((f) => _buildFeatureTile(f)),
        ],
      ),
    );
  }

  Widget _buildFeatureTile(HubFeature feature) {
    final theme = Theme.of(context);
    final tokens = context.appTokens;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.pop(context);
        feature.onTap();
      },
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    feature.color.withValues(alpha: 0.18),
                    feature.color.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: feature.color.withValues(alpha: 0.35)),
                boxShadow: [
                  BoxShadow(
                    color: feature.color.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(feature.icon, color: feature.color, size: 17),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(feature.label,
                  style: GoogleFonts.outfit(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.84),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  )),
            ),
            if (feature.badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      feature.color.withValues(alpha: 0.18),
                      feature.color.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: feature.color.withValues(alpha: 0.4)),
                  boxShadow: [
                    BoxShadow(
                      color: feature.color.withValues(alpha: 0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(feature.badge!,
                    style: GoogleFonts.outfit(
                      color: feature.color,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    )),
              ),
              const SizedBox(width: 6),
            ],
            Icon(
              Icons.chevron_right_rounded,
              color: tokens.textSoft.withValues(alpha: 0.6),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
