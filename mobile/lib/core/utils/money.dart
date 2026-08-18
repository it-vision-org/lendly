import 'package:intl/intl.dart';

final _amountFormat = NumberFormat('#,##0.##');

/// Formats an amount for display, e.g. `120 TND`, `1,250 TND`.
String formatMoney(num amount, String currency) {
  return '${_amountFormat.format(amount)} $currency';
}

num parseAmount(dynamic value) {
  if (value is num) return value;
  return num.parse(value as String);
}
