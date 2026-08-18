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
      appBar: AppBar(title: const Text('Lendly')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/transactions/new'),
        icon: const Icon(Icons.add),
        label: const Text('Add transaction'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(dashboardControllerProvider.notifier).refresh(),
        child: dashboardAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ErrorView(
            error: error,
            onRetry: () => ref.read(dashboardControllerProvider.notifier).refresh(),
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
                  color: summary.netBalance >= 0 ? semantic.success : semantic.warning,
                  icon: Icons.account_balance_wallet_outlined,
                  wide: true,
                ),
                const SizedBox(height: 24),
                Text('Recent transactions', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (summary.recentTransactions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'No transactions yet',
                      message: 'Add the first amount you lent or borrowed.',
                    ),
                  )
                else
                  Card(
                    margin: EdgeInsets.zero,
                    child: Column(
                      children: summary.recentTransactions
                          .map(
                            (transaction) => TransactionTile(
                              transaction: transaction,
                              onTap: () => context.push('/transactions/${transaction.id}'),
                            ),
                          )
                          .toList(),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
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
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color, fontWeight: FontWeight.w800),
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
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
      ),
    );
  }
}
