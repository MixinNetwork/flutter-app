import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../ui/provider/ui_context_providers.dart';
import '../../../utils/uri_utils.dart';
import '../message_bubble.dart';
import '../message_datetime_and_status.dart';
import '../message_layout.dart';
import '../message_style.dart';

class UnknownMessage extends ConsumerWidget {
  const UnknownMessage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationProvider);
    final theme = ref.watch(brightnessThemeDataProvider);
    final content = RichText(
      text: TextSpan(
        text: l10n.messageNotSupport,
        style: TextStyle(
          fontSize: context.messageStyle.primaryFontSize,
          color: theme.text,
        ),
        children: [
          const TextSpan(text: ' '),
          TextSpan(
            mouseCursor: SystemMouseCursors.click,
            text: l10n.learnMore,
            style: TextStyle(
              fontSize: context.messageStyle.primaryFontSize,
              color: theme.accent,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => openUri(
                context,
                l10n.chatNotSupportUrl,
                container: ref.container,
              ),
          ),
        ],
      ),
    );
    return MessageBubble(
      child: MessageLayout(
        spacing: 6,
        content: content,
        dateAndStatus: const MessageDatetimeAndStatus(),
      ),
    );
  }
}
