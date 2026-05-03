import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anime_waifu/utils/api_call.dart';

class ScannedDocument {
  final String id;
  final String title;
  final String text;
  final String docType;
  final String summary;
  final String keyInfo;
  final DateTime createdAt;

  ScannedDocument({
    required this.id,
    required this.title,
    required this.text,
    required this.docType,
    this.summary = '',
    this.keyInfo = '',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'text': text,
        'docType': docType,
        'summary': summary,
        'keyInfo': keyInfo,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ScannedDocument.fromJson(Map<String, dynamic> json) =>
      ScannedDocument(
        id: json['id'] as String,
        title: json['title'] as String,
        text: json['text'] as String,
        docType: json['docType'] as String,
        summary: json['summary'] as String? ?? '',
        keyInfo: json['keyInfo'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class DocumentScannerService {
  DocumentScannerService._internal();
  static final DocumentScannerService instance = DocumentScannerService._internal();

  static const String _storageKey = 'scanned_documents_v1';
  static const List<String> validDocTypes = [
    'note',
    'bill',
    'id',
    'form',
    'receipt',
    'screenshot',
    'other',
  ];

  Future<List<ScannedDocument>> _loadDocuments() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => ScannedDocument.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveDocuments(List<ScannedDocument> documents) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
        documents.map((d) => d.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  Future<ScannedDocument> addDocument({
    required String text,
    required String title,
    required String docType,
  }) async {
    final documents = await _loadDocuments();
    final doc = ScannedDocument(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      text: text,
      docType: validDocTypes.contains(docType) ? docType : 'other',
      createdAt: DateTime.now(),
    );
    documents.insert(0, doc);
    await _saveDocuments(documents);
    return doc;
  }

  Future<String> summarizeDocument(String documentText) async {
    try {
      final prompt =
          'Provide a concise summary of the following document text in 2-3 sentences. Focus on the main purpose and key points:\n\n$documentText';
      final summary = await ApiService()
          .sendConversation([{'role': 'user', 'content': prompt}]);
      return summary;
    } catch (_) {
      return 'Unable to generate summary. Please try again.';
    }
  }

  Future<String> extractKeyInfo(String documentText) async {
    try {
      final prompt =
          'Extract key information from the following document. List any dates, amounts, names, addresses, reference numbers, or other important details in a clean bulleted format. If certain types of info are not found, skip them:\n\n$documentText';
      final result = await ApiService()
          .sendConversation([{'role': 'user', 'content': prompt}]);
      return result;
    } catch (_) {
      return 'Unable to extract key information. Please try again.';
    }
  }

  Future<ScannedDocument> analyzeAndSaveDocument({
    required String text,
    required String title,
    required String docType,
  }) async {
    final documents = await _loadDocuments();

    String summary = '';
    String keyInfo = '';

    try {
      final summaryFuture = summarizeDocument(text);
      final keyInfoFuture = extractKeyInfo(text);
      final results = await Future.wait([summaryFuture, keyInfoFuture]);
      summary = results[0];
      keyInfo = results[1];
    } catch (_) {
      summary = 'Summary pending';
      keyInfo = 'Key info pending';
    }

    final doc = ScannedDocument(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      text: text,
      docType: validDocTypes.contains(docType) ? docType : 'other',
      summary: summary,
      keyInfo: keyInfo,
      createdAt: DateTime.now(),
    );
    documents.insert(0, doc);
    await _saveDocuments(documents);
    return doc;
  }

  Future<List<ScannedDocument>> getDocuments() async {
    final documents = await _loadDocuments();
    return documents;
  }

  Future<ScannedDocument?> getDocumentById(String id) async {
    final documents = await _loadDocuments();
    try {
      return documents.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<List<ScannedDocument>> searchDocuments(String query) async {
    if (query.trim().isEmpty) return getDocuments();
    final documents = await _loadDocuments();
    final lowerQuery = query.toLowerCase();
    return documents.where((d) {
      return d.title.toLowerCase().contains(lowerQuery) ||
          d.text.toLowerCase().contains(lowerQuery) ||
          d.docType.toLowerCase().contains(lowerQuery) ||
          d.summary.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  Future<bool> deleteDocument(String id) async {
    final documents = await _loadDocuments();
    final initialLength = documents.length;
    documents.removeWhere((d) => d.id == id);
    if (documents.length < initialLength) {
      await _saveDocuments(documents);
      return true;
    }
    return false;
  }

  Future<int> getDocumentCount() async {
    final documents = await _loadDocuments();
    return documents.length;
  }

  Future<Map<String, int>> getDocTypeBreakdown() async {
    final documents = await _loadDocuments();
    final Map<String, int> breakdown = {};
    for (final doc in documents) {
      breakdown[doc.docType] = (breakdown[doc.docType] ?? 0) + 1;
    }
    return breakdown;
  }
}
