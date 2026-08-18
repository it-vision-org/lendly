import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/user_summary.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider), ref.watch(tokenStorageProvider));
});

class AuthRepository {
  AuthRepository(this._dio, this._tokenStorage);

  final Dio _dio;
  final TokenStorage _tokenStorage;

  Future<UserSummary> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/register',
        data: {
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'password': password,
          'deviceInfo': 'flutter-app',
        },
      );
      return _saveTokensAndReturnUser(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<UserSummary> login({required String email, required String password}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'email': email, 'password': password, 'deviceInfo': 'flutter-app'},
      );
      return _saveTokensAndReturnUser(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<UserSummary?> restoreSession() async {
    final tokens = await _tokenStorage.read();
    if (tokens == null) {
      return null;
    }

    try {
      final response = await _dio.get<Map<String, dynamic>>('/auth/me');
      return UserSummary.fromJson(response.data!);
    } on DioException catch (e) {
      final apiException = ApiException.fromDioException(e);
      if (apiException.isUnauthorized) {
        await _tokenStorage.clear();
        return null;
      }
      rethrow;
    }
  }

  Future<void> logout() async {
    final tokens = await _tokenStorage.read();
    if (tokens != null) {
      try {
        await _dio.post<void>('/auth/logout', data: {'refreshToken': tokens.refreshToken});
      } on DioException {
        // Best effort: still clear local tokens even if the server call fails.
      }
    }
    await _tokenStorage.clear();
  }

  Future<UserSummary> _saveTokensAndReturnUser(Map<String, dynamic> data) async {
    await _tokenStorage.save(
      StoredTokens(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      ),
    );
    return UserSummary.fromJson(data['user'] as Map<String, dynamic>);
  }
}
