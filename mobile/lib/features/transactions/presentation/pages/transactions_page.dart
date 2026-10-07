import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../controllers/transactions_controller.dart';
import '../widgets/contact_filter_button.dart';
import '../widgets/transaction_tile.dart';

class TransactionsPage extends ConsumerWidget {
  const TransactionsPage({super.key});

  static const _tabs = [
    (TransactionFilterTab.all, 'All'),
    (TransactionFilterTab.lent, 'Lent'),
    (TransactionFilterTab.borrowed, 'Borrowed'),
    (TransactionFilterTab.paid, 'Paid'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFilter = ref.watch(transactionsFilterProvider);
    final selectedContact = ref.watch(transactionsContactFilterProvider);
    final transactionsAsync = ref.watch(transactionsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/transactions/new'),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _tabs
                    .map(
                      (tab) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(tab.$2),
                          selected: selectedFilter == tab.$1,
                          onSelected: (_) =>
                              ref
                                      .read(transactionsFilterProvider.notifier)
                                      .state =
                                  tab.$1,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ContactFilterButton(
                selected: selectedContact,
                onChanged: (contact) =>
                    ref.read(transactionsContactFilterProvider.notifier).state =
                        contact,
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () =>
                  ref.read(transactionsControllerProvider.notifier).refresh(),
              child: transactionsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => ErrorView(
                  error: error,
                  onRetry: () => ref
                      .read(transactionsControllerProvider.notifier)
                      .refresh(),
                ),
                data: (transactions) {
                  if (transactions.isEmpty) {
                    return ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 64),
                          child: selectedContact == null
                              ? const EmptyState(
                                  icon: Icons.receipt_long_outlined,
                                  title: 'No transactions here yet',
                                )
                              : EmptyState(
                                  icon: Icons.person_search_outlined,
                                  title:
                                      'No transactions with '
                                      '${selectedContact.name} here yet',
                                  message:
                                      'Try another filter, or show '
                                      'transactions from everyone.',
                                  actionLabel: 'Show all contacts',
                                  onAction: () =>
                                      ref
                                              .read(
                                                transactionsContactFilterProvider
                                                    .notifier,
                                              )
                                              .state =
                                          null,
                                ),
                        ),
                      ],
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.only(bottom: 96),
                    itemCount: transactions.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final transaction = transactions[index];
                      return TransactionTile(
                        transaction: transaction,
                        onTap: () =>
                            context.push('/transactions/${transaction.id}'),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
