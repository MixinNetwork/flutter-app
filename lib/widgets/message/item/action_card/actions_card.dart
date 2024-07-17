import 'package:flutter/material.dart';

import '../../../../utils/extension/extension.dart';
import '../../../cache_image.dart';
import '../../../high_light_text.dart';
import '../../message_bubble.dart';
import '../../message_style.dart';
import '../action/action_data.dart';
import '../action/action_message.dart';
import '../text/text_message.dart';
import 'action_card_data.dart';

class ActionsCardMessage extends StatelessWidget {
  ActionsCardMessage({required this.data, super.key})
      : assert(data.isActionsCard);

  final AppCardData data;

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final width = (constraints.maxWidth * 0.41).clamp(240.0, 340.0);
        return Column(
          children: [
            MessageBubble(
              padding: EdgeInsets.zero,
              clip: true,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: width, minWidth: width),
                child: ActionsCardBody(
                  data: data,
                  description: MessageTextWidget(
                    color: context.theme.text,
                    fontSize: context.messageStyle.secondaryFontSize,
                    content: data.description,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            MessageBubble(
              showBubble: false,
              padding: EdgeInsets.zero,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: width, minWidth: width),
                child: _Actions(actions: data.actions),
              ),
            )
          ],
        );
      });
}

class ActionsCardBody extends StatelessWidget {
  const ActionsCardBody({
    required this.description,
    required this.data,
    super.key,
  });

  final AppCardData data;
  final Widget description;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (data.coverUrl.isNotEmpty)
            AspectRatio(
              aspectRatio: 16 / 10,
              child: CacheImage(data.coverUrl),
            ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: CustomText(
              data.title,
              style: TextStyle(
                color: context.theme.text,
                fontSize: context.messageStyle.primaryFontSize,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: description,
          ),
          const SizedBox(height: 10),
        ],
      );
}

class _Actions extends StatelessWidget {
  const _Actions({required this.actions});

  final List<ActionData> actions;

  @override
  Widget build(BuildContext context) => ActionButtonLayout(
        children: actions.map((e) => ActionMessageButton(action: e)).toList(),
      );
}
