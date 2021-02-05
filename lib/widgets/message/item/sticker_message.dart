import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/db/mixin_database.dart' hide Offset, Message;
import 'package:flutter_app/utils/dp_utils.dart';
import 'package:flutter_app/widgets/cache_image.dart';

import '../message_bubble.dart';
import '../message_datetime.dart';
import '../message_status.dart';

class StickerMessageWidget extends StatelessWidget {
  const StickerMessageWidget({
    Key key,
    @required this.message,
    @required this.isCurrentUser,
  }) : super(key: key);

  final MessageItem message;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    double width;
    double height;
    if (message.assetWidth == null || message.assetHeight == null) {
      height = 120;
      width = 120;
    } else if (message.assetWidth * 2 < dpToPx(context, 48) ||
        message.assetHeight * 2 < dpToPx(context, 48)) {
      if (message.assetWidth < message.assetHeight) {
        if (dpToPx(context, 48) * message.assetHeight / message.assetWidth >
            dpToPx(context, 120)) {
          height = 120;
          width = 120 * message.assetWidth / message.assetHeight;
        } else {
          width = 48;
          height = 48 * message.assetHeight / message.assetWidth;
        }
      } else {
        if (dpToPx(context, 48) * message.assetWidth / message.assetHeight >
            dpToPx(context, 120)) {
          width = 120;
          height = 120 * message.assetHeight / message.assetWidth;
        } else {
          height = 48;
          width = 48 * message.assetWidth / message.assetHeight;
        }
      }
    } else if (message.assetWidth * 2 < dpToPx(context, 120) ||
        message.assetHeight * 2 > dpToPx(context, 120)) {
      if (message.assetWidth > message.assetHeight) {
        width = 120;
        height = 120 * message.assetHeight / message.assetWidth;
      } else {
        height = 120;
        width = 120 * message.assetWidth / message.assetHeight;
      }
    } else {
      width = pxToDp(context, message.assetWidth * 2);
      height = pxToDp(context, message.assetHeight * 2);
    }
    return MessageBubble(
      showNip: true,
      isCurrentUser: isCurrentUser,
      showBubble: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (message.assetUrl == null)
            SizedBox(
              height: height,
              width: width,
            ),
          if (message.assetUrl != null)
            CacheImage(
              message.assetUrl,
              height: height,
              width: width,
            ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MessageDatetime(dateTime: message.createdAt),
              MessageStatusWidget(status: message.status),
            ],
          ),
        ],
      ),
    );
  }
}
