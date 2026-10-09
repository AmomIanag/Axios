import '../models/financial_assistant_context.dart';
import '../models/financial_transaction.dart';
import '../models/goal.dart';
import 'financial_engine.dart';

class FinancialAssistantContextBuilder {
  const FinancialAssistantContextBuilder({
    this.engine = const FinancialEngine(),
  });

  final FinancialEngine engine;

  FinancialAssistantContext build({
    required Iterable<FinancialTransaction> transactions,
    required Iterable<Goal> goals,
    required FinancialPeriod period,
    required bool transactionsLoaded,
    required bool goalsLoaded,
  }) {
    final periodTransactions = engine.forPeriod(transactions, period);
    final summary = engine.summary(periodTransactions);
    final categoryEntries =
        engine
            .expensesByCategory(periodTransactions)
            .entries
            .map(
              (entry) => AssistantCategorySummary(
                id: entry.key.id,
                label: entry.key.label,
                amountInCents: entry.value,
              ),
            )
            .toList()
          ..sort((a, b) => b.amountInCents.compareTo(a.amountInCents));

    var pendingIncome = 0;
    var pendingExpenses = 0;
    var pendingCount = 0;
    for (final transaction in periodTransactions) {
      if (!transaction.pending || transaction.excludedFromBudget) continue;
      pendingCount++;
      if (transaction.type == TransactionType.income) {
        pendingIncome += transaction.amountInCents;
      } else {
        pendingExpenses += transaction.amountInCents;
      }
    }

    final capacity = summary.estimatedSavingCapacityMoney.cents;
    final goalSummaries = goals
        .take(20)
        .map((goal) {
          final completed = goal.remainingAmountInCents == 0;
          return AssistantGoalSummary(
            name: _safeLabel(goal.name),
            currentInCents: goal.currentAmountInCents,
            targetInCents: goal.targetAmountInCents,
            remainingInCents: goal.remainingAmountInCents,
            progressPercent: goal.progressPercent,
            deadlineMonths: goal.deadlineMonths,
            monthlyNeededInCents: engine.monthlyNeededInCents(
              goal,
              goal.deadlineMonths,
            ),
            estimatedMonthsAtCurrentCapacity: engine.estimatedMonths(
              goal,
              capacity,
            ),
            insufficientBudget:
                !completed && engine.hasInsufficientBudget(goal, capacity),
            completed: completed,
          );
        })
        .toList(growable: false);

    return FinancialAssistantContext(
      periodYear: period.year,
      periodMonth: period.month,
      incomeInCents: summary.incomeInCents,
      expensesInCents: summary.expensesInCents,
      monthlyResultInCents: summary.monthlyResultMoney.cents,
      savingCapacityInCents: capacity,
      pendingTransactionCount: pendingCount,
      pendingIncomeInCents: pendingIncome,
      pendingExpensesInCents: pendingExpenses,
      categories: List.unmodifiable(categoryEntries),
      goals: List.unmodifiable(goalSummaries),
      transactionsLoaded: transactionsLoaded,
      goalsLoaded: goalsLoaded,
    );
  }

