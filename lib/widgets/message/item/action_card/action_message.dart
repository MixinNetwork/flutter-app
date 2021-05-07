import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../../db/mixin_database.dart';
import '../../../../utils/action_utils.dart';
import '../../../../utils/uri_utils.dart';
import '../../../brightness_observer.dart';
import '../../../cache_image.dart';
import '../../../interacter_decorated_box.dart';
import '../../message_bubble.dart';
import '../../message_datetime.dart';
import '../../message_status.dart';
import 'action_card_data.dart';

class ActionCardMessage extends HookWidget {
  const ActionCardMessage({
    Key? key,
    required this.message,
    required this.showNip,
    required this.isCurrentUser,
  }) : super(key: key);

  final bool showNip;
  final bool isCurrentUser;
  final MessageItem message;

  @override
  Widget build(BuildContext context) {
    final appCardData = useMemoized(
      () => AppCardData.fromJson(jsonDecode(message.content!)),
      [message.content],
    );
    return MessageBubble(
      showNip: showNip,
      isCurrentUser: isCurrentUser,
      outerTimeAndStatusWidget: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MessageDatetime(dateTime: message.createdAt),
          if (isCurrentUser) MessageStatusWidget(status: message.status),
        ],
      ),
      child: InteractableDecoratedBox(
        onTap: () {
          if (context.openAction(appCardData.action)) return;
          openUri(appCardData.action);
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
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appCardData.title,
                  style: TextStyle(
                    color: BrightnessData.themeOf(context).text,
                    fontSize: 14,
                  ),
                ),
                Text(
                  appCardData.description,
                  style: TextStyle(
                    color: BrightnessData.themeOf(context).secondaryText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
