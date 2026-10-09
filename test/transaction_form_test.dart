import 'package:axios/app.dart';
import 'package:axios/app_dependencies.dart';
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
}
