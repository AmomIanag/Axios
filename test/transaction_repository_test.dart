import 'package:axios/models/financial_transaction.dart';
import 'package:axios/models/transaction_category.dart';
import 'package:axios/repositories/in_memory_transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CRUD em memória adiciona, edita e exclui transação', () async {
    final repository = InMemoryTransactionRepository();
    final original = FinancialTransaction(
      id: 'transaction-1',
      description: 'Mercado',
      category: TransactionCategory.food,
      date: DateTime(2026, 9, 1),
      amountInCents: 12550,
      type: TransactionType.expense,
    );

    await repository.addTransaction('user', original);
    expect(await repository.watchTransactions('user').first, hasLength(1));

    await repository.updateTransaction(
      'user',
      original.copyWith(description: 'Supermercado', amountInCents: 13000),
    );
    final edited = await repository.watchTransactions('user').first;
    expect(edited.single.description, 'Supermercado');
    expect(edited.single.amountInCents, 13000);

    await repository.deleteTransaction('user', original.id);
    expect(await repository.watchTransactions('user').first, isEmpty);
  });

  test('filtro combina tipo, categoria e descrição', () {
    final transactions = [
      FinancialTransaction(
        id: '1',
        description: 'Mercado Central',
        category: TransactionCategory.food,
        date: DateTime(2026, 9, 1),
        amountInCents: 1000,
        type: TransactionType.expense,
      ),
      FinancialTransaction(
        id: '2',
        description: 'Salário',
        category: TransactionCategory.income,
        date: DateTime(2026, 9, 1),
        amountInCents: 300000,
        type: TransactionType.income,
      ),
    ];

    final result = filterTransactions(
      transactions,
      filter: TransactionFilter.expense,
      category: TransactionCategory.food,
      query: 'central',
    );

    expect(result.map((item) => item.id), ['1']);
  });
}
