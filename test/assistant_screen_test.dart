import 'dart:async';

import 'package:axios/app.dart';
import 'package:axios/models/app_user.dart';
import 'package:axios/repositories/demo_auth_repository.dart';
import 'package:axios/repositories/in_memory_goal_repository.dart';
import 'package:axios/repositories/in_memory_transaction_repository.dart';
import 'package:axios/services/ai_assistant_service.dart';
import 'package:axios/state/app_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_ai_assistant_service.dart';

void main() {
  testWidgets('envia, exibe loading e preserva conversa entre abas', (
    tester,
  ) async {
    final completer = Completer<String>();
    final service = FakeAiAssistantService(handler: (_) => completer.future);
    final controller = _controller(service);
    addTearDown(controller.dispose);
    await _openAssistant(tester, controller);

    await tester.enterText(
      find.byKey(const ValueKey('assistant-input')),
      'Quanto posso guardar?',
    );
    await tester.tap(find.byKey(const ValueKey('assistant-send')));
    await tester.pump();

    expect(find.byKey(const ValueKey('assistant-loading')), findsOneWidget);
    expect(find.text('Quanto posso guardar?'), findsOneWidget);

    completer.complete('Você pode guardar R\$ 850,00 neste cenário.');
    await tester.pumpAndSettle();
    expect(find.textContaining('R\$ 850,00'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nav-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('nav-3')));
    await tester.pumpAndSettle();

    expect(find.text('Quanto posso guardar?'), findsOneWidget);
    expect(find.textContaining('R\$ 850,00'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mostra erro de rede e retry não duplica pergunta', (
    tester,
  ) async {
    var attempts = 0;
    final service = FakeAiAssistantService(
      handler: (_) async {
        attempts++;
        if (attempts == 1) {
          throw const AssistantFailure(
            AssistantFailureKind.network,
            'Sem conexão com o assistente.',
          );
        }
        return 'Resposta após reconexão.';
      },
    );
    final controller = _controller(service);
    addTearDown(controller.dispose);
    await _openAssistant(tester, controller);

    await tester.enterText(
      find.byKey(const ValueKey('assistant-input')),
      'Analise meu mês',
    );
    await tester.tap(find.byKey(const ValueKey('assistant-send')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('assistant-error')), findsOneWidget);
    expect(find.text('Sem conexão com o assistente.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('assistant-retry')));
    await tester.pumpAndSettle();

    expect(find.text('Resposta após reconexão.'), findsOneWidget);
    expect(find.text('Analise meu mês'), findsOneWidget);
    expect(
      controller.assistantMessages.where(
        (message) => message.text == 'Analise meu mês',
      ),
      hasLength(1),
    );
    expect(tester.takeException(), isNull);
  });
}

AppController _controller(FakeAiAssistantService service) {
  final controller = AppController(
    DemoAuthRepository(
      initialUser: const AppUser(
        id: 'widget-assistant-user',
        email: 'widget@axios.test',
      ),
    ),
    InMemoryGoalRepository(),
    transactionRepository: InMemoryTransactionRepository(),
    assistantService: service,
    firebaseAvailable: true,
  );
  controller.initialize();
  return controller;
}

Future<void> _openAssistant(
  WidgetTester tester,
  AppController controller,
) async {
  await tester.pumpWidget(AxiosApp(controller: controller));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('nav-3')));
  await tester.pumpAndSettle();
}
