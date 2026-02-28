// lib/pages/chat/widgets/chat_bubble.dart
import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final bool isUser;
  final String text;

  const ChatBubble({super.key, required this.isUser, required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = isUser ? cs.primaryContainer : cs.surfaceContainerHighest;
    final fg = isUser ? cs.onPrimaryContainer : cs.onSurface;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(text, style: TextStyle(color: fg)),
        ),
      ),
    );
  }
}
