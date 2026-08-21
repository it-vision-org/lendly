enum TransactionType {
  lent,
  borrowed;

  String get apiValue => switch (this) {
    TransactionType.lent => 'LENT',
    TransactionType.borrowed => 'BORROWED',
  };

  String get label => switch (this) {
    TransactionType.lent => 'I lent',
    TransactionType.borrowed => 'I borrowed',
  };

  static TransactionType fromApiValue(String value) {
    return switch (value) {
      'LENT' => TransactionType.lent,
      'BORROWED' => TransactionType.borrowed,
      _ => throw ArgumentError('Unknown transaction type: $value'),
    };
  }
}
