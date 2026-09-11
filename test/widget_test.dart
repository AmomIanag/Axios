import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:axios/main.dart';

void main() {
  testWidgets('Apresenta o Axios e mantém a tela ao tocar em Começar', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AxiosApp());

    expect(find.text('Axios'), findsOneWidget);
    expect(
      find.text('Seu planejamento financeiro, de forma inteligente.'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Transforme seus dados financeiros em planos para alcançar seus objetivos.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Começar'));
    await tester.pumpAndSettle();

    expect(find.text('Axios'), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
