import '../../models/manga_models.dart';

abstract class MangaProvider {
  String get name;
  Future<List<MangaItem>> searchManga(String title, {int limit = 24});
  Future<List<MangaItem>> getTrending({int limit = 24});
  Future<List<MangaItem>> getByTag(String tagId, {int limit = 24});
  Future<List<ChapterItem>> getChapters(String mangaId, {String lang = 'en', int limit = 100, int offset = 0});
  Future<ChapterPages?> getChapterPages(String chapterId, {bool dataSaver = false});
  Future<List<TagItem>> getTags();
}


