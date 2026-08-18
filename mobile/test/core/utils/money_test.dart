import 'package:lendly/core/utils/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatMoney', () {
    test('formats a whole amount without decimals', () {
      expect(formatMoney(120, 'TND'), '120 TND');
    });

    test('adds thousands separators', () {
      expect(formatMoney(1250, 'TND'), '1,250 TND');
    });

    test('keeps a fractional amount', () {
      expect(formatMoney(99.5, 'TND'), '99.5 TND');
    });
  });

  group('parseAmount', () {
    test('passes through a num', () {
      expect(parseAmount(42), 42);
    });

    test('parses a numeric string', () {
      expect(parseAmount('42.50'), 42.50);
    });
  });
}
