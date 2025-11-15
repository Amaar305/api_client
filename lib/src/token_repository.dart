abstract class TokenRepository {
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> saveAccessToken(String token);
  Future<void> saveRefreshToken(String token);
  Future<void> clearTokens();
  Future<bool> isAccessExpired({Duration skew = const Duration(seconds: 30)});
  Future<bool> isRefreshExpired({Duration skew = const Duration(seconds: 30)});
}