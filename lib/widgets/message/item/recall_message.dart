import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/constants/resources.dart';
import 'package:flutter_app/db/mixin_database.dart' hide Offset, Message;
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_app/generated/l10n.dart';
import 'package:flutter_svg/svg.dart';

import '../message_bubble.dart';
import '../message_datetime.dart';
import '../message_status.dart';

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
  Widget build(BuildContext context) => MessageBubble(
        showNip: showNip,
        isCurrentUser: isCurrentUser,
        child: Wrap(
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  Resources.assetsImagesRecallSvg,
                  color: BrightnessData.themeOf(context).text,
                  width: 16,
                  height: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  isCurrentUser
                      ? Localization.of(context).chatRecallMe
                      : Localization.of(context).chatRecallDelete,
                  style: TextStyle(
                    fontSize: 16,
                    color: BrightnessData.themeOf(context).text,
                  ),
                ),
              ],
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
