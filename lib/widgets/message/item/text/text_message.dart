import 'package:flutter/material.dart' hide SelectableRegion;
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../ui/home/chat/chat_page.dart';
import '../../../../ui/provider/conversation_provider.dart';
import '../../../../ui/provider/keyword_provider.dart';
import '../../../../ui/provider/mention_cache_provider.dart';
import '../../../../utils/extension/extension.dart';
import '../../../../utils/hook.dart';
import '../../../../utils/platform.dart';
import '../../../high_light_text.dart';
import '../../message.dart';
import '../../message_bubble.dart';
import '../../message_datetime_and_status.dart';
import '../../message_layout.dart';
import '../../message_style.dart';
import 'selectable.dart';

class TextMessage extends HookConsumerWidget {
  const TextMessage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content =
        useMessageConverter(converter: (state) => state.content ?? '');
    return MessageBubble(
      child: MessageTextWidget(
        fontSize: context.messageStyle.primaryFontSize,
        color: context.theme.text,
        content: content,
      ),
    );
  }
}

class MessageTextWidget extends HookConsumerWidget {
  const MessageTextWidget({
    required this.fontSize,
    required this.color,
    required this.content,
    super.key,
  });

  final double fontSize;
  final Color color;
  final String content;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = useMessageConverter(converter: (state) => state.userId);

    var keyword = useBlocStateConverter<SearchConversationKeywordCubit,
        (String?, String), String>(
      converter: (state) {
        if (state.$1 == null || state.$1 == userId) return state.$2;
        return '';
      },
      keys: [userId],
    );

    final globalKeyword = ref.watch(trimmedKeywordProvider);
    final conversationKeyword =
        ref.watch(conversationProvider.select((value) => value?.keyword));

    if (globalKeyword.isNotEmpty) {
      keyword = globalKeyword;
    } else if (conversationKeyword?.isNotEmpty ?? false) {
      keyword = conversationKeyword!;
    }

    final mentionCache = ref.read(mentionCacheProvider);

    final mentionMap = useMemoizedFuture(
      () => mentionCache.checkMentionCache({content}),
      mentionCache.mentionCache(content),
      keys: [content],
    ).requireData;

    final focusNode = useFocusNode(debugLabel: 'text selection focus');

    return MessageSelectionArea(
      focusNode: focusNode,
      child: MessageLayout(
        spacing: 6,
        content: CustomText(
          content,
          style: TextStyle(
            fontSize: fontSize,
            color: color,
          ),
          textMatchers: [
            UrlTextMatcher(context),
            MailTextMatcher(context),
            MentionTextMatcher(context, mentionMap),
            BotNumberTextMatcher(context),
            EmojiTextMatcher(),
            KeyWordTextMatcher(
              keyword,
              style: TextStyle(
                backgroundColor: context.theme.highlight,
                color: context.theme.text,
              ),
            ),
          ],
        ),
        dateAndStatus: const MessageDatetimeAndStatus(),
      ),
    );
  }
}

class MessageSelectionArea extends HookWidget {
  const MessageSelectionArea({
    required this.child,
    this.focusNode,
    super.key,
  });

  final Widget child;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final node = useMemoized(
      () => focusNode ?? FocusNode(debugLabel: 'message_selection_focus'),
      [focusNode],
    );
    if (kPlatformIsDesktop) {
      return SelectableRegion(
        focusNode: node,
        contextMenuBuilder: (context, state) => const SizedBox(),
        selectionControls: desktopTextSelectionHandleControls,
        child: child,
      );
    }
    return child;
  }
}
