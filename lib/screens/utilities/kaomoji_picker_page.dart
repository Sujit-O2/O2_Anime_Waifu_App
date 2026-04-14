import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:anime_waifu/core/v2_upgrade_kit.dart';

class KaomojiPickerPage extends StatefulWidget {
  const KaomojiPickerPage({super.key});

  @override
  State<KaomojiPickerPage> createState() => _KaomojiPickerPageState();
}

class _KaomojiPickerPageState extends State<KaomojiPickerPage>
    with SingleTickerProviderStateMixin {
  static const String _favoritesKey = 'kaomoji_picker_favorites_v2';
  static const String _recentKey = 'kaomoji_picker_recent_v2';

  static const Map<String, List<String>> _library = <String, List<String>>{
    'Waifu': <String>[
      '(◕‿◕✿)',
      '(。・ω・。)',
      '(づ。◕‿‿◕。)づ',
      '(≧◡≦)',
      '(๑˃ᴗ˂)ﻭ',
      '(♡-_-♡)',
      '(っ˘ڡ˘ς)',
      '(✿◠‿◠)',
    ],
    'Happy': <String>[
      r'\(^o^)/',
      '(ノ´ヮ`)ノ*: ・゚',
      '( ̄▽ ̄)',
      '(o^▽^o)',
      '(ノ◕ヮ◕)ノ*:・゚✧',
      '(✧ω✧)',
      '(*^▽^*)',
      '(づ ̄ 3 ̄)づ',
    ],
    'Soft': <String>[
      '(´。• ᵕ •。`)',
      '(˘▾˘)',
      '(˶ᵔ ᵕ ᵔ˶)',
      '(っ˘ω˘ς )',
      '(´-ω-`)',
      '(ᵔᴥᵔ)',
      '( ˘͈ ᵕ ˘͈♡)',
      '(っ˕ -。)',
    ],
    'Sad': <String>[
      '(T_T)',
      '(。•́︿•̀。)',
      '(╥_╥)',
      '(っ- ‸ -ς)',
      '( ; ω ; )',
      '(。•́︿•̀。)',
      '(。╯︵╰。)',
      '(。•́︵•̀。)',
    ],
    'Angry': <String>[
      '(╬ Ò﹏Ó)',
      '٩(╬ʘ益ʘ╬)۶',
      '(>_<)',
      '(ノಠ益ಠ)ノ',
      '(¬_¬")',
      '(ง •̀_•́)ง',
      'ヽ( `д´*)ノ',
      '(≖_≖ )',
    ],
    'Cool': <String>[
      '(⌐■_■)',
      '(¬‿¬)',
      '(•̀ᴗ•́)و ̑̑',
      '(▀̿Ĺ̯▀̿ ̿)',
      '( ̄ー ̄)',
      '( •_•)>⌐■-■',
      '(ง' '̀-' '́)ง',
      '(☞゚ヮ゚)☞',
    ],
    'Animals': <String>[
      '(=^・ω・^=)',
      'U^ェ^U',
      '(•ㅅ•)',
      '(=^-ω-^=)',
      '(◕ᴥ◕)',
      '(ᵔᴥᵔ)',
      '/ᐠ。‸。ᐟ\\',
      '(=`ω´=)',
    ],
  };

  String _selectedCategory = 'Waifu';
  String _query = '';
  String? _lastCopied;
  Set<String> _favorites = <String>{};
  List<String> _recent = <String>[];
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..forward();
    _restoreState();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _restoreState() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }
    setState(() {
      _favorites = prefs.getStringList(_favoritesKey)?.toSet() ?? <String>{};
      _recent = prefs.getStringList(_recentKey) ?? <String>[];
    });
  }

  Future<void> _persistState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoritesKey, _favorites.toList()..sort());
    await prefs.setStringList(_recentKey, _recent);
  }

  void _copy(String kaomoji) {
    HapticFeedback.selectionClick();
    Clipboard.setData(ClipboardData(text: kaomoji));
    setState(() {
      _lastCopied = kaomoji;
      _recent = <String>[
        kaomoji,
        ..._recent.where((entry) => entry != kaomoji),
      ].take(10).toList();
    });
    _persistState();
    showSuccessSnackbar(context, '$kaomoji copied to clipboard.');
  }

  void _toggleFavorite(String kaomoji) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_favorites.contains(kaomoji)) {
        _favorites.remove(kaomoji);
      } else {
        _favorites.add(kaomoji);
      }
    });
    _persistState();
  }

  List<String> get _visibleKaomojis {
    final baseList = switch (_selectedCategory) {
      'Favorites' => _recentWhereFavorite(),
      'Recent' => _recent,
      _ => _library[_selectedCategory] ?? const <String>[],
    };

    if (_query.trim().isEmpty) {
      return baseList;
    }

    final query = _query.trim().toLowerCase();
    return baseList
        .where((kaomoji) => kaomoji.toLowerCase().contains(query))
        .toList();
  }

  List<String> _recentWhereFavorite() {
    final ordered = <String>[
      ..._recent.where(_favorites.contains),
      ..._favorites.where((item) => !_recent.contains(item)),
    ];
    return ordered;
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleKaomojis;
    final categoryChips = <String>[
      'Waifu',
      'Happy',
      'Soft',
      'Sad',
      'Angry',
      'Cool',
      'Animals',
      'Favorites',
      'Recent',
    ];
    final mood = _favorites.length >= 6
        ? 'achievement'
        : _recent.isNotEmpty
            ? 'motivated'
            : 'neutral';

    return FeaturePageV2(
      title: 'Kaomoji Picker',
      subtitle: 'Search, favorite, and copy reactions instantly.',
      onBack: () => Navigator.of(context).pop(),
      actions: [
        if (_lastCopied != null)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: V2Theme.primaryColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              _lastCopied!,
              style: const TextStyle(fontSize: 13),
            ),
          ),
      ],
      content: RefreshIndicator(
        onRefresh: _restoreState,
        color: V2Theme.primaryColor,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    WaifuCommentary(mood: mood),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: StatCard(
                            title: 'Favorites',
                            value: '${_favorites.length}',
                            icon: Icons.favorite_rounded,
                            color: V2Theme.primaryColor,
                          ),
                        ),
                        Expanded(
                          child: StatCard(
                            title: 'Recent',
                            value: '${_recent.length}',
                            icon: Icons.history_rounded,
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
                            icon: Icons.grid_view_rounded,
                            color: Colors.orangeAccent,
                          ),
                        ),
                        Expanded(
                          child: StatCard(
                            title: 'Category',
                            value: _selectedCategory,
                            icon: Icons.category_rounded,
                            color: Colors.lightGreenAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    V2SearchBar(
                      hintText: 'Search kaomoji...',
                      onChanged: (value) => setState(() => _query = value),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: categoryChips.map((category) {
                          final isSelected = category == _selectedCategory;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              selected: isSelected,
                              onSelected: (_) => setState(
                                () => _selectedCategory = category,
                              ),
                              label: Text(category),
                              selectedColor:
                                  V2Theme.primaryColor.withValues(alpha: 0.22),
                              backgroundColor: Colors.white10,
                              labelStyle: GoogleFonts.outfit(
                                color:
                                    isSelected ? Colors.white : Colors.white70,
                                fontWeight: FontWeight.w600,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                                side: BorderSide(
                                  color: isSelected
                                      ? V2Theme.primaryColor
                                      : Colors.white12,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (visible.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.sentiment_neutral_rounded,
                  title: 'Nothing matched',
                  subtitle: _selectedCategory == 'Favorites'
                      ? 'Favorite a few kaomojis and they will appear here for quick access.'
                      : 'Try another search or switch to a different reaction category.',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final kaomoji = visible[index];
                      final isFavorite = _favorites.contains(kaomoji);
                      final isCopied = _lastCopied == kaomoji;
                      return AnimatedEntry(
                        index: index,
                        child: GlassCard(
                          margin: EdgeInsets.zero,
                          glow: isCopied,
                          onTap: () => _copy(kaomoji),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      _selectedCategory,
                                      style: GoogleFonts.outfit(
                                        color: Colors.white54,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _toggleFavorite(kaomoji),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: Icon(
                                      isFavorite
                                          ? Icons.favorite_rounded
                                          : Icons.favorite_border_rounded,
                                      color: isFavorite
                                          ? Colors.pinkAccent
                                          : Colors.white54,
                                      size: 18,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Center(
                                child: Text(
                                  kaomoji,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                isCopied ? 'Copied' : 'Tap to copy',
                                style: GoogleFonts.outfit(
                                  color: isCopied
                                      ? V2Theme.secondaryColor
                                      : Colors.white38,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: visible.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}



