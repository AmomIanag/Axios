import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/formatters.dart';
import '../data/mock_financial_data.dart';
import '../models/chat_message.dart';
import '../models/goal.dart';
import '../state/app_controller.dart';
import '../widgets/screen_header.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  late final List<ChatMessage> _messages;

  @override
  void initState() {
    super.initState();
    final goal = _primaryGoal;
    _messages = [
      const ChatMessage(
        author: MessageAuthor.assistant,
        text: 'Olá! Como posso ajudar hoje?',
      ),
      ChatMessage(
        author: MessageAuthor.assistant,
        text:
            'Esta é uma demonstração com respostas simuladas. Considerando '
            '${AppFormatters.currency(goal.currentAmount)} já acumulados, guardar '
            '${AppFormatters.currency(goal.monthlyContribution)} por mês leva a '
            'meta ${goal.name} a aproximadamente ${goal.monthsToComplete} meses.',
      ),
    ];
  }

  Goal get _primaryGoal => widget.controller.goals.isNotEmpty
      ? widget.controller.goals.first
      : MockFinancialData.goals.first;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    final response = _responseFor(text);
    setState(() {
      _messages.add(ChatMessage(author: MessageAuthor.user, text: text));
      _messages.add(
        ChatMessage(author: MessageAuthor.assistant, text: response),
      );
    });
    _textController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _responseFor(String input) {
    final normalized = input.toLowerCase();
    final goal = _primaryGoal;
    final summary = MockFinancialData.summary;
    final monthMatch = RegExp(r'(\d+)\s*mes').firstMatch(normalized);
    if (monthMatch != null &&
        (normalized.contains('meta') || normalized.contains('viag'))) {
      final months = int.tryParse(monthMatch.group(1) ?? '') ?? 1;
      final needed = goal.monthlyNeededFor(months);
      final remainingMargin = summary.availableBalance - needed;
      return 'Para atingir ${AppFormatters.currency(goal.targetAmount)} em '
          '$months meses, considerando os '
          '${AppFormatters.currency(goal.currentAmount)} já acumulados, você '
          'precisa guardar ${AppFormatters.currency(needed)} por mês. Sua margem '
          'estimada ficaria em ${AppFormatters.currency(remainingMargin)}.';
    }
    if (normalized.contains('gasto') || normalized.contains('econom')) {
      final topCategory = MockFinancialData.expensesByCategory.entries.reduce(
        (a, b) => a.value >= b.value ? a : b,
      );
      return '${topCategory.key} é sua maior categoria simulada, com '
          '${AppFormatters.currency(topCategory.value)}. Posso demonstrar um '
          'cenário de redução, mas esta versão não usa IA externa.';
    }
    return 'Resposta simulada: sua sobra estimada é '
        '${AppFormatters.currency(summary.availableBalance)}. Pergunte, por '
        'exemplo, em quantos meses pode alcançar a meta ${goal.name}.';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const ScreenHeader(
                  title: 'Assistente Axios',
                  subtitle: 'Planeje suas metas com clareza',
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.goldSoft,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      'Respostas simuladas',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.graphite,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: ListView.separated(
                    key: const ValueKey('chat-list'),
                    controller: _scrollController,
                    padding: const EdgeInsets.only(bottom: 12),
                    itemCount: _messages.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) =>
                        _MessageBubble(message: _messages[index]),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  key: const ValueKey('assistant-input'),
                  controller: _textController,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(
                    hintText: 'Digite sua mensagem...',
                    suffixIcon: IconButton(
                      key: const ValueKey('assistant-send'),
                      tooltip: 'Enviar mensagem',
                      onPressed: _send,
                      icon: const Icon(Icons.send_rounded),
                      color: AppColors.graphite,
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        minimumSize: const Size(44, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.author == MessageAuthor.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          decoration: BoxDecoration(
            color: isUser ? AppColors.gold : AppColors.surface,
            borderRadius: BorderRadius.circular(16).copyWith(
              bottomRight: isUser ? const Radius.circular(4) : null,
              bottomLeft: isUser ? null : const Radius.circular(4),
            ),
            border: isUser ? null : Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x10000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            message.text,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(height: 1.45),
          ),
        ),
      ),
    );
  }
}
