import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/user_summary.dart';
import '../../data/repositories/auth_repository.dart';

final authControllerProvider =
    AsyncNotifierProvider<AuthController, UserSummary?>(AuthController.new);

class AuthController extends AsyncNotifier<UserSummary?> {
  @override
  FutureOr<UserSummary?> build() {
    return ref.watch(authRepositoryProvider).restoreSession();
  }

  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).register(
            firstName: firstName,
            lastName: lastName,
            email: email,
            password: password,
          ),
    );
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).login(email: email, password: password),
    );
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }
}
