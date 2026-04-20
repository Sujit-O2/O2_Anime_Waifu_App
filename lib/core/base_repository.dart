import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'error_handler.dart';

/// Base Repository Abstract Class
/// Provides common CRUD operations for all repositories
abstract class BaseRepository<T> {
  final FirebaseFirestore firestore;
  final String collectionName;

  BaseRepository({
    required this.collectionName,
    FirebaseFirestore? firestore,
  }) : firestore = firestore ?? FirebaseFirestore.instance;

  /// Convert Firestore document to model
  T fromFirestore(Map<String, dynamic> data);

  /// Convert model to Firestore document
  Map<String, dynamic> toFirestore(T item);

  /// Create a new document
  Future<Result<String>> create(T item) async {
    try {
      final docRef = await firestore
          .collection(collectionName)
          .add(toFirestore(item));

      debugPrint('✅ Document created: ${docRef.id}');
      return Result.success(docRef.id);
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.handleException(e, stackTrace));
    }
  }

  /// Read a single document
  Future<Result<T?>> read(String documentId) async {
    try {
      final snapshot =
          await firestore.collection(collectionName).doc(documentId).get();

      if (!snapshot.exists) {
        return Result.success(null);
      }

      final item = fromFirestore(snapshot.data() as Map<String, dynamic>);
      return Result.success(item);
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.handleException(e, stackTrace));
    }
  }

  /// Update a document
  Future<Result<void>> update(String documentId, T item) async {
    try {
      await firestore
          .collection(collectionName)
          .doc(documentId)
          .update(toFirestore(item));

      debugPrint('✅ Document updated: $documentId');
      return Result.success(null);
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.handleException(e, stackTrace));
    }
  }

  /// Delete a document
  Future<Result<void>> delete(String documentId) async {
    try {
      await firestore.collection(collectionName).doc(documentId).delete();

      debugPrint('✅ Document deleted: $documentId');
      return Result.success(null);
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.handleException(e, stackTrace));
    }
  }

  /// Get all documents
  Future<Result<List<T>>> getAll() async {
    try {
      final snapshot = await firestore.collection(collectionName).get();

      final items = snapshot.docs
          .map((doc) => fromFirestore(doc.data()))
          .toList();

      return Result.success(items);
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.handleException(e, stackTrace));
    }
  }

  /// Query documents with where condition
  Future<Result<List<T>>> where(
    String field,
    dynamic isEqualTo,
  ) async {
    try {
      final snapshot = await firestore
          .collection(collectionName)
          .where(field, isEqualTo: isEqualTo)
          .get();

      final items = snapshot.docs
          .map((doc) => fromFirestore(doc.data()))
          .toList();

      return Result.success(items);
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.handleException(e, stackTrace));
    }
  }

  /// Query with custom query function
  Future<Result<List<T>>> query(
    Query Function(Query) queryBuilder,
  ) async {
    try {
      Query query = firestore.collection(collectionName);
      query = queryBuilder(query);
      final snapshot = await query.get();

      final items = snapshot.docs
          .map((doc) => fromFirestore(doc.data() as Map<String, dynamic>))
          .toList();

      return Result.success(items);
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.handleException(e, stackTrace));
    }
  }

  /// Count documents
  Future<Result<int>> count() async {
    try {
      final snapshot = await firestore.collection(collectionName).count().get();
      final count = snapshot.count ?? 0;
      return Result.success(count);
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.handleException(e, stackTrace));
    }
  }

  /// Batch create multiple documents
  Future<Result<void>> batchCreate(List<T> items) async {
    try {
      final batch = firestore.batch();

      for (final item in items) {
        final docRef = firestore.collection(collectionName).doc();
        batch.set(docRef, toFirestore(item));
      }

      await batch.commit();
      debugPrint('✅ Batch created ${items.length} documents');
      return Result.success(null);
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.handleException(e, stackTrace));
    }
  }

  /// Batch delete multiple documents
  Future<Result<void>> batchDelete(List<String> documentIds) async {
    try {
      final batch = firestore.batch();

      for (final docId in documentIds) {
        batch.delete(firestore.collection(collectionName).doc(docId));
      }

      await batch.commit();
      debugPrint('✅ Batch deleted ${documentIds.length} documents');
      return Result.success(null);
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.handleException(e, stackTrace));
    }
  }

  /// Stream single document in real-time
  Stream<Result<T?>> streamDocument(String documentId) {
    return firestore
        .collection(collectionName)
        .doc(documentId)
        .snapshots()
        .map((snapshot) {
      try {
        if (!snapshot.exists) {
          return Result.success(null);
        }
        final item = fromFirestore(snapshot.data() as Map<String, dynamic>);
        return Result.success(item);
      } catch (e, stackTrace) {
        return Result.failure(ErrorHandler.handleException(e, stackTrace));
      }
    });
  }

  /// Stream collection in real-time
  Stream<Result<List<T>>> streamCollection() {
    return firestore.collection(collectionName).snapshots().map((snapshot) {
      try {
        final items = snapshot.docs
            .map((doc) => fromFirestore(doc.data()))
            .toList();
        return Result.success(items);
      } catch (e, stackTrace) {
        return Result.failure(ErrorHandler.handleException(e, stackTrace));
      }
    });
  }

  /// Search documents
  Future<Result<List<T>>> search(
    String searchField,
    String searchTerm,
  ) async {
    try {
      final snapshot = await firestore
          .collection(collectionName)
          .where(searchField, isGreaterThanOrEqualTo: searchTerm)
          .where(searchField, isLessThan: '$searchTerm~')
          .get();

      final items = snapshot.docs
          .map((doc) => fromFirestore(doc.data()))
          .toList();

      return Result.success(items);
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.handleException(e, stackTrace));
    }
  }
}

