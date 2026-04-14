// fallback if needed

class MangaItem {
  final String id;
  final String title;
  final String description;
  final String status;
  final String contentRating;
  final int? year;
  final String? coverFileName; // Used by MangaDex
  final String? externalCoverUrl; // Used by external scrapers
  final List<String> tags;
  final List<String> availableLanguages;

  const MangaItem({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.contentRating,
    this.year,
    this.coverFileName,
    this.externalCoverUrl,
    required this.tags,
    required this.availableLanguages,
  });

  String? get coverUrl {
    if (externalCoverUrl != null) return externalCoverUrl;
    if (coverFileName != null) return 'https://uploads.mangadex.org/covers/$id/$coverFileName.256.jpg';
    return null;
  }

  String? get coverUrlFull {
    if (externalCoverUrl != null) return externalCoverUrl;
    if (coverFileName != null) return 'https://uploads.mangadex.org/covers/$id/$coverFileName';
    return null;
  }

  factory MangaItem.fromJson(Map<String, dynamic> json) {
    final attrs = json['attributes'] as Map<String, dynamic>;
    final titleMap = attrs['title'] as Map<String, dynamic>? ?? {};
    final title = (titleMap['en'] ?? titleMap.values.firstOrNull ?? '') as String;

    final descMap = attrs['description'] as Map<String, dynamic>? ?? {};
    final description = (descMap['en'] ?? descMap.values.firstOrNull ?? '') as String;

    final rels = json['relationships'] as List<dynamic>? ?? [];
    String? coverFileName;
    for (final r in rels) {
      final rel = r as Map<String, dynamic>;
      if (rel['type'] == 'cover_art') {
        final coverAttrs = rel['attributes'] as Map<String, dynamic>?;
        coverFileName = coverAttrs?['fileName'] as String?;
        break;
      }
    }

    final tagList = (attrs['tags'] as List<dynamic>? ?? []).map((t) {
      final tAttrs = (t as Map<String, dynamic>)['attributes'] as Map<String, dynamic>;
      final nameMap = tAttrs['name'] as Map<String, dynamic>? ?? {};
      return (nameMap['en'] ?? '') as String;
    }).where((t) => t.isNotEmpty).toList();

    final langs = (attrs['availableTranslatedLanguages'] as List<dynamic>? ?? []).cast<String>();

    return MangaItem(
      id: json['id'] as String,
      title: title,
      description: description,
      status: (attrs['status'] as String?) ?? 'unknown',
      contentRating: (attrs['contentRating'] as String?) ?? 'safe',
      year: attrs['year'] as int?,
      coverFileName: coverFileName,
      tags: tagList,
      availableLanguages: langs,
    );
  }
}

class ChapterItem {
  final String id;
  final String? volume;
  final String? chapter;
  final String? title;
  final String? publishedAt;
  final int pageCount;

  const ChapterItem({
    required this.id,
    this.volume,
    this.chapter,
    this.title,
    this.publishedAt,
    required this.pageCount,
  });

  String get displayTitle {
    final chNum = chapter != null ? 'Ch. $chapter' : '';
    final vol = volume != null ? 'Vol. $volume ' : '';
    final extra = title != null && title!.isNotEmpty ? ' — $title' : '';
    return '$vol$chNum$extra'.trim();
  }

  factory ChapterItem.fromJson(Map<String, dynamic> json) {
    final attrs = json['attributes'] as Map<String, dynamic>;
    return ChapterItem(
      id: json['id'] as String,
      volume: attrs['volume'] as String?,
      chapter: attrs['chapter'] as String?,
      title: attrs['title'] as String?,
      publishedAt: attrs['publishAt'] as String?,
      pageCount: (attrs['pages'] as int?) ?? 0,
    );
  }
}

class ChapterPages {
  final String chapterId;
  final List<String> pageUrls;
  const ChapterPages({required this.chapterId, required this.pageUrls});
}

class TagItem {
  final String id;
  final String name;
  final String group;
  const TagItem({required this.id, required this.name, required this.group});

  factory TagItem.fromJson(Map<String, dynamic> json) {
    final attrs = json['attributes'] as Map<String, dynamic>;
    final nameMap = attrs['name'] as Map<String, dynamic>? ?? {};
    return TagItem(
      id: json['id'] as String,
      name: (nameMap['en'] ?? '') as String,
      group: (attrs['group'] as String?) ?? '',
    );
  }
}

class MangaGenres {
  static const Map<String, String> popular = {
    '🔥 Action': 'id_action',
    '💕 Romance': 'id_romance',
    '😂 Comedy': 'id_comedy',
    '🗡️ Fantasy': 'id_fantasy',
    '🚀 Sci-Fi': 'id_scifi',
    '🎭 Drama': 'id_drama',
    '🔞 Adult': 'id_adult', // Used purely for UI switching
  };
}


