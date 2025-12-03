import 'package:api_client/api_client.dart';
import 'package:flutter/foundation.dart';

void main() async {
  final client = ApiClient(
    baseUrl: 'http://127.0.0.1:8000',
    tokenRepository: SecureTokenRepository(),
  );

  try {
    final res = await client.dio.post<Map<String, dynamic>>(
      '/api/v1/promotions/promotions/',
      data: {
        'post_id': 'abc123',
        'budget_kobo': 100000,
        'duration_days': 7,
        'action_type': 'website',
        'target_audience_id': 1,
        'products': [
          {'id': 42, 'name': 'Sample'},
        ],
      },
    );
    if (kDebugMode) {
      print('OK ${res.data}');
    }
  } on DioException catch (e) {
    final err = e.error;
    if (err is AppError) {
      if (kDebugMode) {
        print('AppError: ${err.message} (${err.statusCode})');
      }
    } else {
      if (kDebugMode) {
        print('Unhandled: ${e.message}');
      }
    }
  }
}
