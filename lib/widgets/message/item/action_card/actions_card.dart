import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../ui/provider/ui_context_providers.dart';
import '../../../high_light_text.dart';
import '../../../mixin_image.dart';
import '../../message.dart';
import '../../message_bubble.dart';
import '../../message_style.dart';
import '../action/action_data.dart';
import '../action/action_message.dart';
import '../text/text_message.dart';
import 'action_card_data.dart';

class ActionsCardMessage extends ConsumerWidget {
  ActionsCardMessage({required this.data, super.key})
    : assert(data.isActionsCard);

  final AppCardData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth * 0.5).clamp(320.0, 375.0);
        return MessageBubble(
          showBubble: false,
          padding: EdgeInsets.zero,
          includeNip: true,
          child: Column(
            children: [
              _Bubble(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: width, minWidth: width),
                  child: MessageSelectionArea(
                    child: ActionsCardBody(
                      data: data,
                      description: MessageTextWidget(
                        enableSelection: false,
                        color: theme.text,
                        fontSize: context.messageStyle.primaryFontSize,
                        content: data.description,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              HookBuilder(
                builder: (context) => MessageBubbleNipPadding(
                  currentUser: useIsCurrentUser(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: width,
                      minWidth: width,
                    ),
                    child: _Actions(actions: data.actions),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Bubble extends HookWidget {
  const _Bubble({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isCurrentUser = useIsCurrentUser();
    final clipper = BubbleClipper(currentUser: isCurrentUser, showNip: true);
    final bubbleColor = context.messageBubbleColor(isCurrentUser);
    return CustomPaint(
      painter: BubblePainter(color: bubbleColor, clipper: clipper),
      child: ClipPath(
        clipper: clipper,
        child: MessageBubbleNipPadding(
          currentUser: isCurrentUser,
          child: child,
        ),
      ),
    );
  }
}

class ActionsCardBody extends ConsumerWidget {
  const ActionsCardBody({
    required this.description,
    required this.data,
    super.key,
  });

  final AppCardData data;
  final Widget description;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (data.coverUrl.isNotEmpty)
          AspectRatio(aspectRatio: 1, child: MixinImage.network(data.coverUrl))
        else if (data.cover != null)
          _CoverWidget(cover: data.cover!),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: CustomText(
            data.title,
            style: TextStyle(
              color: theme.text,
              fontSize: context.messageStyle.primaryFontSize,
              fontWeight: FontWeight.bold,
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
}

class _CoverWidget extends StatelessWidget {
  const _CoverWidget({required this.cover});

  final Cover cover;

  @override
  Widget build(BuildContext context) {
    var aspect = 1.0;
    try {
      aspect = math.max(cover.width / cover.height, 1.5);
    } catch (err) {
      aspect = 1;
    }
    return AspectRatio(
      aspectRatio: aspect,
      child: MixinImage.network(cover.url),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.actions});

  final List<ActionData> actions;

  @override
  Widget build(BuildContext context) => ActionButtonLayout(
    children: actions.map((e) => ActionMessageButton(action: e)).toList(),
  );
}
