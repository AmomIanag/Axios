import 'package:axios/app.dart';
import 'package:axios/app_dependencies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('valida os campos obrigatórios no login', (tester) async {
    final dependencies = AppDependencies.demo();
    await tester.pumpWidget(AxiosApp(controller: dependencies.controller));

    expect(find.text('Axios'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('login-button')));
    await tester.pump();

    expect(find.text('Digite um e-mail válido.'), findsOneWidget);
    expect(
      find.text('A senha deve ter pelo menos 6 caracteres.'),
      findsOneWidget,
    );
  });
}
