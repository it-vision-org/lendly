import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_semantic_colors.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../transactions/presentation/widgets/transaction_tile.dart';
import '../controllers/dashboard_controller.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/images/home-screen.png', height: 40),
      ), 
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/transactions/new'),
        icon: const Icon(Icons.add),
        label: const Text('Add transaction'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(dashboardControllerProvider.notifier).refresh();
          ref.invalidate(recentTransactionsProvider);
        },
        child: dashboardAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ErrorView(
            error: error,
            onRetry: () =>
                ref.read(dashboardControllerProvider.notifier).refresh(),
          ),
          data: (summary) {
            final semantic = Theme.of(context).extension<AppSemanticColors>()!;

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _BalanceCard(
                        label: 'Owed to me',
                        amount: summary.totalOwedToMe,
                        color: semantic.success,
                        icon: Icons.north_east,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _BalanceCard(
                        label: 'I owe',
                        amount: summary.totalIOwe,
                        color: semantic.warning,
                        icon: Icons.south_west,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _BalanceCard(
                  label: 'Net balance',
                  amount: summary.netBalance,
                  color: summary.netBalance >= 0
                      ? semantic.success
                      : semantic.warning,
                  icon: Icons.account_balance_wallet_outlined,
                  wide: true,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent transactions',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const _RecentTransactionsFilterControl(),
                  ],
                ),
                const SizedBox(height: 8),
                const _RecentTransactionsList(),
              ],
            );
          },
        ),
      ),
    );
  }
}

const _recentFilterIcons = {
  RecentTransactionsFilter.active: Icons.pending_actions_outlined,
  RecentTransactionsFilter.paid: Icons.check_circle_outline,
  RecentTransactionsFilter.all: Icons.list_alt_outlined,
};

class _RecentTransactionsFilterControl extends ConsumerWidget {
  const _RecentTransactionsFilterControl();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(recentTransactionsFilterProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return PopupMenuButton<RecentTransactionsFilter>(
      initialValue: selected,
      onSelected: (value) =>
          ref.read(recentTransactionsFilterProvider.notifier).state = value,
      offset: const Offset(0, 8),
      elevation: 4,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.16),
      color: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      padding: const EdgeInsets.all(6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      itemBuilder: (context) => RecentTransactionsFilter.values.map((filter) {
        final isSelected = filter == selected;
        return PopupMenuItem(
          value: filter,
          padding: EdgeInsets.zero,
          height: 44,
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primaryContainer
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  _recentFilterIcons[filter],
                  size: 18,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    filter.label,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check, size: 16, color: colorScheme.primary),
              ],
            ),
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _recentFilterIcons[selected],
              size: 16,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              selected.label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.expand_more,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentTransactionsList extends ConsumerWidget {
  const _RecentTransactionsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(recentTransactionsProvider);
    final filter = ref.watch(recentTransactionsFilterProvider);

    return transactionsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => ErrorView(
        error: error,
        onRetry: () => ref.invalidate(recentTransactionsProvider),
      ),
      data: (transactions) {
        if (transactions.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: EmptyState(
              icon: Icons.receipt_long_outlined,
              title: switch (filter) {
                RecentTransactionsFilter.active => 'No active transactions',
                RecentTransactionsFilter.paid => 'No paid transactions yet',
                RecentTransactionsFilter.all => 'No transactions yet',
              },
              message: filter == RecentTransactionsFilter.all
                  ? 'Add the first amount you lent or borrowed.'
                  : null,
            ),
          );
        }

        return Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: transactions
                .map(
                  (transaction) => TransactionTile(
                    transaction: transaction,
                    onTap: () =>
                        context.push('/transactions/${transaction.id}'),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
    this.wide = false,
  });

  final String label;
  final num amount;
  final Color color;
  final IconData icon;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: wide
            ? Row(
                children: [
                  Icon(icon, color: color),
                  const SizedBox(width: 12),
                  Text(label, style: Theme.of(context).textTheme.bodyMedium),
                  const Spacer(),
                  Text(
                    formatMoney(amount, 'TND'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: color),
                  const SizedBox(height: 8),
                  Text(label, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 4),
                  Text(
                    formatMoney(amount, 'TND'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
