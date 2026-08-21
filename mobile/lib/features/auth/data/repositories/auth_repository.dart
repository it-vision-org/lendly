import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/email_verification_challenge.dart';
import '../models/login_result.dart';
import '../models/user_summary.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(dioProvider),
    ref.watch(tokenStorageProvider),
  );
});

class AuthRepository {
  AuthRepository(this._dio, this._tokenStorage);

  final Dio _dio;
  final TokenStorage _tokenStorage;

  /// Starts signup. No session is created yet — the account is unverified
  /// until [verifyEmail] succeeds with the code sent to [email].
  Future<EmailVerificationChallenge> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/register',
        data: {'fullName': fullName, 'email': email, 'password': password},
      );
      return EmailVerificationChallenge.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<UserSummary> updateProfile({required String fullName}) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/auth/me',
        data: {'fullName': fullName},
      );
      return UserSummary.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _dio.patch<void>(
        '/auth/me/password',
        data: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Always succeeds from the caller's point of view whether or not the
  /// email belongs to an account — that's the backend's account-enumeration
  /// protection, so there is nothing to branch on here.
  Future<void> requestPasswordReset({required String email}) async {
    try {
      await _dio.post<void>(
        '/auth/password-reset/request',
        data: {'email': email},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> resendPasswordResetCode({required String email}) async {
    try {
      await _dio.post<void>(
        '/auth/password-reset/resend',
        data: {'email': email},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<String> verifyPasswordResetCode({
    required String email,
    required String code,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/password-reset/verify',
        data: {'email': email, 'code': code},
      );
      return response.data!['resetToken'] as String;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<UserSummary> completePasswordReset({
    required String resetToken,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/password-reset/complete',
        data: {
          'resetToken': resetToken,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        },
      );
      return _saveTokensAndReturnUser(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Returns [LoginResult.authenticated] with tokens saved on success, or
  /// [LoginResult.verificationRequired] (no tokens saved) if the password was
  /// correct but the account still needs email verification.
  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
          'deviceInfo': 'flutter-app',
        },
      );
      final data = response.data!;
      final authJson = data['auth'] as Map<String, dynamic>?;
      if (authJson != null) {
        final user = await _saveTokensAndReturnUser(authJson);
        return LoginResult.authenticated(user);
      }
      final verificationJson = data['verification'] as Map<String, dynamic>;
      return LoginResult.verificationRequired(
        EmailVerificationChallenge.fromJson(verificationJson),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<UserSummary> verifyEmail({
    required String verificationId,
    required String code,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/email-verification/verify',
        data: {
          'verificationId': verificationId,
          'code': code,
          'deviceInfo': 'flutter-app',
        },
      );
      return _saveTokensAndReturnUser(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<EmailVerificationChallenge> resendVerificationCode({
    required String verificationId,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/email-verification/resend',
        data: {'verificationId': verificationId},
      );
      return EmailVerificationChallenge.fromJson(response.data!);
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
        await _dio.post<void>(
          '/auth/logout',
          data: {'refreshToken': tokens.refreshToken},
        );
      } on DioException {
        // Best effort: still clear local tokens even if the server call fails.
      }
    }
    await _tokenStorage.clear();
  }

  Future<UserSummary> _saveTokensAndReturnUser(
    Map<String, dynamic> data,
  ) async {
    await _tokenStorage.save(
      StoredTokens(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      ),
    );
    return UserSummary.fromJson(data['user'] as Map<String, dynamic>);
  }
}
