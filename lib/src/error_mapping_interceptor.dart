import 'package:dio/dio.dart';
import 'dio_error_mapper.dart';
import 'app_error.dart';

class ErrorMappingInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final appError = (err.error is AppError)
        ? err.error as AppError
        : DioErrorMapper.fromDio(err);

    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: appError,
        message: appError.message,
      ),
    );
  }
}
