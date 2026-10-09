import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/financial_transaction.dart';
import '../models/transaction_category.dart';
import 'transaction_repository.dart';

class FirestoreTransactionRepository implements TransactionRepository {
  FirestoreTransactionRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _transactions(String userId) =>
      _firestore.collection('users').doc(userId).collection('transactions');

  @override
  Stream<List<FinancialTransaction>> watchTransactions(String userId) =>
      _transactions(userId)
          .orderBy('date', descending: true)
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs.map(_fromFirestore).toList(growable: false),
          );

  @override
  Future<void> addTransaction(
    String userId,
    FinancialTransaction transaction,
  ) async {
    final document = transaction.id.isEmpty
        ? _transactions(userId).doc()
        : _transactions(userId).doc(transaction.id);
    final now = DateTime.now();
    await document.set(
      _toFirestore(
        userId,
        transaction.copyWith(
          id: document.id,
          createdAt: transaction.createdAt ?? now,
          updatedAt: now,
        ),
      ),
    );
  }

  @override
  Future<void> updateTransaction(
    String userId,
    FinancialTransaction transaction,
  ) => _transactions(userId)
      .doc(transaction.id)
      .update(
        _toFirestore(userId, transaction.copyWith(updatedAt: DateTime.now()))
          ..remove('createdAt'),
      );

  @override
  Future<void> deleteTransaction(String userId, String transactionId) =>
      _transactions(userId).doc(transactionId).delete();

  @override
  Future<TransactionImportResult> importTransactions(
    String userId,
    List<FinancialTransaction> transactions, {
    required ImportMode mode,
    required DateTime periodStart,
    required DateTime periodEndExclusive,
  }) async {
    final existing = await _transactions(userId).get();
    final existingTransactions = existing.docs.map(_fromFirestore).toList();
    final fingerprints = existingTransactions
        .map((item) => item.fingerprint)
        .whereType<String>()
        .toSet();
    final writes = <_PendingWrite>[];
    var replaced = 0;

    if (mode == ImportMode.replaceImportedPeriod) {
      final origin = transactions.firstOrNull?.origin ?? TransactionOrigin.pdf;
      for (final document in existing.docs) {
        final item = _fromFirestore(document);
        if (item.origin == origin &&
            !item.date.isBefore(periodStart) &&
            item.date.isBefore(periodEndExclusive)) {
          writes.add(_PendingWrite.delete(document.reference));
          if (item.fingerprint != null) fingerprints.remove(item.fingerprint);
          replaced++;
        }
      }
    }

    var inserted = 0;
    var skipped = 0;
    final now = DateTime.now();
    for (final item in transactions) {
      if (item.fingerprint != null && fingerprints.contains(item.fingerprint)) {
        skipped++;
        continue;
      }
      final document = _transactions(userId).doc();
      final persisted = item.copyWith(
        id: document.id,
        createdAt: now,
        updatedAt: now,
      );
      writes.add(_PendingWrite.set(document, _toFirestore(userId, persisted)));
      if (item.fingerprint != null) fingerprints.add(item.fingerprint!);
      inserted++;
    }

    if (writes.length > 400) {
      throw StateError(
        'A importação excede o limite seguro de 400 alterações por lote.',
      );
    }
    if (writes.isNotEmpty) {
      final batch = _firestore.batch();
      for (final write in writes) {
        if (write.delete) {
          batch.delete(write.reference);
        } else {
          batch.set(write.reference, write.data!);
        }
      }
      await batch.commit();
    }

    return TransactionImportResult(
      inserted: inserted,
      skippedDuplicates: skipped,
      replaced: replaced,
    );
  }

  FinancialTransaction _fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    final legacyAmount = (data['amount'] as num?)?.toDouble();
    final amountInCents =
        (data['amountInCents'] as num?)?.toInt() ??
        ((legacyAmount ?? 0) * 100).round();
    return FinancialTransaction(
      id: document.id,
      description: data['description'] as String? ?? 'Transação',
      category: TransactionCategory.fromId(data['category'] as String?),
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      amountInCents: amountInCents.abs(),
      type: _enumValue(
        TransactionType.values,
        data['type'] as String?,
        TransactionType.expense,
      ),
      origin: _enumValue(
        TransactionOrigin.values,
        data['origin'] as String?,
        TransactionOrigin.manual,
      ),
      externalId: data['externalId'] as String?,
      importBatchId: data['importBatchId'] as String?,
      fingerprint: data['fingerprint'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      pending: data['pending'] as bool? ?? false,
      excludedFromBudget: data['excludedFromBudget'] as bool? ?? false,
    );
  }

  Map<String, Object> _toFirestore(String userId, FinancialTransaction item) {
    final data = <String, Object>{
      'ownerUid': userId,
      'description': item.description,
      'category': item.category.id,
      'date': Timestamp.fromDate(item.date),
      'amountInCents': item.amountInCents,
      'type': item.type.name,
      'origin': item.origin.name,
      'pending': item.pending,
      'excludedFromBudget': item.excludedFromBudget,
      'createdAt': Timestamp.fromDate(item.createdAt ?? DateTime.now()),
      'updatedAt': Timestamp.fromDate(item.updatedAt ?? DateTime.now()),
    };
    if (item.externalId != null) data['externalId'] = item.externalId!;
    if (item.importBatchId != null) data['importBatchId'] = item.importBatchId!;
    if (item.fingerprint != null) data['fingerprint'] = item.fingerprint!;
    return data;
  }

  T _enumValue<T extends Enum>(List<T> values, String? name, T fallback) =>
      values.where((value) => value.name == name).firstOrNull ?? fallback;
}

class _PendingWrite {
  const _PendingWrite._(this.reference, this.data, this.delete);

  factory _PendingWrite.delete(
    DocumentReference<Map<String, dynamic>> reference,
  ) => _PendingWrite._(reference, null, true);

  factory _PendingWrite.set(
    DocumentReference<Map<String, dynamic>> reference,
    Map<String, Object> data,
  ) => _PendingWrite._(reference, data, false);

  final DocumentReference<Map<String, dynamic>> reference;
  final Map<String, Object>? data;
  final bool delete;
}
