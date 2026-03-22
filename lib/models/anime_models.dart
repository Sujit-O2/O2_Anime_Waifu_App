/// Core data models for the Anime Streaming Engine.

class AnimeItem {
  final String id;       // MAL ID or provider-specific ID
  final String title;
  final String description;
  final String coverUrl;
  final String status;   // 'Airing', 'Finished Airing', etc.
  final int totalEpisodes;
  final double score;
  final List<String> genres;

  const AnimeItem({
    required this.id,
    required this.title,
    this.description = '',
    this.coverUrl = '',
    this.status = 'Unknown',
    this.totalEpisodes = 0,
    this.score = 0.0,
    this.genres = const [],
  });
}

class AnimeEpisode {
  final String id;       // Episode identifier (for fetching sources)
  final int number;
  final String title;
  final bool isFiller;

  const AnimeEpisode({
    required this.id,
    required this.number,
    this.title = '',
    this.isFiller = false,
  });
}

class AnimeVideoSource {
  final String url;
  final String quality;  // '1080p', '720p', 'default', etc.
  final bool isM3U8;
  final Map<String, String>? headers;

  const AnimeVideoSource({
    required this.url,
    this.quality = 'default',
    this.isM3U8 = true,
    this.headers,
  });
}
