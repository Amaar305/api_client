import 'package:dio/dio.dart';
import 'refresh_coordinator.dart';
import 'token_repository.dart';

class TokenInterceptor extends Interceptor {
  TokenInterceptor({
    required this.dio,
    required this.tokenRepository,
    required this.refreshEndpoint,
  }) : _coord = RefreshCoordinator();

  final Dio dio;
  final TokenRepository tokenRepository;
  final String refreshEndpoint;
  final RefreshCoordinator _coord;

  static const _requiresTokenKey = 'requiresToken';
  static const _retriedKey = '__retried401';

  bool _isRefreshCall(RequestOptions opts) {
    final url = (opts.baseUrl.isEmpty ? '' : opts.baseUrl) + opts.path;
    return url.endsWith(refreshEndpoint) || opts.path.endsWith(refreshEndpoint);
  }

  Future<String?> _getAccessToken() => tokenRepository.getAccessToken();
  Future<String?> _getRefreshToken() => tokenRepository.getRefreshToken();

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final requiresToken = options.extra[_requiresTokenKey] as bool? ?? true;

    if (requiresToken && !_isRefreshCall(options)) {
      final accessExpired = await tokenRepository.isAccessExpired();
      final refreshExpired = await tokenRepository.isRefreshExpired();

      if (accessExpired && !refreshExpired) {
        await _coord.runOnce(() async {
          final rt = await _getRefreshToken();
          if (rt == null || rt.isEmpty) return;
          final res = await dio.post<Map<String, dynamic>>(
            refreshEndpoint,
            data: {'refresh': rt},
            options: Options(
                extra: {_requiresTokenKey: false},
                headers: {'Authorization': ''}),
          );
          final newAccess = (res.data?['access'] as String?)?.trim();
          if (newAccess != null && newAccess.isNotEmpty) {
            await tokenRepository.saveAccessToken(newAccess);
          }
        });
      }

      final access = await _getAccessToken();
      if (access != null && access.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $access';
      } else {
        options.headers.remove('Authorization');
      }
    } else if (!requiresToken) {
      options.headers.remove('Authorization');
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode ?? 0;
    final req = err.requestOptions;

    final requiresToken = req.extra[_requiresTokenKey] as bool? ?? true;
    final alreadyRetried = req.extra[_retriedKey] == true;

    if (status != 401 || !requiresToken || _isRefreshCall(req)) {
      handler.next(err);
      return;
    }

    final refresh = await _getRefreshToken();
    if (refresh == null || refresh.isEmpty) {
      await tokenRepository.clearTokens();
      handler.next(err);
      return;
    }

    if (alreadyRetried) {
      handler.next(err);
      return;
    }

    try {
      await _coord.runOnce(() async {
        final rt = await _getRefreshToken();
        if (rt == null || rt.isEmpty) {
          throw DioException(
            requestOptions: req,
            message: 'Missing refresh token',
            type: DioExceptionType.badResponse,
            response: err.response,
          );
        }

        final res = await dio.post<Map<String, dynamic>>(
          refreshEndpoint,
          data: {'refresh': rt},
          options: Options(
              extra: {_requiresTokenKey: false},
              headers: {'Authorization': ''}),
        );

        final newAccess = (res.data?['access'] as String?)?.trim();
        if (newAccess == null || newAccess.isEmpty) {
          throw DioException(
            requestOptions: req,
            message: 'Refresh succeeded but no access token returned',
            type: DioExceptionType.badResponse,
            response: err.response,
          );
        }

        await tokenRepository.saveAccessToken(newAccess);
      });

      req.extra[_retriedKey] = true;

      final access = await _getAccessToken();
      if ((req.extra[_requiresTokenKey] as bool? ?? true) &&
          access != null &&
          access.isNotEmpty) {
        req.headers['Authorization'] = 'Bearer $access';
      } else {
        req.headers.remove('Authorization');
      }

      final response = await dio.fetch(req);
      handler.resolve(response);
    } catch (refreshErr, _) {
      _coord.failAll(refreshErr);
      await tokenRepository.clearTokens();
      handler.next(err);
    }
  }
}
