import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../contacts/data/models/contact.dart';
import '../../data/models/transaction.dart';
import '../../data/models/transaction_status.dart';
import '../../data/models/transaction_type.dart';
import '../../data/repositories/transaction_repository.dart';

enum TransactionFilterTab { all, lent, borrowed, paid }

final transactionsFilterProvider =
    StateProvider.autoDispose<TransactionFilterTab>(
      (ref) => TransactionFilterTab.all,
    );

/// The contact the transactions list is narrowed to (`null` = all contacts).
/// Combines with [transactionsFilterProvider].
final transactionsContactFilterProvider = StateProvider.autoDispose<Contact?>(
  (ref) => null,
);

final transactionsControllerProvider =
    AsyncNotifierProvider.autoDispose<
      TransactionsController,
      List<Transaction>
    >(TransactionsController.new);

class TransactionsController extends AsyncNotifier<List<Transaction>> {
  @override
  FutureOr<List<Transaction>> build() {
    final filter = ref.watch(transactionsFilterProvider);
    final contact = ref.watch(transactionsContactFilterProvider);
    return _fetch(filter, contact?.id);
  }

  Future<List<Transaction>> _fetch(
    TransactionFilterTab filter,
    String? contactId,
  ) {
    final repo = ref.read(transactionRepositoryProvider);
    return switch (filter) {
      TransactionFilterTab.all => repo.list(contactId: contactId),
      TransactionFilterTab.lent => repo.list(
        type: TransactionType.lent,
        contactId: contactId,
      ),
      TransactionFilterTab.borrowed => repo.list(
        type: TransactionType.borrowed,
        contactId: contactId,
      ),
      TransactionFilterTab.paid => repo.list(
        status: TransactionStatus.paid,
        contactId: contactId,
      ),
    };
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _fetch(
        ref.read(transactionsFilterProvider),
        ref.read(transactionsContactFilterProvider)?.id,
      ),
    );
  }
}

/// A single contact's transaction history, for the contact detail screen.
final contactTransactionsProvider = FutureProvider.autoDispose
    .family<List<Transaction>, String>((ref, contactId) {
      return ref
          .watch(transactionRepositoryProvider)
          .list(contactId: contactId);
    });
