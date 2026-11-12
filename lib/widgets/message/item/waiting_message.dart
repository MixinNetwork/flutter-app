import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import '../../../utils/extension/extension.dart';
import '../../../utils/uri_utils.dart';
import '../message.dart';
import '../message_bubble.dart';
import '../message_datetime_and_status.dart';
import '../message_layout.dart';
import '../message_style.dart';

class WaitingMessage extends HookConsumerWidget {
  const WaitingMessage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final relationship = useMessageConverter(
      converter: (state) => state.relationship,
    );
    final userFullName = useMessageConverter(
      converter: (state) => state.userFullName,
    );

    final content = RichText(
      text: TextSpan(
        text: context.l10n.chatDecryptionFailedHint(
          relationship == UserRelationship.me
              ? context.l10n.linkedDevice
              : userFullName!,
        ),
        style: TextStyle(
          fontSize: context.messageStyle.primaryFontSize,
          color: context.theme.text,
        ),
        children: [
          TextSpan(
            mouseCursor: SystemMouseCursors.click,
            text: context.l10n.learnMore,
            style: TextStyle(
              fontSize: context.messageStyle.primaryFontSize,
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
