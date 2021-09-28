import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';

import '../../../constants/resources.dart';
import '../../../ui/home/bloc/recall_message_bloc.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/hook.dart';
import '../message.dart';
import '../message_bubble.dart';
import '../message_datetime_and_status.dart';
import '../message_layout.dart';

class RecallMessage extends HookWidget {
  const RecallMessage({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isCurrentUser = useIsCurrentUser();
    final messageId =
        useMessageConverter(converter: (state) => state.messageId);

    final recalledText = useBlocStateConverter<RecallMessageReeditCubit,
        Map<String, String>, String?>(
      converter: (state) => state[messageId],
      keys: [messageId],
    );

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          Resources.assetsImagesRecallSvg,
          color: context.theme.secondaryText,
          width: 16,
          height: 16,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text.rich(
            TextSpan(children: [
              TextSpan(
                text: isCurrentUser
                    ? context.l10n.chatRecallMe
                    : context.l10n.chatRecallDelete,
              ),
              if (recalledText != null)
                TextSpan(
                    text: ' ${context.l10n.reedit}',
                    style: TextStyle(color: context.theme.accent),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        context
                            .read<RecallMessageReeditCubit>()
                            .onReedit(recalledText);
                      }),
            ]),
            style: TextStyle(
              fontSize: MessageItemWidget.primaryFontSize,
              color: context.theme.text,
            ),
          ),
        ),
      ],
    );
    const dateAndStatus = MessageDatetimeAndStatus();
    return MessageBubble(
      child: MessageLayout(
        spacing: 6,
        content: content,
        dateAndStatus: dateAndStatus,
      ),
    );
  }
}
