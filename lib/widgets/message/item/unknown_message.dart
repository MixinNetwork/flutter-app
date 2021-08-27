import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../../db/mixin_database.dart' hide Offset, Message;

import '../../../utils/extension/extension.dart';
import '../../../utils/uri_utils.dart';
import '../message.dart';
import '../message_bubble.dart';
import '../message_datetime_and_status.dart';
import '../message_layout.dart';

class UnknownMessage extends StatelessWidget {
  const UnknownMessage({
    Key? key,
    required this.showNip,
    required this.isCurrentUser,
    required this.message,
  }) : super(key: key);

  final bool showNip;
  final bool isCurrentUser;
  final MessageItem message;

  @override
  Widget build(BuildContext context) {
    final content = RichText(
      text: TextSpan(
        text: context.l10n.chatNotSupport,
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
    final dateAndStatus = MessageDatetimeAndStatus(
      showStatus: isCurrentUser,
      message: message,
    );
    return MessageBubble(
      messageId: message.messageId,
      showNip: showNip,
      isCurrentUser: isCurrentUser,
      child: MessageLayout(
        spacing: 6,
        content: content,
        dateAndStatus: dateAndStatus,
      ),
    );
  }
}
