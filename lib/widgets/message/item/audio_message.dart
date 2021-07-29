import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../../db/mixin_database.dart' hide Offset, Message;

import '../../../utils/extension/extension.dart';
import '../message.dart';
import '../message_bubble.dart';
import '../message_datetime_and_status.dart';
import '../message_layout.dart';

class NotSupportedMessage extends StatelessWidget {
  const NotSupportedMessage({
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
    final content = Text(
      context.l10n.chatCheckOnPhone,
      style: TextStyle(
        fontSize: MessageItemWidget.primaryFontSize,
        color: context.theme.text,
      ),
    );
    final dateAndStatus = MessageDatetimeAndStatus(
      isCurrentUser: isCurrentUser,
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
