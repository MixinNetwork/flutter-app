import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:tuple/tuple.dart';

import '../../../../db/mixin_database.dart' hide Offset, Message;
import '../../../../ui/home/chat_page.dart';
import '../../../../utils/hook.dart';
import '../../../../utils/reg_exp_utils.dart';
import '../../../../utils/uri_utils.dart';
import '../../../brightness_observer.dart';
import '../../../high_light_text.dart';
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
    final keyword = useBlocState<SearchConversationKeywordCubit, String>();

    final mentionMap = useFuture<Map<String, String>>(
        useMemoized(
          () => MentionBuilder.mentionsConverter(message.mentions),
          [message.mentions],
        ),
        initialData: {}).data;

    final highlightTextSpans = useMemoized(
      () => <HighlightTextSpan>[
        ...mentionNumberRegExp
            .allMatches(message.content!)
            .map((e) => e[0]!)
            .map((e) => Tuple2(e, mentionMap?[e]))
            .map(
              (tuple2) => HighlightTextSpan(
                tuple2.item2 ?? tuple2.item1,
                style: TextStyle(
                  color: BrightnessData.themeOf(context).accent,
                ),
                onTap: () {
                  // TODO click mention user
                },
              ),
            ),
        ...uriRegExp.allMatches(message.content!).map(
              (e) => HighlightTextSpan(
                e[0]!,
                style: TextStyle(
                  color: BrightnessData.themeOf(context).accent,
                ),
                onTap: () => openUri(e[0]!),
              ),
            ),
      ],
      [message.content, mentionMap],
    );

    final content = Builder(
      builder: (context) => MentionBuilder(
        mentionString: message.mentions,
        builder: (context, mentionMapAsyncSnapshot) =>
            // todo HighlightSelectableText
            // call child.getMaxIntrinsicWidth is one pixel short
            HighlightText(
          message.content!,
          highlightTextSpans: [
            HighlightTextSpan(
              keyword,
              style: TextStyle(
                color: BrightnessData.themeOf(context).accent,
              ),
            ),
            ...highlightTextSpans,
          ],
          style: TextStyle(
            fontSize: 16,
            color: BrightnessData.themeOf(context).text,
          ),
        ),
      ),
    );
    final dateAndStatus = MessageDatetimeAndStatus(
      isCurrentUser: isCurrentUser,
      createdAt: message.createdAt,
      status: message.status,
    );

    return MessageBubble(
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
