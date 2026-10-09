import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/formatters.dart';
import '../data/mock_financial_data.dart';
import '../models/financial_transaction.dart';
import '../widgets/app_card.dart';
import '../widgets/screen_header.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  TransactionFilter _filter = TransactionFilter.all;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final visibleTransactions = filterTransactions(
      MockFinancialData.transactions,
      filter: _filter,
      query: _query,
    );
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const ScreenHeader(
                  title: 'Transações',
                  subtitle: 'Acompanhe suas movimentações',
                ),
                const SizedBox(height: 24),
                TextField(
                  key: const ValueKey('transaction-search'),
                  onChanged: (value) => setState(() => _query = value),
                  decoration: const InputDecoration(
                    hintText: 'Buscar transação',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'Todas',
                        selected: _filter == TransactionFilter.all,
                        onTap: () =>
                            setState(() => _filter = TransactionFilter.all),
                      ),
                      const SizedBox(width: 10),
                      _FilterChip(
                        label: 'Receitas',
                        selected: _filter == TransactionFilter.income,
                        onTap: () =>
                            setState(() => _filter = TransactionFilter.income),
                      ),
                      const SizedBox(width: 10),
                      _FilterChip(
                        label: 'Despesas',
                        selected: _filter == TransactionFilter.expense,
                        onTap: () =>
                            setState(() => _filter = TransactionFilter.expense),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: visibleTransactions.isEmpty
                      ? const _EmptyTransactions()
                      : ListView.separated(
                          key: const PageStorageKey('transactions-list'),
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: visibleTransactions.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) => _TransactionCard(
                            transaction: visibleTransactions[index],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.gold,
      backgroundColor: AppColors.surface,
      side: BorderSide(color: selected ? AppColors.gold : AppColors.border),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      labelStyle: TextStyle(
        fontFamily: 'Inter',
        color: AppColors.graphite,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.transaction});

  final FinancialTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isIncome
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.goldSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isIncome ? Icons.south_west_rounded : Icons.north_east_rounded,
              color: isIncome ? AppColors.success : AppColors.graphite,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  transaction.category,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIncome ? '+' : '-'}${AppFormatters.currency(transaction.amount)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isIncome ? AppColors.success : AppColors.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppFormatters.transactionDate(transaction.date),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: AppColors.gray,
            ),
            const SizedBox(height: 12),
            Text(
              'Nenhuma transação encontrada',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Tente ajustar a busca ou o filtro.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
