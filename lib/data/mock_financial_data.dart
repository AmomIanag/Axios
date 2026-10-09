import '../models/financial_summary.dart';
import '../models/financial_transaction.dart';
import '../models/goal.dart';

abstract final class MockFinancialData {
  static final transactions = <FinancialTransaction>[
    FinancialTransaction(
      id: 'salary',
      description: 'Salário',
      category: 'Receita',
      date: DateTime(2026, 9, 5),
      amount: 3000,
      type: TransactionType.income,
    ),
    FinancialTransaction(
      id: 'market',
      description: 'Mercado',
      category: 'Alimentação',
      date: DateTime(2026, 9, 5),
      amount: 620,
      type: TransactionType.expense,
    ),
    FinancialTransaction(
      id: 'restaurant',
      description: 'Restaurante',
      category: 'Alimentação',
      date: DateTime(2026, 9, 13),
      amount: 380,
      type: TransactionType.expense,
    ),
    FinancialTransaction(
      id: 'uber',
      description: 'Uber',
      category: 'Transporte',
      date: DateTime(2026, 9, 11),
      amount: 120,
      type: TransactionType.expense,
    ),
    FinancialTransaction(
      id: 'fuel',
      description: 'Combustível',
      category: 'Transporte',
      date: DateTime(2026, 9, 18),
      amount: 280,
      type: TransactionType.expense,
    ),
    FinancialTransaction(
      id: 'netflix',
      description: 'Netflix',
      category: 'Lazer',
      date: DateTime(2026, 9, 2),
      amount: 39.90,
      type: TransactionType.expense,
    ),
    FinancialTransaction(
      id: 'cinema',
      description: 'Cinema e lazer',
      category: 'Lazer',
      date: DateTime(2026, 9, 20),
      amount: 160.10,
      type: TransactionType.expense,
    ),
    FinancialTransaction(
      id: 'energy',
      description: 'Conta de energia',
      category: 'Moradia',
      date: DateTime(2026, 9, 8),
      amount: 250,
      type: TransactionType.expense,
    ),
    FinancialTransaction(
      id: 'internet',
      description: 'Internet',
      category: 'Moradia',
      date: DateTime(2026, 9, 9),
      amount: 120,
      type: TransactionType.expense,
    ),
    FinancialTransaction(
      id: 'pharmacy',
      description: 'Farmácia',
      category: 'Saúde',
      date: DateTime(2026, 9, 1),
      amount: 180,
      type: TransactionType.expense,
    ),
  ];

  static FinancialSummary get summary =>
      FinancialSummary.fromTransactions(transactions);

  static Map<String, double> get expensesByCategory {
    final result = <String, double>{};
    for (final transaction in transactions) {
      if (transaction.type == TransactionType.expense) {
        result.update(
          transaction.category,
          (value) => value + transaction.amount,
          ifAbsent: () => transaction.amount,
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
