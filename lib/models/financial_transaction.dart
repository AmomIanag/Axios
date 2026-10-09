import 'money.dart';
import 'transaction_category.dart';

enum TransactionType { income, expense }

enum TransactionFilter { all, income, expense }

enum TransactionOrigin { manual, pdf, pluggy }

class FinancialTransaction {
  const FinancialTransaction({
    required this.id,
    required this.description,
    required this.category,
    required this.date,
    required this.amountInCents,
    required this.type,
    this.origin = TransactionOrigin.manual,
    this.externalId,
    this.importBatchId,
    this.fingerprint,
    this.createdAt,
    this.updatedAt,
    this.pending = false,
    this.excludedFromBudget = false,
  }) : assert(amountInCents >= 0);

  final String id;
  final String description;
  final TransactionCategory category;
  final DateTime date;
  final int amountInCents;
  final TransactionType type;
  final TransactionOrigin origin;
  final String? externalId;
  final String? importBatchId;
  final String? fingerprint;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool pending;
  final bool excludedFromBudget;

  Money get amount => Money(amountInCents);
  int get signedAmountInCents =>
      type == TransactionType.income ? amountInCents : -amountInCents;

  FinancialTransaction copyWith({
    String? id,
    String? description,
    TransactionCategory? category,
    DateTime? date,
    int? amountInCents,
    TransactionType? type,
    TransactionOrigin? origin,
    String? externalId,
    String? importBatchId,
    String? fingerprint,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? pending,
    bool? excludedFromBudget,
  }) => FinancialTransaction(
    id: id ?? this.id,
    description: description ?? this.description,
    category: category ?? this.category,
    date: date ?? this.date,
    amountInCents: amountInCents ?? this.amountInCents,
    type: type ?? this.type,
    origin: origin ?? this.origin,
    externalId: externalId ?? this.externalId,
    importBatchId: importBatchId ?? this.importBatchId,
    fingerprint: fingerprint ?? this.fingerprint,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    pending: pending ?? this.pending,
    excludedFromBudget: excludedFromBudget ?? this.excludedFromBudget,
  );
}

List<FinancialTransaction> filterTransactions(
  Iterable<FinancialTransaction> transactions, {
  TransactionFilter filter = TransactionFilter.all,
  TransactionCategory? category,
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
        final matchesCategory =
            category == null || transaction.category == category;
        final matchesQuery =
            normalizedQuery.isEmpty ||
            transaction.description.toLowerCase().contains(normalizedQuery) ||
            transaction.category.label.toLowerCase().contains(normalizedQuery);
        return matchesType && matchesCategory && matchesQuery;
      })
      .toList(growable: false);
}
