import '../../models/anime_models.dart';
import 'anime_provider.dart';
import 'gogoanime_provider.dart';

/// A specialized fallback provider that utilizes GogoAnime's enormous uncensored
/// Japanese Hentai catalog to guarantee adult video delivery when primary adult 
/// APIs (like Hanime) are blocked by regional ISPs (e.g. in India).
class HentaiFallbackProvider implements AnimeProvider {
  final GogoAnimeProvider _gogo = GogoAnimeProvider();

  @override
  String get name => 'Hentai (Geo-Bypass)';

  @override
  Future<List<AnimeItem>> searchAnime(String title, {int limit = 24}) {
    // Force the search query to only pull from the hentai/adult catalog
    return _gogo.searchAnime('\$title hentai', limit: limit);
  }

  @override
  Future<List<AnimeItem>> getTrending({int limit = 24}) {
    // GogoAnime's search with 'hentai' returns highly rated adult OVAs
    return _gogo.searchAnime('hentai', limit: limit);
  }

  @override
  Future<List<AnimeItem>> getPopular({int limit = 24}) {
    return _gogo.searchAnime('uncensored', limit: limit);
  }

  @override
  Future<List<AnimeEpisode>> getEpisodes(String animeId) {
    return _gogo.getEpisodes(animeId);
  }

  @override
  Future<List<AnimeVideoSource>> getVideoSources(String episodeId) {
    return _gogo.getVideoSources(episodeId);
  }
}
