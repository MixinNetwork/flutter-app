import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../blaze/vo/pin_message_minimal.dart';
import '../../../ui/provider/mention_cache_provider.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/hook.dart';
import '../../../utils/message_optimize.dart';
import '../../high_light_text.dart';
import '../message.dart';
import '../message_style.dart';

class PinMessageWidget extends HookConsumerWidget {
  const PinMessageWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mentionCache = ref.read(mentionCacheProvider);

    final content = useMessageConverter(
      converter: (state) => state.content ?? '',
    );
    final userFullName = useMessageConverter(
      converter: (state) => state.userFullName ?? '',
    );

    final pinMessageMinimal = useMemoized(
      () => PinMessageMinimal.fromJsonString(content),
      [content],
    );

    final cachePreview = useMemoized(() {
      if (pinMessageMinimal == null) {
        return context.l10n.chatPinMessage(userFullName, context.l10n.aMessage);
      }
      final preview = cachePinPreviewText(
        pinMessageMinimal: pinMessageMinimal,
        mentionCache: mentionCache,
      );

      final lines = const LineSplitter().convert(preview);
      final singleLinePreview =
          lines.length > 1 ? '${lines.first}...' : lines.firstOrNull ?? '';

      return context.l10n.chatPinMessage(userFullName, singleLinePreview);
    }, [userFullName, content, mentionCache]);

    final text =
        useMemoizedFuture(
          () async {
            if (pinMessageMinimal == null) return cachePreview;

            final preview = await generatePinPreviewText(
              pinMessageMinimal: pinMessageMinimal,
              mentionCache: mentionCache,
            );

            final lines = const LineSplitter().convert(preview);
            final singleLinePreview =
                lines.length > 1
                    ? '${lines.first}...'
                    : lines.firstOrNull ?? '';
            return context.l10n
                .chatPinMessage(userFullName, singleLinePreview)
                .overflow;
          },
          cachePreview,
          keys: [userFullName, content, mentionCache],
        ).requireData;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.dynamicColor(
                const Color.fromRGBO(202, 234, 201, 1),
              ),
              borderRadius: const BorderRadius.all(Radius.circular(10)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              child: CustomText(
                text,
                style: TextStyle(
                  fontSize: context.messageStyle.secondaryFontSize,
                  color: context.dynamicColor(const Color.fromRGBO(0, 0, 0, 1)),
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
}) async =>
    pinMessageMinimal.type.isText
        ? mentionCache.replaceMention(
              pinMessageMinimal.content,
              await mentionCache.checkMentionCache({pinMessageMinimal.content}),
            ) ??
            ''
        : messagePreviewOptimize(
              null,
              pinMessageMinimal.type,
              pinMessageMinimal.content,
              false,
              true,
            ) ??
            '';

String cachePinPreviewText({
  required PinMessageMinimal pinMessageMinimal,
  required MentionCache mentionCache,
}) =>
    pinMessageMinimal.type.isText
        ? mentionCache.replaceMention(
              pinMessageMinimal.content,
              mentionCache.mentionCache(pinMessageMinimal.content),
            ) ??
            ''
        : messagePreviewOptimize(
              null,
              pinMessageMinimal.type,
              pinMessageMinimal.content,
              false,
              true,
            ) ??
            '';
