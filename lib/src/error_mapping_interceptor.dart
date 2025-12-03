import 'package:api_client/src/app_error.dart';
import 'package:api_client/src/dio_error_mapper.dart';
import 'package:dio/dio.dart';

class ErrorMappingInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final appError = (err.error is AppError)
        ? err.error! as AppError
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
