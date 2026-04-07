import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'hianime_webview_page.dart';

class WebStreamersHubPage extends StatelessWidget {
  const WebStreamersHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> animeStreamers = [
      {'name': 'HiAnime', 'source': AnimeWebSource.hianime, 'color': Colors.pinkAccent, 'desc': 'The #1 most popular streaming site.'},
      {'name': 'AnimePahe', 'source': AnimeWebSource.animepahe, 'color': Colors.lightBlueAccent, 'desc': 'Lightning fast, highly compressed.'},
      {'name': '9AnimeTV', 'source': AnimeWebSource.nineAnime, 'color': Colors.purpleAccent, 'desc': 'Classic high-quality anime library.'},
      {'name': 'AniWatchTV', 'source': AnimeWebSource.aniWatch, 'color': Colors.orangeAccent, 'desc': 'Modern interface and fast streaming.'},
      {'name': 'AniKai', 'source': AnimeWebSource.aniKai, 'color': Colors.tealAccent, 'desc': 'Clean and smooth experience.'},
      {'name': 'AniZone', 'source': AnimeWebSource.aniZone, 'color': Colors.cyanAccent, 'desc': 'Great for subbed & dubbed.'},
      {'name': 'AniWorld', 'source': AnimeWebSource.aniWorld, 'color': Colors.redAccent, 'desc': 'Massive European anime catalog.'},
      {'name': 'KickAssAnime', 'source': AnimeWebSource.kickAssAnime, 'color': Colors.greenAccent, 'desc': 'Legendary ad-free backup server.'},

      {'name': 'GogoAnime', 'source': AnimeWebSource.gogoAnime, 'color': Colors.yellowAccent, 'desc': 'The legendary open-source anime vault.'},
      {'name': 'ZoroTV', 'source': AnimeWebSource.zoroTv, 'color': Colors.green, 'desc': 'Zero ads, perfect quality.'},
      {'name': 'YugenAnime', 'source': AnimeWebSource.yugenAnime, 'color': Colors.brown, 'desc': 'Aesthetically pleasing clean UI.'},
      {'name': 'AnimeSuge', 'source': AnimeWebSource.animeSuge, 'color': Colors.blueAccent, 'desc': 'Massive sub/dub multi-server network.'},
      {'name': 'Kaido.to', 'source': AnimeWebSource.kaido, 'color': Colors.cyan, 'desc': 'Premium ad-free clone repository.'},
      {'name': 'Anix', 'source': AnimeWebSource.anix, 'color': Colors.deepPurpleAccent, 'desc': 'Fast loading, premium servers.'},
      {'name': 'AnimeFlix', 'source': AnimeWebSource.animeFlix, 'color': Colors.red, 'desc': 'Netflix style beautiful UI.'},
      {'name': 'Marin.moe', 'source': AnimeWebSource.marin, 'color': Colors.pink, 'desc': 'Highest quality raw encodes.'},
      {'name': 'Crunchyroll', 'source': AnimeWebSource.crunchyroll, 'color': Colors.orange, 'desc': 'Official web client wrapper.'},
      {'name': 'WCOstream', 'source': AnimeWebSource.wcostream, 'color': Colors.lightGreenAccent, 'desc': 'The ultimate western cartoon & dub site.'},
    ];

    final List<Map<String, dynamic>> hentaiStreamers = [
      {'name': 'Hanime.tv', 'source': AnimeWebSource.hanime, 'color': Colors.pinkAccent, 'desc': 'The highest quality adult database.'},
      {'name': 'HentaiHaven', 'source': AnimeWebSource.hentaiHaven, 'color': Colors.deepOrangeAccent, 'desc': 'The legend returns. Ad-Free.'},
      {'name': 'nHentai', 'source': AnimeWebSource.nhentai, 'color': Colors.redAccent, 'desc': 'Read premium doujins safely.'},
      {'name': 'Rule34Video', 'source': AnimeWebSource.rule34video, 'color': Colors.greenAccent, 'desc': 'Limitless animated archives.'},
      {'name': 'HentaiFox', 'source': AnimeWebSource.hentaiFox, 'color': Colors.orangeAccent, 'desc': 'Smooth and fast adult UI.'},
      {'name': 'HentaiMama', 'source': AnimeWebSource.hentaiMama, 'color': Colors.purpleAccent, 'desc': 'Massive library of high-res adult content.'},
      {'name': 'AnimeIdHentai', 'source': AnimeWebSource.animeIdHentai, 'color': Colors.blueAccent, 'desc': 'Premium quality Spanish/English subs.'},
      {'name': 'HentaiWorld', 'source': AnimeWebSource.hentaiWorld, 'color': Colors.indigoAccent, 'desc': 'The ultimate global adult portal.'},
    ];

    Widget buildGrid(List<Map<String, dynamic>> streamers) {
      return GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        physics: const NeverScrollableScrollPhysics(), // Let the outer ListView scroll
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: streamers.length,
        itemBuilder: (context, index) {
          final streamer = streamers[index];
          final Color c = streamer['color'];
          
          return GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => HiAnimeWebviewPage(source: streamer['source']),
              ));
            },
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF151515),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: c.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: c.withValues(alpha: 0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -20, top: -20,
                    child: Icon(Icons.play_circle_filled, size: 100, color: c.withValues(alpha: 0.05)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: c.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.travel_explore, color: c, size: 28),
                        ),
                        const Spacer(),
                        Text(
                          streamer['name'],
                          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          streamer['desc'],
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text('LAUNCH', style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_forward_ios, size: 10, color: c),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Web Streamers Hub',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.indigo.shade900, Colors.purple.shade900]),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield, color: Colors.greenAccent, size: 36),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('100% Ad-Free Browsing', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text('Select any streaming site below. Our built-in mini-browser will aggressively block all their intrusive ads and popups automatically.', style: TextStyle(color: Colors.grey.shade300, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 20, top: 8, bottom: 8),
                    child: Text('ANIME SITES (18)', style: GoogleFonts.outfit(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.5)),
                  ),
                  buildGrid(animeStreamers),
                  
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.only(left: 20, top: 8, bottom: 8),
                    child: Text('ADULT SITES (8)', style: GoogleFonts.outfit(color: Colors.pinkAccent, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.5)),
                  ),
                  buildGrid(hentaiStreamers),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