/// User Repository Example Implementation
class UserRepository extends BaseRepository<Map<String, dynamic>> {
  UserRepository() : super(collectionName: 'users');

  @override
  Map<String, dynamic> fromFirestore(Map<String, dynamic> data) {
    return data;
  }

  @override
  Map<String, dynamic> toFirestore(Map<String, dynamic> item) {
    return item;
  }

  /// Get user by email
  Future<Result<Map<String, dynamic>?>> getUserByEmail(String email) async {
    return where('email', email).then((result) {
      if (result.isSuccess) {
        return Result.success(result.data?.firstOrNull);
      }
      return Result.failure(result.error!);
    });
  }
}

/// Message Repository Example Implementation
class MessageRepository extends BaseRepository<Map<String, dynamic>> {
  MessageRepository() : super(collectionName: 'messages');

  @override
  Map<String, dynamic> fromFirestore(Map<String, dynamic> data) {
    return data;
  }

  @override
  Map<String, dynamic> toFirestore(Map<String, dynamic> item) {
    return item;
  }

  /// Get messages for user
  Future<Result<List<Map<String, dynamic>>>> getMessagesForUser(
    String userId,
  ) async {
    return where('userId', userId);
  }

  /// Get messages between users
  Future<Result<List<Map<String, dynamic>>>> getMessagesBetween(
    String userId,
    String characterId,
  ) async {
    return query((q) =>
        q.where('userId', isEqualTo: userId)
         .where('characterId', isEqualTo: characterId)
         .orderBy('createdAt', descending: true));
  }

  /// Stream messages for character
  Stream<Result<List<Map<String, dynamic>>>> streamCharacterMessages(
    String characterId,
  ) {
    return firestore
        .collection(collectionName)
        .where('characterId', isEqualTo: characterId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      try {
        final items = snapshot.docs.map((doc) => doc.data()).toList();
        return Result.success(items);
      } catch (e, stackTrace) {
        return Result.failure(ErrorHandler.handleException(e, stackTrace));
      }
    });
  }
}

/// Offline Repository Implementation
/// Can work with local cache when offline
class OfflineCapableRepository<T> extends BaseRepository<T> {
  final Map<String, T> _offlineCache = {};
  bool _isOnline = true;

  OfflineCapableRepository({
    required super.collectionName,
    super.firestore,
  });

  @override
  T fromFirestore(Map<String, dynamic> data) {
    throw UnimplementedError('Subclasses must implement fromFirestore');
  }

  @override
  Map<String, dynamic> toFirestore(T item) {
    throw UnimplementedError('Subclasses must implement toFirestore');
  }

  /// Set connectivity status
  void setOnlineStatus(bool isOnline) {
    _isOnline = isOnline;
  }

  /// Override create to use offline cache
  @override
  Future<Result<String>> create(T item) async {
    if (!_isOnline) {
      // Create locally with temporary ID
      final tempId = 'offline_${DateTime.now().millisecondsSinceEpoch}';
      _offlineCache[tempId] = item;
      debugPrint('📱 Document created offline: $tempId');
      return Result.success(tempId);
    }

    return super.create(item);
  }

  /// Get from offline cache if available
  Future<Result<T?>> readOfflineFirst(String documentId) async {
    if (_offlineCache.containsKey(documentId)) {
      debugPrint('📱 Document loaded from offline cache: $documentId');
      return Result.success(_offlineCache[documentId]);
    }

    return super.read(documentId);
  }

  /// Sync offline changes when back online
  Future<Result<void>> syncOfflineChanges() async {
    if (_isOnline && _offlineCache.isNotEmpty) {
      try {
        final batch = firestore.batch();

        for (final entry in _offlineCache.entries) {
          batch.set(
            firestore.collection(collectionName).doc(entry.key),
            toFirestore(entry.value),
          );
        }

        await batch.commit();
        _offlineCache.clear();

        debugPrint('✅ Offline changes synced to server');
        return Result.success(null);
      } catch (e, stackTrace) {
        return Result.failure(ErrorHandler.handleException(e, stackTrace));
      }
    }

    return Result.success(null);
  }

  /// Get offline cache size
  int getOfflineCacheSize() {
    return _offlineCache.length;
  }
}


