import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/environment.dart';
import '../storage/token_storage.dart';

/// Bare Dio instance with no auth interceptor, used only to call
/// `/auth/refresh` from within [_AuthInterceptor] without recursing back
/// into itself.
final _rawDioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      baseUrl: Environment.apiBaseUrl,
      // Generous timeouts: the hosted backend is on Render's free tier, which
      // spins the service down when idle and can take up to ~60s to wake up
      // on the next request.
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 90),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );
});

final dioProvider = Provider<Dio>((ref) {
  final rawDio = ref.watch(_rawDioProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);

  final dio = Dio(rawDio.options);
  dio.interceptors.add(_AuthInterceptor(rawDio, tokenStorage));

  if (kDebugMode) {
    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  }

  return dio;
});

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._dio, this._tokenStorage);

  final Dio _dio;
  final TokenStorage _tokenStorage;
  Future<StoredTokens?>? _refreshInFlight;

  // Only these are callable without a token (they're what get someone from
  // signed-out to signed-in); every other endpoint — including /auth/me — is
  // an authenticated call and must get the Authorization header (a blanket
  // "any /auth/ path" check used to strip it from those too, which silently
  // made them anonymous requests).
  static const _publicAuthPaths = {
    '/auth/register',
    '/auth/login',
    '/auth/refresh',
    '/auth/email-verification/verify',
    '/auth/email-verification/resend',
  };

  bool _isPublicAuthPath(String path) =>
      _publicAuthPaths.any((p) => path.endsWith(p));

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isPublicAuthPath(options.path)) {
      final tokens = await _tokenStorage.read();
      if (tokens != null) {
        options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final isAuthCall = _isPublicAuthPath(err.requestOptions.path);
    if (err.response?.statusCode != 401 || isAuthCall) {
      handler.next(err);
      return;
    }

    final refreshed = await _refreshTokens();
    if (refreshed == null) {
      handler.next(err);
      return;
    }

    try {
      final retryOptions = err.requestOptions;
      retryOptions.headers['Authorization'] = 'Bearer ${refreshed.accessToken}';
      final response = await _dio.fetch(retryOptions);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  Future<StoredTokens?> _refreshTokens() {
    // Coalesce concurrent 401s into a single refresh call.
    return _refreshInFlight ??= _doRefresh().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<StoredTokens?> _doRefresh() async {
    final current = await _tokenStorage.read();
    if (current == null) {
      return null;
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': current.refreshToken},
      );

      final data = response.data;
      if (data == null) {
        return null;
      }

      final tokens = StoredTokens(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );
      await _tokenStorage.save(tokens);
      return tokens;
    } on DioException {
      await _tokenStorage.clear();
      return null;
    }
  }
}
