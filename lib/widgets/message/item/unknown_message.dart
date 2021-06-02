import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../../db/mixin_database.dart' hide Offset, Message;
import '../../../generated/l10n.dart';
import '../../../utils/uri_utils.dart';
import '../../brightness_observer.dart';
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
        text: Localization.of(context).chatNotSupport,
        style: TextStyle(
          fontSize: 16,
          color: BrightnessData.themeOf(context).text,
        ),
        children: [
          TextSpan(
            mouseCursor: SystemMouseCursors.click,
            text: Localization.of(context).chatLearn,
            style: TextStyle(
              fontSize: 16,
              color: BrightnessData.themeOf(context).accent,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () =>
                  openUri(context, Localization.of(context).chatNotSupportUrl),
          ),
        ],
      ),
    );
    final dateAndStatus = MessageDatetimeAndStatus(
      isCurrentUser: isCurrentUser,
      createdAt: message.createdAt,
      status: message.status,
    );
    return MessageBubble(
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
