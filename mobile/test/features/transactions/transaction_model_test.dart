import 'package:lendly/features/transactions/data/models/transaction.dart';
import 'package:lendly/features/transactions/data/models/transaction_status.dart';
import 'package:lendly/features/transactions/data/models/transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Transaction.fromJson', () {
    test('parses a LENT transaction from the backend response shape', () {
      final transaction = Transaction.fromJson({
        'id': 't-1',
        'contactId': 'c-1',
        'contactName': 'Sami',
        'type': 'LENT',
        'originalAmount': 300,
        'remainingAmount': 200,
        'currency': 'TND',
        'description': 'Restaurant payment',
        'transactionDate': '2026-08-18',
        'status': 'PARTIALLY_PAID',
        'createdAt': '2026-08-18T12:00:00Z',
        'updatedAt': '2026-08-18T12:30:00Z',
      });

      expect(transaction.type, TransactionType.lent);
      expect(transaction.status, TransactionStatus.partiallyPaid);
      expect(transaction.remainingAmount, 200);
      expect(transaction.isPaid, isFalse);
    });

    test('a fully paid transaction reports isPaid', () {
      final transaction = Transaction.fromJson({
        'id': 't-2',
        'contactId': 'c-1',
        'contactName': 'Youssef',
        'type': 'BORROWED',
        'originalAmount': 80,
        'remainingAmount': 0,
        'currency': 'TND',
        'description': null,
        'transactionDate': '2026-08-16',
        'status': 'PAID',
        'createdAt': '2026-08-16T09:00:00Z',
        'updatedAt': '2026-08-17T09:00:00Z',
      });

      expect(transaction.isPaid, isTrue);
    });
  });
}
