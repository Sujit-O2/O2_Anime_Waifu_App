import 'package:anime_waifu/models/anime_models.dart';
import 'package:anime_waifu/models/manga_models.dart';
import 'package:anime_waifu/services/anime_providers/anime_provider.dart';
import 'package:anime_waifu/services/manga_providers/manga_provider.dart';

/// Wraps two Anime providers to create a highly fault-tolerant engine.
/// It attempts to fetch data from the [primary] provider first.
/// If the data is empty or the network call throws, it instantly falls back to [secondary].
class RobustAnimeWrapper implements AnimeProvider {
  final AnimeProvider primary;
  final AnimeProvider secondary;

  const RobustAnimeWrapper({required this.primary, required this.secondary});

  @override
  String get name => primary.name;

  @override
  Future<List<AnimeItem>> searchAnime(String title, {int limit = 24}) async {
    try {
      final res = await primary.searchAnime(title, limit: limit);
      if (res.isNotEmpty) return res;
    } catch (_) {}
    return secondary.searchAnime(title, limit: limit);
  }

  @override
  Future<List<AnimeItem>> getTrending({int limit = 24}) async {
    try {
      final res = await primary.getTrending(limit: limit);
      if (res.isNotEmpty) return res;
    } catch (_) {}
    return secondary.getTrending(limit: limit);
  }

  @override
  Future<List<AnimeItem>> getPopular({int limit = 24}) async {
    try {
      final res = await primary.getPopular(limit: limit);
      if (res.isNotEmpty) return res;
    } catch (_) {}
    return secondary.getPopular(limit: limit);
  }

  @override
  Future<List<AnimeEpisode>> getEpisodes(String animeId) async {
    try {
      final res = await primary.getEpisodes(animeId);
      if (res.isNotEmpty) return res;
    } catch (_) {}
    // If primary failed, we fallback. Note: Provider IDs may mismatch.
    // In production, fallback searches by title. Here we try the ID and gracefully return empty if mismatched.
    return secondary.getEpisodes(animeId);
  }

  @override
  Future<List<AnimeVideoSource>> getVideoSources(String episodeId) async {
    try {
      final res = await primary.getVideoSources(episodeId);
      if (res.isNotEmpty) return res;
    } catch (_) {}
    return secondary.getVideoSources(episodeId);
  }
}

/// Wraps two Manga providers for fault-tolerance against CloudFlare 403s.
class RobustMangaWrapper implements MangaProvider {
  final MangaProvider primary;
  final MangaProvider secondary;

  const RobustMangaWrapper({required this.primary, required this.secondary});

  @override
  String get name => primary.name;

  @override
  Future<List<MangaItem>> searchManga(String title, {int limit = 24}) async {
    try {
      final res = await primary.searchManga(title, limit: limit);
      if (res.isNotEmpty) return res;
    } catch (_) {}
    return secondary.searchManga(title, limit: limit);
  }

  @override
  Future<List<MangaItem>> getTrending({int limit = 24}) async {
    try {
      final res = await primary.getTrending(limit: limit);
      if (res.isNotEmpty) return res;
    } catch (_) {}
    return secondary.getTrending(limit: limit);
  }

  @override
  Future<List<MangaItem>> getByTag(String tagId, {int limit = 24}) async {
    try {
      final res = await primary.getByTag(tagId, limit: limit);
      if (res.isNotEmpty) return res;
    } catch (_) {}
    return secondary.getByTag(tagId, limit: limit);
  }

  @override
  Future<List<ChapterItem>> getChapters(String mangaId, {String lang = 'en', int limit = 100, int offset = 0}) async {
    try {
      final res = await primary.getChapters(mangaId, lang: lang, limit: limit, offset: offset);
      if (res.isNotEmpty) return res;
    } catch (_) {}
    return secondary.getChapters(mangaId, lang: lang, limit: limit, offset: offset);
  }

  @override
  Future<ChapterPages?> getChapterPages(String chapterId, {bool dataSaver = false}) async {
    try {
      final res = await primary.getChapterPages(chapterId, dataSaver: dataSaver);
      if (res != null && res.pageUrls.isNotEmpty) return res;
    } catch (_) {}
    return secondary.getChapterPages(chapterId, dataSaver: dataSaver);
  }

  @override
  Future<List<TagItem>> getTags() async {
    try {
      final res = await primary.getTags();
      if (res.isNotEmpty) return res;
    } catch (_) {}
    return secondary.getTags();
  }
}


