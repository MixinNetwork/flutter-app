import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/db/mixin_database.dart' hide Offset, Message;
import 'package:flutter_app/widgets/brightness_observer.dart';

import '../message_bubble.dart';
import '../message_datetime.dart';
import '../message_status.dart';

class TextMessage extends StatelessWidget {
  const TextMessage({
    Key key,
    @required this.showNip,
    @required this.isCurrentUser,
    @required this.message,
  }) : super(key: key);

  final bool showNip;
  final bool isCurrentUser;
  final MessageItem message;

  @override
  Widget build(BuildContext context) => MessageBubble(
      showNip: showNip,
      isCurrentUser: isCurrentUser,
      child: Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.end,
        children: [
          Text(
            message.content,
            style: TextStyle(
              fontSize: 16,
              color: BrightnessData.themeOf(context).text,
            ),
          ),
          const SizedBox(width: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MessageDatetime(dateTime: message.createdAt),
              if (isCurrentUser) MessageStatusWidget(status: message.status),
            ],
          ),
        ],
      ),
    );
}

