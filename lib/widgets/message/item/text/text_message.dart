import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../../db/mixin_database.dart' hide Offset, Message;
import '../../../../ui/home/chat_page.dart';
import '../../../../utils/hook.dart';
import '../../../../utils/reg_exp_utils.dart';
import '../../../../utils/uri_utils.dart';
import '../../../brightness_observer.dart';
import '../../../high_light_text.dart';
import '../../message.dart';
import '../../message_bubble.dart';
import '../../message_datetime_and_status.dart';
import '../../message_layout.dart';
import 'mention_builder.dart';

class TextMessage extends HookWidget {
  const TextMessage({
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
    final keywordTextStyle = TextStyle(
      backgroundColor: BrightnessData.themeOf(context).highlight,
    );

    final keyword = useBlocState<SearchConversationKeywordCubit, String>();

    final highlightTextSpans = useMemoized(
      () => uriRegExp.allMatches(message.content!).map(
            (e) => HighlightTextSpan(
              e[0]!,
              style: TextStyle(
                color: BrightnessData.themeOf(context).accent,
              ),
              onTap: () => openUri(context, e[0]!),
            ),
          ),
      [message.content],
    );

    final keywordHighlightTextSpans = useMemoized(
        () => keyword.trim().isEmpty
            ? highlightTextSpans
            : highlightTextSpans.fold<Set<HighlightTextSpan>>({},
                (previousValue, element) {
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

    final content = Builder(
      builder: (context) => MentionBuilder(
        content: message.content,
        builder: (context, newContent, mentionHighlightTextSpans) =>
            HighlightSelectableText(
          newContent!,
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
            color: BrightnessData.themeOf(context).text,
          ),
        ),
      ),
    );
    final dateAndStatus = MessageDatetimeAndStatus(
      isCurrentUser: isCurrentUser,
      message: message,
    );

    return MessageBubble(
      messageId: message.messageId,
      quoteMessageId: message.quoteId,
      quoteMessageContent: message.quoteContent,
      showNip: showNip,
      isCurrentUser: isCurrentUser,
      child: MessageLayout(
        spacing: 6,
        content: content,
        dateAndStatus: dateAndStatus,
      ),
    );
  }
}
