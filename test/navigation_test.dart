import 'package:axios/app.dart';
import 'package:axios/app_dependencies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('navega pelas quatro abas sem empilhar rotas', (tester) async {
    final dependencies = AppDependencies.demo(authenticated: true);
    await tester.pumpWidget(AxiosApp(controller: dependencies.controller));
    await tester.pumpAndSettle();

    expect(find.text('Resumo financeiro'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nav-1')));
    await tester.pumpAndSettle();
    expect(find.text('Acompanhe suas movimentações'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nav-2')));
    await tester.pumpAndSettle();
    expect(find.text('Acompanhe seus objetivos financeiros'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nav-3')));
    await tester.pumpAndSettle();
    expect(find.text('Respostas simuladas'), findsOneWidget);
  });

  testWidgets('mostra estado vazio após uma busca sem resultado', (
    tester,
  ) async {
    final dependencies = AppDependencies.demo(authenticated: true);
    await tester.pumpWidget(AxiosApp(controller: dependencies.controller));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('nav-1')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('transaction-search')),
      'não existe',
    );
    await tester.pump();

    expect(find.text('Nenhuma transação encontrada'), findsOneWidget);
  });
}
