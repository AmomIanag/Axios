import 'dart:async';

import 'package:axios/models/app_user.dart';
import 'package:axios/models/financial_transaction.dart';
import 'package:axios/models/transaction_category.dart';
import 'package:axios/repositories/demo_auth_repository.dart';
import 'package:axios/repositories/in_memory_goal_repository.dart';
import 'package:axios/repositories/in_memory_transaction_repository.dart';
import 'package:axios/services/ai_assistant_service.dart';
import 'package:axios/state/app_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_ai_assistant_service.dart';

void main() {
  test('atualiza o contexto após mudanças em transações e metas', () async {
    final service = FakeAiAssistantService(
      handler: (_) async => 'Resposta contextualizada.',
    );
    final controller = _controller(service);
    addTearDown(controller.dispose);
    await _flushStreams();

    await controller.sendAssistantMessage('Como está meu orçamento?');
    expect(service.requests.single.context.expensesInCents, 10000);
    expect(service.requests.single.context.goals, isEmpty);

    await controller.addTransaction(
      FinancialTransaction(
        id: '',
        description: 'Nova despesa privada',
        category: TransactionCategory.health,
        date: DateTime(2026, 9, 20),
        amountInCents: 5000,
        type: TransactionType.expense,
      ),
    );
    await controller.addGoal(
      name: 'Reserva',
      currentAmount: 100,
      targetAmount: 1000,
      deadlineMonths: 9,
    );
    await _flushStreams();

    await controller.sendAssistantMessage('E depois das mudanças?');
    final updated = service.requests.last.context;
    expect(updated.expensesInCents, 15000);
    expect(updated.goals.single.remainingInCents, 90000);
    expect(updated.toPromptJson(), isNot(contains('Nova despesa privada')));
  });

  test('protege contra envio duplicado enquanto aguarda resposta', () async {
    final completer = Completer<String>();
    final service = FakeAiAssistantService(handler: (_) => completer.future);
    final controller = _controller(service);
    addTearDown(controller.dispose);
    await _flushStreams();

    final first = controller.sendAssistantMessage('Pergunta livre');
    expect(controller.assistantBusy, isTrue);
    expect(await controller.sendAssistantMessage('Duplicada'), isFalse);
    expect(service.requests, hasLength(1));

    completer.complete('Resposta real fake.');
    expect(await first, isTrue);
    expect(controller.assistantBusy, isFalse);
    expect(controller.assistantMessages.last.text, 'Resposta real fake.');
  });

  for (final failure in [
    const AssistantFailure(
      AssistantFailureKind.network,
      'Sem conexão com o assistente.',
    ),
    const AssistantFailure(
      AssistantFailureKind.quota,
      'Limite temporário atingido.',
    ),
  ]) {
    test(
      'expõe falha ${failure.kind.name} e permite tentar novamente',
      () async {
        var attempts = 0;
        final service = FakeAiAssistantService(
          handler: (_) async {
            attempts++;
            if (attempts == 1) throw failure;
            return 'Recuperado.';
          },
        );
        final controller = _controller(service);
        addTearDown(controller.dispose);
        await _flushStreams();

        expect(
          await controller.sendAssistantMessage('Pode me ajudar?'),
          isFalse,
        );
        expect(controller.assistantFailure?.kind, failure.kind);
        expect(await controller.retryAssistantMessage(), isTrue);
        expect(controller.assistantFailure, isNull);
        expect(controller.assistantMessages.last.text, 'Recuperado.');
        expect(
          controller.assistantMessages.where(
            (message) => message.text == 'Pode me ajudar?',
          ),
          hasLength(1),
        );
      },
    );
  }

  test('trata resposta vazia sem adicionar mensagem fictícia', () async {
    final service = FakeAiAssistantService(handler: (_) async => '   ');
    final controller = _controller(service);
    addTearDown(controller.dispose);
    await _flushStreams();

    expect(await controller.sendAssistantMessage('Pergunta livre'), isFalse);
    expect(
      controller.assistantFailure?.kind,
      AssistantFailureKind.emptyResponse,
    );
    expect(controller.assistantMessages.last.text, 'Pergunta livre');
  });
}

AppController _controller(FakeAiAssistantService service) {
  final controller = AppController(
    DemoAuthRepository(
      initialUser: const AppUser(
        id: 'assistant-user',
        email: 'privado@axios.test',
      ),
    ),
    InMemoryGoalRepository(),
    transactionRepository: InMemoryTransactionRepository(
      initialTransactions: [
        FinancialTransaction(
          id: 'income',
          description: 'Receita privada',
          category: TransactionCategory.income,
          date: DateTime(2026, 9, 1),
          amountInCents: 100000,
          type: TransactionType.income,
        ),
        FinancialTransaction(
          id: 'expense',
          description: 'Despesa privada',
          category: TransactionCategory.food,
          date: DateTime(2026, 9, 2),
          amountInCents: 10000,
          type: TransactionType.expense,
        ),
      ],
    ),
    assistantService: service,
    firebaseAvailable: true,
  );
  controller.initialize();
  return controller;
}

Future<void> _flushStreams() => Future<void>.delayed(Duration.zero);
