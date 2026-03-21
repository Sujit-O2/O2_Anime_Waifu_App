import '../models/anime_models.dart';
import 'anime_providers/anime_provider.dart';
import 'anime_providers/amvstrm_provider.dart';
import 'anime_providers/anilist_provider.dart';

/// Anime source enum — only REAL working sources.
/// HiAnime: sub/dub anime via aniwatch-api (VERIFIED working, actively maintained)
// --- Global Enum for Active Sources ---
enum AnimeSource {
  amvstrm,    // Uses api.amvstr.me (GogoAnime scraper)
  anilist,    // Consumet AniList (meta)
  jikanPopular
}

/// Central router for the Anime Streaming Engine.
class AnimeService {
  static AnimeSource _currentSource = AnimeSource.anilist;

  static final AmvstrmProvider _amvstrm = AmvstrmProvider();
  static final AniListProvider _anilist = AniListProvider();

  static final Map<AnimeSource, AnimeProvider> _providers = {
    AnimeSource.amvstrm: _amvstrm,
    AnimeSource.anilist: _anilist,
    AnimeSource.jikanPopular: _amvstrm,  // Same provider, different sort
  };

  static AnimeSource get currentSource => _currentSource;
  static set currentSource(AnimeSource s) => _currentSource = s;
  static AnimeProvider get _provider => _providers[_currentSource]!;
  static String get sourceName => _provider.name;

  /// Get display name for each source
  static String sourceDisplayName(AnimeSource s) {
    switch (s) {
      case AnimeSource.amvstrm: return '🚀 Amvstrm';
      case AnimeSource.anilist: return '📚 AniList';
      case AnimeSource.jikanPopular: return '⭐ Top Rated';
    }
  }

  // ──── Forwarded API ────

  static Future<List<AnimeItem>> searchAnime(String title,
      {int limit = 24}) => _provider.searchAnime(title, limit: limit);

  static Future<List<AnimeItem>> getTrending({int limit = 24}) async {
    return _provider.getTrending(limit: limit);
  }

  static Future<List<AnimeItem>> getPopular({int limit = 24}) =>
      _provider.getPopular(limit: limit);

  static Future<List<AnimeEpisode>> getEpisodes(String animeId) =>
      _provider.getEpisodes(animeId);

  static Future<List<AnimeVideoSource>> getVideoSources(String episodeId) =>
      _provider.getVideoSources(episodeId);

  /// Get video sources for a specific sub/dub type.
  static Future<List<AnimeVideoSource>> getVideoSourcesForType(
      String episodeId, String type) async {
    // HiAnime handles sub/dub internally
    return _provider.getVideoSources(episodeId);
  }

  // legacy compatibility
  static Future<String> getGogoSlug(String animeTitle) async {
    return '';
  }

  // legacy compatibility
  static Future<String> getGogoSlugForType(String animeTitle, String type) async {
    return '';
  }

  // legacy compatibility
  static Future<List<AnimeEpisode>> getGogoEpisodes(String sourceUrl) async {
    return [];
  }
}
