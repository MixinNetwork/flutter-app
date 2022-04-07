import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:tuple/tuple.dart';
import 'package:url_launcher/url_launcher.dart';

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
import 'mention_builder.dart';

class TextMessage extends HookWidget {
  const TextMessage({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userId = useMessageConverter(converter: (state) => state.userId);
    final content =
        useMessageConverter(converter: (state) => state.content ?? '');

    final keywordTextStyle = TextStyle(
      backgroundColor: context.theme.highlight,
    );

    final keyword = useBlocStateConverter<SearchConversationKeywordCubit,
        Tuple2<String?, String>, String>(
      converter: (state) => state.item1 != userId ? '' : state.item2,
      keys: [userId],
    );

    final urlHighlightTextSpans = useMemoized(
      () => uriRegExp.allMatchesAndSort(content).map(
            (e) => HighlightTextSpan(
              e[0]!,
              style: TextStyle(
                color: context.theme.accent,
              ),
              onTap: () => openUri(context, e[0]!),
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
                launch(uri);
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
                  RegExp(keyword, caseSensitive: false),
                  onMatch: (match) {
                    previousValue.add(
                      HighlightTextSpan(
                        match[0]!,
                        onTap: element.onTap,
                        style: keywordTextStyle.merge(element.style),
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
            ...keywordHighlightTextSpans,
            HighlightTextSpan(
              keyword,
              style: keywordTextStyle,
            ),
            ...mentionHighlightTextSpans,
          ],
          style: TextStyle(
            fontSize: MessageItemWidget.primaryFontSize,
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
