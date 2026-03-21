import '../models/manga_models.dart';
import 'manga_providers/manga_provider.dart';
import 'manga_providers/manga_dex_provider.dart';
import 'manga_providers/raw_manhwa_provider.dart';
import 'manga_providers/comick_provider.dart';
import 'manga_providers/mangapark_provider.dart';
import 'manga_providers/nhentai_provider.dart';
import 'manga_providers/madara_generic_provider.dart';
import 'robustness_wrappers.dart';

export '../models/manga_models.dart';

enum MangaSource { 
  dex, comick, mangapark, nhentai, manhwa,
  manytoon, mangatx, mangabob, webtoonxyz, mangaread, manhwa18,
  manhwatop, zinmanga, freewebtoon, mangaweebs, reaperscans,
  asurascans, flamescans, luminous
}

class MangaService {
  static MangaSource currentSource = MangaSource.dex;

  static final MangaDexProvider   _dexProvider      = MangaDexProvider();
  static final ComickProvider     _comickProvider   = ComickProvider();
  static final MangaParkProvider  _mpProvider       = MangaParkProvider();
  static final NhentaiProvider    _nhProvider       = NhentaiProvider();
  static final RawManhwaProvider  _manhwaProvider   = RawManhwaProvider();

  static final Map<MangaSource, MangaProvider> _madaraProviders = {
    MangaSource.manytoon: RobustMangaWrapper(primary: MadaraGenericProvider(providerName: 'ManyToon', providerBaseUrl: 'https://manytoon.com', isAdult: true), secondary: _comickProvider),
    MangaSource.mangatx: RobustMangaWrapper(primary: MadaraGenericProvider(providerName: 'MangaTx', providerBaseUrl: 'https://mangatx.com', isAdult: false), secondary: _dexProvider),
    MangaSource.mangabob: RobustMangaWrapper(primary: MadaraGenericProvider(providerName: 'MangaBob', providerBaseUrl: 'https://mangabob.com', isAdult: false), secondary: _dexProvider),
    MangaSource.webtoonxyz: RobustMangaWrapper(primary: MadaraGenericProvider(providerName: 'WebtoonXYZ', providerBaseUrl: 'https://www.webtoon.xyz', isAdult: true), secondary: _comickProvider),
    MangaSource.mangaread: RobustMangaWrapper(primary: MadaraGenericProvider(providerName: 'MangaRead', providerBaseUrl: 'https://www.mangaread.org', isAdult: false), secondary: _dexProvider),
    MangaSource.manhwa18: RobustMangaWrapper(primary: MadaraGenericProvider(providerName: 'Manhwa18', providerBaseUrl: 'https://manhwa18.com', isAdult: true), secondary: _nhProvider),
    MangaSource.manhwatop: RobustMangaWrapper(primary: MadaraGenericProvider(providerName: 'ManhwaTop', providerBaseUrl: 'https://manhwatop.com', isAdult: false), secondary: _comickProvider),
    MangaSource.zinmanga: RobustMangaWrapper(primary: MadaraGenericProvider(providerName: 'ZinManga', providerBaseUrl: 'https://zinmanga.com', isAdult: false), secondary: _dexProvider),
    MangaSource.freewebtoon: RobustMangaWrapper(primary: MadaraGenericProvider(providerName: 'FreeWebtoons', providerBaseUrl: 'https://freewebtooncoins.com', isAdult: false), secondary: _dexProvider),
    MangaSource.mangaweebs: RobustMangaWrapper(primary: MadaraGenericProvider(providerName: 'MangaWeebs', providerBaseUrl: 'https://mangaweebs.in', isAdult: false), secondary: _comickProvider),
    MangaSource.reaperscans: RobustMangaWrapper(primary: MadaraGenericProvider(providerName: 'ReaperScans', providerBaseUrl: 'https://reaperscans.com', isAdult: false), secondary: _dexProvider),
    MangaSource.asurascans: RobustMangaWrapper(primary: MadaraGenericProvider(providerName: 'AsuraScans', providerBaseUrl: 'https://asurascans.com', isAdult: false), secondary: _comickProvider),
    MangaSource.flamescans: RobustMangaWrapper(primary: MadaraGenericProvider(providerName: 'FlameScans', providerBaseUrl: 'https://flamescans.org', isAdult: false), secondary: _dexProvider),
    MangaSource.luminous: RobustMangaWrapper(primary: MadaraGenericProvider(providerName: 'Luminous', providerBaseUrl: 'https://luminousscans.com', isAdult: false), secondary: _comickProvider),
  };

