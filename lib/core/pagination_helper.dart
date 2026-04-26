import 'package:anime_waifu/core/constants.dart';
import 'package:anime_waifu/core/error_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;

/// Pagination Helper
/// Efficient cursor-based pagination for Firestore queries
class PaginationHelper<T> {
  final String collectionName;
  final T Function(DocumentSnapshot) converter;
  final FirebaseFirestore firestore;
  
  DocumentSnapshot? _lastDocument;
  DocumentSnapshot? _firstDocument;
  bool _hasNextPage = true;
  bool _hasPreviousPage = false;
  List<T> _currentPage = [];
  int _pageSize = AppLimits.pageSize;

  PaginationHelper({
    required this.collectionName,
    required this.converter,
    FirebaseFirestore? firestore,
    int pageSize = AppLimits.pageSize,
  })  : firestore = firestore ?? FirebaseFirestore.instance,
        _pageSize = pageSize;

  /// Get first page of results
  Future<Result<List<T>>> getFirstPage({
    List<QueryConstraint>? constraints,
    String? orderByField,
    bool descending = true,
  }) async {
    try {
      _lastDocument = null;
      _firstDocument = null;
      _hasNextPage = true;
      _hasPreviousPage = false;

      return await _fetchPage(
        constraints: constraints,
        orderByField: orderByField,
        descending: descending,
      );
    } catch (e, stackTrace) {
      return Result.failure(
        ErrorHandler.handleException(e, stackTrace),
      );
    }
  }

  /// Get next page
  Future<Result<List<T>>> getNextPage({
    List<QueryConstraint>? constraints,
    String? orderByField,
    bool descending = true,
  }) async {
    if (!_hasNextPage) {
      return Result.failure(
        AppException(message: 'No more pages available'),
      );
    }

    try {
      return await _fetchPage(
        constraints: constraints,
        orderByField: orderByField,
        descending: descending,
        startAfter: _lastDocument,
      );
    } catch (e, stackTrace) {
      return Result.failure(
        ErrorHandler.handleException(e, stackTrace),
      );
    }
  }

  /// Get previous page
  Future<Result<List<T>>> getPreviousPage({
    List<QueryConstraint>? constraints,
    String? orderByField,
    bool descending = true,
  }) async {
    if (!_hasPreviousPage) {
      return Result.failure(
        AppException(message: 'No previous page available'),
      );
    }

    try {
      return await _fetchPage(
        constraints: constraints,
        orderByField: orderByField,
        descending: descending,
        endBefore: _firstDocument,
      );
    } catch (e, stackTrace) {
      return Result.failure(
        ErrorHandler.handleException(e, stackTrace),
      );
    }
  }

  /// Internal fetch page implementation
  Future<Result<List<T>>> _fetchPage({
    List<QueryConstraint>? constraints,
    String? orderByField,
    bool descending = true,
    DocumentSnapshot? startAfter,
    DocumentSnapshot? endBefore,
  }) async {
    try {
      var query = firestore.collection(collectionName) as Query;

      // Apply constraints
      if (constraints != null) {
        for (final constraint in constraints) {
          query = constraint.apply(query);
        }
      }

      // Apply ordering
      if (orderByField != null) {
        query = query.orderBy(orderByField, descending: descending);
      }

      // Apply pagination
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      } else if (endBefore != null) {
        query = query.endBeforeDocument(endBefore);
      }

      // Fetch one extra to determine if more pages exist
      query = query.limit(_pageSize + 1);

      final snapshot = await query.get();

      // Process results
      _currentPage = [];
      int resultCount = snapshot.docs.length;
      bool hasMore = resultCount > _pageSize;

      if (hasMore) {
        resultCount = _pageSize;
      }

      for (int i = 0; i < resultCount; i++) {
        try {
          final item = converter(snapshot.docs[i]);
          _currentPage.add(item);
        } catch (e) {
          if (kDebugMode) debugPrint('⚠️ Error converting document: $e');
        }
      }

      // Update pagination state
      if (_currentPage.isNotEmpty) {
        _firstDocument = snapshot.docs[0];
        _lastDocument = snapshot.docs[resultCount - 1];
        _hasNextPage = hasMore;
        _hasPreviousPage = startAfter == null && endBefore == null
            ? false
            : true; // Simplified logic
      }

      if (kDebugMode) {
        debugPrint(
        '✅ Fetched page (${_currentPage.length} items, hasMore: $_hasNextPage)',
      );
      }

      return Result.success(_currentPage);
    } catch (e, stackTrace) {
      return Result.failure(
        ErrorHandler.handleException(e, stackTrace),
      );
    }
  }

  /// Get current page
  List<T> getCurrentPage() {
    return _currentPage;
  }

  /// Check if has next page
  bool hasNextPage() {
    return _hasNextPage;
  }

  /// Check if has previous page
  bool hasPreviousPage() {
    return _hasPreviousPage;
  }

  /// Get current page size
  int getPageSize() {
    return _pageSize;
  }

  /// Set page size
  void setPageSize(int size) {
    if (size > 0) {
      _pageSize = size;
    }
  }

  /// Reset pagination
  void reset() {
    _lastDocument = null;
    _firstDocument = null;
    _hasNextPage = true;
    _hasPreviousPage = false;
    _currentPage = [];
  }

  /// Get pagination info
  PaginationInfo getPaginationInfo() {
    return PaginationInfo(
      currentPageSize: _currentPage.length,
      hasNextPage: _hasNextPage,
      hasPreviousPage: _hasPreviousPage,
      pageSize: _pageSize,
    );
  }
}

/// Query constraint for flexible filtering
abstract class QueryConstraint {
  Query apply(Query query);
}

/// Where constraint
class WhereConstraint extends QueryConstraint {
  final String field;
  final dynamic isEqualTo;
  final dynamic isLessThan;
  final dynamic isGreaterThan;

  WhereConstraint({
    required this.field,
    this.isEqualTo,
    this.isLessThan,
    this.isGreaterThan,
  });

  @override
  Query apply(Query query) {
    if (isEqualTo != null) {
      return query.where(field, isEqualTo: isEqualTo);
    } else if (isLessThan != null) {
      return query.where(field, isLessThan: isLessThan);
    } else if (isGreaterThan != null) {
      return query.where(field, isGreaterThan: isGreaterThan);
    }
    return query;
  }
}

/// Range constraint
class RangeConstraint extends QueryConstraint {
  final String field;
  final dynamic min;
  final dynamic max;

  RangeConstraint({
    required this.field,
    required this.min,
    required this.max,
  });

  @override
  Query apply(Query query) {
    return query
        .where(field, isGreaterThanOrEqualTo: min)
        .where(field, isLessThanOrEqualTo: max);
  }
}

/// In constraint
class InConstraint extends QueryConstraint {
  final String field;
  final List<dynamic> values;

  InConstraint({
    required this.field,
    required this.values,
  });

  @override
  Query apply(Query query) {
    return query.where(field, whereIn: values);
  }
}

/// Pagination information model
class PaginationInfo {
  final int currentPageSize;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final int pageSize;

  PaginationInfo({
    required this.currentPageSize,
    required this.hasNextPage,
    required this.hasPreviousPage,
    required this.pageSize,
  });

  @override
  String toString() {
    return 'PaginationInfo(size: $currentPageSize, nextPage: $hasNextPage, prevPage: $hasPreviousPage)';
  }
}