  FinancialScenarioFacts? analyzeQuestion(
    String question,
    FinancialAssistantContext context,
  ) {
    final normalized = _normalize(question);
    final matchedGoal = _findGoal(normalized, context.goals);
    final months = _extractMonths(normalized);
    final monthlySaving = _extractMonthlySaving(normalized);
    final mentionedAmount = _extractFirstMoney(normalized);

    if (matchedGoal != null && months != null) {
      final monthlyNeeded = _ceilDivide(matchedGoal.remainingInCents, months);
      return FinancialScenarioFacts({
        'tipo': 'meta_existente_em_prazo_informado',
        'meta': matchedGoal.name,
        'meses': months,
        'restante_centavos': matchedGoal.remainingInCents,
        'necessario_por_mes_centavos': monthlyNeeded,
        'capacidade_estimada_centavos': context.savingCapacityInCents,
        'viavel_na_capacidade_atual':
            monthlyNeeded <= context.savingCapacityInCents,
      });
    }

    if (matchedGoal != null && monthlySaving != null) {
      final estimatedMonths = monthlySaving <= 0
          ? -1
          : _ceilDivide(matchedGoal.remainingInCents, monthlySaving);
      return FinancialScenarioFacts({
        'tipo': 'meta_existente_com_aporte_informado',
        'meta': matchedGoal.name,
        'aporte_mensal_centavos': monthlySaving,
        'restante_centavos': matchedGoal.remainingInCents,
        'meses_estimados': estimatedMonths,
      });
    }

    if (matchedGoal == null && mentionedAmount != null && months != null) {
      final monthlyNeeded = _ceilDivide(mentionedAmount, months);
      return FinancialScenarioFacts({
        'tipo': 'objetivo_hipotetico_sem_valor_acumulado',
        'objetivo_centavos': mentionedAmount,
        'meses': months,
        'necessario_por_mes_centavos': monthlyNeeded,
        'capacidade_estimada_centavos': context.savingCapacityInCents,
        'viavel_na_capacidade_atual':
            monthlyNeeded <= context.savingCapacityInCents,
        'observacao': 'O cálculo considera valor acumulado igual a zero.',
      });
    }

    return null;
  }

  AssistantGoalSummary? _findGoal(
    String normalizedQuestion,
    List<AssistantGoalSummary> goals,
  ) {
    for (final goal in goals) {
      final name = _normalize(goal.name);
      if (name.isNotEmpty && normalizedQuestion.contains(name)) return goal;
    }
    if (goals.length == 1 && normalizedQuestion.contains('meta')) {
      return goals.first;
    }
    return null;
  }

  int? _extractMonths(String input) {
    final digits = RegExp(r'(\d{1,3})\s*mes').firstMatch(input);
    if (digits != null) return int.tryParse(digits.group(1)!);
    const words = {
      'um': 1,
      'dois': 2,
      'tres': 3,
      'quatro': 4,
      'cinco': 5,
      'seis': 6,
      'sete': 7,
      'oito': 8,
      'nove': 9,
      'dez': 10,
      'onze': 11,
      'doze': 12,
    };
    for (final entry in words.entries) {
      if (RegExp('\\b${entry.key}\\s+mes').hasMatch(input)) {
        return entry.value;
      }
    }
    return null;
  }

  int? _extractMonthlySaving(String input) {
    final match = RegExp(
      r'(?:guardar|economizar|poupar|aporte)[^\d]{0,20}(?:r\$\s*)?([\d\.]+(?:,\d{1,2})?)\s*(?:por|ao)?\s*mes',
    ).firstMatch(input);
    return match == null ? null : _parseBrazilianMoney(match.group(1)!);
  }

  int? _extractFirstMoney(String input) {
    final match = RegExp(r'r\$\s*([\d\.]+(?:,\d{1,2})?)').firstMatch(input);
    return match == null ? null : _parseBrazilianMoney(match.group(1)!);
  }

  int? _parseBrazilianMoney(String raw) {
    final normalized = raw.replaceAll('.', '').replaceAll(',', '.');
    final value = double.tryParse(normalized);
    return value == null ? null : (value * 100).round();
  }

  int _ceilDivide(int value, int divisor) {
    if (value <= 0) return 0;
    if (divisor <= 0) return value;
    return (value / divisor).ceil();
  }

  String _safeLabel(String value) {
    final singleLine = value.replaceAll(RegExp(r'[\r\n\t]+'), ' ').trim();
    return singleLine.length <= 80 ? singleLine : singleLine.substring(0, 80);
  }

  String _normalize(String value) => value
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('à', 'a')
      .replaceAll('â', 'a')
      .replaceAll('ã', 'a')
      .replaceAll('é', 'e')
      .replaceAll('ê', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ô', 'o')
      .replaceAll('õ', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ç', 'c');
}
