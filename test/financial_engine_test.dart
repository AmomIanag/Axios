import 'package:axios/models/financial_transaction.dart';
import 'package:axios/models/goal.dart';
import 'package:axios/models/transaction_category.dart';
import 'package:axios/services/financial_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = FinancialEngine();

  test('calcula período, categorias e ignora pagamentos internos', () {
    final transactions = [
      _transaction('renda', 300000, TransactionType.income),
      _transaction('mercado', 100050, TransactionType.expense),
      _transaction('fatura', 50000, TransactionType.expense, excluded: true),
      FinancialTransaction(
        id: 'outubro',
        description: 'Outro mês',
        category: TransactionCategory.other,
        date: DateTime(2026, 10, 1),
        amountInCents: 9999,
        type: TransactionType.expense,
      ),
    ];

    final summary = engine.summary(
      transactions,
      period: const FinancialPeriod(2026, 9),
    );
    expect(summary.incomeInCents, 300000);
    expect(summary.expensesInCents, 100050);
    expect(summary.monthlyResultMoney.cents, 199950);
    expect(
      engine.expensesByCategory(
        transactions,
        period: const FinancialPeriod(2026, 9),
      )[TransactionCategory.food],
      100050,
    );
  });

  test('trata renda zero, orçamento negativo e meta concluída', () {
    final negative = engine.summary([
      _transaction('despesa', 1000, TransactionType.expense),
    ]);
    final completed = Goal(
      id: 'goal',
      name: 'Concluída',
      currentAmount: 100,
      targetAmount: 100,
      deadlineMonths: 1,
      monthlyContribution: 0,
      createdAt: DateTime(2026),
    );

    expect(negative.estimatedSavingCapacityMoney.cents, 0);
    expect(engine.estimatedMonths(completed, 0), 0);
    expect(engine.monthlyNeededInCents(completed, 0), 0);
  });
}

FinancialTransaction _transaction(
  String id,
  int cents,
  TransactionType type, {
  bool excluded = false,
}) => FinancialTransaction(
  id: id,
  description: id,
  category: type == TransactionType.income
      ? TransactionCategory.income
      : TransactionCategory.food,
  date: DateTime(2026, 9, 1),
  amountInCents: cents,
  type: type,
  excludedFromBudget: excluded,
);
