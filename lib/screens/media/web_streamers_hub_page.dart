import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'hianime_webview_page.dart';

class WebStreamersHubPage extends StatefulWidget {
  const WebStreamersHubPage({super.key});

  @override
  State<WebStreamersHubPage> createState() => _WebStreamersHubPageState();
}

class _WebStreamersHubPageState extends State<WebStreamersHubPage> {
  static const String _queryKey = 'web_streamers_query_v2';
  static const String _filterKey = 'web_streamers_filter_v2';

  String _query = '';
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _restoreState();
  }

  Future<void> _restoreState() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }
    if (!mounted) return;
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

  List<_StreamerSite> get _visibleSites {
    final query = _query.trim().toLowerCase();
    return _sites.where((site) {
      final filterMatches = _filter == 'All' || site.group == _filter;
      final queryMatches = query.isEmpty ||
          site.name.toLowerCase().contains(query) ||
          site.description.toLowerCase().contains(query);
      return filterMatches && queryMatches;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleSites;

    return Scaffold(
      backgroundColor: V2Theme.surfaceDark,
      body: WaifuBackground(
        opacity: 0.08,
        tint: V2Theme.surfaceDark,
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _restoreState,
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
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: Colors.white60,
                                  size: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    'Web Streamers Hub',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    'Launch a site inside the app browser with the clean ad-block shell.',
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
                        const SizedBox(height: 14),
                        GlassCard(
                          margin: EdgeInsets.zero,
                          glow: true,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  gradient: V2Theme.accentGradient,
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: const Icon(
                                  Icons.travel_explore_rounded,
                                  color: Colors.white,
                                  size: 34,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      'Streaming shortcuts',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Pick a source, browse inside the in-app shell, and keep the navigation consistent.',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white70,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        const SizedBox(height: 12),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: StatCard(
                                title: 'All Sources',
                                value: '${_sites.length}',
                                icon: Icons.hub_rounded,
                                color: V2Theme.primaryColor,
                              ),
                            ),
                            Expanded(
                              child: StatCard(
                                title: 'Anime',
                                value:
                                    '${_sites.where((site) => site.group == 'Anime').length}',
                                icon: Icons.movie_filter_rounded,
                                color: V2Theme.secondaryColor,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: StatCard(
                                title: 'Adult',
                                value:
                                    '${_sites.where((site) => site.group == 'Adult').length}',
                                icon: Icons.lock_rounded,
                                color: Colors.orangeAccent,
                              ),
                            ),
                            Expanded(
                              child: StatCard(
                                title: 'Visible',
                                value: '${visible.length}',
                                icon: Icons.visibility_rounded,
                                color: Colors.lightGreenAccent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        V2SearchBar(
                          hintText: 'Search streamer name or description...',
                          onChanged: (value) {
                            if (!mounted) return;
                            setState(() => _query = value);
                            _persistState();
                          },
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: const <String>['All', 'Anime', 'Adult']
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
                      icon: Icons.stream_outlined,
                      title: 'No streamers matched',
                      subtitle:
                          'Try another search or switch the filter to see more sources.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final site = visible[index];
                          return AnimatedEntry(
                            index: index,
                            child: GlassCard(
                              margin: EdgeInsets.zero,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => HiAnimeWebviewPage(
                                      source: site.source,
                                    ),
                                  ),
                                );
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: site.color.withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(
                                      Icons.play_circle_fill_rounded,
                                      color: site.color,
                                      size: 28,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    site.name,
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    site.description,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: site.color.withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      site.group,
                                      style: GoogleFonts.outfit(
                                        color: site.color,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
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
                        childAspectRatio: 0.88,
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

class _StreamerSite {
  const _StreamerSite({
    required this.name,
    required this.source,
    required this.color,
    required this.description,
    required this.group,
  });

  final String name;
  final AnimeWebSource source;
  final Color color;
  final String description;
  final String group;
}

const List<_StreamerSite> _sites = <_StreamerSite>[
  _StreamerSite(
    name: 'AnimoTV Slash',
    source: AnimeWebSource.animotvslash,
    color: Color(0xFF00E5FF),
    description: 'Fast, clean anime streaming. Sub & dub with a modern interface.',
    group: 'Anime',
  ),
  _StreamerSite(
    name: 'AnimePahe',
    source: AnimeWebSource.animepahe,
    color: Colors.lightBlueAccent,
    description: 'Compressed streams with a fast browsing flow.',
    group: 'Anime',
  ),
  _StreamerSite(
    name: '9AnimeTV',
    source: AnimeWebSource.nineAnime,
    color: Colors.purpleAccent,
    description: 'Classic catalog with a familiar series search flow.',
    group: 'Anime',
  ),
  _StreamerSite(
    name: 'AniWatchTV',
    source: AnimeWebSource.aniWatch,
    color: Colors.orangeAccent,
    description: 'Modern interface and quick streaming handoff.',
    group: 'Anime',
  ),
  _StreamerSite(
    name: 'AniKai',
    source: AnimeWebSource.aniKai,
    color: Colors.tealAccent,
    description: 'Clean browsing experience for anime searches.',
    group: 'Anime',
  ),
  _StreamerSite(
    name: 'AniZone',
    source: AnimeWebSource.aniZone,
    color: Colors.cyanAccent,
    description: 'Sub and dub discovery with simple navigation.',
    group: 'Anime',
  ),
  _StreamerSite(
    name: 'AniWorld',
    source: AnimeWebSource.aniWorld,
    color: Colors.redAccent,
    description: 'Large regional catalog with browser access.',
    group: 'Anime',
  ),
  _StreamerSite(
    name: 'KickAssAnime',
    source: AnimeWebSource.kickAssAnime,
    color: Colors.greenAccent,
    description: 'Alternative anime source with a backup-friendly flow.',
    group: 'Anime',
  ),
  _StreamerSite(
    name: 'GogoAnime',
    source: AnimeWebSource.gogoAnime,
    color: Colors.yellowAccent,
    description: 'Long-running anime index for manual browsing.',
    group: 'Anime',
  ),
  _StreamerSite(
    name: 'ZoroTV',
    source: AnimeWebSource.zoroTv,
    color: Colors.green,
    description: 'Anime library with search-forward discovery.',
    group: 'Anime',
  ),
  _StreamerSite(
    name: 'AnimeSuge',
    source: AnimeWebSource.animeSuge,
    color: Colors.blueAccent,
    description: 'Broad anime source with multi-server routing.',
    group: 'Anime',
  ),
  _StreamerSite(
    name: 'Crunchyroll',
    source: AnimeWebSource.crunchyroll,
    color: Colors.orange,
    description: 'Official web client wrapper inside the app shell.',
    group: 'Anime',
  ),
  _StreamerSite(
    name: 'Hanime',
    source: AnimeWebSource.hanime,
    color: Colors.pinkAccent,
    description: 'Adult browser shortcut inside the same shell.',
    group: 'Adult',
  ),
  _StreamerSite(
    name: 'HentaiHaven',
    source: AnimeWebSource.hentaiHaven,
    color: Colors.deepOrangeAccent,
    description: 'Adult source with search access through the web shell.',
    group: 'Adult',
  ),
  _StreamerSite(
    name: 'nHentai',
    source: AnimeWebSource.nhentai,
    color: Colors.redAccent,
    description: 'Direct adult search source inside the browser view.',
    group: 'Adult',
  ),
  _StreamerSite(
    name: 'Rule34Video',
    source: AnimeWebSource.rule34video,
    color: Colors.greenAccent,
    description: 'Animated adult catalog wrapper.',
    group: 'Adult',
  ),
  _StreamerSite(
    name: 'HentaiFox',
    source: AnimeWebSource.hentaiFox,
    color: Colors.orangeAccent,
    description: 'Adult search endpoint with in-app navigation.',
    group: 'Adult',
  ),
  _StreamerSite(
    name: 'HentaiWorld',
    source: AnimeWebSource.hentaiWorld,
    color: Colors.indigoAccent,
    description: 'Another adult source option inside the web shell.',
    group: 'Adult',
  ),
];



