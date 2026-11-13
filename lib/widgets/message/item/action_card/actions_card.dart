import 'dart:math' as math;

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../utils/extension/extension.dart';
import '../../../high_light_text.dart';
import '../../../interactive_decorated_box.dart';
import '../../../mixin_image.dart';
import '../../message.dart';
import '../../message_bubble.dart';
import '../../message_style.dart';
import '../action/action_data.dart';
import '../action/action_message.dart';
import '../text/text_message.dart';
import 'action_card_data.dart';
import 'network_cover_preview.dart';

class ActionsCardMessage extends StatelessWidget {
  ActionsCardMessage({required this.data, super.key})
    : assert(data.isActionsCard);

  final AppCardData data;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
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
                    previewCover: true,
                    description: MessageTextWidget(
                      enableSelection: false,
                      color: context.theme.text,
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
                  constraints: BoxConstraints(maxWidth: width, minWidth: width),
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

class _Bubble extends HookWidget {
  const _Bubble({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isCurrentUser = useIsCurrentUser();
    final highlightEnabled = useMessageHighlightEnabled();
    final menuHighlighted = useMessageMenuHighlighted();
    final clipper = BubbleClipper(currentUser: isCurrentUser, showNip: true);
    final bubbleColor = context.messageBubbleColor(isCurrentUser);
    Widget bubble = CustomPaint(
      painter: BubblePainter(color: bubbleColor, clipper: clipper),
      child: ClipPath(
        clipper: clipper,
        child: MessageBubbleNipPadding(
          currentUser: isCurrentUser,
          child: child,
        ),
      ),
    );
    if (highlightEnabled || menuHighlighted) {
      bubble = MessageBubbleHighlight(
        messageId: context.message.messageId,
        enabled: highlightEnabled,
        clipper: clipper,
        currentUser: isCurrentUser,
        media: false,
        menuHighlighted: menuHighlighted,
        child: bubble,
      );
    }
    return bubble;
  }
}

class ActionsCardBody extends StatelessWidget {
  const ActionsCardBody({
    required this.description,
    required this.data,
    this.previewCover = false,
    super.key,
  });

  final AppCardData data;
  final Widget description;

  /// Whether a tap on the cover opens it in an image preview.
  final bool previewCover;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (data.coverUrl.isNotEmpty)
        _PreviewableCover(
          enabled: previewCover,
          url: data.coverUrl,
          child: AspectRatio(
            aspectRatio: 1,
            child: MixinImage.network(data.coverUrl),
          ),
        )
      else if (data.cover != null)
        _CoverWidget(cover: data.cover!, preview: previewCover),
      const SizedBox(height: 10),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: CustomText(
          data.title,
          style: TextStyle(
            color: context.theme.text,
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

class _PreviewableCover extends StatelessWidget {
  const _PreviewableCover({
    required this.enabled,
    required this.url,
    required this.child,
    this.thumbnail,
  });

  final bool enabled;
  final String url;
  final String? thumbnail;
  final Widget child;

  @override
  Widget build(BuildContext context) => enabled
      ? InteractiveDecoratedBox(
          cursor: SystemMouseCursors.click,
          onTap: () => NetworkCoverPreview.push(
            context,
            url: url,
            thumbnail: thumbnail,
          ),
          child: child,
        )
      : child;
}

class _CoverWidget extends StatelessWidget {
  const _CoverWidget({required this.cover, required this.preview});

  final Cover cover;
  final bool preview;

  @override
  Widget build(BuildContext context) {
    var aspect = 1.0;
    try {
      aspect = math.max(cover.width / cover.height, 1.5);
    } catch (err) {
      aspect = 1;
    }
    return _PreviewableCover(
      enabled: preview,
      url: cover.url,
      thumbnail: cover.thumbnail,
      child: AspectRatio(
        aspectRatio: aspect,
        child: MixinImage.network(cover.url),
      ),
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
