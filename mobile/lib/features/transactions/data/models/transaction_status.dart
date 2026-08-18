enum TransactionStatus {
  active,
  partiallyPaid,
  paid;

  String get apiValue => switch (this) {
        TransactionStatus.active => 'ACTIVE',
        TransactionStatus.partiallyPaid => 'PARTIALLY_PAID',
        TransactionStatus.paid => 'PAID',
      };

  String get label => switch (this) {
        TransactionStatus.active => 'Active',
        TransactionStatus.partiallyPaid => 'Partially paid',
        TransactionStatus.paid => 'Paid',
      };

  static TransactionStatus fromApiValue(String value) {
    return switch (value) {
      'ACTIVE' => TransactionStatus.active,
      'PARTIALLY_PAID' => TransactionStatus.partiallyPaid,
      'PAID' => TransactionStatus.paid,
      _ => throw ArgumentError('Unknown transaction status: $value'),
    };
  }
}
