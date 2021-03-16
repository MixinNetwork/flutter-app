import 'package:flutter/widgets.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/account/account_server.dart';
import 'package:flutter_app/db/mixin_database.dart' hide Offset, Message;
import 'package:flutter_app/ui/home/bloc/conversation_cubit.dart';
import 'package:flutter_app/utils/uri_utils.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/generated/l10n.dart';
import 'package:flutter_app/db/extension/conversation.dart';

import '../../interacter_decorated_box.dart';

class StrangerMessage extends StatelessWidget {
  const StrangerMessage({
    Key? key,
    required this.message,
  }) : super(key: key);

  final MessageItem message;

  @override
  Widget build(BuildContext context) {
    final isBotConversation =
        BlocProvider.of<ConversationCubit>(context).state?.isBotConversation ??
            false;
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
                final conversationItem =
                    BlocProvider.of<ConversationCubit>(context).state;
                if (conversationItem == null) return;
                if (conversationItem.isBotConversation) {
                  final app = await context.read<AccountServer>().database.appsDao.findUserById(conversationItem.appId!);
                  if(app == null) return;
                  await openUri(app.homeUri);
                } else {
                  // TODO block
                  debugPrint('block');
                }

              },
            ),
            const SizedBox(width: 16),
            _StrangerButton(
              isBotConversation
                  ? Localization.of(context).botInteractHi
                  : Localization.of(context).addContact,
              onTap: () {
                final conversationItem =
                    BlocProvider.of<ConversationCubit>(context).state;
                if (conversationItem == null) return;
                if (conversationItem.isBotConversation)
                  Provider.of<AccountServer>(context, listen: false)
                      .sendTextMessage(
                    conversationItem.conversationId,
                    'Hi',
                  );
                else
                  // TODO add user
                  debugPrint('add user');
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
