sealed class AppError implements Exception {
  const AppError(this.message, {this.statusCode, this.raw});

  factory AppError.network([Object? raw]) =>
      _NetworkError('No internet connection.', raw: raw);

  factory AppError.timeout([Object? raw]) =>
      _TimeoutError('Request timed out. Please try again.', raw: raw);

  factory AppError.cancelled([Object? raw]) =>
      _CancelledError('Request was cancelled.', raw: raw);

  factory AppError.unauthorized([Object? raw, int? code]) => _HttpError(
        'You need to sign in again.',
        statusCode: code ?? 401,
        raw: raw,
      );

  factory AppError.forbidden([Object? raw, int? code]) => _HttpError(
        'You don’t have permission to do that.',
        statusCode: code ?? 403,
        raw: raw,
      );

  factory AppError.notFound([Object? raw, int? code]) =>
      _HttpError('Resource not found.', statusCode: code ?? 404, raw: raw);

  factory AppError.conflict([Object? raw, int? code]) => _HttpError(
        'Conflict. Please refresh and try again.',
        statusCode: code ?? 409,
        raw: raw,
      );

  factory AppError.validation(String message, {Object? raw, int? code}) =>
      _HttpError(message, statusCode: code ?? 400, raw: raw);

  factory AppError.server([Object? raw, int? code]) => _HttpError(
        'Server error. Please try again later.',
        statusCode: code ?? 500,
        raw: raw,
      );

  factory AppError.unknown([Object? raw, int? code]) => _HttpError(
        'Something went wrong. Please try again.',
        statusCode: code,
        raw: raw,
      );
  final String message;
  final int? statusCode;
  final Object? raw;

  @override
  String toString() => message;
}

class _HttpError extends AppError {
  const _HttpError(super.message, {super.statusCode, super.raw});
}

class _NetworkError extends AppError {
  const _NetworkError(super.message, {super.raw}) : super(statusCode: null);
}

class _TimeoutError extends AppError {
  const _TimeoutError(super.message, {super.raw}) : super(statusCode: null);
}

class _CancelledError extends AppError {
  const _CancelledError(super.message, {super.raw}) : super(statusCode: null);
}
