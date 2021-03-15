import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/utils/color_utils.dart';
import 'package:flutter_app/utils/uri_utils.dart';
import 'package:flutter_app/widgets/message/item/action/action_data.dart';
import 'package:flutter_app/utils/action_utils.dart';

import '../../../brightness_observer.dart';
import '../../../interacter_decorated_box.dart';
import '../../message_bubble.dart';

class ActionMessage extends StatelessWidget {
  const ActionMessage({
    Key? key,
    required this.message,
    required this.isCurrentUser,
  }) : super(key: key);

  final MessageItem message;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) => MessageBubble(
        isCurrentUser: isCurrentUser,
        showBubble: false,
        padding: EdgeInsets.zero,
        child: Wrap(
          spacing: 10,
          runSpacing: 8,
          children: List<Widget>.from(
            jsonDecode(message.content!).map((e) => ActionData.fromJson(e)).map(
                  (e) => InteractableDecoratedBox.color(
                    onTap: () {
                      if (context.openAction(e.action)) return;
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
      );
}
