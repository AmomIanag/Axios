import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../models/chat_message.dart';
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
  int _lastMessageCount = 0;
  bool _lastBusy = false;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _textController.text.trim();
    if (text.isEmpty || widget.controller.assistantBusy) return;
    _textController.clear();
    FocusScope.of(context).unfocus();
    await widget.controller.sendAssistantMessage(text);
    if (mounted) _scrollToEnd();
  }

  Future<void> _retry() async {
    await widget.controller.retryAssistantMessage();
    if (mounted) _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  void _scheduleScrollWhenConversationChanges() {
    final messageCount = widget.controller.assistantMessages.length;
    final busy = widget.controller.assistantBusy;
    if (messageCount == _lastMessageCount && busy == _lastBusy) return;
    _lastMessageCount = messageCount;
    _lastBusy = busy;
    _scrollToEnd();
  }

  @override
  Widget build(BuildContext context) {
    _scheduleScrollWhenConversationChanges();
    final controller = widget.controller;
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
                      controller.usesRealAssistant
                          ? 'IA real · ${controller.assistantModelName}'
                          : 'Respostas simuladas',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.graphite,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                if (controller.usesRealAssistant) ...[
                  const SizedBox(height: 8),
                  Text(
                    'O assistente recebe somente resumos financeiros '
                    'necessários para responder.',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppColors.gray),
                  ),
                ],
                const SizedBox(height: 14),
                Expanded(
                  child: ListView.separated(
                    key: const ValueKey('chat-list'),
                    controller: _scrollController,
                    padding: const EdgeInsets.only(bottom: 12),
                    itemCount:
                        controller.assistantMessages.length +
                        (controller.assistantBusy ? 1 : 0),
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index == controller.assistantMessages.length) {
                        return const _AssistantTypingBubble();
                      }
                      return _MessageBubble(
                        message: controller.assistantMessages[index],
                      );
                    },
                  ),
                ),
                if (controller.assistantFailure case final failure?) ...[
                  const SizedBox(height: 8),
                  Container(
                    key: const ValueKey('assistant-error'),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.danger.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.danger,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            failure.message,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        TextButton(
                          key: const ValueKey('assistant-retry'),
                          onPressed: controller.assistantBusy ? null : _retry,
                          child: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                TextField(
                  key: const ValueKey('assistant-input'),
                  controller: _textController,
                  enabled: !controller.assistantBusy,
                  textInputAction: TextInputAction.send,
                  onSubmitted: controller.assistantBusy ? null : (_) => _send(),
                  decoration: InputDecoration(
                    hintText: 'Digite sua mensagem...',
                    suffixIcon: IconButton(
                      key: const ValueKey('assistant-send'),
                      tooltip: 'Enviar mensagem',
                      onPressed: controller.assistantBusy ? null : _send,
                      icon: controller.assistantBusy
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded),
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

class _AssistantTypingBubble extends StatelessWidget {
  const _AssistantTypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        key: const ValueKey('assistant-loading'),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const SizedBox(
          width: 44,
          child: LinearProgressIndicator(minHeight: 3),
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
