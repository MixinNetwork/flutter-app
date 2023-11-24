import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../ui/provider/conversation_provider.dart';
import '../../../../utils/extension/extension.dart';
import '../../../../utils/hook.dart';
import '../../../../utils/logger.dart';
import '../../../../utils/uri_utils.dart';
import '../../../cache_image.dart';
import '../../../interactive_decorated_box.dart';
import '../../message.dart';
import '../../message_bubble.dart';
import '../../message_datetime_and_status.dart';
import '../../message_style.dart';
import '../unknown_message.dart';
import 'action_card_data.dart';

class ActionCardMessage extends HookConsumerWidget {
  const ActionCardMessage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          openUriWithWebView(
            context,
            appCardData.action,
            title: appCardData.title,
            appCardData: appCardData,
            conversationId: ref.read(currentConversationIdProvider),
          );
        },
        child: AppCardItem(data: appCardData),
      ),
    );
  }
}

class AppCardItem extends HookConsumerWidget {
  const AppCardItem({required this.data, super.key});

  final AppCardData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playing = useImagePlaying(context);
    final description = useMemoized(
      () => const LineSplitter().convert(data.description).firstOrNull ?? '',
      [data.description],
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(4)),
          child: CacheImage(
            data.iconUrl,
            height: 40,
            width: 40,
            controller: playing,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.title,
                style: TextStyle(
                  color: context.theme.text,
                  fontSize: ref.watch(messageStyleProvider).secondaryFontSize,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                description,
                maxLines: 1,
                style: TextStyle(
                  color: context.theme.secondaryText,
                  fontSize: ref.watch(messageStyleProvider).tertiaryFontSize,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
