import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:url_launcher/url_launcher_string.dart';

import '../../../../bloc/keyword_cubit.dart';
import '../../../../ui/home/bloc/conversation_cubit.dart';
import '../../../../ui/home/chat/chat_page.dart';
import '../../../../utils/extension/extension.dart';
import '../../../../utils/hook.dart';
import '../../../../utils/logger.dart';
import '../../../../utils/reg_exp_utils.dart';
import '../../../../utils/uri_utils.dart';
import '../../../high_light_text.dart';
import '../../../user/user_dialog.dart';
import '../../message.dart';
import '../../message_bubble.dart';
import '../../message_datetime_and_status.dart';
import '../../message_layout.dart';
import '../../message_style.dart';
import 'mention_builder.dart';

class TextMessage extends HookWidget {
  const TextMessage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = useMessageConverter(converter: (state) => state.userId);
    final content =
        useMessageConverter(converter: (state) => state.content ?? '');

    final keywordTextStyle = TextStyle(
      backgroundColor: context.theme.highlight,
      color: context.theme.text,
    );

    var keyword = useBlocStateConverter<SearchConversationKeywordCubit,
        (String?, String), String>(
      converter: (state) {
        if (state.$1 == null || state.$1 == userId) return state.$2;
        return '';
      },
      keys: [userId],
    );

    final globalKeyword = useBlocState<KeywordCubit, String>();
    final conversationKeyword =
        useBlocState<ConversationCubit, ConversationState?>()?.keyword;

    if (globalKeyword.isNotEmpty) {
      keyword = globalKeyword;
    } else if (conversationKeyword?.isNotEmpty ?? false) {
      keyword = conversationKeyword!;
    }

    final urlHighlightTextSpans = useMemoized(
      () => uriRegExp.allMatchesAndSort(content).map(
            (e) => HighlightTextSpan(
              e[0]!,
              style: TextStyle(
                color: context.theme.accent,
              ),
              onTap: () => openUri(context, e[0]!,
                  app: context.read<ConversationCubit>().state?.app),
            ),
          ),
      [content],
    );
    final mailHighlightTextSpans = useMemoized(
      () => mailRegExp.allMatchesAndSort(content).map(
            (e) => HighlightTextSpan(
              e[0]!,
              style: TextStyle(
                color: context.theme.accent,
              ),
              onTap: () {
                final uri = 'mailto:${e[0]!}';
                d('open mail uri: $uri');
                launchUrlString(uri);
              },
            ),
          ),
      [content],
    );

    final botNumberHighlightTextSpans = useMemoized(
      () => botNumberRegExp.allMatchesAndSort(content).map(
            (e) => HighlightTextSpan(
              e[0]!,
              style: TextStyle(
                color: context.theme.accent,
              ),
              onTap: () => showUserDialog(context, null, e[0]),
            ),
          ),
      [content],
    );

    final keywordHighlightTextSpans = useMemoized(
        () => keyword.trim().isEmpty
            ? [
                ...urlHighlightTextSpans,
                ...mailHighlightTextSpans,
                ...botNumberHighlightTextSpans
              ]
            : [
                ...urlHighlightTextSpans,
                ...mailHighlightTextSpans,
                ...botNumberHighlightTextSpans
              ].fold<Set<HighlightTextSpan>>({}, (previousValue, element) {
                element.text.splitMapJoin(
                  RegExp(RegExp.escape(keyword), caseSensitive: false),
                  onMatch: (match) {
                    previousValue.add(
                      HighlightTextSpan(
                        match[0]!,
                        onTap: element.onTap,
                        style: (element.style ?? const TextStyle())
                            .merge(keywordTextStyle),
                      ),
                    );
                    return '';
                  },
                  onNonMatch: (text) {
                    previousValue.add(
                      HighlightTextSpan(
                        text,
                        onTap: element.onTap,
                        style: element.style,
                      ),
                    );
                    return '';
                  },
                );

                return previousValue;
              }).toList(),
        [keyword]);

    final contentWidget = Builder(
      builder: (context) => MentionBuilder(
        content: content,
        builder: (context, newContent, mentionHighlightTextSpans) =>
            HighlightSelectableText(
          newContent ?? ' ',
          highlightTextSpans: [
            HighlightTextSpan(
              keyword,
              style: keywordTextStyle,
            ),
            ...keywordHighlightTextSpans,
            ...mentionHighlightTextSpans,
          ],
          style: TextStyle(
            fontSize: context.messageStyle.primaryFontSize,
            color: context.theme.text,
          ),
        ),
      ),
    );

    return MessageBubble(
      child: MessageLayout(
        spacing: 6,
        content: contentWidget,
        dateAndStatus: const MessageDatetimeAndStatus(),
      ),
    );
  }
}
