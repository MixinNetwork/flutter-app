import 'package:flutter/material.dart';

import '../../db/mixin_database.dart' hide Offset;
import '../../utils/extension/extension.dart';
import '../markdown.dart';
import '../message/message_bubble.dart';

class AiMessageCard extends StatelessWidget {
  const AiMessageCard({required this.message, super.key});

  final AiChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final title = isUser ? 'You -> AI' : 'AI Assistant';
    final time = message.createdAt.format;
    final cardColor = isUser
        ? context.messageBubbleColor(true)
        : context.messageBubbleColor(false);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.08),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$title · $time',
                style: TextStyle(
                  color: context.theme.secondaryText,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              if (message.content.trim().isEmpty)
                SelectableText(
                  message.status == 'error'
                      ? (message.errorText ?? 'Request failed')
                      : 'Thinking...',
                  style: TextStyle(color: context.theme.text, fontSize: 14),
                )
              else if (isUser)
                SelectableText(
                  message.content,
                  style: TextStyle(color: context.theme.text, fontSize: 14),
                )
              else
                MarkdownColumn(
                  data: message.content,
                  selectable: true,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
