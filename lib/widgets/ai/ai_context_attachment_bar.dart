import 'package:flutter/material.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import '../../ai/ai_message_context.dart';
import '../../db/mixin_database.dart';
import '../../utils/extension/extension.dart';
import '../action_button.dart';

class AiContextAttachmentBar extends StatelessWidget {
  const AiContextAttachmentBar({
    required this.messages,
    required this.onRemove,
    required this.onTap,
    super.key,
  });

  final List<MessageItem> messages;
  final ValueChanged<String> onRemove;
  final ValueChanged<MessageItem> onTap;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return const SizedBox.shrink();
    }

    final showSenderName = messages.any(
      (message) => message.conversionCategory == ConversationCategory.group,
    );

    return SizedBox(
      height: showSenderName ? 46 : 30,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        itemBuilder: (context, index) => _AttachmentChip(
          message: messages[index],
          showSenderName: showSenderName,
          onRemove: onRemove,
          onTap: onTap,
        ),
        separatorBuilder: (context, index) => const SizedBox(width: 6),
        itemCount: messages.length,
      ),
    );
  }
}

class _AttachmentChip extends StatefulWidget {
  const _AttachmentChip({
    required this.message,
    required this.showSenderName,
    required this.onRemove,
    required this.onTap,
  });

  final MessageItem message;
  final bool showSenderName;
  final ValueChanged<String> onRemove;
  final ValueChanged<MessageItem> onTap;

  @override
  State<_AttachmentChip> createState() => _AttachmentChipState();
}

class _AttachmentChipState extends State<_AttachmentChip> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final preview = aiMessageContextPreview(widget.message, maxLength: 72);
    final senderName = widget.message.userFullName ?? widget.message.userId;
    final backgroundColor = context.dynamicColor(
      const Color.fromRGBO(245, 247, 250, 1),
      darkColor: const Color.fromRGBO(255, 255, 255, 0.08),
    );
    final borderColor = _hovering
        ? context.theme.accent.withValues(alpha: 0.35)
        : context.dynamicColor(
            const Color.fromRGBO(0, 0, 0, 0.06),
            darkColor: const Color.fromRGBO(255, 255, 255, 0.08),
          );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 200),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => widget.onTap(widget.message),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border.all(color: borderColor),
              borderRadius: const BorderRadius.all(Radius.circular(8)),
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 8, right: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: widget.showSenderName
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                senderName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: context.theme.secondaryText,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              _PreviewText(preview),
                            ],
                          )
                        : _PreviewText(preview),
                  ),
                  const SizedBox(width: 4),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 120),
                    opacity: _hovering ? 1 : 0,
                    child: ActionButton(
                      padding: EdgeInsets.zero,
                      size: 18,
                      interactive: _hovering,
                      onTap: () => widget.onRemove(widget.message.messageId),
                      child: Icon(
                        Icons.close_rounded,
                        color: context.theme.secondaryText,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewText extends StatelessWidget {
  const _PreviewText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: TextStyle(
      color: context.theme.text,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
  );
}
