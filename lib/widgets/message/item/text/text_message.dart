import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../ui/home/chat/chat_page.dart';
import '../../../../ui/provider/conversation_provider.dart';
import '../../../../ui/provider/keyword_provider.dart';
import '../../../../ui/provider/mention_cache_provider.dart';
import '../../../../utils/extension/extension.dart';
import '../../../../utils/hook.dart';
import '../../../high_light_text.dart';
import '../../message.dart';
import '../../message_bubble.dart';
import '../../message_datetime_and_status.dart';
import '../../message_layout.dart';
import '../../message_style.dart';

class TextMessage extends HookConsumerWidget {
  const TextMessage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = useMessageConverter(converter: (state) => state.userId);
    final content =
        useMessageConverter(converter: (state) => state.content ?? '');

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

    return MessageBubble(
      child: MessageLayout(
        spacing: 6,
        content: SelectionArea(
          child: CustomText(
            content,
            style: TextStyle(
              fontSize: context.messageStyle.primaryFontSize,
              color: context.theme.text,
            ),
            textMatchers: [
              BotNumberTextMatcher(context),
              UrlTextMatcher(context),
              MailTextMatcher(context),
              MentionTextMatcher(context, mentionMap),
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
        ),
        dateAndStatus: const MessageDatetimeAndStatus(),
      ),
    );
  }
}
