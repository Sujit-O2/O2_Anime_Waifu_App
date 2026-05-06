// ignore_for_file: use_build_context_synchronously
part of 'package:anime_waifu/main.dart';

extension _MainDrawerExtension on _ChatHomePageState {
  Widget _buildNavDrawer(AppThemeMode mode) => _buildDrawer();


  Widget navItem(String label, IconData icon, int navIdx, {int? badgeCount}) {
         final selected = _navIndex == navIdx;

  return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
             decoration: BoxDecoration(
               borderRadius: BorderRadius.circular(16),
               gradient: selected
                   ? LinearGradient(
                       colors: [
                         primary.withValues(alpha: 0.2),
                         primary.withValues(alpha: 0.08),
                       ],
                       begin: Alignment.centerLeft,
                       end: Alignment.centerRight,
                     )
                   : null,
               border: selected
                   ? Border.all(color: primary.withValues(alpha: 0.3), width: 1)
                   : null,
               boxShadow: selected
                   ? [
                       BoxShadow(
                           color: primary.withValues(alpha: 0.15),
                           blurRadius: 20,
                           offset: const Offset(0, 4),
                       ),
                     ]
                   : null,
             ),
             child: Material(
               color: Colors.transparent,
               child: InkWell(
                 borderRadius: BorderRadius.circular(16),
                 splashColor: primary.withValues(alpha: 0.1),
                 onTap: () {
                   HapticFeedback.lightImpact();
                   updateState(() => _navIndex = navIdx);
                   Navigator.pop(context);
                 },
                 child: Padding(
                   padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                   child: Row(children: [
                     AnimatedContainer(
                       duration: const Duration(milliseconds: 250),
                       width: 40,
                       height: 40,
                       decoration: BoxDecoration(
                         borderRadius: BorderRadius.circular(12),
                         gradient: selected
                             ? LinearGradient(
                                 colors: [
                                   primary.withValues(alpha: 0.25),
                                   primary.withValues(alpha: 0.1),
                                 ],
                                 begin: Alignment.topLeft,
                                 end: Alignment.bottomRight,
                               )
                             : LinearGradient(
                                 colors: [
                                   tokens.panelElevated,
                                   tokens.panel,
                                 ],
                               ),
                         boxShadow: selected
                             ? [
                                 BoxShadow(
                                     color: primary.withValues(alpha: 0.2),
                                     blurRadius: 12,
                                 ),
                               ]
                             : null,
                       ),
                       child: Icon(icon,
                           color: selected ? primary : tokens.textMuted,
                           size: 20),
                     ),
                     const SizedBox(width: 14),
                     Expanded(
                       child: Text(label,
                           style: GoogleFonts.outfit(
                             color: selected ? colors.onSurface : tokens.textSoft,
                             fontSize: 14.5,
                             fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                             letterSpacing: 0.3,
                           )),
                     ),
                     if (badgeCount != null && badgeCount > 0)
                       Container(
                         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                         decoration: BoxDecoration(
                           borderRadius: BorderRadius.circular(20),
                           gradient: LinearGradient(
                             colors: [
                               primary.withValues(alpha: 0.3),
                               primary.withValues(alpha: 0.15),
                             ],
                           ),
                         ),
                         child: Text('$badgeCount',
                             style: GoogleFonts.outfit(
                                 fontSize: 11,
                                 color: colors.onSurface,
                                 fontWeight: FontWeight.w800)),
                       ),
                   ]),
                 ),
               ),
             ),
           ),
         );
       }

  Widget drawerTile(
      String label, IconData icon, Color color, VoidCallback onTap,
      {String? badge}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          splashColor: color.withValues(alpha: 0.2),
          highlightColor: color.withValues(alpha: 0.1),
          onTap: () {
            Navigator.pop(context);
            onTap();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  tokens.panelElevated.withValues(alpha: 0.8),
                  tokens.panel.withValues(alpha: 0.6)
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(children: [
              // Premium glowing icon with pulse
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.4),
                      color.withValues(alpha: 0.15)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: color.withValues(alpha: 0.25),
                        blurRadius: 12,
                        spreadRadius: -1),
                  ],
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(label,
                    style: GoogleFonts.outfit(
                      color: colors.onSurface.withValues(alpha: 0.95),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    )),
              ),
              if (badge != null)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.2),
                        color.withValues(alpha: 0.1)
                      ],
                    ),
                  ),
                  child: Text(badge,
                      style: GoogleFonts.jetBrainsMono(
                          color: color,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5)),
                ),
              Icon(Icons.arrow_forward_ios_rounded,
                  color: color.withValues(alpha: 0.5), size: 14),
            ]),
          ),
        ),
      ),
    );
  }

Widget hubAccordion(
      String title, IconData icon, Color color, List<Widget> children,
      {String? badge}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            tokens.panel.withValues(alpha: 0.9),
            tokens.panelElevated.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          )
        ],
      ),
      child: Theme(
        data: materialTheme.copyWith(
          dividerColor: Colors.transparent,
          splashColor: color.withValues(alpha: 0.15),
          highlightColor: color.withValues(alpha: 0.08),
        ),
        child: ExpansionTile(
          collapsedIconColor: tokens.textMuted,
          iconColor: color,
          childrenPadding: const EdgeInsets.only(bottom: 8),
          tilePadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          collapsedShape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          leading: Padding(
            padding: const EdgeInsets.all(4),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: color.withValues(alpha: 0.1),
              ),
              child: Icon(icon, color: color, size: 14),
            ),
          ),
          title: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: GoogleFonts.outfit(
                        color: colors.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: LinearGradient(
                        colors: [
                          color.withValues(alpha: 0.3),
                          color.withValues(alpha: 0.1)
                        ],
                      ),
                      border: Border.all(
                        color: color.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: Text(badge,
                        style: GoogleFonts.outfit(
                          fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
          ),
          children: children.map((child) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: DefaultTextStyle(
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: tokens.textSoft,
              ),
              child: child,
            ),
          )).toList(),
        ),
      ),
    );
  }

