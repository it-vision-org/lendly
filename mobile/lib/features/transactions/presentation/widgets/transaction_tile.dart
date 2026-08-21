import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_semantic_colors.dart';
import '../../../../core/utils/money.dart';
import '../../data/models/transaction.dart';
import '../../data/models/transaction_type.dart';

final _dateFormat = DateFormat('d MMM yyyy');

class TransactionTile extends StatelessWidget {
  const TransactionTile({required this.transaction, this.onTap, super.key});

  final Transaction transaction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final isLent = transaction.type == TransactionType.lent;
    final amountColor = isLent ? semantic.success : semantic.warning;

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: amountColor.withValues(alpha: 0.12),
        child: Icon(
          isLent ? Icons.north_east : Icons.south_west,
          color: amountColor,
        ),
      ),
      title: Text(
        transaction.contactName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        transaction.description?.isNotEmpty == true
            ? transaction.description!
            : _dateFormat.format(transaction.transactionDate),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            formatMoney(transaction.remainingAmount, transaction.currency),
            style: TextStyle(fontWeight: FontWeight.w700, color: amountColor),
          ),
          Text(
            transaction.status.label,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}
