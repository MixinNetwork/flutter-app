import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../../../db/mixin_database.dart';
import '../../../db/mixin_database.dart' hide Offset, Message;

import '../../../utils/extension/extension.dart';
import '../../../utils/uri_utils.dart';
import '../../interacter_decorated_box.dart';
import '../../toast.dart';
import '../message.dart';

class StrangerMessage extends StatelessWidget {
  const StrangerMessage({
    Key? key,
    required this.message,
  }) : super(key: key);

  final MessageItem message;

  @override
  Widget build(BuildContext context) {
    final isBotConversation = message.appId != null;
    return Column(
      children: [
        Text(
          isBotConversation
              ? context.l10n.botInteractInfo
              : context.l10n.strangerFromMessage,
          style: TextStyle(
            fontSize: MessageItemWidget.primaryFontSize,
            color: context.theme.text,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StrangerButton(
              isBotConversation
                  ? context.l10n.botInteractOpen
                  : context.l10n.block,
              onTap: () async {
                if (isBotConversation) {
                  final app = await context.accountServer.database.appDao
                      .findUserById(message.appId!);
                  if (app == null) return;
                  await openUri(context, app.homeUri);
                } else {
                  await runFutureWithToast(
                    context,
                    context.accountServer.blockUser(message.userId),
                  );
                }
              },
            ),
            const SizedBox(width: 16),
            _StrangerButton(
              isBotConversation
                  ? context.l10n.botInteractHi
                  : context.l10n.addContact,
              onTap: () {
                if (isBotConversation) {
                  context.accountServer.sendTextMessage('Hi', true,
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

class _StrangerButton extends StatelessWidget {
  const _StrangerButton(
    this.text, {
    Key? key,
    this.onTap,
  }) : super(key: key);

  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InteractableDecoratedBox.color(
        onTap: onTap,
        decoration: BoxDecoration(
          color: context.theme.primary,
          borderRadius: BorderRadius.circular(8),
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
                  fontSize: MessageItemWidget.primaryFontSize,
                  color: context.theme.accent,
                ),
              ),
            ),
          ),
        ),
      );
}
