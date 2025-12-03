import 'dart:convert';

class JwtUtils {
  static Map<String, dynamic>? tryDecodePayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = _base64UrlDecode(parts[1]);
      final map = json.decode(payload);
      if (map is Map<String, dynamic>) return map;
      return null;
    } catch (_) {
      return null;
    }
  }

  static int? tryGetExp(String token) {
    final payload = tryDecodePayload(token);
    final exp = payload?['exp'];
    if (exp is int) return exp;
    if (exp is num) return exp.toInt();
    return null;
  }

  static String _base64UrlDecode(String input) {
    var output = input.replaceAll('-', '+').replaceAll('_', '/');
    switch (output.length % 4) {
      case 0:
        break;
      case 2:
        output += '==';
      case 3:
        output += '=';
      default:
        throw const FormatException('Invalid Base64Url');
    }
    return utf8.decode(base64.decode(output));
  }
}
