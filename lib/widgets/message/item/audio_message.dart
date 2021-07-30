import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../../db/mixin_database.dart' hide Offset, Message;
import '../../../generated/l10n.dart';
import '../../brightness_observer.dart';
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
      Localization.of(context).chatCheckOnPhone,
      style: TextStyle(
        fontSize: MessageItemWidget.primaryFontSize,
        color: BrightnessData.themeOf(context).text,
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
