// lib/models/chat/chat_message.dart
//
// Simple chat message model for UI only.

class ChatMessage {
  final String id;
  final bool isUser;
  final String text;
  final DateTime time;

  ChatMessage({
    required this.id,
    required this.isUser,
    required this.text,
    required this.time,
  });
}
