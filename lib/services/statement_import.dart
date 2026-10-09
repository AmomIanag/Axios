import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdfrx/pdfrx.dart';

import '../models/financial_transaction.dart';
import '../models/money.dart';
import '../models/transaction_category.dart';

class StatementImportException implements Exception {
  const StatementImportException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SelectedPdf {
  const SelectedPdf({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

abstract interface class StatementFilePicker {
  Future<SelectedPdf?> pickPdf();
}

class PlatformStatementFilePicker implements StatementFilePicker {
  const PlatformStatementFilePicker();

  @override
  Future<SelectedPdf?> pickPdf() async {
    final file = await FilePicker.pickFile(
      dialogTitle: 'Selecione um extrato em PDF',
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );
    if (file == null) return null;
    return SelectedPdf(name: file.name, bytes: await file.readAsBytes());
  }
}

abstract interface class PdfTextExtractor {
  Future<List<String>> extractPages(Uint8List bytes);
}

class PdfrxTextExtractor implements PdfTextExtractor {
  const PdfrxTextExtractor();

  @override
  Future<List<String>> extractPages(Uint8List bytes) async {
    PdfDocument? document;
    try {
      document = await PdfDocument.openData(bytes, sourceName: 'extrato.pdf');
      final pages = <String>[];
      for (final page in document.pages) {
        final text = await page.loadStructuredText();
        pages.add(text.fullText);
      }
      return pages;
    } catch (_) {
      throw const StatementImportException(
        'Não foi possível ler o PDF. Verifique se o arquivo é válido e não possui senha.',
      );
    } finally {
      await document?.dispose();
    }
  }
}

class StatementParseResult {
  const StatementParseResult({
    required this.transactions,
    required this.unrecognizedLines,
    required this.periodStart,
    required this.periodEndExclusive,
  });

  final List<FinancialTransaction> transactions;
  final List<String> unrecognizedLines;
  final DateTime periodStart;
  final DateTime periodEndExclusive;

  int get incomeInCents => transactions
      .where((item) => item.type == TransactionType.income)
      .fold(0, (total, item) => total + item.amountInCents);

  int get expensesInCents => transactions
      .where((item) => item.type == TransactionType.expense)
      .fold(0, (total, item) => total + item.amountInCents);
}

class PreparedStatementImport {
  const PreparedStatementImport({
    required this.fileName,
    required this.batchId,
    required this.result,
    this.origin = TransactionOrigin.pdf,
  });

  final String fileName;
  final String batchId;
  final StatementParseResult result;
  final TransactionOrigin origin;
}

class AxiosStatementParser {
  const AxiosStatementParser();

  static final _transactionLine = RegExp(
    r'^(\d{2}/\d{2}/\d{4})\s+(.+?)\s+([+-])\s*R\$\s*([\d.]+,\d{2})(?:\s+R\$\s*[\d.]+,\d{2})?\s*$',
    caseSensitive: false,
  );

  StatementParseResult parse(List<String> pages, {required String batchId}) {
    final transactions = <FinancialTransaction>[];
    final unrecognized = <String>[];

    for (final page in pages) {
      final lines = page
          .replaceAll('\u00a0', ' ')
          .split(RegExp(r'[\r\n]+'))
          .map((line) => line.replaceAll(RegExp(r'\s+'), ' ').trim())
          .where((line) => line.isNotEmpty);
      for (final line in lines) {
        final match = _transactionLine.firstMatch(line);
        if (match == null) {
          if (_looksLikeUnrecognizedTransaction(line)) unrecognized.add(line);
          continue;
        }
        final date = _parseDate(match.group(1)!);
        final description = match.group(2)!.trim();
        if (_isBalanceOrTotal(description)) continue;
        final amount = Money.parseBrazilian(match.group(4)!);
        final type = match.group(3) == '+'
            ? TransactionType.income
            : TransactionType.expense;
        final fingerprint = _fingerprint(
          date: date,
          description: description,
          signedAmountInCents: type == TransactionType.income
              ? amount.cents
              : -amount.cents,
        );
        transactions.add(
          FinancialTransaction(
            id: '',
            description: description,
            category: suggestCategory(description, type),
            date: date,
            amountInCents: amount.cents.abs(),
            type: type,
            origin: TransactionOrigin.pdf,
            externalId: 'pdf:$fingerprint',
            importBatchId: batchId,
            fingerprint: fingerprint,
          ),
        );
      }
    }

    transactions.sort((a, b) => a.date.compareTo(b.date));
    if (transactions.isEmpty) {
      throw const StatementImportException(
        'Nenhuma movimentação compatível foi encontrada neste extrato.',
      );
    }
    final first = transactions.first.date;
    final last = transactions.last.date;
    return StatementParseResult(
      transactions: List.unmodifiable(transactions),
      unrecognizedLines: List.unmodifiable(unrecognized),
      periodStart: DateTime(first.year, first.month),
      periodEndExclusive: DateTime(last.year, last.month + 1),
    );
  }

  TransactionCategory suggestCategory(
    String description,
    TransactionType type,
  ) {
    if (type == TransactionType.income) return TransactionCategory.income;
    final value = _normalize(description);
    if (_containsAny(value, ['aluguel'])) return TransactionCategory.housing;
    if (_containsAny(value, [
      'mercado',
      'supermercado',
      'padaria',
      'restaurante',
      'refeicao',
      'cafeteria',
    ])) {
      return TransactionCategory.food;
    }
    if (_containsAny(value, ['transporte', 'posto', 'combustivel', 'uber'])) {
      return TransactionCategory.transport;
    }
    if (_containsAny(value, ['farmacia', 'academia'])) {
      return TransactionCategory.health;
    }
    if (_containsAny(value, ['cinema'])) return TransactionCategory.leisure;
    if (_containsAny(value, ['livraria', 'curso'])) {
      return TransactionCategory.education;
    }
    if (_containsAny(value, ['streaming'])) {
      return TransactionCategory.subscriptions;
    }
    if (_containsAny(value, ['energia', 'internet', 'agua', 'telefonia'])) {
      return TransactionCategory.utilities;
    }
    if (_containsAny(value, ['loja'])) return TransactionCategory.shopping;
    if (_containsAny(value, ['pix enviado', 'transferencia'])) {
      return TransactionCategory.transfer;
    }
    return TransactionCategory.other;
  }

  bool _looksLikeUnrecognizedTransaction(String line) {
    final normalized = _normalize(line);
    if (_isBalanceOrTotal(normalized)) return false;
    return RegExp(r'\d{2}/\d{2}/\d{4}').hasMatch(line) &&
        line.toUpperCase().contains(r'R$');
  }

  bool _isBalanceOrTotal(String value) {
    final normalized = _normalize(value);
    return _containsAny(normalized, [
      'saldo inicial',
      'saldo final',
      'resumo do periodo',
      'entradas',
      'saidas',
    ]);
  }

  bool _containsAny(String value, List<String> terms) =>
      terms.any(value.contains);

  DateTime _parseDate(String value) {
    final parts = value.split('/').map(int.parse).toList(growable: false);
    return DateTime(parts[2], parts[1], parts[0]);
  }

  String _fingerprint({
    required DateTime date,
    required String description,
    required int signedAmountInCents,
  }) {
    final isoDate =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return sha256
        .convert(
          utf8.encode(
            '$isoDate|${_normalize(description)}|$signedAmountInCents',
          ),
        )
        .toString();
  }

  String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[áàâã]'), 'a')
      .replaceAll(RegExp(r'[éèê]'), 'e')
      .replaceAll(RegExp(r'[íìî]'), 'i')
      .replaceAll(RegExp(r'[óòôõ]'), 'o')
      .replaceAll(RegExp(r'[úùû]'), 'u')
      .replaceAll('ç', 'c')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

class StatementImportService {
  const StatementImportService({
    this.extractor = const PdfrxTextExtractor(),
    this.parser = const AxiosStatementParser(),
    this.maxFileSize = 10 * 1024 * 1024,
  });

  final PdfTextExtractor extractor;
  final AxiosStatementParser parser;
  final int maxFileSize;

  Future<PreparedStatementImport> prepare(SelectedPdf file) async {
    if (!file.name.toLowerCase().endsWith('.pdf')) {
      throw const StatementImportException('Selecione um arquivo PDF.');
    }
    if (file.bytes.isEmpty) {
      throw const StatementImportException('O arquivo selecionado está vazio.');
    }
    if (file.bytes.length > maxFileSize) {
      throw const StatementImportException('O PDF excede o limite de 10 MB.');
    }
    if (file.bytes.length < 5 ||
        ascii.decode(file.bytes.sublist(0, 5), allowInvalid: true) != '%PDF-') {
      throw const StatementImportException(
        'O arquivo não possui uma assinatura PDF válida.',
      );
    }

    final batchId = sha256.convert(file.bytes).toString();
    final pages = await extractor.extractPages(file.bytes);
    if (pages.every((page) => page.trim().isEmpty)) {
      throw const StatementImportException(
        'O PDF não contém texto selecionável para importação.',
      );
    }
    return PreparedStatementImport(
      fileName: file.name,
      batchId: batchId,
      result: parser.parse(pages, batchId: batchId),
    );
  }
}

class StatementImportCoordinator {
  const StatementImportCoordinator({
    this.picker = const PlatformStatementFilePicker(),
    this.service = const StatementImportService(),
  });

  final StatementFilePicker picker;
  final StatementImportService service;

  Future<PreparedStatementImport?> pickAndPrepare() async {
    final selected = await picker.pickPdf();
    if (selected == null) return null;
    return service.prepare(selected);
  }
}
