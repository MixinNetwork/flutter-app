import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../blaze/vo/pin_message_minimal.dart';
import '../../../db/mixin_database.dart' hide Offset, Message;
import '../../../utils/extension/extension.dart';
import '../../../utils/hook.dart';
import '../../../utils/message_optimize.dart';
import '../message.dart';
import 'text/mention_builder.dart';

class PinMessageWidget extends HookWidget {
  const PinMessageWidget({
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
    final pinMessageMinimal = useMemoized(
      () => PinMessageMinimal.fromJsonString(message.content ?? ''),
      [message.content],
    );

    final cachePreview = useMemoized(() {
      if (pinMessageMinimal == null) {
        return context.l10n
            .pinned(message.userFullName ?? '', context.l10n.aMessage);
      }
      final preview = cachePinPreviewText(
        pinMessageMinimal: pinMessageMinimal,
        mentionCache: context.read<MentionCache>(),
      );
      return context.l10n.pinned(message.userFullName ?? '', preview);
    }, [message.userFullName, message.content]);

    final text = useMemoizedFuture(
      () async {
        if (pinMessageMinimal == null) return cachePreview;

        final preview = await generatePinPreviewText(
          pinMessageMinimal: pinMessageMinimal,
          mentionCache: context.read<MentionCache>(),
        );

        return context.l10n.pinned(message.userFullName ?? '', preview);
      },
      cachePreview,
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
  required PinMessageMinimal pinMessageMinimal,
  required MentionCache mentionCache,
}) async {
  if (pinMessageMinimal.type.isText) {
    return '"${mentionCache.replaceMention(
          pinMessageMinimal.content,
          await mentionCache.checkMentionCache({pinMessageMinimal.content}),
        ) ?? ''}"';
  } else {
    return messagePreviewOptimize(
          null,
          pinMessageMinimal.type,
          pinMessageMinimal.content,
          false,
          true,
        ) ??
        '';
  }
}

String cachePinPreviewText({
  required PinMessageMinimal pinMessageMinimal,
  required MentionCache mentionCache,
}) {
  if (pinMessageMinimal.type.isText) {
    return '"${mentionCache.replaceMention(
          pinMessageMinimal.content,
          mentionCache.mentionCache(pinMessageMinimal.content),
        ) ?? ''}"';
  } else {
    return messagePreviewOptimize(
          null,
          pinMessageMinimal.type,
          pinMessageMinimal.content,
          false,
          true,
        ) ??
        '';
  }
}
