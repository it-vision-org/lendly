import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../transactions/data/models/transaction.dart';
import '../../../transactions/data/repositories/transaction_repository.dart';
import '../../data/models/dashboard_summary.dart';
import '../../data/repositories/dashboard_repository.dart';

final dashboardControllerProvider =
    AsyncNotifierProvider.autoDispose<DashboardController, DashboardSummary>(
      DashboardController.new,
    );

class DashboardController extends AsyncNotifier<DashboardSummary> {
  @override
  FutureOr<DashboardSummary> build() {
    return ref.watch(dashboardRepositoryProvider).get();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(dashboardRepositoryProvider).get(),
    );
  }
}

enum RecentTransactionsFilter {
  active,
  paid,
  all;

  String get label => switch (this) {
    RecentTransactionsFilter.active => 'Active',
    RecentTransactionsFilter.paid => 'Paid',
    RecentTransactionsFilter.all => 'All',
  };
}

final recentTransactionsFilterProvider =
    StateProvider.autoDispose<RecentTransactionsFilter>(
      (ref) => RecentTransactionsFilter.active,
    );

const _recentTransactionsLimit = 5;

/// The "Recent transactions" list on the home page — independent of
/// [DashboardSummary.recentTransactions] (which is always the unfiltered
/// top 5) so the user can switch between active/paid/all without affecting
/// the balance cards above it.
final recentTransactionsProvider =
    FutureProvider.autoDispose<List<Transaction>>((ref) async {
      final filter = ref.watch(recentTransactionsFilterProvider);
      final transactions = await ref
          .watch(transactionRepositoryProvider)
          .list();

      final filtered = switch (filter) {
        RecentTransactionsFilter.active => transactions.where((t) => !t.isPaid),
        RecentTransactionsFilter.paid => transactions.where((t) => t.isPaid),
        RecentTransactionsFilter.all => transactions,
      };

      return filtered.take(_recentTransactionsLimit).toList();
    });
