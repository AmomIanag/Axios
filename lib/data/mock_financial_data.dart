import '../models/financial_summary.dart';
import '../models/financial_transaction.dart';
import '../models/goal.dart';
import '../models/transaction_category.dart';

abstract final class MockFinancialData {
  static final transactions = <FinancialTransaction>[
    FinancialTransaction(
      id: 'salary',
      description: 'Salário',
      category: TransactionCategory.income,
      date: DateTime(2026, 9, 5),
      amountInCents: 300000,
      type: TransactionType.income,
    ),
    FinancialTransaction(
      id: 'market',
      description: 'Mercado',
      category: TransactionCategory.food,
      date: DateTime(2026, 9, 5),
      amountInCents: 62000,
      type: TransactionType.expense,
    ),
    FinancialTransaction(
      id: 'restaurant',
      description: 'Restaurante',
      category: TransactionCategory.food,
      date: DateTime(2026, 9, 13),
      amountInCents: 38000,
      type: TransactionType.expense,
    ),
    FinancialTransaction(
      id: 'uber',
      description: 'Uber',
      category: TransactionCategory.transport,
      date: DateTime(2026, 9, 11),
      amountInCents: 12000,
      type: TransactionType.expense,
    ),
    FinancialTransaction(
      id: 'fuel',
      description: 'Combustível',
      category: TransactionCategory.transport,
      date: DateTime(2026, 9, 18),
      amountInCents: 28000,
      type: TransactionType.expense,
    ),
    FinancialTransaction(
      id: 'netflix',
      description: 'Netflix',
      category: TransactionCategory.leisure,
      date: DateTime(2026, 9, 2),
      amountInCents: 3990,
      type: TransactionType.expense,
    ),
    FinancialTransaction(
      id: 'cinema',
      description: 'Cinema e lazer',
      category: TransactionCategory.leisure,
      date: DateTime(2026, 9, 20),
      amountInCents: 16010,
      type: TransactionType.expense,
    ),
    FinancialTransaction(
      id: 'energy',
      description: 'Conta de energia',
      category: TransactionCategory.housing,
      date: DateTime(2026, 9, 8),
      amountInCents: 25000,
      type: TransactionType.expense,
    ),
    FinancialTransaction(
      id: 'internet',
      description: 'Internet',
      category: TransactionCategory.housing,
      date: DateTime(2026, 9, 9),
      amountInCents: 12000,
      type: TransactionType.expense,
    ),
    FinancialTransaction(
      id: 'pharmacy',
      description: 'Farmácia',
      category: TransactionCategory.health,
      date: DateTime(2026, 9, 1),
      amountInCents: 18000,
      type: TransactionType.expense,
    ),
  ];

  static FinancialSummary get summary =>
      FinancialSummary.fromTransactions(transactions);

  static Map<String, int> get expensesByCategory {
    final result = <String, int>{};
    for (final transaction in transactions) {
      if (transaction.type == TransactionType.expense) {
        result.update(
          transaction.category.label,
          (value) => value + transaction.amountInCents,
          ifAbsent: () => transaction.amountInCents,
        );
      }
    }
    return result;
  }

  static final goals = <Goal>[
    Goal(
      id: 'viagem',
      name: 'Viagem',
      currentAmount: 1500,
      targetAmount: 6000,
      deadlineMonths: 12,
      monthlyContribution: 500,
      createdAt: DateTime(2026, 9, 1),
    ),
    Goal(
      id: 'notebook',
      name: 'Notebook',
      currentAmount: 800,
      targetAmount: 4000,
      deadlineMonths: 10,
      monthlyContribution: 320,
      createdAt: DateTime(2026, 9, 2),
    ),
  ];
}
