import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import '../../../db/mixin_database.dart' hide Offset, Message;
import '../../../utils/dp_utils.dart';
import '../../cache_image.dart';

import '../message_bubble.dart';
import '../message_datetime.dart';
import '../message_status.dart';

class StickerMessageWidget extends StatelessWidget {
  const StickerMessageWidget({
    Key? key,
    required this.message,
    required this.isCurrentUser,
  }) : super(key: key);

  final MessageItem message;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    double width;
    double height;
    final assetWidth = message.assetWidth;
    final assetHeight = message.assetHeight;
    if (assetWidth == null || assetHeight == null) {
      height = 120;
      width = 120;
    } else if (assetWidth * 2 < dpToPx(context, 48) ||
        assetHeight * 2 < dpToPx(context, 48)) {
      if (assetWidth < assetHeight) {
        if (dpToPx(context, 48) * assetHeight / assetWidth >
            dpToPx(context, 120)) {
          height = 120;
          width = 120 * assetWidth / assetHeight;
        } else {
          width = 48;
          height = 48 * assetHeight / assetWidth;
        }
      } else {
        if (dpToPx(context, 48) * assetWidth / assetHeight >
            dpToPx(context, 120)) {
          width = 120;
          height = 120 * assetHeight / assetWidth;
        } else {
          height = 48;
          width = 48 * assetWidth / assetHeight;
        }
      }
    } else if (assetWidth * 2 < dpToPx(context, 120) ||
        assetHeight * 2 > dpToPx(context, 120)) {
      if (assetWidth > assetHeight) {
        width = 120;
        height = 120 * assetHeight / assetWidth;
      } else {
        height = 120;
        width = 120 * assetWidth / assetHeight;
      }
    } else {
      width = pxToDp(context, assetWidth * 2);
      height = pxToDp(context, assetHeight * 2);
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
              message.assetUrl!,
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
