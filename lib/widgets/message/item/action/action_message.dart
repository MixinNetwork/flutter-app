import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../../../../db/mixin_database.dart';
import '../../../../utils/action_utils.dart';
import '../../../../utils/color_utils.dart';
import '../../../../utils/uri_utils.dart';
import '../../../brightness_observer.dart';
import '../../message_bubble.dart';
import 'action_data.dart';

class ActionMessage extends StatelessWidget {
  const ActionMessage({
    Key? key,
    required this.message,
    required this.isCurrentUser,
  }) : super(key: key);

  final MessageItem message;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 8, bottom: 4),
        child: Wrap(
          spacing: 10,
          runSpacing: 8,
          children: List<Widget>.from(
            // ignore: avoid_dynamic_calls
            jsonDecode(message.content!).map((e) => ActionData.fromJson(e)).map(
                  (e) => ElevatedButton(
                    onPressed: () {
                      // ignore: avoid_dynamic_calls
                      if (context.openAction(e.action)) return;
                      // ignore: avoid_dynamic_calls
                      openUri(context, e.action);
                    },
                    style: ElevatedButton.styleFrom(
                      primary: BrightnessData.themeOf(context).primary,
                    ),
                    // ignore: avoid_dynamic_calls
                    child: Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 8),
                        child: Text(e.label,
                            style: TextStyle(
                              fontSize: 15,
                              // ignore: avoid_dynamic_calls
                              color: colorHex(e.color) ?? Colors.black,
                            ))),
                  ),
                ),
          ),
        ),
      );
}
