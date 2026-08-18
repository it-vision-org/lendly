import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/repayment.dart';
import '../../data/models/transaction.dart';
import '../../data/repositories/transaction_repository.dart';

class TransactionDetail {
  const TransactionDetail({required this.transaction, required this.repayments});

  final Transaction transaction;
  final List<Repayment> repayments;
}

final transactionDetailProvider =
    FutureProvider.autoDispose.family<TransactionDetail, String>((ref, id) async {
  final repo = ref.watch(transactionRepositoryProvider);
  final transaction = await repo.get(id);
  final repayments = await repo.listRepayments(id);
  return TransactionDetail(transaction: transaction, repayments: repayments);
});
