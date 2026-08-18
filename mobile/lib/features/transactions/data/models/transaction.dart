import '../../../../core/utils/money.dart';
import 'transaction_status.dart';
import 'transaction_type.dart';

class Transaction {
  const Transaction({
    required this.id,
    required this.contactId,
    required this.contactName,
    required this.type,
    required this.originalAmount,
    required this.remainingAmount,
    required this.currency,
    required this.description,
    required this.transactionDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      contactId: json['contactId'] as String,
      contactName: json['contactName'] as String,
      type: TransactionType.fromApiValue(json['type'] as String),
      originalAmount: parseAmount(json['originalAmount']),
      remainingAmount: parseAmount(json['remainingAmount']),
      currency: json['currency'] as String,
      description: json['description'] as String?,
      transactionDate: DateTime.parse(json['transactionDate'] as String),
      status: TransactionStatus.fromApiValue(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  final String id;
  final String contactId;
  final String contactName;
  final TransactionType type;
  final num originalAmount;
  final num remainingAmount;
  final String currency;
  final String? description;
  final DateTime transactionDate;
  final TransactionStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isPaid => status == TransactionStatus.paid;
}
