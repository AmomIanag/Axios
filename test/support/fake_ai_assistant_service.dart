import 'package:axios/services/ai_assistant_service.dart';

typedef AssistantReplyHandler = Future<String> Function(
  AiAssistantRequest request,
);

class FakeAiAssistantService implements AiAssistantService {
  FakeAiAssistantService({
    required this.handler,
    this.mode = AiAssistantMode.real,
    this.modelName = 'fake-gemini',
  });

  final AssistantReplyHandler handler;
  final List<AiAssistantRequest> requests = [];

  @override
  final AiAssistantMode mode;

  @override
  final String modelName;

  @override
  Future<String> generateReply(AiAssistantRequest request) {
    requests.add(request);
    return handler(request);
  }
}
