import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../blaze/vo/pin_message_minimal.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/hook.dart';
import '../../../utils/message_optimize.dart';
import '../message.dart';
import 'text/mention_builder.dart';

class PinMessageWidget extends HookWidget {
  const PinMessageWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final content =
        useMessageConverter(converter: (state) => state.content ?? '');
    final userFullName =
        useMessageConverter(converter: (state) => state.userFullName ?? '');

    final pinMessageMinimal = useMemoized(
      () => PinMessageMinimal.fromJsonString(content),
      [content],
    );

    final cachePreview = useMemoized(() {
      if (pinMessageMinimal == null) {
        return context.l10n.pinned(userFullName, context.l10n.aMessage);
      }
      final preview = cachePinPreviewText(
        pinMessageMinimal: pinMessageMinimal,
        mentionCache: context.read<MentionCache>(),
      );
      return context.l10n.pinned(userFullName, preview);
    }, [userFullName, content]);

    final text = useMemoizedFuture(
      () async {
        if (pinMessageMinimal == null) return cachePreview;

        final preview = await generatePinPreviewText(
          pinMessageMinimal: pinMessageMinimal,
          mentionCache: context.read<MentionCache>(),
        );

        return context.l10n.pinned(userFullName, preview).overflow;
      },
      cachePreview,
      keys: [userFullName, content],
    ).requireData;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 4,
          horizontal: 8,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 400,
          ),
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
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
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
  final content = LineSplitter.split(pinMessageMinimal.content ?? '').join(' ');

  if (pinMessageMinimal.type.isText) {
    return mentionCache.replaceMention(
          content,
          await mentionCache.checkMentionCache({content}),
        ) ??
        '';
  } else {
    return messagePreviewOptimize(
          null,
          pinMessageMinimal.type,
          content,
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
  final content = LineSplitter.split(pinMessageMinimal.content ?? '').join(' ');

  if (pinMessageMinimal.type.isText) {
    return mentionCache.replaceMention(
          content,
          mentionCache.mentionCache(content),
        ) ??
        '';
  } else {
    return messagePreviewOptimize(
          null,
          pinMessageMinimal.type,
          content,
          false,
          true,
        ) ??
        '';
  }
}
