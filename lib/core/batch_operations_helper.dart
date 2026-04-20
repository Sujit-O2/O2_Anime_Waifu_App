import 'package:anime_waifu/core/error_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Batch Operations Helper
/// Optimizes Firestore writes using batch operations (up to 500 writes per batch)
class BatchOperationsHelper {
  static final int maxBatchSize = 500;
  final FirebaseFirestore _firestore;
  late WriteBatch _currentBatch;
  int _operationCount = 0;
  final List<Future<void>> _pendingBatches = [];

  BatchOperationsHelper({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance {
    _currentBatch = _firestore.batch();
  }

  /// Set document (create or overwrite)
  Future<void> set(
    String collection,
    String documentId,
    Map<String, dynamic> data, {
    bool merge = false,
  }) async {
    if (_operationCount >= maxBatchSize) {
      await _flushBatch();
    }

    _currentBatch.set(
      _firestore.collection(collection).doc(documentId),
      data,
      SetOptions(merge: merge),
    );
    _operationCount++;
  }

  /// Update document
  Future<void> update(
    String collection,
    String documentId,
    Map<String, dynamic> data,
  ) async {
    if (_operationCount >= maxBatchSize) {
      await _flushBatch();
    }

    _currentBatch.update(
      _firestore.collection(collection).doc(documentId),
      data,
    );
    _operationCount++;
  }

  /// Delete document
  Future<void> delete(String collection, String documentId) async {
    if (_operationCount >= maxBatchSize) {
      await _flushBatch();
    }

    _currentBatch.delete(
      _firestore.collection(collection).doc(documentId),
    );
    _operationCount++;
  }

  /// Set document field to server timestamp
  Future<void> setServerTimestamp(
    String collection,
    String documentId,
    String field,
  ) async {
    await set(collection, documentId, {field: FieldValue.serverTimestamp()},
        merge: true);
  }

  /// Increment field value
  Future<void> incrementField(
    String collection,
    String documentId,
    String field,
    num value,
  ) async {
    if (_operationCount >= maxBatchSize) {
      await _flushBatch();
    }

    _currentBatch.update(
      _firestore.collection(collection).doc(documentId),
      {field: FieldValue.increment(value)},
    );
    _operationCount++;
  }

  /// Add array element
  Future<void> addToArray(
    String collection,
    String documentId,
    String field,
    dynamic value,
  ) async {
    if (_operationCount >= maxBatchSize) {
      await _flushBatch();
    }

    _currentBatch.update(
      _firestore.collection(collection).doc(documentId),
      {field: FieldValue.arrayUnion([value])},
    );
    _operationCount++;
  }

  /// Remove array element
  Future<void> removeFromArray(
    String collection,
    String documentId,
    String field,
    dynamic value,
  ) async {
    if (_operationCount >= maxBatchSize) {
      await _flushBatch();
    }

    _currentBatch.update(
      _firestore.collection(collection).doc(documentId),
      {field: FieldValue.arrayRemove([value])},
    );
    _operationCount++;
  }

  /// Flush current batch
  Future<void> _flushBatch() async {
    if (_operationCount == 0) return;

    try {
      final batchFuture = _currentBatch.commit();
      _pendingBatches.add(batchFuture);

      debugPrint('📤 Batch operations flushed ($_operationCount operations)');

      _currentBatch = _firestore.batch();
      _operationCount = 0;
    } catch (e) {
      debugPrint('❌ Error flushing batch: $e');
      rethrow;
    }
  }

  /// Commit all pending operations
  Future<void> commit() async {
    try {
      // Flush current batch if has operations
      if (_operationCount > 0) {
        await _flushBatch();
      }

      // Wait for all pending batches
      await Future.wait(_pendingBatches);
      _pendingBatches.clear();

      debugPrint('✅ All batch operations committed successfully');
    } catch (e) {
      debugPrint('❌ Error committing batches: $e');
      rethrow;
    }
  }

  /// Get pending operations count
  int getPendingOperations() {
    return _operationCount;
  }

  /// Get total pending batches
  int getPendingBatchCount() {
    return _pendingBatches.length;
  }

  /// Clear all pending operations
  void clear() {
    _currentBatch = _firestore.batch();
    _operationCount = 0;
    _pendingBatches.clear();
  }

  /// Batch update multiple documents
  static Future<Result<void>> batchUpdateDocuments(
    String collection,
    Map<String, Map<String, dynamic>> updates,
  ) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      for (final entry in updates.entries) {
        batch.update(
          firestore.collection(collection).doc(entry.key),
          entry.value,
        );
      }

      await batch.commit();
      debugPrint('✅ Batch updated ${updates.length} documents');
      return Result.success(null);
    } catch (e, stackTrace) {
      return Result.failure(
        ErrorHandler.handleException(e, stackTrace),
      );
    }
  }

  /// Batch delete multiple documents
  static Future<Result<void>> batchDeleteDocuments(
    String collection,
    List<String> documentIds,
  ) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      for (final docId in documentIds) {
        batch.delete(firestore.collection(collection).doc(docId));
      }

      await batch.commit();
      debugPrint('✅ Batch deleted ${documentIds.length} documents');
      return Result.success(null);
    } catch (e, stackTrace) {
      return Result.failure(
        ErrorHandler.handleException(e, stackTrace),
      );
    }
  }

  /// Batch create multiple documents
  static Future<Result<void>> batchCreateDocuments(
    String collection,
    Map<String, Map<String, dynamic>> documents,
  ) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      for (final entry in documents.entries) {
        batch.set(
          firestore.collection(collection).doc(entry.key),
          entry.value,
        );
      }

      await batch.commit();
      debugPrint('✅ Batch created ${documents.length} documents');
      return Result.success(null);
    } catch (e, stackTrace) {
      return Result.failure(
        ErrorHandler.handleException(e, stackTrace),
      );
    }
  }

  /// Batch mixed operations
  static Future<Result<void>> batchMixedOperations(
    List<BatchOperation> operations,
  ) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      for (final op in operations) {
        switch (op.type) {
          case OperationType.set:
            batch.set(
              firestore.collection(op.collection).doc(op.documentId),
              op.data!,
            );
            break;
          case OperationType.update:
            batch.update(
              firestore.collection(op.collection).doc(op.documentId),
              op.data!,
            );
            break;
          case OperationType.delete:
            batch.delete(
              firestore.collection(op.collection).doc(op.documentId),
            );
            break;
        }
      }

      await batch.commit();
      debugPrint('✅ Batch executed ${operations.length} mixed operations');
      return Result.success(null);
    } catch (e, stackTrace) {
      return Result.failure(
        ErrorHandler.handleException(e, stackTrace),
      );
    }
  }
}

/// Batch operation types
enum OperationType { set, update, delete }

/// Batch operation model
class BatchOperation {
  final OperationType type;
  final String collection;
  final String documentId;
  final Map<String, dynamic>? data;

  BatchOperation({
    required this.type,
    required this.collection,
    required this.documentId,
    this.data,
  });
}



