import 'package:api_client/src/jwt_utils.dart';
import 'package:api_client/src/token_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureTokenRepository implements TokenRepository {
  SecureTokenRepository({
    FlutterSecureStorage? storage,
    this.accessKey = 'auth.access',
    this.refreshKey = 'auth.refresh',
  }) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  final String accessKey;
  final String refreshKey;

  @override
  Future<String?> getAccessToken() => _storage.read(key: accessKey);

  @override
  Future<String?> getRefreshToken() => _storage.read(key: refreshKey);

  @override
  Future<void> saveAccessToken(String token) =>
      _storage.write(key: accessKey, value: token);

  @override
  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: refreshKey, value: token);

  @override
  Future<void> clearTokens() async {
    await _storage.delete(key: accessKey);
    await _storage.delete(key: refreshKey);
  }

  @override
  Future<bool> isAccessExpired({
    Duration skew = const Duration(seconds: 30),
  }) async {
    final t = await getAccessToken();
    return _isExpiredToken(t, skew);
  }

  @override
  Future<bool> isRefreshExpired({
    Duration skew = const Duration(seconds: 30),
  }) async {
    final t = await getRefreshToken();
    return _isExpiredToken(t, skew);
  }

  bool _isExpiredToken(String? token, Duration skew) {
    if (token == null || token.isEmpty) return true;
    final exp = JwtUtils.tryGetExp(token);
    if (exp == null) return true;
    final nowSec = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    final skewSec = skew.inSeconds;
    return (exp - skewSec) <= nowSec;
  }
}
