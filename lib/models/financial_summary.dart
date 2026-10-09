import 'financial_transaction.dart';

class FinancialSummary {
  const FinancialSummary({required this.income, required this.expenses});

  factory FinancialSummary.fromTransactions(
    Iterable<FinancialTransaction> transactions,
  ) {
    var income = 0.0;
    var expenses = 0.0;
    for (final transaction in transactions) {
      if (transaction.type == TransactionType.income) {
        income += transaction.amount;
      } else {
        expenses += transaction.amount;
      }
    }
    return FinancialSummary(income: income, expenses: expenses);
  }

  final double income;
  final double expenses;

  double get availableBalance => income - expenses;
}
