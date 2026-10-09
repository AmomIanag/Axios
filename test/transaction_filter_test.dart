import 'package:axios/data/mock_financial_data.dart';
import 'package:axios/models/financial_transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('filtros de transações', () {
    test('filtra somente receitas', () {
      final result = filterTransactions(
        MockFinancialData.transactions,
        filter: TransactionFilter.income,
      );

      expect(result, isNotEmpty);
      expect(
        result.every((item) => item.type == TransactionType.income),
        isTrue,
      );
    });

    test('busca por descrição sem diferenciar maiúsculas', () {
      final result = filterTransactions(
        MockFinancialData.transactions,
        query: 'NETFLIX',
      );

      expect(result, hasLength(1));
      expect(result.single.description, 'Netflix');
    });

    test('combina busca e filtro e pode retornar vazio', () {
      final result = filterTransactions(
        MockFinancialData.transactions,
        filter: TransactionFilter.income,
        query: 'Uber',
      );

      expect(result, isEmpty);
    });
  });
}
