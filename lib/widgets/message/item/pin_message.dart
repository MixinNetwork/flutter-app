import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../blaze/vo/pin_message_minimal.dart';
import '../../../db/mixin_database.dart' hide Offset, Message;
import '../../../utils/extension/extension.dart';
import '../../../utils/hook.dart';
import '../../../utils/load_balancer_utils.dart';
import '../../../utils/logger.dart';
import '../../../utils/message_optimize.dart';
import '../message.dart';
import 'text/mention_builder.dart';

class PinMessageWidget extends HookWidget {
  const PinMessageWidget({
    Key? key,
    required this.message,
  }) : super(key: key);

  final MessageItem message;

  @override
  Widget build(BuildContext context) {
    final text = useMemoizedFuture(
      () async {
        final preview = await generatePinPreviewText(
          content: message.content ?? '',
          mentionCache: context.read<MentionCache>(),
        );

        return context.l10n.pinned(message.userFullName ?? '', preview);
      },
      '',
      keys: [message.userFullName, message.content],
    ).requireData;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 4,
          horizontal: 8,
        ),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.dynamicColor(
                const Color.fromRGBO(202, 234, 201, 1),
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 5,
                horizontal: 10,
              ),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: MessageItemWidget.secondaryFontSize,
                  color: context.dynamicColor(
                    const Color.fromRGBO(0, 0, 0, 1),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<String> generatePinPreviewText({
  required String content,
  required MentionCache mentionCache,
}) async {
  try {
    final json = await jsonDecodeWithIsolate(content);
    if (json is! Map) return '';
    final pinMessageMinimal =
        PinMessageMinimal.fromJson(json as Map<String, dynamic>);

    if (pinMessageMinimal.type.isText) {
      return '"${mentionCache.replaceMention(
            pinMessageMinimal.content,
            await mentionCache.checkMentionCache({pinMessageMinimal.content}),
          ) ?? ''}"';
    } else {
      return await messagePreviewOptimize(
            null,
            pinMessageMinimal.type,
            pinMessageMinimal.content,
            false,
            true,
          ) ??
          '';
    }
  } catch (error, s) {
    e('generate pin message error: $error, $s ');
    return '';
  }
}
