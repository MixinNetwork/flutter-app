import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../../db/mixin_database.dart';
import '../../../../utils/extension/extension.dart';
import '../../../../utils/uri_utils.dart';
import '../../../cache_image.dart';
import '../../../interacter_decorated_box.dart';
import '../../message.dart';
import '../../message_bubble.dart';
import '../../message_datetime_and_status.dart';
import 'action_card_data.dart';

class ActionCardMessage extends HookWidget {
  const ActionCardMessage({
    Key? key,
    required this.message,
    required this.showNip,
    required this.isCurrentUser,
    this.pinArrow,
  }) : super(key: key);

  final bool showNip;
  final bool isCurrentUser;
  final MessageItem message;
  final Widget? pinArrow;

  @override
  Widget build(BuildContext context) {
    final appCardData = useMemoized(
      () => AppCardData.fromJson(
          jsonDecode(message.content!) as Map<String, dynamic>),
      [message.content],
    );
    return MessageBubble(
      messageId: message.messageId,
      showNip: showNip,
      isCurrentUser: isCurrentUser,
      pinArrow: pinArrow,
      outerTimeAndStatusWidget: MessageDatetimeAndStatus(
        showStatus: isCurrentUser,
        message: message,
      ),
      child: InteractiveDecoratedBox(
        onTap: () {
          if (context.openAction(appCardData.action)) return;
          openUri(context, appCardData.action);
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: CacheImage(
                appCardData.iconUrl,
                height: 40,
                width: 40,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appCardData.title,
                    style: TextStyle(
                      color: context.theme.text,
                      fontSize: MessageItemWidget.secondaryFontSize,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    appCardData.description,
                    style: TextStyle(
                      color: context.theme.secondaryText,
                      fontSize: MessageItemWidget.tertiaryFontSize,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
