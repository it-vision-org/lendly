import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../data/models/transaction.dart';
import '../../data/models/transaction_status.dart';
import '../../data/models/transaction_type.dart';
import '../../data/repositories/transaction_repository.dart';

enum TransactionFilterTab { all, lent, borrowed, paid }

final transactionsFilterProvider = StateProvider.autoDispose<TransactionFilterTab>(
  (ref) => TransactionFilterTab.all,
);

final transactionsControllerProvider =
    AsyncNotifierProvider.autoDispose<TransactionsController, List<Transaction>>(TransactionsController.new);

class TransactionsController extends AsyncNotifier<List<Transaction>> {
  @override
  FutureOr<List<Transaction>> build() {
    final filter = ref.watch(transactionsFilterProvider);
    return _fetch(filter);
  }

  Future<List<Transaction>> _fetch(TransactionFilterTab filter) {
    final repo = ref.read(transactionRepositoryProvider);
    return switch (filter) {
      TransactionFilterTab.all => repo.list(),
      TransactionFilterTab.lent => repo.list(type: TransactionType.lent),
      TransactionFilterTab.borrowed => repo.list(type: TransactionType.borrowed),
      TransactionFilterTab.paid => repo.list(status: TransactionStatus.paid),
    };
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(ref.read(transactionsFilterProvider)));
  }
}

/// A single contact's transaction history, for the contact detail screen.
final contactTransactionsProvider =
    FutureProvider.autoDispose.family<List<Transaction>, String>((ref, contactId) {
  return ref.watch(transactionRepositoryProvider).list(contactId: contactId);
});
