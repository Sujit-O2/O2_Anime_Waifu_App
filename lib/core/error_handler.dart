import 'package:flutter/foundation.dart';

/// Error message constants
class ErrorMessages {
  static const String networkError =
      'Network error. Please check your connection.';
  static const String networkTimeout = 'Request timed out. Please try again.';
  static const String unauthorized = 'Session expired. Please sign in again.';
  static const String forbidden = 'Access denied.';
  static const String notFound = 'Resource not found.';
  static const String invalidInput = 'Invalid input provided.';
  static const String databaseError = 'Database operation failed.';
  static const String unexpectedError = 'An unexpected error occurred.';
}

/// Custom exception classes for the application
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  AppException({
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException({String? message})
      : super(message: message ?? ErrorMessages.networkError);
}

class TimeoutException extends AppException {
  TimeoutException({String? message})
      : super(message: message ?? ErrorMessages.networkTimeout);
}

class UnauthorizedException extends AppException {
  UnauthorizedException({String? message})
      : super(message: message ?? ErrorMessages.unauthorized);
}

class ForbiddenException extends AppException {
  ForbiddenException({String? message})
      : super(message: message ?? ErrorMessages.forbidden);
}

class NotFoundException extends AppException {
  NotFoundException({String? message})
      : super(message: message ?? ErrorMessages.notFound);
}

class ValidationException extends AppException {
  ValidationException({String? message})
      : super(message: message ?? ErrorMessages.invalidInput);
}

class DatabaseException extends AppException {
  DatabaseException({String? message})
      : super(message: message ?? ErrorMessages.databaseError);
}

class CacheException extends AppException {
  CacheException({String? message})
      : super(message: message ?? 'Cache operation failed');
}

/// Central error handler for the application
class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();

  factory ErrorHandler() {
    return _instance;
  }

  ErrorHandler._internal();

  /// Handle network exceptions
  static AppException handleNetworkException(
      dynamic error, StackTrace? stackTrace) {
    if (error is TimeoutException) {
      return TimeoutException();
    } else if (error is NetworkException) {
      return error;
    }
    return NetworkException(message: error.toString());
  }

  /// Handle Firebase exceptions
  static AppException handleFirebaseException(
      dynamic error, StackTrace? stackTrace) {
    final errorString = error.toString();

    if (errorString.contains('permission-denied')) {
      return UnauthorizedException();
    } else if (errorString.contains('not-found')) {
      return NotFoundException();
    } else if (errorString.contains('unauthenticated')) {
      return UnauthorizedException();
    } else if (errorString.contains('invalid-argument')) {
      return ValidationException();
    }

    return DatabaseException(message: errorString);
  }

  /// Handle validation errors
  static AppException handleValidationException(String message) {
    return ValidationException(message: message);
  }

  /// Handle generic exceptions
  static AppException handleException(
    dynamic error,
    StackTrace? stackTrace, {
    String? customMessage,
  }) {
    if (error is AppException) {
      return error;
    }

    final message = customMessage ?? error.toString();

    return AppException(
      message: message.isEmpty ? ErrorMessages.unexpectedError : message,
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// Determine user-friendly message from exception
  static String getUserMessage(AppException exception) {
    if (exception is NetworkException) {
      return ErrorMessages.networkError;
    } else if (exception is TimeoutException) {
      return ErrorMessages.networkTimeout;
    } else if (exception is UnauthorizedException) {
      return ErrorMessages.unauthorized;
    } else if (exception is ForbiddenException) {
      return ErrorMessages.forbidden;
    } else if (exception is NotFoundException) {
      return ErrorMessages.notFound;
    } else if (exception is ValidationException) {
      return exception.message;
    } else if (exception is DatabaseException) {
      return ErrorMessages.databaseError;
    }
    return exception.message.isEmpty
        ? ErrorMessages.unexpectedError
        : exception.message;
  }

  /// Log error to console (development only)
  static void logError(AppException exception) {
    if (kDebugMode) {
      debugPrint('❌ ERROR: ${exception.message}');
      if (exception.code != null) {
        debugPrint('Code: ${exception.code}');
      }
      if (exception.stackTrace != null) {
        debugPrint('${exception.stackTrace}');
      }
    }
  }

  /// Log error with context
  static void logErrorWithContext(
    AppException exception,
    String context,
  ) {
    if (kDebugMode) {
      debugPrint('❌ ERROR in $context: ${exception.message}');
      if (exception.stackTrace != null) {
        debugPrint('${exception.stackTrace}');
      }
    }
  }
}

/// Result wrapper for better error handling
class Result<T> {
  final T? data;
  final AppException? error;
  final bool isSuccess;

  Result({
    this.data,
    this.error,
    this.isSuccess = false,
  });

  factory Result.success(T data) {
    return Result(data: data, isSuccess: true);
  }

  factory Result.failure(AppException error) {
    return Result(error: error, isSuccess: false);
  }

  /// Execute callback on success
  void onSuccess(void Function(T) callback) {
    if (isSuccess && data != null) {
      callback(data as T);
    }
  }

  /// Execute callback on failure
  void onFailure(void Function(AppException) callback) {
    if (!isSuccess && error != null) {
      callback(error!);
    }
  }

  /// Map the result to another type
  Result<R> map<R>(R Function(T) mapper) {
    if (isSuccess && data != null) {
      try {
        return Result.success(mapper(data as T));
      } catch (e, stackTrace) {
        return Result.failure(
          ErrorHandler.handleException(e, stackTrace),
        );
      }
    }
    return Result.failure(error!);
  }

  /// Bind the result to another operation
  Future<Result<R>> asyncMap<R>(Future<R> Function(T) mapper) async {
    if (isSuccess && data != null) {
      try {
        final result = await mapper(data as T);
        return Result.success(result);
      } catch (e, stackTrace) {
        return Result.failure(
          ErrorHandler.handleException(e, stackTrace),
        );
      }
    }
    return Result.failure(error!);
  }

  /// Get error message or null
  String? getErrorMessage() =>
      isSuccess ? null : ErrorHandler.getUserMessage(error!);
}

/// Safe async wrapper
Future<Result<T>> safeAsync<T>(Future<T> Function() operation) async {
  try {
    final result = await operation();
    return Result.success(result);
  } catch (e, stackTrace) {
    return Result.failure(
      ErrorHandler.handleException(e, stackTrace),
    );
  }
}

/// Safe sync wrapper
Result<T> safe<T>(T Function() operation) {
  try {
    final result = operation();
    return Result.success(result);
  } catch (e, stackTrace) {
    return Result.failure(
      ErrorHandler.handleException(e, stackTrace),
    );
  }
}
