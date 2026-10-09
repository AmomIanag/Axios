import 'package:axios/app.dart';
import 'package:axios/app_dependencies.dart';
import 'package:axios/models/app_user.dart';
import 'package:axios/models/financial_transaction.dart';
import 'package:axios/models/transaction_category.dart';
import 'package:axios/repositories/demo_auth_repository.dart';
import 'package:axios/repositories/in_memory_goal_repository.dart';
import 'package:axios/repositories/in_memory_transaction_repository.dart';
import 'package:axios/state/app_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('cria, edita, exclui e reabre formulário de transação', (
    tester,
  ) async {
    final dependencies = AppDependencies.demo(authenticated: true);
    addTearDown(dependencies.controller.dispose);
    await tester.pumpWidget(AxiosApp(controller: dependencies.controller));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('nav-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('new-transaction-button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('transaction-description-field')),
      'Conta CP6',
    );
    await tester.enterText(
      find.byKey(const ValueKey('transaction-amount-field')),
      '12,34',
    );
    await tester.tap(find.byKey(const ValueKey('save-transaction-button')));
    await tester.pumpAndSettle();

    expect(find.text('Conta CP6'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('nav-0')));
    await tester.pumpAndSettle();
    expect(find.textContaining('12,34'), findsNWidgets(2));
    await tester.tap(find.byKey(const ValueKey('nav-1')));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Editar').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('transaction-description-field')),
      'Conta CP6 editada',
    );
    await tester.tap(find.byKey(const ValueKey('save-transaction-button')));
    await tester.pumpAndSettle();
    expect(find.text('Conta CP6 editada'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('new-transaction-button')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('transaction-description-field')),
      findsOneWidget,
    );
    Navigator.of(
      tester.element(
        find.byKey(const ValueKey('transaction-description-field')),
      ),
    ).pop();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Excluir').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
    await tester.pumpAndSettle();
    expect(find.text('Conta CP6 editada'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('nav-0')));
    await tester.pumpAndSettle();
    expect(find.text('Resumo financeiro'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('alterna Receita para Despesa preservando os demais campos', (
    tester,
  ) async {
    final dependencies = AppDependencies.demo(authenticated: true);
    addTearDown(dependencies.controller.dispose);
    await _openNewTransactionForm(tester, dependencies.controller);

    await tester.enterText(
      find.byKey(const ValueKey('transaction-description-field')),
      'Freelance',
    );
    await tester.enterText(
      find.byKey(const ValueKey('transaction-amount-field')),
      '450,75',
    );

    await _selectType(tester, 'Receita');
    expect(
      find.byKey(const ValueKey('transaction-category-field')),
      findsNothing,
    );
    await _selectType(tester, 'Despesa');

    expect(
      find.byKey(const ValueKey('transaction-category-field')),
      findsOneWidget,
    );
    expect(_fieldText(tester, 'transaction-description-field'), 'Freelance');
    expect(_fieldText(tester, 'transaction-amount-field'), '450,75');
    _expectUniqueExpenseCategories(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'alterna repetidamente e mantém a última categoria válida de despesa',
    (tester) async {
      final dependencies = AppDependencies.demo(authenticated: true);
      addTearDown(dependencies.controller.dispose);
      await _openNewTransactionForm(tester, dependencies.controller);

      await _selectCategory(tester, 'Saúde');
      await _selectType(tester, 'Receita');
      await _selectType(tester, 'Despesa');
      await _selectType(tester, 'Receita');
      await _selectType(tester, 'Despesa');

      expect(find.text('Saúde'), findsOneWidget);
      _expectUniqueExpenseCategories(tester);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'edita Receita como Despesa, seleciona categoria e salva sem exceção',
    (tester) async {
      final controller = _controllerWithTransaction(
        FinancialTransaction(
          id: 'income-1',
          description: 'Receita existente',
          category: TransactionCategory.income,
          date: DateTime(2026, 9, 10),
          amountInCents: 325000,
          type: TransactionType.income,
        ),
      );
      addTearDown(controller.dispose);
      await _openExistingTransactionForm(tester, controller);

      await _selectType(tester, 'Despesa');
      _expectUniqueExpenseCategories(tester);
      await _selectCategory(tester, 'Alimentação');
      await tester.tap(find.byKey(const ValueKey('save-transaction-button')));
      await tester.pumpAndSettle();

      final saved = controller.transactions.single;
      expect(saved.description, 'Receita existente');
      expect(saved.amountInCents, 325000);
      expect(saved.type, TransactionType.expense);
      expect(saved.category, TransactionCategory.food);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('edita Despesa como Receita e salva com categoria coerente', (
    tester,
  ) async {
    final controller = _controllerWithTransaction(
      FinancialTransaction(
        id: 'expense-1',
        description: 'Despesa existente',
        category: TransactionCategory.transport,
        date: DateTime(2026, 9, 11),
        amountInCents: 2890,
        type: TransactionType.expense,
      ),
    );
    addTearDown(controller.dispose);
    await _openExistingTransactionForm(tester, controller);

    await _selectType(tester, 'Receita');
    await tester.tap(find.byKey(const ValueKey('save-transaction-button')));
    await tester.pumpAndSettle();

    final saved = controller.transactions.single;
    expect(saved.description, 'Despesa existente');
    expect(saved.amountInCents, 2890);
    expect(saved.type, TransactionType.income);
    expect(saved.category, TransactionCategory.income);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _openNewTransactionForm(
  WidgetTester tester,
  AppController controller,
) async {
  await tester.pumpWidget(AxiosApp(controller: controller));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('nav-1')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('new-transaction-button')));
  await tester.pumpAndSettle();
}

Future<void> _openExistingTransactionForm(
  WidgetTester tester,
  AppController controller,
) async {
  await tester.pumpWidget(AxiosApp(controller: controller));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('nav-1')));
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Editar').first);
  await tester.pumpAndSettle();
}

Future<void> _selectType(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

Future<void> _selectCategory(WidgetTester tester, String label) async {
  await tester.tap(find.byKey(const ValueKey('transaction-category-field')));
  await tester.pumpAndSettle();
  final option = find.text(label).last;
  await tester.ensureVisible(option);
  await tester.pumpAndSettle();
  await tester.tap(option);
  await tester.pumpAndSettle();
}

String _fieldText(WidgetTester tester, String key) {
  return tester
      .widget<TextFormField>(find.byKey(ValueKey(key)))
      .controller!
      .text;
}

void _expectUniqueExpenseCategories(WidgetTester tester) {
  final field = find.byKey(const ValueKey('transaction-category-field'));
  final dropdown = tester.widget<DropdownButton<TransactionCategory>>(
    find.descendant(
      of: field,
      matching: find.byType(DropdownButton<TransactionCategory>),
    ),
  );
  final values = dropdown.items!.map((item) => item.value).toList();
  expect(values, isNot(contains(TransactionCategory.income)));
  expect(values.toSet(), hasLength(values.length));
}

AppController _controllerWithTransaction(FinancialTransaction transaction) {
  final controller = AppController(
    DemoAuthRepository(
      initialUser: const AppUser(id: 'widget-user', email: 'widget@axios.test'),
    ),
    InMemoryGoalRepository(),
    transactionRepository: InMemoryTransactionRepository(
      initialTransactions: [transaction],
    ),
    firebaseAvailable: false,
  );
  controller.initialize();
  return controller;
}
