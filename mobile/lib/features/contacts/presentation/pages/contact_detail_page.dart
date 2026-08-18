import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_semantic_colors.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../transactions/presentation/controllers/transactions_controller.dart';
import '../../../transactions/presentation/widgets/transaction_tile.dart';
import '../../data/repositories/contact_repository.dart';
import '../controllers/contacts_controller.dart';

class ContactDetailPage extends ConsumerWidget {
  const ContactDetailPage({required this.contactId, super.key});

  final String contactId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactAsync = ref.watch(contactProvider(contactId));
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;

    return Scaffold(
      appBar: AppBar(
        title: contactAsync.whenOrNull(data: (c) => Text(c.name)) ?? const Text('Contact'),
        actions: [
          contactAsync.whenOrNull(
                data: (contact) => IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => context.push('/contacts/${contact.id}/edit', extra: contact),
                ),
              ) ??
              const SizedBox.shrink(),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: contactAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(error: error),
        data: (contact) {
          final transactionsAsync = ref.watch(contactTransactionsProvider(contactId));

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _row(context, 'Owed to me', formatMoney(contact.totalOwedToMe, 'TND'), semantic.success),
                      const SizedBox(height: 8),
                      _row(context, 'I owe', formatMoney(contact.totalIOwe, 'TND'), semantic.warning),
                      const Divider(height: 24),
                      _row(
                        context,
                        'Net balance',
                        formatMoney(contact.netBalance, 'TND'),
                        contact.netBalance >= 0 ? semantic.success : semantic.warning,
                        bold: true,
                      ),
                    ],
                  ),
                ),
              ),
              if (contact.phone != null || contact.email != null || contact.notes != null) ...[
                const SizedBox(height: 12),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (contact.phone != null) Text('Phone: ${contact.phone}'),
                        if (contact.email != null) Text('Email: ${contact.email}'),
                        if (contact.notes != null) Text(contact.notes!),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Text('Transaction history', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              transactionsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => ErrorView(error: error),
                data: (transactions) {
                  if (transactions.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'No transactions with this contact yet',
                      ),
                    );
                  }
                  return Card(
                    margin: EdgeInsets.zero,
                    child: Column(
                      children: transactions
                          .map(
                            (t) => TransactionTile(
                              transaction: t,
                              onTap: () => context.push('/transactions/${t.id}'),
                            ),
                          )
                          .toList(),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value, Color color, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete contact?'),
        content: const Text('This will remove the contact. Existing transactions stay in your history.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(contactRepositoryProvider).delete(contactId);
      ref.invalidate(contactsControllerProvider);
      if (context.mounted) context.pop();
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not delete contact')));
      }
    }
  }
}
