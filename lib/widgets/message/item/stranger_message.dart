import 'package:flutter/widgets.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/account/account_server.dart';
import 'package:flutter_app/db/mixin_database.dart' hide Offset, Message;
import 'package:flutter_app/utils/uri_utils.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_app/widgets/toast.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/generated/l10n.dart';

import '../../interacter_decorated_box.dart';

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
              ? Localization.of(context).botInteractInfo
              : Localization.of(context).strangerFromMessage,
          style: TextStyle(
            fontSize: 14,
            color: BrightnessData.themeOf(context).text,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StrangerButton(
              isBotConversation
                  ? Localization.of(context).botInteractOpen
                  : Localization.of(context).block,
              onTap: () async {
                if (isBotConversation) {
                  final app = await context
                      .read<AccountServer>()
                      .database
                      .appsDao
                      .findUserById(message.appId!);
                  if (app == null) return;
                  await openUri(app.homeUri);
                } else {
                  await runFutureWithToast(
                    context,
                    context.read<AccountServer>().blockUser(message.userId),
                  );
                }
              },
            ),
            const SizedBox(width: 16),
            _StrangerButton(
              isBotConversation
                  ? Localization.of(context).botInteractHi
                  : Localization.of(context).addContact,
              onTap: () {
                if (isBotConversation)
                  Provider.of<AccountServer>(context, listen: false)
                      .sendTextMessage('Hi',
                          conversationId: message.conversationId);
                else
                  context.read<AccountServer>().addUser(message.userId);
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
          color: BrightnessData.themeOf(context).primary,
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
                  fontSize: 14,
                  color: BrightnessData.themeOf(context).accent,
                ),
              ),
            ),
          ),
        ),
      );
}
