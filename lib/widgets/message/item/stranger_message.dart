import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../enum/encrypt_category.dart';
import '../../../ui/provider/account_server_provider.dart';
import '../../../ui/provider/database_provider.dart';
import '../../../ui/provider/ui_context_providers.dart';
import '../../../utils/web_view/web_view_interface.dart';
import '../../interactive_decorated_box.dart';
import '../../toast.dart';
import '../message.dart';
import '../message_style.dart';

class StrangerMessage extends HookConsumerWidget {
  const StrangerMessage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationProvider);
    final theme = ref.watch(brightnessThemeDataProvider);
    final accountServer = ref.read(accountServerProvider).requireValue;
    final database = ref.read(databaseProvider).requireValue;
    final isBotConversation = useMessageConverter(
      converter: (state) => state.appId != null,
    );

    return Column(
      children: [
        Text(
          isBotConversation ? l10n.chatBotReceptionTitle : l10n.strangerHint,
          style: TextStyle(
            fontSize: context.messageStyle.primaryFontSize,
            color: theme.text,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StrangerButton(
              isBotConversation ? l10n.openHomePage : l10n.block,
              onTap: () async {
                final message = context.message;
                if (isBotConversation) {
                  final app = await database.appDao.findAppById(
                    message.appId!,
                  );
                  if (app == null) return;
                  await MixinWebView.instance.openBotWebViewWindow(
                    context,
                    ref.container,
                    app,
                    conversationId: message.conversationId,
                  );
                } else {
                  await runFutureWithToast(
                    accountServer.blockUser(message.userId),
                  );
                }
              },
            ),
            const SizedBox(width: 16),
            _StrangerButton(
              isBotConversation ? l10n.sayHi : l10n.addContact,
              onTap: () {
                final message = context.message;
                if (isBotConversation) {
                  accountServer.sendTextMessage(
                    'Hi',
                    EncryptCategory.plain,
                    conversationId: message.conversationId,
                  );
                } else {
                  accountServer.addUser(
                    message.userId,
                    message.userFullName,
                  );
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
  const _StrangerButton(this.text, {this.onTap});

  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    return InteractiveDecoratedBox.color(
      onTap: onTap,
      decoration: BoxDecoration(
        color: theme.primary,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 162,
          minHeight: 36,
          maxHeight: 36,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontSize: context.messageStyle.primaryFontSize,
                color: theme.accent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
