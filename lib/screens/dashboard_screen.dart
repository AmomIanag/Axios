import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/formatters.dart';
import '../services/financial_engine.dart';
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
    return SafeArea(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final summary = controller.financialSummary;
          final currentGoal = controller.goals.firstOrNull;
          return SingleChildScrollView(
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
                    const SizedBox(height: 16),
                    _PeriodSelector(controller: controller),
                    const SizedBox(height: 16),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Resultado líquido do mês',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.gray),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            AppFormatters.money(summary.monthlyResultMoney),
                            style: Theme.of(context).textTheme.displaySmall
                                ?.copyWith(
                                  color: summary.monthlyResultMoney.cents < 0
                                      ? AppColors.danger
                                      : AppColors.graphite,
                                ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Receitas menos despesas. Não representa o saldo bancário.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryCard(
                            label: 'Receitas',
                            value: AppFormatters.money(summary.incomeMoney),
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SummaryCard(
                            label: 'Despesas',
                            value: AppFormatters.money(summary.expensesMoney),
                            color: AppColors.danger,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Gastos por categoria',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    controller.expensesByCategory.isEmpty
                        ? const _DashboardEmpty(
                            message: 'Nenhuma despesa neste período.',
                          )
                        : SpendingChart(values: controller.expensesByCategory),
                    const SizedBox(height: 28),
                    Text(
                      'Meta em destaque',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    if (currentGoal != null)
                      GoalCard(goal: currentGoal, compact: true)
                    else
                      const _DashboardEmpty(
                        message: 'Crie uma meta para acompanhar seu progresso.',
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final period = controller.selectedPeriod;
    final date = DateTime(period.year, period.month);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          tooltip: 'Mês anterior',
          onPressed: () => controller.selectPeriod(
            FinancialPeriod(
              date.subtract(const Duration(days: 1)).year,
              date.subtract(const Duration(days: 1)).month,
            ),
          ),
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Semantics(
          label: 'Período selecionado',
          child: Text(
            AppFormatters.monthYear(date),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton(
          tooltip: 'Próximo mês',
          onPressed: () => controller.selectPeriod(
            FinancialPeriod(
              DateTime(period.year, period.month + 1).year,
              DateTime(period.year, period.month + 1).month,
            ),
          ),
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
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

class _DashboardEmpty extends StatelessWidget {
  const _DashboardEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Text(
      message,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyMedium,
    ),
  );
}
