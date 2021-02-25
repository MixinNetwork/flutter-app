import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/account/account_server.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/ui/home/bloc/conversation_cubit.dart';
import 'package:flutter_app/utils/color_utils.dart';
import 'package:flutter_app/utils/uri_utils.dart';
import 'package:flutter_app/widgets/message/item/action/action_data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../../../brightness_observer.dart';
import '../../../interacter_decorated_box.dart';

class ActionMessage extends StatelessWidget {
  const ActionMessage({
    Key key,
    this.message,
  }) : super(key: key);

  final MessageItem message;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 4,
          horizontal: 25,
        ),
        child: Builder(
          builder: (context) => Wrap(
            spacing: 10,
            runSpacing: 8,
            children: List<Widget>.from(
              jsonDecode(message.content)
                  .map((e) => ActionData.fromJson(e))
                  .map(
                    (e) => InteractableDecoratedBox.color(
                      onTap: () {
                        if (e.action.startsWith('input:/')) {
                          final content = e.action.substring(6).trim();
                          if (content?.isNotEmpty == true)
                            return Provider.of<AccountServer>(context,
                                    listen: false)
                                .sendTextMessage(
                              BlocProvider.of<ConversationCubit>(context)
                                  .state
                                  .conversationId,
                              content,
                            );
                        }
                        openUri(e.action);
                      },
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: BrightnessData.themeOf(context).primary,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          e.label,
                          style: TextStyle(
                            fontSize: 15,
                            color: colorHex(e.color) ?? Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
            ),
          ),
        ),
      );
}
