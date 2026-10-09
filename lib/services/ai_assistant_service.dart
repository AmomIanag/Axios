import '../core/utils/formatters.dart';
import '../models/chat_message.dart';
import '../models/financial_assistant_context.dart';

enum AiAssistantMode { real, demo }

enum AssistantFailureKind {
  network,
  timeout,
  quota,
  configuration,
  appCheck,
  authentication,
  emptyResponse,
  unavailable,
  unknown,
}

class AssistantFailure implements Exception {
  const AssistantFailure(this.kind, this.message);

  final AssistantFailureKind kind;
  final String message;

  @override
  String toString() => message;
}

class AiAssistantRequest {
  const AiAssistantRequest({
    required this.question,
    required this.context,
    required this.history,
    this.scenarioFacts,
  });

  final String question;
  final FinancialAssistantContext context;
  final List<ChatMessage> history;
  final FinancialScenarioFacts? scenarioFacts;
}

abstract interface class AiAssistantService {
  AiAssistantMode get mode;
  String get modelName;

  Future<String> generateReply(AiAssistantRequest request);
}

class DemoAssistantService implements AiAssistantService {
  const DemoAssistantService();

  @override
  AiAssistantMode get mode => AiAssistantMode.demo;

  @override
  String get modelName => 'simulador-deterministico';

  @override
  Future<String> generateReply(AiAssistantRequest request) async {
    final scenario = request.scenarioFacts?.values;
    if (scenario != null) {
      final monthly = scenario['necessario_por_mes_centavos'];
      final months = scenario['meses_estimados'] ?? scenario['meses'];
      if (monthly is int) {
        return 'Resposta simulada: o cálculo determinístico indica '
            '${AppFormatters.cents(monthly)} por mês durante $months meses. '
            'Nenhuma IA externa foi utilizada.';
      }
      if (months is int) {
        return 'Resposta simulada: mantendo o aporte informado, a estimativa '
            'determinística é de $months meses. Nenhuma IA externa foi utilizada.';
      }
    }

    final context = request.context;
    if (context.categories.isNotEmpty &&
        request.question.toLowerCase().contains('gasto')) {
      final category = context.categories.first;
      return 'Resposta simulada: ${category.label} é a maior categoria do '
          'período, com ${AppFormatters.cents(category.amountInCents)}. '
          'Nenhuma IA externa foi utilizada.';
    }

    return 'Resposta simulada: sua capacidade estimada de poupança no período '
        'é ${AppFormatters.cents(context.savingCapacityInCents)}. O modo '
        'demonstração não envia dados a uma IA externa.';
  }
}
