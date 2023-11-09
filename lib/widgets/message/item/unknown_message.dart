import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../utils/extension/extension.dart';
import '../../../utils/uri_utils.dart';
import '../message_bubble.dart';
import '../message_datetime_and_status.dart';
import '../message_layout.dart';
import '../message_style.dart';

class UnknownMessage extends ConsumerWidget {
  const UnknownMessage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = RichText(
      text: TextSpan(
        text: context.l10n.messageNotSupport,
        style: TextStyle(
          fontSize: ref.watch(messageStyleProvider).primaryFontSize,
          color: context.theme.text,
        ),
        children: [
          const TextSpan(text: ' '),
          TextSpan(
            mouseCursor: SystemMouseCursors.click,
            text: context.l10n.learnMore,
            style: TextStyle(
              fontSize: ref.watch(messageStyleProvider).primaryFontSize,
              color: context.theme.accent,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => openUri(context, context.l10n.chatNotSupportUrl),
          ),
        ],
      ),
    );
    return MessageBubble(
      child: MessageLayout(
        spacing: 6,
        content: content,
        dateAndStatus: const MessageDatetimeAndStatus(),
      ),
    );
  }
}
