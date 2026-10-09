import 'package:axios/data/mock_financial_data.dart';
import 'package:axios/models/goal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('cálculos financeiros', () {
    test('calcula renda, gastos e saldo a partir das transações', () {
      final summary = MockFinancialData.summary;

      expect(summary.income, 3000);
      expect(summary.expenses, 2150);
      expect(summary.availableBalance, 850);
    });

    test('calcula o progresso da meta com limite de 100%', () {
      final goal = MockFinancialData.goals.first;

      expect(goal.progress, 0.25);
      expect(goal.progressPercent, 25);
    });

    test('considera o acumulado no valor mensal necessário', () {
      final goal = MockFinancialData.goals.first;

      expect(goal.remainingAmount, 4500);
      expect(goal.monthlyNeededFor(8), 562.5);
      expect(goal.monthsToComplete, 9);
    });

    test('não produz progresso negativo para uma meta vazia', () {
      final goal = Goal(
        id: 'empty',
        name: 'Teste',
        currentAmount: 0,
        targetAmount: 0,
        deadlineMonths: 1,
        monthlyContribution: 0,
        createdAt: DateTime(2026),
      );

      expect(goal.progress, 0);
      expect(goal.monthsToComplete, 0);
    });
  });
}
