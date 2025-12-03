import 'package:api_client/src/dio_setup.dart';
import 'package:api_client/src/secure_token_repository.dart';
import 'package:api_client/src/token_repository.dart';
import 'package:dio/dio.dart';

/// Convenience wrapper that wires up [Dio] with sensible defaults so that
/// callers can just do `ApiClient(baseUrl: ...).dio.get(...)`.
class ApiClient {
  factory ApiClient({
    required String baseUrl,
    TokenRepository? tokenRepository,
    String refreshEndpoint = '/api/v1/users/token/refresh/',
    Duration connectTimeout = const Duration(seconds: 15),
    Duration receiveTimeout = const Duration(seconds: 20),
  }) {
    final normalizedBaseUrl = baseUrl.trim();
    if (normalizedBaseUrl.isEmpty) {
      throw ArgumentError.value(baseUrl, 'baseUrl', 'must not be empty');
    }

    final repo = tokenRepository ?? SecureTokenRepository();
    final client = buildApiClient(
      baseUrl: normalizedBaseUrl,
      tokenRepository: repo,
      refreshEndpoint: refreshEndpoint,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
    );

    return ApiClient._(
      dio: client,
      baseUrl: normalizedBaseUrl,
      repository: repo,
    );
  }

  ApiClient._({
    required this.dio,
    required this.baseUrl,
    required TokenRepository repository,
  }) : tokenRepository = repository;

  /// Configured [Dio] instance with token + error interceptors installed.
  final Dio dio;

  /// Base URL used to initialise the client.
  final String baseUrl;

  /// Token storage backing the client.
  final TokenRepository tokenRepository;

  /// Helper to persist both tokens (e.g., right after login).
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await tokenRepository.saveAccessToken(accessToken);
    await tokenRepository.saveRefreshToken(refreshToken);
  }

  /// Clears all persisted auth tokens.
  Future<void> clearTokens() => tokenRepository.clearTokens();
}
