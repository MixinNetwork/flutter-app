import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import '../../../utils/extension/extension.dart';
import '../../../utils/uri_utils.dart';
import '../message.dart';
import '../message_bubble.dart';
import '../message_datetime_and_status.dart';
import '../message_layout.dart';

class WaitingMessage extends HookWidget {
  const WaitingMessage({super.key});

  @override
  Widget build(BuildContext context) {
    final relationship =
        useMessageConverter(converter: (state) => state.relationship);
    final userFullName =
        useMessageConverter(converter: (state) => state.userFullName);

    final content = RichText(
      text: TextSpan(
        text: context.l10n.chatWaiting(
          relationship == UserRelationship.me
              ? context.l10n.chatWaitingDesktop
              : userFullName!,
        ),
        style: TextStyle(
          fontSize: MessageItemWidget.primaryFontSize,
          color: context.theme.text,
        ),
        children: [
          TextSpan(
            mouseCursor: SystemMouseCursors.click,
            text: context.l10n.chatLearn,
            style: TextStyle(
              fontSize: MessageItemWidget.primaryFontSize,
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
