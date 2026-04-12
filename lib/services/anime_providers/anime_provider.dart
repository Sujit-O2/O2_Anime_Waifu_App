import '../../models/anime_models.dart';

/// Base protocol for all Anime streaming providers.
abstract class AnimeProvider {
  String get name;

  /// Search for anime by title
  Future<List<AnimeItem>> searchAnime(String title, {int limit = 24});

  /// Get currently airing/trending anime
  Future<List<AnimeItem>> getTrending({int limit = 24});

  /// Get most popular anime of all time
  Future<List<AnimeItem>> getPopular({int limit = 24});

  /// Get episode list for an anime
  Future<List<AnimeEpisode>> getEpisodes(String animeId);

  /// Get M3U8/MP4 streaming video sources for an episode
  Future<List<AnimeVideoSource>> getVideoSources(String episodeId);
}


