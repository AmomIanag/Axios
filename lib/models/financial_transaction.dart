enum TransactionType { income, expense }

enum TransactionFilter { all, income, expense }

class FinancialTransaction {
  const FinancialTransaction({
    required this.id,
    required this.description,
    required this.category,
    required this.date,
    required this.amount,
    required this.type,
  });

  final String id;
  final String description;
  final String category;
  final DateTime date;
  final double amount;
  final TransactionType type;

  double get signedAmount => type == TransactionType.income ? amount : -amount;
}

List<FinancialTransaction> filterTransactions(
  Iterable<FinancialTransaction> transactions, {
  TransactionFilter filter = TransactionFilter.all,
  String query = '',
}) {
  final normalizedQuery = query.trim().toLowerCase();
  return transactions
      .where((transaction) {
        final matchesType = switch (filter) {
          TransactionFilter.all => true,
          TransactionFilter.income =>
            transaction.type == TransactionType.income,
          TransactionFilter.expense =>
            transaction.type == TransactionType.expense,
        };
        final matchesQuery =
            normalizedQuery.isEmpty ||
            transaction.description.toLowerCase().contains(normalizedQuery) ||
            transaction.category.toLowerCase().contains(normalizedQuery);
        return matchesType && matchesQuery;
      })
      .toList(growable: false);
}
