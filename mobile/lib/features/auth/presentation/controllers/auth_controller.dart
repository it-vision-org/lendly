import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/email_verification_challenge.dart';
import '../../data/models/login_result.dart';
import '../../data/models/user_summary.dart';
import '../../data/repositories/auth_repository.dart';

final authControllerProvider =
    AsyncNotifierProvider<AuthController, UserSummary?>(AuthController.new);

/// Tracks the current session (null = signed out). Signup and an
/// unverified-account login intentionally don't touch [state] — no session
/// exists yet in either case, and doing so would transiently clear
/// [AsyncValue.hasValue], which the router's splash-redirect logic treats as
/// "still initializing."
class AuthController extends AsyncNotifier<UserSummary?> {
  @override
  FutureOr<UserSummary?> build() {
    return ref.watch(authRepositoryProvider).restoreSession();
  }

  Future<EmailVerificationChallenge> register({
    required String fullName,
    required String email,
    required String password,
  }) {
    return ref
        .read(authRepositoryProvider)
        .register(fullName: fullName, email: email, password: password);
  }

  Future<void> updateProfile({required String fullName}) async {
    final user = await ref
        .read(authRepositoryProvider)
        .updateProfile(fullName: fullName);
    state = AsyncData(user);
  }

  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    final result = await ref
        .read(authRepositoryProvider)
        .login(email: email, password: password);
    if (!result.requiresVerification) {
      state = AsyncData(result.user);
    }
    return result;
  }

  Future<void> verifyEmail({
    required String verificationId,
    required String code,
  }) async {
    final user = await ref
        .read(authRepositoryProvider)
        .verifyEmail(verificationId: verificationId, code: code);
    state = AsyncData(user);
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }
}
