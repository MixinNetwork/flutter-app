import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/resources.dart';
import '../../../ui/provider/recall_message_reedit_provider.dart';
import '../../../utils/extension/extension.dart';
import '../message.dart';
import '../message_bubble.dart';
import '../message_style.dart';

class RecallMessage extends HookConsumerWidget {
  const RecallMessage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCurrentUser = useIsCurrentUser();
    final messageId = useMessageConverter(
      converter: (state) => state.messageId,
    );

    final recalledText = ref.watch(recalledTextProvider(messageId));

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          Resources.assetsImagesRecallSvg,
          colorFilter: ColorFilter.mode(
            context.theme.secondaryText,
            BlendMode.srcIn,
          ),
          width: 16,
          height: 16,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text:
                      isCurrentUser
                          ? context.l10n.youDeletedThisMessage
                          : context.l10n.thisMessageWasDeleted,
                ),
                if (recalledText != null)
                  TextSpan(
                    text: ' ${context.l10n.reedit}',
                    style: TextStyle(color: context.theme.accent),
                    recognizer:
                        TapGestureRecognizer()
                          ..onTap =
                              () => ref
                                  .read(recallMessageNotifierProvider)
                                  .onReedit(recalledText),
                  ),
              ],
            ),
            style: TextStyle(
              fontSize: context.messageStyle.primaryFontSize,
              color: context.theme.text,
            ),
          ),
        ),
      ],
    );
    return MessageBubble(child: content);
  }
}
