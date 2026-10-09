enum MessageAuthor { user, assistant }

class ChatMessage {
  const ChatMessage({required this.author, required this.text});

  final MessageAuthor author;
  final String text;
}