Widget drawerPulseStat({
     required String label,
     required String value,
     required IconData icon,
     required Color color,
   }) {
     return Expanded(
       child: Container(
         margin: const EdgeInsets.symmetric(horizontal: 3),
         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
         decoration: BoxDecoration(
           borderRadius: BorderRadius.circular(14),
           gradient: LinearGradient(
             colors: [
               color.withValues(alpha: 0.08),
               Colors.white.withValues(alpha: 0.04),
             ],
             begin: Alignment.topLeft,
             end: Alignment.bottomRight,
           ),
           border: Border.all(
             color: color.withValues(alpha: 0.3),
             width: 1.5,
           ),
           boxShadow: [
             BoxShadow(
               color: color.withValues(alpha: 0.15),
               blurRadius: 12,
               offset: const Offset(0, 4),
               spreadRadius: -2,
             )
           ],
         ),
         child: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             Container(
               padding: const EdgeInsets.all(10),
               decoration: BoxDecoration(
                 gradient: LinearGradient(
                   colors: [
                     color.withValues(alpha: 0.3),
                     color.withValues(alpha: 0.15),
                   ],
                 ),
                 borderRadius: BorderRadius.circular(10),
                 boxShadow: [
                   BoxShadow(
                     color: color.withValues(alpha: 0.4),
                     blurRadius: 8,
                     spreadRadius: -1,
                   ),
                 ],
               ),
               child: Icon(icon, color: color, size: 20),
             ),
             const SizedBox(height: 10),
             ShaderMask(
               shaderCallback: (bounds) => LinearGradient(
                 colors: [color, color.withValues(alpha: 0.7)],
               ).createShader(bounds),
               child: Text(
                 value,
                 maxLines: 1,
                 overflow: TextOverflow.ellipsis,
                 style: GoogleFonts.outfit(
                   color: Colors.white,
                   fontSize: 15,
                   fontWeight: FontWeight.w900,
                   letterSpacing: 0.5,
                 ),
               ),
             ),
             const SizedBox(height: 4),
             Text(
               label,
               style: GoogleFonts.outfit(
                 color: Colors.white54,
                 fontSize: 10,
                 fontWeight: FontWeight.w600,
                 letterSpacing: 0.8,
               ),
             ),
           ],
         ),
       ),
);
    }

  // ═══ STAT ITEM ═══
  Widget _statItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: color.withValues(alpha: 0.15),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 6),
        Text(value, style: GoogleFonts.outfit(
          color: colors.onSurface,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        )),
        Text(label, style: GoogleFonts.outfit(
          color: tokens.textMuted,
          fontSize: 10,
        )),
      ],
    );
  }

  // ═══ QUICK TOGGLE ═══
  Widget _quickToggle(IconData icon, String label, bool value, Function(bool) onToggle) {
    return GestureDetector(
      onTap: () => onToggle(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: value ? primary.withValues(alpha: 0.2) : tokens.panel,
          border: Border.all(
            color: value ? primary.withValues(alpha: 0.4) : tokens.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: value ? primary : tokens.textMuted),
            const SizedBox(width: 4),
            Text(label, style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: value ? primary : tokens.textMuted,
            )),
          ],
        ),
      ),
    );
  }

  // ═══ ACTION BUTTON ═══
  Widget _actionBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [
              primary.withValues(alpha: 0.1),
              Colors.transparent,
            ],
          ),
          border: Border.all(
            color: primary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: primary, size: 18),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.outfit(
              color: colors.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            )),
          ],
        ),
      ),
    );
  }

  // ═══ HELPER METHODS FOR CUSTOM FAVORITES ═══
  IconData _getIconFromString(String iconName) {
    final iconMap = {
      'call_rounded': Icons.call_rounded,
      'cloud_queue_rounded': Icons.cloud_queue_rounded,
      'menu_book_rounded': Icons.menu_book_rounded,
      'music_note_rounded': Icons.music_note_rounded,
      'favorite_rounded': Icons.favorite_rounded,
      'quiz_rounded': Icons.quiz_rounded,
      'travel_explore_rounded': Icons.travel_explore_rounded,
      'movie_rounded': Icons.movie_rounded,
      'sports_esports_rounded': Icons.sports_esports_rounded,
      'self_improvement_rounded': Icons.self_improvement_rounded,
      'psychology_rounded': Icons.psychology_rounded,
      'local_hospital_rounded': Icons.local_hospital_rounded,
      'spa_rounded': Icons.spa_rounded,
      'games_rounded': Icons.games_rounded,
      'chat_rounded': Icons.chat_rounded,
      'settings_rounded': Icons.settings_rounded,
      'person_rounded': Icons.person_rounded,
    };
    return iconMap[iconName] ?? Icons.star_rounded;
  }

  void _handleFavoriteAction(String action) {
    switch (action) {
      case 'voice_call':
        Navigator.push(context, MaterialPageRoute(builder: (_) => WaifuVoiceCallScreen(
          waifuImageAsset: _chatImageAsset,
          waifuName: _selectedPersona == 'Default' ? 'Zero Two' : _selectedPersona,
          onMicPressed: () => unawaited(_startContinuousListening()),
        )));
        break;
      case 'cloud_videos':
        updateState(() => _navIndex = 12);
        Navigator.pop(context);
        break;
      case 'manga':
        Navigator.pushNamed(context, '/manga-section');
        break;
      case 'quotes':
        Navigator.pushNamed(context, '/quote-of-day');
        break;
      case 'diary':
        Navigator.pushNamed(context, '/diary');
        break;
      case 'settings':
        updateState(() => _navIndex = 3);
        Navigator.pop(context);
        break;
      case 'themes':
        updateState(() => _navIndex = 4);
        Navigator.pop(context);
        break;
      case 'explore':
        updateState(() => _navIndex = 2);
        Navigator.pop(context);
        break;
      case 'affirmation':
        Navigator.pushNamed(context, '/daily-affirmation');
        break;
      case 'horoscope':
        Navigator.pushNamed(context, '/daily-horoscope');
        break;
      case 'trivia':
        Navigator.pushNamed(context, '/daily-trivia');
        break;
      case 'challenge':
        Navigator.pushNamed(context, '/daily-challenge');
        break;
      default:
        _showSnack('Opening $action...');
    }
  }

  // ═══ CUSTOM FAVORITES ═══
  List<Widget> _buildCustomFavoritesTiles() {
    final tiles = <Widget>[];
    for (var i = 0; i < _customFavorites.length; i++) {
      final fav = _customFavorites[i];
      final name = fav['name'] as String;
      final iconName = fav['icon'] as String;
      final colorVal = int.tryParse(fav['color'] as String? ?? '0xFFFF9800') ?? 0xFFFF9800;
      final color = Color(colorVal);
      final badge = fav['badge'] as String?;
      final action = fav['action'] as String?;
      
      tiles.add(drawerTile(
        name,
        _getIconFromString(iconName),
        color,
        () => _handleFavoriteAction(action ?? ''),
        badge: badge,
      ));
    }
    return tiles;
  }

  Widget _availableFeatureChip(String name, IconData icon, Color color, String action, {bool isAdded = false, String? badge, required void Function() onChanged}) {
    return GestureDetector(
      onTap: () {
        final currentFavs = List<Map<String, dynamic>>.from(_customFavorites);
        if (isAdded) {
          currentFavs.removeWhere((f) => f['action'] == action);
        } else {
          currentFavs.add({
            'name': name,
            'icon': icon.toString().split('.').last,
            'color': color.value.toString(),
            'action': action,
          });
        }
        _sp.setCustomFavorites(currentFavs);
        onChanged();
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: isAdded
              ? LinearGradient(
                  colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          border: Border.all(color: color.withValues(alpha: isAdded ? 0.5 : 0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isAdded ? color : color.withValues(alpha: 0.6), size: 24),
            const SizedBox(height: 4),
            Text(name, style: GoogleFonts.outfit(
              color: isAdded ? colors.onSurface : tokens.textMuted,
              fontSize: 10,
              fontWeight: isAdded ? FontWeight.w600 : FontWeight.w400,
            ), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
            if (isAdded) ...[
              const SizedBox(height: 2),
              Icon(Icons.check_circle, color: color, size: 12),
            ],
          ],
        ),
      ),
    );
  }

  Widget _favoriteItem(String name, String iconName, String colorStr, int index) {
    final colorVal = int.tryParse(colorStr) ?? 0xFFFF9800;
    final color = Color(colorVal);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(_getIconFromString(iconName), color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(name, style: GoogleFonts.outfit(color: colors.onSurface, fontWeight: FontWeight.w500))),
          IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.redAccent.withValues(alpha: 0.7), size: 20),
            onPressed: () => _sp.removeFavorite(index),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  void _showFavoritesCustomizationDialog(BuildContext context) {
    final availableFeatures = [
      {'name': 'Voice Call', 'icon': 'call_rounded', 'color': '0xFF4CAF50', 'action': 'voice_call'},
      {'name': 'Videos', 'icon': 'cloud_queue_rounded', 'color': '0xFF2196F3', 'action': 'cloud_videos'},
      {'name': 'Manga', 'icon': 'menu_book_rounded', 'color': '0xFF9C27B0', 'action': 'manga'},
      {'name': 'Music', 'icon': 'music_note_rounded', 'color': '0xFFE91E63', 'action': 'music'},
      {'name': 'Favorites', 'icon': 'favorite_rounded', 'color': '0xFFFF5722', 'action': 'favorites'},
      {'name': 'Quiz', 'icon': 'quiz_rounded', 'color': '0xFF00BCD4', 'action': 'anime_quiz'},
      {'name': 'Explore', 'icon': 'travel_explore_rounded', 'color': '0xFF8BC34A', 'action': 'explore'},
      {'name': 'Movies', 'icon': 'movie_rounded', 'color': '0xFFFF9800', 'action': 'web_streamers'},
      {'name': 'Games', 'icon': 'sports_esports_rounded', 'color': '0xFF673AB7', 'action': 'games'},
      {'name': 'Meditation', 'icon': 'self_improvement_rounded', 'color': '0xFF009688', 'action': 'meditation'},
      {'name': 'Story', 'icon': 'psychology_rounded', 'color': '0xFFCDDC39', 'action': 'story'},
      {'name': 'Quotes', 'icon': 'format_quote_rounded', 'color': '0xFFFFEB3B', 'action': 'quotes'},
      {'name': 'Diary', 'icon': 'book_rounded', 'color': '0xFFF44336', 'action': 'diary'},
      {'name': 'Settings', 'icon': 'settings_rounded', 'color': '0xFF607D8B', 'action': 'settings'},
      {'name': 'Themes', 'icon': 'palette_rounded', 'color': '0xFFE91E63', 'action': 'themes'},
      {'name': 'Affirmation', 'icon': 'self_improvement_rounded', 'color': '0xFF4CAF50', 'action': 'affirmation'},
      {'name': 'Horoscope', 'icon': 'auto_awesome_rounded', 'color': '0xFF9C27B0', 'action': 'horoscope'},
      {'name': 'Trivia', 'icon': 'quiz_rounded', 'color': '0xFF2196F3', 'action': 'trivia'},
      {'name': 'Challenge', 'icon': 'emoji_events_rounded', 'color': '0xFFFF5722', 'action': 'challenge'},
    ];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: tokens.panel,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: tokens.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text('Customize Favorites', style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  )),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, color: tokens.textMuted),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.1,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: availableFeatures.length,
                itemBuilder: (ctx, i) {
                  final feat = availableFeatures[i];
                  final name = feat['name'] as String;
                  final iconName = feat['icon'] as String;
                  final colorVal = int.tryParse(feat['color'] as String) ?? 0xFFFF9800;
                  final color = Color(colorVal);
                  final action = feat['action'] as String;
                  final isAdded = _customFavorites.any((f) => f['action'] == action);
                  
                  return _availableFeatureChip(name, _getIconFromString(iconName), color, action, isAdded: isAdded, onChanged: _triggerRebuild);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _customizeFavoritesBtn() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showFavoritesCustomizationDialog(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.add_circle_outline, color: primary, size: 18),
                const SizedBox(width: 10),
                Text('Customize Favorites', style: GoogleFonts.outfit(
                  color: primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                )),
                const Spacer(),
                Icon(Icons.edit_rounded, color: primary.withValues(alpha: 0.6), size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget seeAllFeaturesButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () {
          Navigator.pop(context);
          updateState(() => _navIndex = 2);
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                primary.withValues(alpha: 0.18),
                colors.tertiary.withValues(alpha: 0.14),
              ],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.explore_rounded, color: primary, size: 18),
              const SizedBox(width: 8),
              Text('See All Features',
                  style: GoogleFonts.outfit(
                      color: colors.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5)),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward_ios_rounded,
                  color: tokens.textMuted, size: 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
  final screenWidth = MediaQuery.sizeOf(context).width;
  final drawerWidth = (screenWidth * 0.82).clamp(0.0, 320.0);
  return Drawer(
    width: drawerWidth,
    backgroundColor: materialTheme.scaffoldBackgroundColor,
    child: Stack(
      children: [
        // Simple gradient background (no GIF for performance)
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  materialTheme.scaffoldBackgroundColor
                      .withValues(alpha: 0.92)
                ],
              ),
            ),
          ),
        ),
        // ── ULTRA-PREMIUM FULL-BLEED "SEXY" HEADER ───────────────────────
        /* 
           We remove SafeArea from wrapping the entire drawer so the banner 
           can dynamically extend all the way under the status bar, creating
           a stunning, edge-to-edge "sexy" immersive gaming aesthetic.
        */
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 180, // Restored, slightly more compact
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Static cover image to keep drawer motion smooth
                  Image.asset(
                    'assets/gif/sidebar_top.gif',
                    fit: BoxFit.cover,
                    alignment: const Alignment(0, -0.2), // Focus on face/eyes
                  ),

                  // Deep Vignette + Fade to Black (seamless merge)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black
                              .withValues(alpha: 0.2), // Top edge shading
                          Colors.transparent,
                          const Color(0xFF0F1014).withValues(alpha: 0.6),
                          const Color(
                              0xFF0F1014), // Exactly matches drawer BG
                        ],
                        stops: const [0.0, 0.4, 0.8, 1.0],
                      ),
                    ),
                  ),

                  // Top-right dynamic ambient quote
                  // Avatar & Stats directly overlaid on the fade
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Scaled down Avatar
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: primary.withValues(alpha: 0.8),
                                    width: 2),
                                boxShadow: [
                                  BoxShadow(
                                      color: primary.withValues(alpha: 0.6),
                                      blurRadius: 16,
                                      spreadRadius: -2),
                                  BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.8),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4)),
                                ],
                                image: DecorationImage(
                                  image: _imageProviderFor(
                                      assetPath: _appIconImageAsset,
                                      customPath:
                                          _effectiveAppIconCustomPath),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    ShaderMask(
                                      shaderCallback: (bounds) =>
                                          LinearGradient(
                                        colors: [
                                          Colors.white,
                                          Colors.pink.shade200
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ).createShader(bounds),
                                      child: Text('ZERO TWO',
                                          style: GoogleFonts.outfit(
                                              color: Colors.white,
                                              fontSize: 22,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 3)),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.greenAccent,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text('SYSTEM ONLINE',
                                            style: GoogleFonts.jetBrainsMono(
                                                color: Colors.white70,
                                                fontSize: 9,
                                                letterSpacing: 1.5,
                                                fontWeight: FontWeight.w800)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── SCROLLING NAV LIST ─────────────────────────────────────────────
            // ── PINNED XP BAR (Does NOT scroll) ───────────────────────
            AnimatedBuilder(
              animation: AffectionService.instance,
              builder: (context, child) {
                final srv = AffectionService.instance;
                final Color color = srv.levelColor;
                const barColor = Color(0xFFFF2D55);

                int maxPts = 50;
                if (srv.points >= 2500) {
                  maxPts = 9999;
                } else if (srv.points >= 1500) {
                  maxPts = 2500;
                } else if (srv.points >= 900) {
                  maxPts = 1500;
                } else if (srv.points >= 500) {
                  maxPts = 900;
                } else if (srv.points >= 200) {
                  maxPts = 500;
                } else if (srv.points >= 50) {
                  maxPts = 200;
                }

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.12),
                        Colors.white.withValues(alpha: 0.03),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                        color: color.withValues(alpha: 0.2), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                          color: color.withValues(alpha: 0.15),
                          blurRadius: 24,
                          spreadRadius: -2),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.auto_awesome_rounded,
                                  color: color, size: 12),
                              const SizedBox(width: 6),
                              Text(srv.levelName.toUpperCase(),
                                  style: GoogleFonts.outfit(
                                      color: Colors.white
                                          .withValues(alpha: 0.95),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.8)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: color.withValues(alpha: 0.2),
                                  width: 0.5),
                            ),
                            child: Text(
                                '${(srv.levelProgress * 100).toInt()}%',
                                style: GoogleFonts.jetBrainsMono(
                                    color: color,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            height: 6,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.black.withValues(alpha: 0.6),
                              boxShadow: [
                                BoxShadow(
                                    color:
                                        Colors.white.withValues(alpha: 0.02),
                                    offset: const Offset(0, 1)),
                              ],
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: srv.levelProgress,
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                gradient: LinearGradient(
                                  colors: [
                                    barColor.withValues(alpha: 0.6),
                                    barColor
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                      color: barColor.withValues(alpha: 0.5),
                                      blurRadius: 12,
                                      spreadRadius: 1),
                                  BoxShadow(
                                      color: barColor.withValues(alpha: 0.3),
                                      blurRadius: 2,
                                      spreadRadius: -1),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('${srv.points} / $maxPts XP TO NEXT LEVEL',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.jetBrainsMono(
                              color: Colors.white24,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1)),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 10),

            // ── SCROLLING NAV LIST ─────────────────────────────────────────────
            AnimatedBuilder(
              animation: AffectionService.instance,
              builder: (context, child) {
                final srv = AffectionService.instance;
                final mood = srv.levelProgress >= 0.75
                    ? 'achievement'
                    : srv.levelProgress >= 0.35
                        ? 'motivated'
                        : 'neutral';
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: GlassCard(
                    margin: EdgeInsets.zero,
                    padding: const EdgeInsets.all(14),
                    glow: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _AnimatedMissionIcon(primary: primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ShaderMask(
                                    shaderCallback: (bounds) => LinearGradient(
                                      colors: [
                                        primary,
                                        Colors.pinkAccent,
                                      ],
                                    ).createShader(bounds),
                                    child: Text(
                                      'Mission Control',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    mood == 'achievement'
                                        ? 'Zero Two is fully synced with you.'
                                        : mood == 'motivated'
                                            ? 'Momentum is building nicely.'
                                            : 'Everything is calm and ready.',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white60,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            drawerPulseStat(
                              label: 'XP',
                              value: '${srv.points}',
                              icon: Icons.auto_awesome_rounded,
                              color: primary,
                            ),
                            drawerPulseStat(
                              label: 'Bond',
                              value: srv.levelName.split(' ').first,
                              icon: Icons.workspace_premium_rounded,
                              color: Colors.amberAccent,
                            ),
                            drawerPulseStat(
                              label: 'Hubs',
                              value: '4',
                              icon: Icons.hub_rounded,
                              color: Colors.cyanAccent,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    
                    // ═══ COOL HEADER ═══
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          colors: [
                            primary.withValues(alpha: 0.2),
                            primary.withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: primary.withValues(alpha: 0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: LinearGradient(
                                colors: [
                                  primary.withValues(alpha: 0.4),
                                  primary.withValues(alpha: 0.15),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: primary.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.favorite_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'O2-WAIFU',
                                  style: GoogleFonts.outfit(
                                    color: colors.onSurface,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Neural Companion',
                                  style: GoogleFonts.outfit(
                                    color: tokens.textMuted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: primary.withValues(alpha: 0.2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'v2.0',
                  style: GoogleFonts.jetBrainsMono(
                    color: primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () {
                    _sp.liteModeEnabled = !_liteModeEnabled;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_sp.liteModeEnabled ? 'Performance Mode: ON' : 'Performance Mode: OFF'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Icon(
                    _liteModeEnabled ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                    color: _liteModeEnabled ? Colors.amber : tokens.textMuted,
                    size: 14,
                  ),
                ),
              ],
            ),
          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),
                    
                    // ═══ USER STATS ═══
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [
                            tokens.panelElevated.withValues(alpha: 0.8),
                            tokens.panel.withValues(alpha: 0.6),
                          ],
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _statItem(Icons.favorite_rounded, '${AffectionService.instance.affection}', 'Love', Colors.pinkAccent),
                          _statItem(Icons.local_fire_department_rounded, '${AffectionService.instance.streakDays}', 'Streak', Colors.orangeAccent),
                          _statItem(Icons.emoji_events_rounded, '${AffectionService.instance.level}', 'Level', Colors.amberAccent),
                        ],
                      ),
                    ),

                    // ═══ QUICK TOGGLES ═══
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: tokens.panel.withValues(alpha: 0.5),
                      ),
                      child: Row(
                        children: [
                          Expanded(child: _quickToggle(Icons.wb_sunny_rounded, 'Lite', _liteModeEnabled, (v) => _sp.liteModeEnabled = v)),
                          const SizedBox(width: 8),
                          Expanded(child: _quickToggle(Icons.mic_rounded, 'Mic', _wakeWordEnabledByUser, _updateWakeWord)),
                          const SizedBox(width: 8),
                          Expanded(child: _quickToggle(Icons.notifications_rounded, 'Notif', _notificationsAllowed, (v) => _sp.notificationsAllowed = v)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ═══ QUICK ACTIONS ═══
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Expanded(child: _actionBtn(Icons.settings_rounded, 'Settings', () { Navigator.pop(context); updateState(() => _navIndex = 4); })),
                          const SizedBox(width: 8),
                          Expanded(child: _actionBtn(Icons.person_rounded, 'Profile', () { Navigator.pop(context); })),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    _DrawerStaggerItem(
                        index: 0,
                        child: navItem('Chat', Icons.chat_bubble_outline, 0)),
                    const SizedBox(height: 4),
                    _DrawerStaggerItem(
                        index: 1, child: seeAllFeaturesButton()),

                    const SizedBox(height: 12),
                    Divider(
                        color: Colors.white.withValues(alpha: 0.06),
                        height: 1,
                        indent: 20,
                        endIndent: 20),
                    const SizedBox(height: 12),

                    // ═══ FAVORITES (Customizable) ═══
                    _DrawerStaggerItem(
                      index: 2,
                      child: hubAccordion(
                        'Favorites', Icons.star_rounded, Colors.amber,
                        _buildCustomFavoritesTiles() + [
                          _customizeFavoritesBtn(),
                        ],
                      ),
                    ),

                    // ── 💕 DAILY RITUALS ────────────────────────────────────
                    _DrawerStaggerItem(
                        index: 3,
                        child: hubAccordion(
                            'Daily Rituals',
                            Icons.wb_sunny_rounded,
                            Colors.pinkAccent,
                            [
                              drawerTile(
                                  'ZT Diary',
                                  Icons.book_outlined,
                                  Colors.pinkAccent,
                                  () => Navigator.pushNamed(
                                      context, '/zero-two-diary'),
                                  badge: 'Daily'),
                              drawerTile(
                                  'Love Letter',
                                  Icons.mail_outline_rounded,
                                  Colors.pinkAccent,
                                  () => Navigator.pushNamed(
                                      context, '/daily-love-letter')),
                              drawerTile(
                                  'Affirmations',
                                  Icons.self_improvement_outlined,
                                  Colors.purpleAccent,
                                  () => Navigator.pushNamed(
                                      context, '/daily-affirmations')),
                              drawerTile(
                                  'Quote of Day',
                                  Icons.format_quote_outlined,
                                  Colors.cyanAccent,
                                  () => Navigator.pushNamed(
                                      context, '/quote-of-day')),
                              drawerTile(
                                  'Fortune Cookie',
                                  Icons.cookie_outlined,
                                  Colors.amberAccent,
                                  () => Navigator.pushNamed(
                                      context, '/fortune-cookie'),
                                  badge: 'LUCK'),
                              drawerTile(
                                  'Check-In',
                                  Icons.check_circle_outlined,
                                  Colors.greenAccent,
                                  () => Navigator.pushNamed(
                                      context, '/checkin-streak'),
                                  badge: 'FIRE'),
                            ],
                            badge: 'Heart')),

                    // ── 🎮 FUN & GAMES ──────────────────────────────────────
                    _DrawerStaggerItem(
                        index: 4,
                        child: hubAccordion(
                            'Fun & Games',
                            Icons.sports_esports_rounded,
                            Colors.greenAccent,
                            [
                              drawerTile(
                                  'Boss Battles',
                                  Icons.security_rounded,
                                  Colors.redAccent,
                                  () => Navigator.pushNamed(
                                      context, '/boss-battle'),
                                  badge: 'NEW'),
                              drawerTile(
                                  'Anime Wordle',
                                  Icons.grid_view_rounded,
                                  Colors.orangeAccent,
                                  () => Navigator.pushNamed(
                                      context, '/anime-wordle'),
                                  badge: 'NEW'),
                              drawerTile(
                                  'Gacha Cards',
                                  Icons.card_giftcard_rounded,
                                  Colors.purpleAccent,
                                  () => Navigator.pushNamed(
                                      context, '/gacha-collector'),
                                  badge: 'NEW'),
                              drawerTile(
                                  'Mini Games',
                                  Icons.sports_esports_rounded,
                                  Colors.greenAccent,
                                  () => Navigator.pushNamed(
                                      context, '/mini-games'),
                                  badge: '8+'),
                              drawerTile(
                                  'Story Mode',
                                  Icons.book_rounded,
                                  Colors.purpleAccent,
                                  () => Navigator.pushNamed(
                                      context, '/story-mode')),
                              drawerTile(
                                  'AR Companion',
                                  Icons.view_in_ar_rounded,
                                  Colors.pinkAccent,
                                  () => Navigator.pushNamed(
                                      context, '/ar-companion'),
                                  badge: '3D'),
                              drawerTile(
                                  'Virtual Date',
                                  Icons.favorite_outline_rounded,
                                  Colors.redAccent,
                                  () => Navigator.pushNamed(
                                      context, '/virtual-date')),
                              drawerTile(
                                  'Spin Wheel',
                                  Icons.radio_button_checked_outlined,
                                  Colors.amberAccent,
                                  () => Navigator.pushNamed(
                                      context, '/spinner-wheel')),
                            ],
                            badge: 'Play')),

                    // ── 🤖 AI TOOLS ──────────────────────────────────────
                    _DrawerStaggerItem(
                        index: 5,
                        child: hubAccordion(
                            'AI Tools',
                            Icons.auto_awesome_rounded,
                            Colors.purpleAccent,
                            [
                              drawerTile('AI Art', Icons.brush_rounded, Colors.deepPurpleAccent, () => Navigator.pushNamed(context, '/ai-art-generator'), badge: 'NEW'),
                              drawerTile('AI Video', Icons.videocam_rounded, Colors.deepPurple, () => Navigator.pushNamed(context, '/video-gen'), badge: 'NEW'),
                              drawerTile('AI Audio', Icons.music_note_rounded, Colors.purpleAccent, () => Navigator.pushNamed(context, '/audio-gen'), badge: 'NEW'),
                              drawerTile('Writing Helper', Icons.edit_note_rounded, Colors.lightBlueAccent, () => Navigator.pushNamed(context, '/writing-helper')),
                              drawerTile('Translator', Icons.translate_rounded, Colors.tealAccent, () => Navigator.pushNamed(context, '/language-translator')),
                              drawerTile('Recipe AI', Icons.restaurant_menu_rounded, Colors.orangeAccent, () => Navigator.pushNamed(context, '/recipe-recommender')),
                              drawerTile('Life Advice', Icons.psychology_rounded, Colors.pinkAccent, () => Navigator.pushNamed(context, '/life-advice')),
                              drawerTile('Smart Reply', Icons.quickreply_rounded, Colors.cyanAccent, () => Navigator.pushNamed(context, '/smart-reply'), badge: 'AI'),
                              drawerTile('AI Copilot', Icons.assistant_rounded, Colors.amberAccent, () => Navigator.pushNamed(context, '/ai-copilot'), badge: 'GPT'),
                              drawerTile('Future Sim', Icons.timeline_rounded, Colors.purpleAccent, () => Navigator.pushNamed(context, '/future-simulation'), badge: 'SIM'),
                            ],
                            badge: 'AI')),

                    // ── 🎬 ANIME & MEDIA ───────────────────────────────
                    _DrawerStaggerItem(
                        index: 6,
                        child: hubAccordion(
                            'Anime & Media',
                            Icons.movie_filter_rounded,
                            Colors.pinkAccent,
                            [
                              drawerTile('Anime Section', Icons.live_tv_rounded, Colors.pinkAccent, () => Navigator.pushNamed(context, '/anime-section'), badge: 'HOT'),
                              drawerTile('Manga Reader', Icons.menu_book_rounded, const Color(0xFFBB52FF), () => Navigator.pushNamed(context, '/manga-section')),
                              drawerTile('My Watchlist', Icons.favorite_rounded, Colors.redAccent, () => Navigator.pushNamed(context, '/watchlist')),
                              drawerTile('Watch History', Icons.history_rounded, Colors.blueAccent, () => Navigator.pushNamed(context, '/watch-history')),
                              drawerTile('Anime Quiz', Icons.quiz_rounded, Colors.amber, () => Navigator.pushNamed(context, '/anime-quiz'), badge: 'PLAY'),
                              drawerTile('Anime OST', Icons.music_note_rounded, Colors.tealAccent, () => Navigator.pushNamed(context, '/anime-ost')),
                              drawerTile('Web Streamers', Icons.travel_explore_rounded, Colors.lightBlueAccent, () => Navigator.pushNamed(context, '/web-streamers-hub'), badge: '26'),
                              drawerTile('Cloud Videos', Icons.cloud_queue_rounded, Colors.cyanAccent, () => updateState(() => _navIndex = 12), badge: 'HD'),
                            ],
                            badge: 'Watch')),

                    // ── 💪 WELLNESS ─────────────────────────────────────────────
                    _DrawerStaggerItem(
                        index: 7,
                        child: hubAccordion(
                            'Wellness',
                            Icons.favorite_border_rounded,
                            Colors.greenAccent,
                            [
                              drawerTile('Mood Tracker', Icons.mood_rounded, Colors.amberAccent, () => Navigator.pushNamed(context, '/mood-tracking')),
                              drawerTile('Habit Tracker', Icons.track_changes_rounded, Colors.greenAccent, () => Navigator.pushNamed(context, '/habit-tracker'), badge: 'STREAK'),
                              drawerTile('Meditation', Icons.self_improvement_rounded, Colors.purpleAccent, () => Navigator.pushNamed(context, '/guided-meditation')),
                              drawerTile('Pomodoro', Icons.timer_rounded, Colors.redAccent, () => Navigator.pushNamed(context, '/pomodoro'), badge: 'FOCUS'),
                              drawerTile('Sleep Tracker', Icons.bedtime_rounded, Colors.indigoAccent, () => Navigator.pushNamed(context, '/sleep-tracking')),
                              drawerTile('Stress Check', Icons.monitor_heart_rounded, Colors.orangeAccent, () => Navigator.pushNamed(context, '/stress-detection')),
                              drawerTile('Goal Tracker', Icons.flag_rounded, Colors.tealAccent, () => Navigator.pushNamed(context, '/goal-tracker')),
                            ],
                            badge: 'Health')),

                    // ── 🧠 MEMORY & AI ─────────────────────────────────────────
                    _DrawerStaggerItem(
                        index: 8,
                        child: hubAccordion(
                            'Memory & AI',
                            Icons.psychology_alt_rounded,
                            Colors.cyanAccent,
                            [
                              drawerTile('Memory Vault', Icons.lock_rounded, Colors.cyanAccent, () => Navigator.pushNamed(context, '/memory-vault'), badge: 'VAULT'),
                              drawerTile('Dream Journal', Icons.nights_stay_rounded, Colors.indigoAccent, () => Navigator.pushNamed(context, '/enhanced-dream-journal')),
                              drawerTile('Emotion Timeline', Icons.timeline_rounded, Colors.pinkAccent, () => Navigator.pushNamed(context, '/emotion-memory-timeline')),
                              drawerTile('Relationship Map', Icons.favorite_rounded, Colors.redAccent, () => Navigator.pushNamed(context, '/relationship-heatmap')),
                              drawerTile('Semantic Memory', Icons.hub_rounded, Colors.purpleAccent, () => Navigator.pushNamed(context, '/semantic-memory')),
                              drawerTile('Personality', Icons.person_pin_rounded, Colors.amberAccent, () => Navigator.pushNamed(context, '/personality-evolution')),
                              drawerTile('Self Reflection', Icons.visibility_rounded, Colors.tealAccent, () => Navigator.pushNamed(context, '/self-reflection')),
                            ],
                            badge: 'Mind')),

                    // ── 🛠️ UTILITIES ───────────────────────────────────────────
                    _DrawerStaggerItem(
                        index: 9,
                        child: hubAccordion(
                            'Utilities',
                            Icons.build_rounded,
                            Colors.blueAccent,
                            [
                              drawerTile('QR Scanner', Icons.qr_code_scanner_rounded, Colors.greenAccent, () => Navigator.pushNamed(context, '/qr-scanner')),
                              drawerTile('Password Gen', Icons.password_rounded, Colors.redAccent, () => Navigator.pushNamed(context, '/password-generator'), badge: 'SAFE'),
                              drawerTile('Bill Splitter', Icons.calculate_rounded, Colors.amberAccent, () => Navigator.pushNamed(context, '/bill-splitter')),
                              drawerTile('Countdown', Icons.hourglass_bottom_rounded, Colors.cyanAccent, () => Navigator.pushNamed(context, '/countdown-timer')),
                              drawerTile('Thought Capture', Icons.lightbulb_rounded, Colors.yellowAccent, () => Navigator.pushNamed(context, '/thought-capture')),
                              drawerTile('Secret Notes', Icons.note_alt_rounded, Colors.purpleAccent, () => Navigator.pushNamed(context, '/secret-notes'), badge: 'LOCK'),
                              drawerTile('Pinned Msgs', Icons.push_pin_rounded, Colors.orangeAccent, () => Navigator.pushNamed(context, '/pinned-messages')),
                              drawerTile('Chat Export', Icons.ios_share_rounded, Colors.blueAccent, () => Navigator.pushNamed(context, '/chat-export')),
                            ],
                            badge: 'Tools')),

                    // ── ⚙️ SETTINGS ─────────────────────────────────────────
                    _DrawerStaggerItem(
                        index: 15,
                        child: hubAccordion(
                            'Settings',
                            Icons.settings_rounded,
                            Colors.blueGrey,
                            [
                              drawerTile(
                                  'App Settings',
                                  Icons.settings_rounded,
                                  Colors.white70,
                                  () => updateState(() => _navIndex = 3)),
                              drawerTile(
                                  'Themes',
                                  Icons.palette_rounded,
                                  Colors.pinkAccent,
                                  () => updateState(() => _navIndex = 4)),
                              drawerTile(
                                  'Geofence Settings',
                                  Icons.map_rounded,
                                  Colors.tealAccent,
                                  () => Navigator.pushNamed(
                                      context, '/geofencing-settings'),
                                  badge: 'GPS'),
                              drawerTile(
                                  'My Profile',
                                  Icons.person_rounded,
                                  Colors.blueAccent,
                                  () => Navigator.pushNamed(
                                      context, '/profile')),
                              drawerTile(
                                  'Achievements',
                                  Icons.emoji_events_rounded,
                                  Colors.amberAccent,
                                  () => Navigator.pushNamed(
                                      context, '/achievements')),
                              drawerTile(
                                  'App Icons',
                                  Icons.app_shortcut_rounded,
                                  Colors.deepPurpleAccent,
                                  () => Navigator.pushNamed(
                                      context, '/app-icon-picker'),
                                  badge: 'ART'),
                              drawerTile(
                                  'Dev Config',
                                  Icons.terminal_rounded,
                                  Colors.greenAccent,
                                  () => updateState(() => _navIndex = 5)),
                              drawerTile(
                                  'Debug Panel',
                                  Icons.bug_report_rounded,
                                  Colors.orangeAccent,
                                  () => updateState(() => _navIndex = 6),
                                  badge: 'DEV'),
                              drawerTile(
                                  'About App',
                                  Icons.info_outline_rounded,
                                  Colors.grey,
                                  () => updateState(() => _navIndex = 7)),
                            ],
                            badge: 'Config')),

                    // ── SEE ALL FEATURES BUTTON ─────────────────────────────
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            // ── STATIC BOTTOM STATUS STRIP (always visible) ──────────
            const _DrawerStatusFooter(),
            const SizedBox(height: 16),
          ],
        ),
        // Stack children end
      ],
    ),
  );
  }


}

// ── CUSTOM ANIMATION WIDGETS ─────────────────────────────────────────────────

/// Staggered slide+fade entrance for drawer items.
class _DrawerStaggerItem extends StatefulWidget {
  final int index;
  final Widget child;
  const _DrawerStaggerItem({required this.index, required this.child});
  @override
  State<_DrawerStaggerItem> createState() => _DrawerStaggerItemState();
}

class _DrawerStaggerItemState extends State<_DrawerStaggerItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Stagger the animation based on widget.index
    final delay = widget.index * 0.08; // 80ms between each item
    _controller.value = math.min(1.0, delay);
    
    _slideAnimation = Tween<double>(begin: 0.1, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(delay, delay + 0.3, curve: Curves.easeOutCubic),
      ),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(delay, delay + 0.4, curve: Curves.easeOut),
      ),
    );
    
    // Start the animation
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value * 20),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Animated bottom footer shown at the bottom of the drawer.
class _DrawerStatusFooter extends StatefulWidget {
  const _DrawerStatusFooter();
  @override
  State<_DrawerStatusFooter> createState() => _DrawerStatusFooterState();
}

class _DrawerStatusFooterState extends State<_DrawerStatusFooter>
    with SingleTickerProviderStateMixin {
  late AnimationController _glow;
  @override
  void initState() {
    super.initState();
    _glow = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glow,
      builder: (_, __) {
        final t = _glow.value;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: const Color(0xFFFF4FA8).withValues(alpha: 0.2)),
            gradient: LinearGradient(
              colors: [
                const Color(0xFFFF4FA8).withValues(alpha: 0.06 + 0.03 * t),
                const Color(0xFF9B59B6).withValues(alpha: 0.04),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color:
                    const Color(0xFFFF4FA8).withValues(alpha: 0.08 + 0.06 * t),
                blurRadius: 20,
              ),
            ],
          ),
          child: Row(
            children: [
              // Pulsing status dot
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.greenAccent,
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.greenAccent.withValues(alpha: 0.3 + 0.5 * t),
                      blurRadius: 8,
                    )
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CORE ONLINE',
                        style: GoogleFonts.jetBrainsMono(
                            color: Colors.greenAccent.withValues(alpha: 0.8),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2)),
                    Text('ZERO TWO  002',
                        style: GoogleFonts.jetBrainsMono(
                            color: Colors.white30,
                            fontSize: 8,
                            letterSpacing: 1.5)),
                  ],
                ),
              ),
              Text('❤️ MY DARLING',
                  style: GoogleFonts.outfit(
                      color: const Color(0xFFFF4FA8)
                          .withValues(alpha: 0.6 + 0.3 * t),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1)),
            ],
          ),
        );
      },
    );
  }
}

