import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../ui/provider/conversation_provider.dart';
import '../../../../utils/color_utils.dart';
import '../../../../utils/extension/extension.dart';
import '../../../../utils/logger.dart';
import '../../../../utils/uri_utils.dart';
import '../../../interactive_decorated_box.dart';
import '../../message.dart';
import '../../message_bubble.dart';
import '../../message_style.dart';
import '../unknown_message.dart';
import 'action_data.dart';

class ActionMessage extends HookConsumerWidget {
  const ActionMessage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                cursor: WidgetStateMouseCursor.clickable,
                onTap: () {
                  if (context.openAction(e.action)) return;
                  openUriWithWebView(
                    context,
                    e.action,
                    title: e.label,
                    conversationId: ref.read(currentConversationIdProvider),
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
                          fontSize: context.messageStyle.primaryFontSize,
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
