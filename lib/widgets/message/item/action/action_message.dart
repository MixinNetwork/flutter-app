import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../../../../db/mixin_database.dart';
import '../../../../utils/action_utils.dart';
import '../../../../utils/color_utils.dart';
import '../../../../utils/uri_utils.dart';
import '../../../brightness_observer.dart';
import '../../../interacter_decorated_box.dart';
import '../../message.dart';
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
  Widget build(BuildContext context) {
    final bubbleClipper = BubbleClipper(
      currentUser: false,
      showNip: false,
      nipPadding: false,
    );

    return MessageBubble(
      messageId: message.messageId,
      isCurrentUser: isCurrentUser,
      showBubble: false,
      padding: EdgeInsets.zero,
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: List<Widget>.from(
          // ignore: avoid_dynamic_calls
          jsonDecode(message.content!).map((e) => ActionData.fromJson(e)).map(
                (e) => InteractableDecoratedBox.color(
                  cursor: MaterialStateMouseCursor.clickable,
                  onTap: () {
                    // ignore: avoid_dynamic_calls
                    if (context.openAction(e.action)) return;
                    // ignore: avoid_dynamic_calls
                    openUri(context, e.action);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(1),
                    child: CustomPaint(
                      painter: BubblePainter(
                        color: BrightnessData.themeOf(context).primary,
                        clipper: bubbleClipper,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          // ignore: avoid_dynamic_calls
                          e.label,
                          style: TextStyle(
                            fontSize: MessageItemWidget.secondaryFontSize,
                            // ignore: avoid_dynamic_calls
                            color: colorHex(e.color) ?? Colors.black,
                          ),
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
}
