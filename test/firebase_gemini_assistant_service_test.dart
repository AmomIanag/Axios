import 'dart:async';

import 'package:axios/models/financial_assistant_context.dart';
import 'package:axios/services/ai_assistant_service.dart';
import 'package:axios/services/firebase_gemini_assistant_service.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const context = FinancialAssistantContext(
    periodYear: 2026,
    periodMonth: 9,
    incomeInCents: 300000,
    expensesInCents: 215000,
    monthlyResultInCents: 85000,
    savingCapacityInCents: 85000,
    pendingTransactionCount: 0,
    pendingIncomeInCents: 0,
    pendingExpensesInCents: 0,
    categories: [],
    goals: [],
    transactionsLoaded: true,
    goalsLoaded: true,
  );

  test('envia pergunta livre e contexto ao gerador injetado', () async {
    String? capturedPrompt;
    final service = FirebaseGeminiAssistantService(
      generateText: (prompt) async {
        capturedPrompt = prompt;
        return 'Resposta gerada.';
      },
    );

    final response = await service.generateReply(
      const AiAssistantRequest(
        question: 'Por que meu resultado mensal diminuiu?',
        context: context,
        history: [],
      ),
    );

    expect(response, 'Resposta gerada.');
    expect(capturedPrompt, contains('Por que meu resultado mensal diminuiu?'));
    expect(capturedPrompt, contains('"resultado_liquido_centavos":85000'));
  });

  test('converte timeout em erro compreensível', () async {
    final pending = Completer<String?>();
    final service = FirebaseGeminiAssistantService(
      timeout: const Duration(milliseconds: 1),
      generateText: (_) => pending.future,
    );

    await expectLater(
      service.generateReply(
        const AiAssistantRequest(
          question: 'Pergunta',
          context: context,
          history: [],
        ),
      ),
      throwsA(
        isA<AssistantFailure>().having(
          (failure) => failure.kind,
          'kind',
          AssistantFailureKind.timeout,
        ),
      ),
    );
  });

  test('converte quota do SDK em erro específico', () async {
    final service = FirebaseGeminiAssistantService(
      generateText: (_) async => throw QuotaExceeded('quota'),
    );

    await expectLater(
      service.generateReply(
        const AiAssistantRequest(
          question: 'Pergunta',
          context: context,
          history: [],
        ),
      ),
      throwsA(
        isA<AssistantFailure>().having(
          (failure) => failure.kind,
          'kind',
          AssistantFailureKind.quota,
        ),
      ),
    );
  });
}
