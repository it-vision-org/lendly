import '../../../../core/utils/money.dart';
import '../../../transactions/data/models/transaction.dart';

class DashboardSummary {
  const DashboardSummary({
    required this.totalOwedToMe,
    required this.totalIOwe,
    required this.netBalance,
    required this.activeLentTransactions,
    required this.activeBorrowedTransactions,
    required this.recentTransactions,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      totalOwedToMe: parseAmount(json['totalOwedToMe']),
      totalIOwe: parseAmount(json['totalIOwe']),
      netBalance: parseAmount(json['netBalance']),
      activeLentTransactions: json['activeLentTransactions'] as int,
      activeBorrowedTransactions: json['activeBorrowedTransactions'] as int,
      recentTransactions: (json['recentTransactions'] as List<dynamic>)
          .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final num totalOwedToMe;
  final num totalIOwe;
  final num netBalance;
  final int activeLentTransactions;
  final int activeBorrowedTransactions;
  final List<Transaction> recentTransactions;
}
