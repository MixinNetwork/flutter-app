import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/db/mixin_database.dart' hide Offset, Message;
import 'package:flutter_app/utils/reg_exp_utils.dart';
import 'package:flutter_app/utils/uri_utils.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_app/widgets/message/item/quote_message.dart';

import '../../high_light_text.dart';
import '../message_bubble.dart';
import '../message_datetime.dart';
import '../message_status.dart';

class TextMessage extends StatelessWidget {
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
  Widget build(BuildContext context) => MessageBubble(
        quoteMessage: QuoteMessage(
          id: message.quoteId,
          content: message.quoteContent,
        ),
        showNip: showNip,
        isCurrentUser: isCurrentUser,
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            Builder(
              builder: (context) => HighlightText(
                message.content!,
                highlightTextSpans: [
                  ...mentionNumberRegExp
                      .allMatches(message.content!)
                      .where((element) {
                    // TODO: Check identityNumber validity.
                    return true;
                  }).map((e) {
                    // TODO: Convert to User.
                    return e;
                  }).map(
                    (RegExpMatch e) => HighlightTextSpan(
                      e[0]!,
                      style: TextStyle(
                        color: BrightnessData.themeOf(context).accent,
                      ),
                      onTap: () {},
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
                style: TextStyle(
                  fontSize: 16,
                  color: BrightnessData.themeOf(context).text,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                MessageDatetime(dateTime: message.createdAt),
                if (isCurrentUser) MessageStatusWidget(status: message.status),
              ],
            ),
          ],
        ),
      );
}
