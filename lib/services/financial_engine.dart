import '../models/financial_summary.dart';
import '../models/financial_transaction.dart';
import '../models/goal.dart';
import '../models/transaction_category.dart';

class FinancialPeriod {
  const FinancialPeriod(this.year, this.month);

  final int year;
  final int month;

  DateTime get start => DateTime(year, month);
  DateTime get endExclusive => DateTime(year, month + 1);

  bool contains(DateTime value) =>
      !value.isBefore(start) && value.isBefore(endExclusive);

  @override
  bool operator ==(Object other) =>
      other is FinancialPeriod && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);
}

class FinancialEngine {
  const FinancialEngine();

  List<FinancialTransaction> forPeriod(
    Iterable<FinancialTransaction> transactions,
    FinancialPeriod period,
  ) => transactions.where((item) => period.contains(item.date)).toList();

  FinancialSummary summary(
    Iterable<FinancialTransaction> transactions, {
    FinancialPeriod? period,
  }) => FinancialSummary.fromTransactions(
    period == null ? transactions : forPeriod(transactions, period),
  );

  Map<TransactionCategory, int> expensesByCategory(
    Iterable<FinancialTransaction> transactions, {
    FinancialPeriod? period,
  }) {
    final result = <TransactionCategory, int>{};
    final source = period == null
        ? transactions
        : forPeriod(transactions, period);
    for (final item in source) {
      if (item.type != TransactionType.expense || item.excludedFromBudget) {
        continue;
      }
      result.update(
        item.category,
        (value) => value + item.amountInCents,
        ifAbsent: () => item.amountInCents,
      );
    }
    return result;
  }

  int monthlyNeededInCents(Goal goal, int months) {
    if (goal.remainingAmountInCents <= 0) return 0;
    if (months <= 0) return goal.remainingAmountInCents;
    return (goal.remainingAmountInCents / months).ceil();
  }

  int estimatedMonths(Goal goal, int monthlyCapacityInCents) {
    if (goal.remainingAmountInCents <= 0) return 0;
    if (monthlyCapacityInCents <= 0) return -1;
    return (goal.remainingAmountInCents / monthlyCapacityInCents).ceil();
  }

  bool hasInsufficientBudget(Goal goal, int monthlyCapacityInCents) =>
      monthlyNeededInCents(goal, goal.deadlineMonths) > monthlyCapacityInCents;

  FinancialSummary simulateExpenseChange(
    FinancialSummary summary,
    int deltaInCents,
  ) {
    final simulated = summary.expensesInCents + deltaInCents;
    return FinancialSummary(
      incomeInCents: summary.incomeInCents,
      expensesInCents: simulated < 0 ? 0 : simulated,
    );
  }
}
