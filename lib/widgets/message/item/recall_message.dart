import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';

import '../../../constants/resources.dart';
import '../../../db/mixin_database.dart' hide Offset, Message;

import '../../../utils/extension/extension.dart';
import '../message.dart';
import '../message_bubble.dart';
import '../message_datetime_and_status.dart';
import '../message_layout.dart';

class RecallMessage extends StatelessWidget {
  const RecallMessage({
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
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          Resources.assetsImagesRecallSvg,
          color: context.theme.secondaryText,
          width: 16,
          height: 16,
        ),
        const SizedBox(width: 4),
        Text(
          isCurrentUser
              ? context.l10n.chatRecallMe
              : context.l10n.chatRecallDelete,
          style: TextStyle(
            fontSize: MessageItemWidget.primaryFontSize,
            color: context.theme.text,
          ),
        ),
      ],
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
