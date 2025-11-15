# api_client

`api_client` is a small collection of Dio helpers that make it painless to talk to a JWT secured Django REST Framework backend. It wires together:

- a token repository that persists the current access/refresh pair,
- an interceptor that silently refreshes access tokens when they are close to expiring, and
- an error mapper that turns raw DRF responses into a friendly `AppError` model.

The crate stays intentionally small and focuses on predictable behavior. There is no code generation and it is safe to use inside Flutter, Dart CLI tools, and server-side Dart.

## Highlights

- **JWT refresh flow** – refresh requests are single-flight and only retry the original failing request once (`__retried401`).
- **Expiry aware** – refresh kicks in before `exp` is reached (configurable skew) to avoid UI jank.
- **DRF savvy** – understands `detail`, `non_field_errors`, regular fields, and nested arrays so that each error becomes a clear `AppError` instance.
- **Composable** – the interceptors plug into any existing `Dio` instance. Bring your own logging/retry interceptors.
- **Dio 5 support** – uses the latest interceptor APIs and typed responses.

## Installation

Add the package to your workspace. When consuming it from another local package:

```yaml
dependencies:
  api_client:
    path: ../api_client
```

If you plan to share the client, publish it to your private registry and depend on it by version instead of `path`.

## Usage

### Create a client

```dart
import 'package:api_client/api_client.dart';

final tokenRepo = SecureTokenRepository();
final dio = buildApiClient(
  baseUrl: 'https://api.example.com',
  tokenRepository: tokenRepo,
  refreshEndpoint: '/api/v1/users/token/refresh/',
  refreshLeeway: const Duration(seconds: 30),
);
```

### Make requests

```dart
final response = await dio.get<Map<String, dynamic>>('/api/v1/ping/');
print(response.data);
```

### Handle errors

```dart
try {
  await dio.get('/api/v1/protected/');
} on DioException catch (e) {
  final err = e.error;
  if (err is AppError) {
    // e.g. showToast(err.message);
  }
}
```

### Mark public endpoints

```dart
await dio.get(
  '/public/info',
  options: Options(extra: {'requiresToken': false}),
);
```

### Persist tokens after login

```dart
await tokenRepo.saveAccessToken(loginResponse.accessToken);
await tokenRepo.saveRefreshToken(loginResponse.refreshToken);
```

## Interceptor order

If you are composing your own Dio, register interceptors in this order:

1. `TokenInterceptor`
2. `ErrorMappingInterceptor`
3. any logging/analytics interceptors

This ensures requests always have an up-to-date access token before you start logging or reporting them.

## Development

- `lib/src/api_client.dart` exposes `buildApiClient` and the interceptors.
- `lib/src/secure_token_repository.dart` shows the contract expected by the interceptors.
- `example/main.dart` demonstrates a real flow.

Run analyzer/tests as you normally would in a Dart package:

```bash
dart analyze
dart test
```

## License

MIT
