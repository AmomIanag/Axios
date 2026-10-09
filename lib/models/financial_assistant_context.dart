import 'dart:convert';

class AssistantCategorySummary {
  const AssistantCategorySummary({
    required this.id,
    required this.label,
    required this.amountInCents,
  });

  final String id;
  final String label;
  final int amountInCents;

  Map<String, Object> toJson() => {
    'categoria': label,
    'valor_centavos': amountInCents,
  };
}

class AssistantGoalSummary {
  const AssistantGoalSummary({
    required this.name,
    required this.currentInCents,
    required this.targetInCents,
    required this.remainingInCents,
    required this.progressPercent,
    required this.deadlineMonths,
    required this.monthlyNeededInCents,
    required this.estimatedMonthsAtCurrentCapacity,
    required this.insufficientBudget,
    required this.completed,
  });

  final String name;
  final int currentInCents;
  final int targetInCents;
  final int remainingInCents;
  final int progressPercent;
  final int deadlineMonths;
  final int monthlyNeededInCents;
  final int estimatedMonthsAtCurrentCapacity;
  final bool insufficientBudget;
  final bool completed;

  Map<String, Object> toJson() => {
    'nome': name,
    'acumulado_centavos': currentInCents,
    'objetivo_centavos': targetInCents,
    'restante_centavos': remainingInCents,
    'progresso_percentual': progressPercent,
    'prazo_meses': deadlineMonths,
    'necessario_por_mes_centavos': monthlyNeededInCents,
    'meses_estimados_na_capacidade_atual': estimatedMonthsAtCurrentCapacity,
    'orcamento_insuficiente_para_o_prazo': insufficientBudget,
    'concluida': completed,
  };
}

class FinancialAssistantContext {
  const FinancialAssistantContext({
    required this.periodYear,
    required this.periodMonth,
    required this.incomeInCents,
    required this.expensesInCents,
    required this.monthlyResultInCents,
    required this.savingCapacityInCents,
    required this.pendingTransactionCount,
    required this.pendingIncomeInCents,
    required this.pendingExpensesInCents,
    required this.categories,
    required this.goals,
    required this.transactionsLoaded,
    required this.goalsLoaded,
  });

  final int periodYear;
  final int periodMonth;
  final int incomeInCents;
  final int expensesInCents;
  final int monthlyResultInCents;
  final int savingCapacityInCents;
  final int pendingTransactionCount;
  final int pendingIncomeInCents;
  final int pendingExpensesInCents;
  final List<AssistantCategorySummary> categories;
  final List<AssistantGoalSummary> goals;
  final bool transactionsLoaded;
  final bool goalsLoaded;

  Map<String, Object> toJson() => {
    'moeda': 'BRL',
    'periodo': {'ano': periodYear, 'mes': periodMonth},
    'resumo': {
      'receitas_centavos': incomeInCents,
      'despesas_centavos': expensesInCents,
      'resultado_liquido_centavos': monthlyResultInCents,
      'capacidade_estimada_poupanca_centavos': savingCapacityInCents,
    },
    'pendencias': {
      'quantidade': pendingTransactionCount,
      'receitas_pendentes_centavos': pendingIncomeInCents,
      'despesas_pendentes_centavos': pendingExpensesInCents,
      'observacao':
          'Os totais seguem a mesma regra do Dashboard; registros marcados '
          'como excluídos do orçamento não são contabilizados.',
    },
    'gastos_por_categoria': categories.map((item) => item.toJson()).toList(),
    'metas': goals.map((item) => item.toJson()).toList(),
    'dados_carregados': {
      'transacoes': transactionsLoaded,
      'metas': goalsLoaded,
    },
  };

  String toPromptJson() => jsonEncode(toJson());
}

class FinancialScenarioFacts {
  const FinancialScenarioFacts(this.values);

  final Map<String, Object> values;

  String toPromptJson() => jsonEncode(values);
}
