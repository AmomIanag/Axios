import '../models/financial_transaction.dart';

enum ImportMode { addWithoutDuplicates, replaceImportedPeriod }

class TransactionImportResult {
  const TransactionImportResult({
    required this.inserted,
    required this.skippedDuplicates,
    required this.replaced,
  });

  final int inserted;
  final int skippedDuplicates;
  final int replaced;
}

abstract interface class TransactionRepository {
  Stream<List<FinancialTransaction>> watchTransactions(String userId);

  Future<void> addTransaction(String userId, FinancialTransaction transaction);

  Future<void> updateTransaction(
    String userId,
    FinancialTransaction transaction,
  );

  Future<void> deleteTransaction(String userId, String transactionId);

  Future<TransactionImportResult> importTransactions(
    String userId,
    List<FinancialTransaction> transactions, {
    required ImportMode mode,
    required DateTime periodStart,
    required DateTime periodEndExclusive,
  });
}
