import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../../ui/home/bloc/conversation_cubit.dart';
import '../../../../utils/color_utils.dart';
import '../../../../utils/extension/extension.dart';
import '../../../../utils/logger.dart';
import '../../../../utils/uri_utils.dart';
import '../../../interactive_decorated_box.dart';
import '../../message.dart';
import '../../message_bubble.dart';
import '../unknown_message.dart';
import 'action_data.dart';

class ActionMessage extends HookWidget {
  const ActionMessage({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final actionDataList = useMessageConverter(converter: (state) {
      try {
        final list = jsonDecode(state.content!) as List<dynamic>;
        return list.map((e) => ActionData.fromJson(e as Map<String, dynamic>));
      } catch (error) {
        e('ActionData decode error: $error');
        return null;
      }
    });

    if (actionDataList == null) return const UnknownMessage();

    final bubbleClipper = BubbleClipper(
      currentUser: false,
      showNip: false,
      nipPadding: false,
    );

    return MessageBubble(
      showBubble: false,
      padding: EdgeInsets.zero,
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: actionDataList
            .map(
              (e) => InteractiveDecoratedBox.color(
                cursor: MaterialStateMouseCursor.clickable,
                onTap: () {
                  if (context.openAction(e.action)) return;
                  openUriWithWebView(
                    context,
                    e.action,
                    title: e.label,
                    conversationId:
                        context.read<ConversationCubit>().state?.conversationId,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(1),
                  child: CustomPaint(
                    painter: BubblePainter(
                      color: context.theme.primary,
                      clipper: bubbleClipper,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        // ignore: avoid_dynamic_calls
                        e.label,
                        style: TextStyle(
                          fontSize: MessageItemWidget.primaryFontSize,
                          // ignore: avoid_dynamic_calls
                          color: colorHex(e.color) ?? Colors.black,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
