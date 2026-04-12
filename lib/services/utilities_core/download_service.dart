import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Download Service — saves manga chapters and anime episodes for offline use.
class DownloadService {
  static const String _downloadsKey = 'offline_downloads';

  /// Download a manga chapter (list of image URLs).
  static Future<DownloadItem?> downloadMangaChapter({
    required String mangaId,
    required String chapterId,
    required String title,
    required String coverUrl,
    required List<String> imageUrls,
    Function(double)? onProgress,
  }) async {
    try {
      final dir = await _getDownloadDir();
      final chapterDir = Directory('${dir.path}/manga/$mangaId/$chapterId');
      await chapterDir.create(recursive: true);

      final totalImages = imageUrls.length;
      final savedPaths = <String>[];

      for (int i = 0; i < totalImages; i++) {
        final imgUrl = imageUrls[i];
        final ext = imgUrl.split('.').last.split('?').first;
        final filePath = '${chapterDir.path}/page_${i + 1}.$ext';

        final resp = await http.get(Uri.parse(imgUrl), headers: {
          'User-Agent': 'Mozilla/5.0',
          'Referer': 'https://mangadex.org/',
        }).timeout(const Duration(seconds: 30));

        if (resp.statusCode == 200) {
          await File(filePath).writeAsBytes(resp.bodyBytes);
          savedPaths.add(filePath);
        }
        onProgress?.call((i + 1) / totalImages);
      }

      final item = DownloadItem(
        id: '$mangaId-$chapterId',
        title: title,
        coverUrl: coverUrl,
        type: 'manga',
        localPath: chapterDir.path,
        pageCount: savedPaths.length,
        downloadedAt: DateTime.now(),
      );
      await _saveDownloadItem(item);
      return item;
    } catch (e) {
      debugPrint('Download failed: $e');
      return null;
    }
  }

  /// Download an anime episode (M3U8 links saved as reference).
  static Future<DownloadItem?> downloadAnimeEpisode({
    required String animeId,
    required String episodeId,
    required String title,
    required String coverUrl,
    required String streamUrl,
    Function(double)? onProgress,
  }) async {
    try {
      final dir = await _getDownloadDir();
      final epDir = Directory('${dir.path}/anime/$animeId/$episodeId');
      await epDir.create(recursive: true);

      // For M3U8 streaming, save the manifest + download TS segments
      if (streamUrl.contains('.m3u8')) {
        // Save the M3U8 manifest
        final manifestResp = await http.get(Uri.parse(streamUrl), headers: {
          'User-Agent': 'Mozilla/5.0',
          'Referer': 'https://gogocdn.net/',
        }).timeout(const Duration(seconds: 15));

        if (manifestResp.statusCode == 200) {
          await File('${epDir.path}/manifest.m3u8')
              .writeAsString(manifestResp.body);

          // Parse TS segment URLs from manifest
          final lines = manifestResp.body.split('\n');
          final baseUrl = streamUrl.substring(0, streamUrl.lastIndexOf('/') + 1);
          final tsUrls = lines
              .where((l) => l.trim().isNotEmpty && !l.startsWith('#'))
              .map((l) => l.startsWith('http') ? l : '$baseUrl$l')
              .toList();

          // Download each TS segment
          for (int i = 0; i < tsUrls.length; i++) {
            try {
              final tsResp = await http.get(Uri.parse(tsUrls[i].trim()), headers: {
                'User-Agent': 'Mozilla/5.0',
                'Referer': 'https://gogocdn.net/',
              }).timeout(const Duration(seconds: 30));

              if (tsResp.statusCode == 200) {
                await File('${epDir.path}/segment_$i.ts')
                    .writeAsBytes(tsResp.bodyBytes);
              }
            } catch (_) {}
            onProgress?.call((i + 1) / tsUrls.length);
          }
        }
      } else {
        // Direct MP4 download
        final resp = await http.get(Uri.parse(streamUrl), headers: {
          'User-Agent': 'Mozilla/5.0',
        }).timeout(const Duration(minutes: 5));

        if (resp.statusCode == 200) {
          await File('${epDir.path}/video.mp4').writeAsBytes(resp.bodyBytes);
        }
        onProgress?.call(1.0);
      }

      final item = DownloadItem(
        id: '$animeId-$episodeId',
        title: title,
        coverUrl: coverUrl,
        type: 'anime',
        localPath: epDir.path,
        downloadedAt: DateTime.now(),
      );
      await _saveDownloadItem(item);
      return item;
    } catch (e) {
      debugPrint('Anime download failed: $e');
      return null;
    }
  }

  /// Get all downloaded items.
  static Future<List<DownloadItem>> getDownloads() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_downloadsKey) ?? [];
    return raw.map((s) => DownloadItem.fromJson(jsonDecode(s))).toList();
  }

  /// Delete a downloaded item.
  static Future<void> deleteDownload(String id) async {
    final items = await getDownloads();
    DownloadItem? item;
    try {
      item = items.firstWhere((e) => e.id == id);
    } catch (_) {
      item = null;
    }
    if (item != null) {
      final dir = Directory(item.localPath);
      if (await dir.exists()) await dir.delete(recursive: true);
    }
    items.removeWhere((e) => e.id == id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _downloadsKey,
      items.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  /// Get total download size in bytes.
  static Future<int> getTotalSize() async {
    final items = await getDownloads();
    int total = 0;
    for (final item in items) {
      final dir = Directory(item.localPath);
      if (await dir.exists()) {
        await for (final entity in dir.list(recursive: true)) {
          if (entity is File) total += await entity.length();
        }
      }
    }
    return total;
  }

  static Future<void> _saveDownloadItem(DownloadItem item) async {
    final items = await getDownloads();
    items.removeWhere((e) => e.id == item.id);
    items.insert(0, item);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _downloadsKey,
      items.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  static Future<Directory> _getDownloadDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dlDir = Directory('${appDir.path}/downloads');
    if (!await dlDir.exists()) await dlDir.create(recursive: true);
    return dlDir;
  }
}

class DownloadItem {
  final String id;
  final String title;
  final String coverUrl;
  final String type; // 'manga' or 'anime'
  final String localPath;
  final int pageCount;
  final DateTime downloadedAt;

  DownloadItem({
    required this.id, required this.title, required this.coverUrl,
    required this.type, required this.localPath, this.pageCount = 0,
    required this.downloadedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'coverUrl': coverUrl,
    'type': type, 'localPath': localPath, 'pageCount': pageCount,
    'downloadedAt': downloadedAt.toIso8601String(),
  };

  factory DownloadItem.fromJson(Map<String, dynamic> j) => DownloadItem(
    id: j['id'] ?? '', title: j['title'] ?? '', coverUrl: j['coverUrl'] ?? '',
    type: j['type'] ?? '', localPath: j['localPath'] ?? '',
    pageCount: j['pageCount'] ?? 0,
    downloadedAt: DateTime.tryParse(j['downloadedAt'] ?? '') ?? DateTime.now(),
  );
}


