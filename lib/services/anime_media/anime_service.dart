import 'package:anime_waifu/models/anime_models.dart';
import 'package:anime_waifu/services/anime_providers/amvstrm_provider.dart';
import 'package:anime_waifu/services/anime_providers/anilist_provider.dart';
import 'package:anime_waifu/services/anime_providers/anime_provider.dart';
import 'package:anime_waifu/services/anime_providers/hianime_provider.dart';

enum AnimeSource { amvstrm, anilist, jikanPopular }

class AnimeService {
  static AnimeSource currentSource = AnimeSource.anilist;

  static final AmvstrmProvider _amvstrm = AmvstrmProvider();
  static final AniListProvider _anilist = AniListProvider();
  static final HiAnimeProvider _legacyStreamProvider = HiAnimeProvider();

  static final Map<AnimeSource, AnimeProvider> _providers = {
    AnimeSource.amvstrm: _amvstrm,
    AnimeSource.anilist: _anilist,
    AnimeSource.jikanPopular: _amvstrm,
  };

  static AnimeProvider get _provider => _providers[currentSource]!;
  static String get sourceName => _provider.name;

  static String sourceDisplayName(AnimeSource source) {
    switch (source) {
      case AnimeSource.amvstrm:
        return 'Stream Auto';
      case AnimeSource.anilist:
        return 'AniList';
      case AnimeSource.jikanPopular:
        return 'Top Rated';
    }
  }

  static Future<List<AnimeItem>> searchAnime(String title, {int limit = 24}) {
    return _provider.searchAnime(title, limit: limit);
  }

  static Future<List<AnimeItem>> getTrending({int limit = 24}) {
    return _provider.getTrending(limit: limit);
  }

  static Future<List<AnimeItem>> getPopular({int limit = 24}) {
    return _provider.getPopular(limit: limit);
  }

  static Future<List<AnimeEpisode>> getEpisodes(String animeId) {
    return _provider.getEpisodes(animeId);
  }

  static Future<List<AnimeVideoSource>> getVideoSources(String episodeId) {
    return _provider.getVideoSources(episodeId);
  }

  static Future<List<AnimeVideoSource>> getVideoSourcesForType(
    String episodeId,
    String type,
  ) async {
    if (currentSource == AnimeSource.anilist) {
      return _anilist.getVideoSourcesForType(episodeId, type);
    }

    final direct = await _legacyStreamProvider.getVideoSourcesForType(
      episodeId,
      type: type,
    );
    if (direct.isNotEmpty) {
      return direct;
    }

    return _provider.getVideoSources(episodeId);
  }

  static Future<String> getGogoSlug(String animeTitle) async {
    return await _legacyStreamProvider.searchHiAnimeId(animeTitle) ?? '';
  }

  static Future<String> getGogoSlugForType(
    String animeTitle,
    String type,
  ) async {
    return getGogoSlug(animeTitle);
  }

  static Future<List<AnimeEpisode>> getGogoEpisodes(String sourceUrl) {
    return _legacyStreamProvider.getEpisodesByProviderId(sourceUrl);
  }
}