  static MangaProvider get _provider {
    if (_madaraProviders.containsKey(currentSource)) {
      return _madaraProviders[currentSource]!;
    }
    switch (currentSource) {
      case MangaSource.dex:         return _dexProvider;
      case MangaSource.comick:      return _comickProvider;
      case MangaSource.mangapark:   return _mpProvider;
      case MangaSource.nhentai:     return _nhProvider;
      case MangaSource.manhwa:      return _manhwaProvider;
      default:                      return _dexProvider; // Fallback
    }
  }

  static String get sourceName => _provider.name;

  static String sourceDisplayName(MangaSource s) {
    if (_madaraProviders.containsKey(s)) {
      final name = _madaraProviders[s]!.name;
      // Assume _madaraProviders maps RobustMangaWrapper which exposes name.
      // To determine isAdult, we check if primary is MadaraGenericProvider.
      final wrapper = _madaraProviders[s] as RobustMangaWrapper;
      final isAdult = (wrapper.primary as MadaraGenericProvider).isAdult;
      return isAdult ? '🔞 $name' : '🌸 $name';
    }
    switch (s) {
      case MangaSource.dex:         return '🟠 MangaDex';
      case MangaSource.comick:      return '🔵 ComicK';
      case MangaSource.mangapark:   return '🟣 MangaPark';
      case MangaSource.nhentai:     return '🔞 NHentai';
      case MangaSource.manhwa:      return '🌸 Toonily';
      case MangaSource.mangatx:     return '🌸 MangaTx';
      case MangaSource.mangabob:    return '🌸 MangaBob';
      case MangaSource.webtoonxyz:  return '🔞 WebtoonXYZ';
      case MangaSource.mangaread:   return '🌸 MangaRead';
      case MangaSource.manhwa18:    return '🔞 Manhwa18';
      case MangaSource.manhwatop:   return '🌸 ManhwaTop';
      case MangaSource.zinmanga:    return '🌸 ZinManga';
      case MangaSource.freewebtoon: return '🌸 FreeWebtoons';
      case MangaSource.mangaweebs:  return '🌸 MangaWeebs';
      case MangaSource.reaperscans: return '🌸 ReaperScans';
      case MangaSource.asurascans:  return '🌸 AsuraScans';
      case MangaSource.flamescans:  return '🌸 FlameScans';
      case MangaSource.luminous:    return '🌸 Luminous';
      default:                      return '📖 Unknown'; // Fallback
    }
  }

  static Future<List<MangaItem>> searchManga(String title, {int limit = 24}) =>
      _provider.searchManga(title, limit: limit);

  static Future<List<MangaItem>> getTrending({int limit = 24}) =>
      _provider.getTrending(limit: limit);

  static Future<List<MangaItem>> getByTag(String tagId, {int limit = 24}) =>
      _provider.getByTag(tagId, limit: limit);

  static Future<List<ChapterItem>> getChapters(String mangaId,
          {String lang = 'en', int limit = 100, int offset = 0}) =>
      _provider.getChapters(mangaId, lang: lang, limit: limit, offset: offset);

  static Future<ChapterPages?> getChapterPages(String chapterId,
          {bool dataSaver = false}) =>
      _provider.getChapterPages(chapterId, dataSaver: dataSaver);

  static Future<List<TagItem>> getTags() => _provider.getTags();
}
