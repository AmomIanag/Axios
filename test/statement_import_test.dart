import 'dart:io';

import 'package:axios/models/financial_transaction.dart';
import 'package:axios/models/transaction_category.dart';
import 'package:axios/repositories/in_memory_transaction_repository.dart';
import 'package:axios/repositories/transaction_repository.dart';
import 'package:axios/services/statement_import.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:pdfrx/pdfrx.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => Directory.systemTemp.path,
        );
    await pdfrxFlutterInitialize();
  });

  const fixturePath =
      'docs/fixtures/extrato_bancario_ficticio_amom_ianaguivara_setembro_2026.pdf';

  group('extrato PDF real do Axios', () {
    test('extrai as 30 movimentações e confere totais e ordem', () async {
      final bytes = await File(fixturePath).readAsBytes();
      final prepared = await const StatementImportService().prepare(
        SelectedPdf(name: 'extrato-setembro-2026.pdf', bytes: bytes),
      );

      expect(prepared.result.transactions, hasLength(30));
      expect(prepared.result.incomeInCents, 421475);
      expect(prepared.result.expensesInCents, 294467);
      expect(prepared.result.periodStart, DateTime(2026, 9));
      expect(prepared.result.periodEndExclusive, DateTime(2026, 10));
      expect(
        prepared.result.transactions.first.description,
        'Transferência recebida - Salário',
      );
      expect(
        prepared.result.transactions.last.description,
        'Cartão débito - Mercado Bom Dia',
      );
      expect(
        prepared.result.transactions.any(
          (item) => item.description.toLowerCase().contains('saldo'),
        ),
        isFalse,
      );
    });

    test('reimportação é idempotente e ignora duplicatas', () async {
      final bytes = await File(fixturePath).readAsBytes();
      final prepared = await const StatementImportService().prepare(
        SelectedPdf(name: 'extrato.pdf', bytes: bytes),
      );
      final repository = InMemoryTransactionRepository();

      final first = await repository.importTransactions(
        'user',
        prepared.result.transactions,
        mode: ImportMode.addWithoutDuplicates,
        periodStart: prepared.result.periodStart,
        periodEndExclusive: prepared.result.periodEndExclusive,
      );
      final second = await repository.importTransactions(
        'user',
        prepared.result.transactions,
        mode: ImportMode.addWithoutDuplicates,
        periodStart: prepared.result.periodStart,
        periodEndExclusive: prepared.result.periodEndExclusive,
      );

      expect(first.inserted, 30);
      expect(second.inserted, 0);
      expect(second.skippedDuplicates, 30);
      expect(await repository.watchTransactions('user').first, hasLength(30));
    });

    test('substituição remove somente PDF do período', () async {
      final bytes = await File(fixturePath).readAsBytes();
      final prepared = await const StatementImportService().prepare(
        SelectedPdf(name: 'extrato.pdf', bytes: bytes),
      );
      final repository = InMemoryTransactionRepository();
      await repository.addTransaction(
        'user',
        FinancialTransaction(
          id: 'manual',
          description: 'Despesa manual',
          category: TransactionCategory.other,
          date: DateTime(2026, 9, 10),
          amountInCents: 1000,
          type: TransactionType.expense,
        ),
      );
      await repository.importTransactions(
        'user',
        prepared.result.transactions,
        mode: ImportMode.addWithoutDuplicates,
        periodStart: prepared.result.periodStart,
        periodEndExclusive: prepared.result.periodEndExclusive,
      );

      final replacement = await repository.importTransactions(
        'user',
        [prepared.result.transactions.first],
        mode: ImportMode.replaceImportedPeriod,
        periodStart: prepared.result.periodStart,
        periodEndExclusive: prepared.result.periodEndExclusive,
      );
      final remaining = await repository.watchTransactions('user').first;

      expect(replacement.replaced, 30);
      expect(replacement.inserted, 1);
      expect(remaining, hasLength(2));
      expect(remaining.any((item) => item.id == 'manual'), isTrue);
    });
  });

  group('falhas e ambiguidades', () {
    test('rejeita arquivo vazio', () async {
      await expectLater(
        const StatementImportService().prepare(
          SelectedPdf(name: 'vazio.pdf', bytes: Uint8List(0)),
        ),
        throwsA(isA<StatementImportException>()),
      );
    });

    test('rejeita arquivo sem assinatura PDF', () async {
      await expectLater(
        const StatementImportService().prepare(
          SelectedPdf(
            name: 'invalido.pdf',
            bytes: Uint8List.fromList('texto comum'.codeUnits),
          ),
        ),
        throwsA(isA<StatementImportException>()),
      );
    });

    test('informa lançamento não reconhecido sem perder os válidos', () {
      const parser = AxiosStatementParser();
      final result = parser.parse(const [
        '01/09/2026 PIX recebido - Teste +R\$ 10,00 R\$ 10,00\n'
            '02/09/2026 linha ambígua R\$ 5,00',
      ], batchId: 'batch');

      expect(result.transactions, hasLength(1));
      expect(result.unrecognizedLines, hasLength(1));
    });

    test('cancelamento não tenta extrair documento', () async {
      final extractor = _CountingExtractor();
      final coordinator = StatementImportCoordinator(
        picker: const _CancelledPicker(),
        service: StatementImportService(extractor: extractor),
      );

      expect(await coordinator.pickAndPrepare(), isNull);
      expect(extractor.calls, 0);
    });
  });
}

class _CancelledPicker implements StatementFilePicker {
  const _CancelledPicker();

  @override
  Future<SelectedPdf?> pickPdf() async => null;
}

class _CountingExtractor implements PdfTextExtractor {
  int calls = 0;

  @override
  Future<List<String>> extractPages(Uint8List bytes) async {
    calls++;
    return const [];
  }
}
