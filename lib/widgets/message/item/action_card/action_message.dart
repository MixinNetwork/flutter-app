import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../../utils/extension/extension.dart';
import '../../../../utils/logger.dart';
import '../../../../utils/uri_utils.dart';
import '../../../cache_image.dart';
import '../../../interactive_decorated_box.dart';
import '../../message.dart';
import '../../message_bubble.dart';
import '../../message_datetime_and_status.dart';
import '../unknown_message.dart';
import 'action_card_data.dart';

class ActionCardMessage extends HookWidget {
  const ActionCardMessage({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final content = useMessageConverter(converter: (state) => state.content);
    final appCardData = useMemoized(
      () {
        try {
          return AppCardData.fromJson(
              jsonDecode(content!) as Map<String, dynamic>);
        } catch (error) {
          e('ActionCard decode error: $error');
          return null;
        }
      },
      [content],
    );

    if (appCardData == null) return const UnknownMessage();

    return MessageBubble(
      outerTimeAndStatusWidget: const MessageDatetimeAndStatus(),
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
