import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../../db/mixin_database.dart' hide Offset, Message;
import '../../../generated/l10n.dart';
import '../../../utils/uri_utils.dart';
import '../../brightness_observer.dart';
import '../../mouse_region_span.dart';
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
          MouseRegionSpan(
            mouseCursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => openUri(Localization.of(context).chatNotSupportUrl),
              child: Text(
                Localization.of(context).chatLearn,
                style: TextStyle(
                  fontSize: 16,
                  color: BrightnessData.themeOf(context).accent,
                ),
              ),
            ),
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
