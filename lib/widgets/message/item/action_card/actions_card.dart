import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../ui/home/chat/chat_page.dart';
import '../../../../ui/provider/conversation_provider.dart';
import '../../../../ui/provider/keyword_provider.dart';
import '../../../../ui/provider/mention_cache_provider.dart';
import '../../../../utils/extension/extension.dart';
import '../../../../utils/hook.dart';
import '../../../cache_image.dart';
import '../../../high_light_text.dart';
import '../../message.dart';
import '../../message_bubble.dart';
import '../../message_datetime_and_status.dart';
import '../../message_layout.dart';
import '../../message_style.dart';
import '../action/action_data.dart';
import '../action/action_message.dart';
import '../text/text_message.dart';
import 'action_card_data.dart';

class ActionsCardMessage extends StatelessWidget {
  ActionsCardMessage({required this.data, super.key})
      : assert(data.isActionsCard);

  final AppCardData data;

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final width = (constraints.maxWidth * 0.41).clamp(240.0, 340.0);
        return Column(
          children: [
            MessageBubble(
              padding: EdgeInsets.zero,
              clip: true,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: width, minWidth: width),
                child: _ActionsCard(data: data),
              ),
            ),
            const SizedBox(height: 8),
            MessageBubble(
              showBubble: false,
              padding: EdgeInsets.zero,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: width, minWidth: width),
                child: _Actions(actions: data.actions),
              ),
            )
          ],
        );
      });
}

class ActionsCardBody extends StatelessWidget {
  const ActionsCardBody({
    required this.description,
    required this.data,
    super.key,
  });

  final AppCardData data;
  final Widget description;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data.coverUrl.isNotEmpty)
            AspectRatio(
              aspectRatio: 16 / 10,
              child: CacheImage(data.coverUrl),
            ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: CustomText(
              data.title,
              style: TextStyle(
                color: context.theme.text,
                fontSize: context.messageStyle.primaryFontSize,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: description,
          ),
          const SizedBox(height: 10),
        ],
      );
}

class _ActionsCard extends HookConsumerWidget {
  const _ActionsCard({required this.data});

  final AppCardData data;

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
      () => mentionCache.checkMentionCache({data.description}),
      mentionCache.mentionCache(data.description),
      keys: [data.description],
    ).requireData;

    final focusNode = useFocusNode(debugLabel: 'text selection focus');

    return ActionsCardBody(
      data: data,
      description: MessageSelectionArea(
        focusNode: focusNode,
        child: MessageLayout(
          spacing: 6,
          content: CustomText(
            data.description,
            style: TextStyle(
              color: context.theme.secondaryText,
              fontSize: context.messageStyle.secondaryFontSize,
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
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.actions});

  final List<ActionData> actions;

  @override
  Widget build(BuildContext context) => ActionButtonLayout(
        children: actions.map((e) => ActionMessageButton(action: e)).toList(),
      );
}
