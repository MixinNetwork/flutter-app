import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../enum/encrypt_category.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/web_view/web_view_interface.dart';
import '../../interactive_decorated_box.dart';
import '../../toast.dart';
import '../message.dart';
import '../message_style.dart';

class StrangerMessage extends ConsumerWidget {
  const StrangerMessage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBotConversation =
        useMessageConverter(converter: (state) => state.appId != null);

    return Column(
      children: [
        Text(
          isBotConversation
              ? context.l10n.chatBotReceptionTitle
              : context.l10n.strangerHint,
          style: TextStyle(
            fontSize: ref.watch(messageStyleProvider).primaryFontSize,
            color: context.theme.text,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StrangerButton(
              isBotConversation
                  ? context.l10n.openHomePage
                  : context.l10n.block,
              onTap: () async {
                final message = context.message;
                if (isBotConversation) {
                  final app =
                      await context.database.appDao.findAppById(message.appId!);
                  if (app == null) return;
                  await MixinWebView.instance.openBotWebViewWindow(context, app,
                      conversationId: message.conversationId);
                } else {
                  await runFutureWithToast(
                    context.accountServer.blockUser(message.userId),
                  );
                }
              },
            ),
            const SizedBox(width: 16),
            _StrangerButton(
              isBotConversation ? context.l10n.sayHi : context.l10n.addContact,
              onTap: () {
                final message = context.message;
                if (isBotConversation) {
                  context.accountServer.sendTextMessage(
                      'Hi', EncryptCategory.plain,
                      conversationId: message.conversationId);
                } else {
                  context.accountServer
                      .addUser(message.userId, message.userFullName);
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _StrangerButton extends ConsumerWidget {
  const _StrangerButton(
    this.text, {
    this.onTap,
  });

  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      InteractiveDecoratedBox.color(
        onTap: onTap,
        decoration: BoxDecoration(
          color: context.theme.primary,
          borderRadius: const BorderRadius.all(Radius.circular(8)),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 162,
            minHeight: 36,
            maxHeight: 36,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: ref.watch(messageStyleProvider).primaryFontSize,
                  color: context.theme.accent,
                ),
              ),
            ),
          ),
        ),
      );
}
