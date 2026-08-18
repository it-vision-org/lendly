import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/dashboard_summary.dart';
import '../../data/repositories/dashboard_repository.dart';

final dashboardControllerProvider =
    AsyncNotifierProvider.autoDispose<DashboardController, DashboardSummary>(DashboardController.new);

class DashboardController extends AsyncNotifier<DashboardSummary> {
  @override
  FutureOr<DashboardSummary> build() {
    return ref.watch(dashboardRepositoryProvider).get();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(dashboardRepositoryProvider).get());
  }
}
