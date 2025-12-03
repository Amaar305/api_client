import 'package:api_client/src/app_error.dart';
import 'package:api_client/src/drf_error_parser.dart';
import 'package:dio/dio.dart';

class DioErrorMapper {
  static AppError fromDio(Object error) {
    if (error is! DioException) {
      return AppError.unknown(error);
    }

    final e = error;
    final status = e.response?.statusCode;
    final data = e.response?.data;

    switch (e.type) {
      case DioExceptionType.connectionError:
        return AppError.network(e);
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AppError.timeout(e);
      case DioExceptionType.cancel:
        return AppError.cancelled(e);
      case DioExceptionType.badCertificate:
        return AppError.unknown(e, status);
      case DioExceptionType.unknown:
        return AppError.network(e);
      case DioExceptionType.badResponse:
        break;
    }

    final backendMsg = DrfErrorParser.parse(data).trim();

    if (status != null) {
      if (status == 401) {
        return backendMsg.isNotEmpty
            ? AppError.validation(backendMsg, raw: e, code: status)
            : AppError.unauthorized(e, status);
      }
      if (status == 403) {
        return backendMsg.isNotEmpty
            ? AppError.validation(backendMsg, raw: e, code: status)
            : AppError.forbidden(e, status);
      }
      if (status == 404) {
        return backendMsg.isNotEmpty
            ? AppError.validation(backendMsg, raw: e, code: status)
            : AppError.notFound(e, status);
      }
      if (status == 409) {
        return backendMsg.isNotEmpty
            ? AppError.validation(backendMsg, raw: e, code: status)
            : AppError.conflict(e, status);
      }
      if (status >= 400 && status < 500) {
        return AppError.validation(
          backendMsg.isNotEmpty ? backendMsg : 'Invalid request.',
          raw: e,
          code: status,
        );
      }
      if (status >= 500) {
        return backendMsg.isNotEmpty
            ? AppError.validation(backendMsg, raw: e, code: status)
            : AppError.server(e, status);
      }
    }

    return backendMsg.isNotEmpty
        ? AppError.validation(backendMsg, raw: e, code: status)
        : AppError.unknown(e, status);
  }
}
