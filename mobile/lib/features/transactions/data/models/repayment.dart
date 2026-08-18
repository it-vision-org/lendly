import '../../../../core/utils/money.dart';

class Repayment {
  const Repayment({
    required this.id,
    required this.transactionId,
    required this.amount,
    required this.paymentDate,
    required this.notes,
    required this.createdAt,
  });

  factory Repayment.fromJson(Map<String, dynamic> json) {
    return Repayment(
      id: json['id'] as String,
      transactionId: json['transactionId'] as String,
      amount: parseAmount(json['amount']),
      paymentDate: DateTime.parse(json['paymentDate'] as String),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  final String id;
  final String transactionId;
  final num amount;
  final DateTime paymentDate;
  final String? notes;
  final DateTime createdAt;
}
