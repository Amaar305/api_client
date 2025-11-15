import 'package:dio/dio.dart';
import 'token_interceptor.dart';
import 'token_repository.dart';
import 'error_mapping_interceptor.dart';

Dio buildApiClient({
  required String baseUrl,
  required TokenRepository tokenRepository,
  String refreshEndpoint = '/api/v1/users/token/refresh/',
  Duration connectTimeout = const Duration(seconds: 15),
  Duration receiveTimeout = const Duration(seconds: 20),
}) {
  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: connectTimeout,
    receiveTimeout: receiveTimeout,
  ));

  dio.interceptors.addAll([
    TokenInterceptor(
      dio: dio,
      tokenRepository: tokenRepository,
      refreshEndpoint: refreshEndpoint,
    ),
    ErrorMappingInterceptor(),
  ]);

  return dio;
}