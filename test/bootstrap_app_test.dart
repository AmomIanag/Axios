import 'package:axios/app_dependencies.dart';
import 'package:axios/bootstrap_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('exibe erro de inicialização e permite tentar novamente', (
    tester,
  ) async {
    var attempts = 0;

    Future<AppDependencies> bootstrap() async {
      attempts++;
      if (attempts == 1) {
        throw const FirebaseInitializationException(
          'Não foi possível conectar ao Firebase.',
        );
      }
      return AppDependencies.demo();
    }

    await tester.pumpWidget(AxiosBootstrapApp(bootstrap: bootstrap));
    await tester.pumpAndSettle();

    expect(find.text('Não foi possível iniciar o Axios'), findsOneWidget);
    expect(find.text('Não foi possível conectar ao Firebase.'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);

    await tester.tap(find.byKey(const Key('firebase-retry-button')));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.byKey(const ValueKey('login-button')), findsOneWidget);
    expect(find.textContaining('Modo demonstração ativo'), findsOneWidget);
  });
}