class _AnimatedMissionIcon extends StatefulWidget {
  final Color primary;
  const _AnimatedMissionIcon({required this.primary});

  @override
  State<_AnimatedMissionIcon> createState() => _AnimatedMissionIconState();
}

class _AnimatedMissionIconState extends State<_AnimatedMissionIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _rotation;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _rotation = Tween<double>(begin: 0, end: 1).animate(_ctrl);
    _pulse = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulse.value,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                colors: [
                  widget.primary,
                  Colors.pinkAccent,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.primary.withValues(alpha: 0.5),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: RotationTransition(
              turns: _rotation,
              child: const Icon(
                Icons.dashboard_customize_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        );
      },
    );
  }
}

class BreathingPulse extends StatefulWidget {
  final Color color;
  final double size;
  const BreathingPulse({super.key, required this.color, this.size = 8.0});

  @override
  State<BreathingPulse> createState() => _BreathingPulseState();
}

class _BreathingPulseState extends State<BreathingPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color,
          boxShadow: [BoxShadow(color: widget.color, blurRadius: widget.size)],
        ),
      ),
    );
  }
}

class _XPShimmerOverlay extends StatefulWidget {
  const _XPShimmerOverlay();
  @override
  State<_XPShimmerOverlay> createState() => _XPShimmerOverlayState();
}

class _XPShimmerOverlayState extends State<_XPShimmerOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return FractionalTranslation(
          translation: Offset(_ctrl.value * 2 - 1, 0),
          child: Container(
            width: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0),
                  Colors.white.withValues(alpha: 0.3),
                  Colors.white.withValues(alpha: 0)
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        );
      },
    );
  }
}
