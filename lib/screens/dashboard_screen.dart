import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/formatters.dart';
import '../data/mock_financial_data.dart';
import '../state/app_controller.dart';
import '../widgets/app_card.dart';
import '../widgets/goal_card.dart';
import '../widgets/screen_header.dart';
import '../widgets/spending_chart.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final summary = MockFinancialData.summary;
    final currentGoal = controller.goals.isNotEmpty
        ? controller.goals.first
        : MockFinancialData.goals.first;
    return SafeArea(
      child: SingleChildScrollView(
        key: const PageStorageKey('dashboard-scroll'),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ScreenHeader(
                  title: 'Olá, ${controller.user?.firstName ?? 'usuário'}',
                  subtitle: 'Resumo financeiro',
                  trailing: IconButton(
                    tooltip: 'Sair',
                    onPressed: controller.signOut,
                    icon: const Icon(Icons.logout_rounded),
                  ),
                ),
                const SizedBox(height: 20),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Saldo disponível',
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: AppColors.gray),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppFormatters.currency(summary.availableBalance),
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Sobra estimada do mês',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cards = [
                      _SummaryCard(
                        label: 'Renda mensal',
                        value: AppFormatters.currency(summary.income),
                        color: AppColors.success,
                      ),
                      _SummaryCard(
                        label: 'Gastos mensais',
                        value: AppFormatters.currency(summary.expenses),
                        color: AppColors.danger,
                      ),
                    ];
                    if (constraints.maxWidth < 320) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          cards.first,
                          const SizedBox(height: 12),
                          cards.last,
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: cards.first),
                        const SizedBox(width: 12),
                        Expanded(child: cards.last),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 28),
                Text(
                  'Gastos por categoria',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                SpendingChart(values: MockFinancialData.expensesByCategory),
                const SizedBox(height: 28),
                Text(
                  'Meta atual',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                GoalCard(goal: currentGoal, compact: true),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(color: color, fontSize: 21),
            ),
          ),
        ],
      ),
    );
  }
}
