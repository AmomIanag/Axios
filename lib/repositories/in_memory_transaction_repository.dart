import 'dart:async';

import '../models/financial_transaction.dart';
import 'transaction_repository.dart';

class InMemoryTransactionRepository implements TransactionRepository {
  InMemoryTransactionRepository({
    List<FinancialTransaction> initialTransactions = const [],
  }) : _initialTransactions = List.of(initialTransactions);

  final List<FinancialTransaction> _initialTransactions;
  final Map<String, List<FinancialTransaction>> _transactions = {};
  final Map<String, StreamController<List<FinancialTransaction>>> _controllers =
      {};
  int _nextId = 1;

  List<FinancialTransaction> _items(String userId) =>
      _transactions.putIfAbsent(userId, () => List.of(_initialTransactions));

  StreamController<List<FinancialTransaction>> _controller(String userId) =>
      _controllers.putIfAbsent(
        userId,
        () => StreamController<List<FinancialTransaction>>.broadcast(),
      );

  void _emit(String userId) {
    final sorted = List<FinancialTransaction>.of(_items(userId))
      ..sort((a, b) => b.date.compareTo(a.date));
    _controller(userId).add(List.unmodifiable(sorted));
  }

  @override
  Stream<List<FinancialTransaction>> watchTransactions(String userId) async* {
    final sorted = List<FinancialTransaction>.of(_items(userId))
      ..sort((a, b) => b.date.compareTo(a.date));
    yield List.unmodifiable(sorted);
    yield* _controller(userId).stream;
  }

  @override
  Future<void> addTransaction(
    String userId,
    FinancialTransaction transaction,
  ) async {
    final now = DateTime.now();
    _items(userId).add(
      transaction.copyWith(
        id: transaction.id.isEmpty
            ? 'transaction-${_nextId++}'
            : transaction.id,
        createdAt: transaction.createdAt ?? now,
        updatedAt: now,
      ),
    );
    _emit(userId);
  }

  @override
  Future<void> updateTransaction(
    String userId,
    FinancialTransaction transaction,
  ) async {
    final items = _items(userId);
    final index = items.indexWhere((item) => item.id == transaction.id);
    if (index < 0) throw StateError('Transação não encontrada.');
    items[index] = transaction.copyWith(updatedAt: DateTime.now());
    _emit(userId);
  }

  @override
  Future<void> deleteTransaction(String userId, String transactionId) async {
    _items(userId).removeWhere((item) => item.id == transactionId);
    _emit(userId);
  }

  @override
  Future<TransactionImportResult> importTransactions(
    String userId,
    List<FinancialTransaction> transactions, {
    required ImportMode mode,
    required DateTime periodStart,
    required DateTime periodEndExclusive,
  }) async {
    final items = _items(userId);
    var replaced = 0;
    if (mode == ImportMode.replaceImportedPeriod) {
      final origin = transactions.firstOrNull?.origin ?? TransactionOrigin.pdf;
      final before = items.length;
      items.removeWhere(
        (item) =>
            item.origin == origin &&
            !item.date.isBefore(periodStart) &&
            item.date.isBefore(periodEndExclusive),
      );
      replaced = before - items.length;
    }

    final fingerprints = items
        .map((item) => item.fingerprint)
        .whereType<String>()
        .toSet();
    var inserted = 0;
    var skipped = 0;
    for (final transaction in transactions) {
      final fingerprint = transaction.fingerprint;
      if (fingerprint != null && fingerprints.contains(fingerprint)) {
        skipped++;
        continue;
      }
      final now = DateTime.now();
      items.add(
        transaction.copyWith(
          id: transaction.id.isEmpty
              ? 'transaction-${_nextId++}'
              : transaction.id,
          createdAt: transaction.createdAt ?? now,
          updatedAt: now,
        ),
      );
      if (fingerprint != null) fingerprints.add(fingerprint);
      inserted++;
    }
    _emit(userId);
    return TransactionImportResult(
      inserted: inserted,
      skippedDuplicates: skipped,
      replaced: replaced,
    );
  }
}
