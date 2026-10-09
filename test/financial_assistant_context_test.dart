import 'package:axios/models/financial_transaction.dart';
import 'package:axios/models/goal.dart';
import 'package:axios/models/transaction_category.dart';
import 'package:axios/services/financial_assistant_context_builder.dart';
import 'package:axios/services/financial_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const builder = FinancialAssistantContextBuilder();
  final period = const FinancialPeriod(2026, 9);
  final transactions = [
    FinancialTransaction(
      id: 'income-sensitive-id',
      description: 'Salário que não deve ir ao prompt',
      category: TransactionCategory.income,
      date: DateTime(2026, 9, 5),
      amountInCents: 300000,
      type: TransactionType.income,
    ),
    FinancialTransaction(
      id: 'food-sensitive-id',
      description: 'Restaurante identificável',
      category: TransactionCategory.food,
      date: DateTime(2026, 9, 8),
      amountInCents: 120000,
      type: TransactionType.expense,
    ),
    FinancialTransaction(
      id: 'pending-sensitive-id',
      description: 'Compra pendente identificável',
      category: TransactionCategory.transport,
      date: DateTime(2026, 9, 9),
      amountInCents: 95000,
      type: TransactionType.expense,
      pending: true,
    ),
    FinancialTransaction(
      id: 'excluded-sensitive-id',
      description: 'Transferência interna',
      category: TransactionCategory.transfer,
      date: DateTime(2026, 9, 10),
      amountInCents: 50000,
      type: TransactionType.expense,
      excludedFromBudget: true,
    ),
    FinancialTransaction(
      id: 'other-period',
      description: 'Outro mês',
      category: TransactionCategory.leisure,
      date: DateTime(2026, 8, 10),
      amountInCents: 99900,
      type: TransactionType.expense,
    ),
  ];
  final goals = [
    Goal(
      id: 'goal-sensitive-id',
      name: 'Viagem',
      currentAmount: 1500,
      targetAmount: 6000,
      deadlineMonths: 8,
      monthlyContribution: 500,
      createdAt: DateTime(2026, 1, 1),
    ),
  ];

  test('cria contexto agregado com cálculos do motor financeiro', () {
    final context = builder.build(
      transactions: transactions,
      goals: goals,
      period: period,
      transactionsLoaded: true,
      goalsLoaded: true,
    );

    expect(context.incomeInCents, 300000);
    expect(context.expensesInCents, 215000);
    expect(context.monthlyResultInCents, 85000);
    expect(context.savingCapacityInCents, 85000);
    expect(context.pendingTransactionCount, 1);
    expect(context.pendingExpensesInCents, 95000);
    expect(context.categories.map((item) => item.amountInCents), [
      120000,
      95000,
    ]);

    final goal = context.goals.single;
    expect(goal.remainingInCents, 450000);
    expect(goal.monthlyNeededInCents, 56250);
    expect(goal.estimatedMonthsAtCurrentCapacity, 6);
    expect(goal.insufficientBudget, isFalse);
  });

  test('contexto não inclui e-mail, IDs ou descrições individuais', () {
    final context = builder.build(
      transactions: transactions,
      goals: goals,
      period: period,
      transactionsLoaded: true,
      goalsLoaded: true,
    );
    final prompt = context.toPromptJson();

    expect(prompt, isNot(contains('usuario@axios.app')));
    expect(prompt, isNot(contains('sensitive-id')));
    expect(prompt, isNot(contains('Restaurante identificável')));
    expect(prompt, isNot(contains('Salário que não deve ir ao prompt')));
    expect(prompt, contains('Viagem'));
  });

  test('calcula cenários determinísticos antes de consultar a IA', () {
    final context = builder.build(
      transactions: transactions,
      goals: goals,
      period: period,
      transactionsLoaded: true,
      goalsLoaded: true,
    );

    final deadline = builder.analyzeQuestion(
      'Consigo antecipar minha viagem para 8 meses?',
      context,
    );
    expect(deadline?.values['necessario_por_mes_centavos'], 56250);

    final contribution = builder.analyzeQuestion(
      r'Se eu guardar R$ 500 por mês na viagem, quanto tempo leva?',
      context,
    );
    expect(contribution?.values['meses_estimados'], 9);

    final hypothetical = builder.analyzeQuestion(
      r'Consigo comprar um celular de R$ 4.000 em seis meses?',
      context,
    );
    expect(hypothetical?.values['necessario_por_mes_centavos'], 66667);
  });
}
