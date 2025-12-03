import 'package:api_client/src/jwt_utils.dart';
import 'package:api_client/src/token_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureTokenRepository implements TokenRepository {
  SecureTokenRepository({
    SharedPreferences? preferences,
    this.accessKey = 'auth.access',
    this.refreshKey = 'auth.refresh',
  }) : _preferences = preferences;

  SharedPreferences? _preferences;
  final String accessKey;
  final String refreshKey;

  Future<SharedPreferences> _prefs() async =>
      _preferences ??= await SharedPreferences.getInstance();

  @override
  Future<String?> getAccessToken() async {
    final prefs = await _prefs();
    return prefs.getString(accessKey);
  }

  @override
  Future<String?> getRefreshToken() async {
    final prefs = await _prefs();
    return prefs.getString(refreshKey);
  }

  @override
  Future<void> saveAccessToken(String token) async {
    final prefs = await _prefs();
    await prefs.setString(accessKey, token);
  }

  @override
  Future<void> saveRefreshToken(String token) async {
    final prefs = await _prefs();
    await prefs.setString(refreshKey, token);
  }

  @override
  Future<void> clearTokens() async {
    final prefs = await _prefs();
    await prefs.remove(accessKey);
    await prefs.remove(refreshKey);
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
