import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_semantic_colors.dart';
import '../../../../core/network/error_messages.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../contacts/presentation/controllers/contacts_controller.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../data/models/transaction_type.dart';
import '../../data/repositories/transaction_repository.dart';
import '../controllers/transaction_detail_controller.dart';
import '../controllers/transactions_controller.dart';

final _dateFormat = DateFormat('d MMM yyyy');

class TransactionDetailPage extends ConsumerWidget {
  const TransactionDetailPage({required this.transactionId, super.key});

  final String transactionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(transactionDetailProvider(transactionId));
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction'),
        actions: [
          detailAsync.whenOrNull(
                data: (detail) => IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => context.push(
                    '/transactions/${detail.transaction.id}/edit',
                    extra: detail.transaction,
                  ),
                ),
              ) ??
              const SizedBox.shrink(),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDeleteTransaction(context, ref),
          ),
        ],
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () =>
              ref.invalidate(transactionDetailProvider(transactionId)),
        ),
        data: (detail) {
          final transaction = detail.transaction;
          final isLent = transaction.type == TransactionType.lent;
          final color = isLent ? semantic.success : semantic.warning;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isLent ? Icons.north_east : Icons.south_west,
                            color: color,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isLent
                                ? 'You lent to ${transaction.contactName}'
                                : 'You borrowed from ${transaction.contactName}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _row(
                        context,
                        'Original amount',
                        formatMoney(
                          transaction.originalAmount,
                          transaction.currency,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _row(
                        context,
                        'Remaining',
                        formatMoney(
                          transaction.remainingAmount,
                          transaction.currency,
                        ),
                        valueColor: transaction.isPaid
                            ? semantic.success
                            : color,
                      ),
                      const SizedBox(height: 8),
                      _row(context, 'Status', transaction.status.label),
                      const SizedBox(height: 8),
                      _row(
                        context,
                        'Date',
                        _dateFormat.format(transaction.transactionDate),
                      ),
                      if (transaction.description?.isNotEmpty == true) ...[
                        const SizedBox(height: 8),
                        _row(context, 'Description', transaction.description!),
                      ],
                      if (transaction.isPaid) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: semantic.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Fully paid',
                            style: TextStyle(
                              color: semantic.success,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Repayment history',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (!transaction.isPaid)
                    TextButton.icon(
                      onPressed: () => _showAddRepaymentSheet(
                        context,
                        ref,
                        remainingAmount: transaction.remainingAmount,
                        currency: transaction.currency,
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Add repayment'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (detail.repayments.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: EmptyState(
                    icon: Icons.history,
                    title: 'No repayments recorded yet',
                  ),
                )
              else
                Card(
                  margin: EdgeInsets.zero,
                  child: Column(
                    children: detail.repayments
                        .map(
                          (repayment) => ListTile(
                            leading: const Icon(Icons.check_circle_outline),
                            title: Text(
                              formatMoney(
                                repayment.amount,
                                transaction.currency,
                              ),
                            ),
                            subtitle: Text(
                              [
                                _dateFormat.format(repayment.paymentDate),
                                if (repayment.notes?.isNotEmpty == true)
                                  repayment.notes!,
                              ].join(' · '),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _deleteRepayment(
                                context,
                                ref,
                                transaction.id,
                                repayment.id,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }

  void _invalidateAfterMutation(WidgetRef ref) {
    ref.invalidate(transactionDetailProvider(transactionId));
    ref.invalidate(transactionsControllerProvider);
    ref.invalidate(dashboardControllerProvider);
    ref.invalidate(recentTransactionsProvider);
    ref.invalidate(contactsControllerProvider);
  }

  Future<void> _showAddRepaymentSheet(
    BuildContext context,
    WidgetRef ref, {
    required num remainingAmount,
    required String currency,
  }) async {
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    var paymentDate = DateTime.now();
    final formKey = GlobalKey<FormState>();
    String? error;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Add repayment',
                      style: Theme.of(sheetContext).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: amountController,
                      autofocus: true,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        helperText:
                            'Remaining: ${formatMoney(remainingAmount, currency)}',
                      ),
                      validator: (value) {
                        final amount = num.tryParse(value ?? '');
                        if (amount == null || amount <= 0) {
                          return 'Enter a valid amount';
                        }
                        if (amount > remainingAmount) {
                          return 'Cannot exceed the remaining balance';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Payment date'),
                      subtitle: Text(_dateFormat.format(paymentDate)),
                      trailing: const Icon(Icons.calendar_today_outlined),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: sheetContext,
                          initialDate: paymentDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now().add(const Duration(days: 1)),
                        );
                        if (picked != null) {
                          setSheetState(() => paymentDate = picked);
                        }
                      },
                    ),
                    TextFormField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                      ),
                    ),
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          error!,
                          style: TextStyle(
                            color: Theme.of(sheetContext).colorScheme.error,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () async {
                        if (!(formKey.currentState?.validate() ?? false)) {
                          return;
                        }
                        try {
                          await ref
                              .read(transactionRepositoryProvider)
                              .addRepayment(
                                transactionId: transactionId,
                                amount: num.parse(amountController.text),
                                paymentDate: paymentDate,
                                notes: notesController.text.trim().isEmpty
                                    ? null
                                    : notesController.text.trim(),
                              );
                          _invalidateAfterMutation(ref);
                          if (sheetContext.mounted) Navigator.pop(sheetContext);
                        } catch (e) {
                          setSheetState(() => error = friendlyErrorMessage(e));
                        }
                      },
                      child: const Text('Save repayment'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteRepayment(
    BuildContext context,
    WidgetRef ref,
    String transactionId,
    String repaymentId,
  ) async {
    try {
      await ref
          .read(transactionRepositoryProvider)
          .deleteRepayment(
            transactionId: transactionId,
            repaymentId: repaymentId,
          );
      _invalidateAfterMutation(ref);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete repayment')),
        );
      }
    }
  }

  Future<void> _confirmDeleteTransaction(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: const Text(
          'This will permanently remove the transaction and its repayment history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(transactionRepositoryProvider).delete(transactionId);
      ref.invalidate(transactionsControllerProvider);
      ref.invalidate(dashboardControllerProvider);
      ref.invalidate(recentTransactionsProvider);
      ref.invalidate(contactsControllerProvider);
      if (context.mounted) context.pop();
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete transaction')),
        );
      }
    }
  }
}
