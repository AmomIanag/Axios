import 'financial_transaction.dart';
import 'money.dart';

class FinancialSummary {
  const FinancialSummary({
    required this.incomeInCents,
    required this.expensesInCents,
  });

  factory FinancialSummary.fromTransactions(
    Iterable<FinancialTransaction> transactions,
  ) {
    var income = 0;
    var expenses = 0;
    for (final transaction in transactions) {
      if (transaction.excludedFromBudget) continue;
      if (transaction.type == TransactionType.income) {
        income += transaction.amountInCents;
      } else {
        expenses += transaction.amountInCents;
      }
    }
    return FinancialSummary(incomeInCents: income, expensesInCents: expenses);
  }

  final int incomeInCents;
  final int expensesInCents;

  Money get incomeMoney => Money(incomeInCents);
  Money get expensesMoney => Money(expensesInCents);
  Money get monthlyResultMoney => Money(incomeInCents - expensesInCents);
  Money get estimatedSavingCapacityMoney =>
      Money((incomeInCents - expensesInCents).clamp(0, incomeInCents));

  double get income => incomeMoney.asDouble;
  double get expenses => expensesMoney.asDouble;
  double get availableBalance => monthlyResultMoney.asDouble;
}
