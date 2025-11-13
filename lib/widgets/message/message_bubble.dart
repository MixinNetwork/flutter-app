import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../constants/resources.dart';
import '../../ui/home/bloc/blink_cubit.dart';
import '../../ui/provider/conversation_provider.dart';
import '../../utils/extension/extension.dart';
import '../action_button.dart';
import '../toast.dart';
import 'item/quote_message.dart';
import 'message.dart';

const _nipWidth = 9.0;
const _lightCurrentBubble = Color.fromRGBO(197, 237, 253, 1);
const _darkCurrentBubble = Color.fromRGBO(59, 79, 103, 1);
const lightOtherBubble = Colors.white;
const darkOtherBubble = Color.fromRGBO(52, 59, 67, 1);

extension BubbleColor on BuildContext {
  Color messageBubbleColor(bool isCurrentUser) => isCurrentUser
      ? dynamicColor(_lightCurrentBubble, darkColor: _darkCurrentBubble)
      : dynamicColor(lightOtherBubble, darkColor: darkOtherBubble);
}

class MessageBubble extends HookConsumerWidget {
  const MessageBubble({
    required this.child,
    super.key,
    this.showBubble = true,
    this.includeNip = false,
    this.clip = false,
    this.padding = const EdgeInsets.all(8),
    this.outerTimeAndStatusWidget,
    this.forceIsCurrentUserColor,
  });

  final Widget child;
  final bool showBubble;
  final bool includeNip;
  final bool clip;
  final EdgeInsetsGeometry padding;
  final Widget? outerTimeAndStatusWidget;
  final bool? forceIsCurrentUserColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showNip = useShowNip();
    final isCurrentUser = useIsCurrentUser();
    final isPinnedPage = useIsPinnedPage();
    final isDisappearingMessage = useMessageConverter<bool>(
      converter: (message) => message.expireIn != null && message.expireIn! > 0,
    );

    final quoteId = useMessageConverter(converter: (state) => state.quoteId);

    final hasQuoteMessage = quoteId?.isNotEmpty ?? false;

    final isTranscriptPage = useIsTranscriptPage();

    final bubbleColor = context.messageBubbleColor(
      forceIsCurrentUserColor ?? isCurrentUser,
    );

    final messageType = useMessageConverter(converter: (state) => state.type);

    var _child = child;

    if (!includeNip) {
      _child = MessageBubbleNipPadding(
        currentUser: isCurrentUser,
        child: child,
      );
    }

    _child = Padding(padding: padding, child: _child);

    if (hasQuoteMessage) {
      final constraintQuoteWidthToMessage =
          messageType.isVideo || messageType.isImage || messageType.isLive;
      _child = IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              // constraint width to 0, the ancestor IntrinsicWidth will relayout
              // and get the correct width.
              width: constraintQuoteWidthToMessage ? 0 : null,
              child: MessageBubbleNipPadding(
                currentUser: isCurrentUser,
                child: HookBuilder(
                  builder: (context) {
                    final quoteContent = useMessageConverter(
                      converter: (state) => state.quoteContent,
                    );
                    final messageId = useMessageConverter(
                      converter: (state) => state.messageId,
                    );

                    return QuoteMessage(
                      messageId: messageId,
                      quoteMessageId: quoteId,
                      quoteContent: quoteContent,
                      isTranscriptPage: isTranscriptPage,
                    );
                  },
                ),
              ),
            ),
            _child,
          ],
        ),
      );
    }

    final clipper = BubbleClipper(currentUser: isCurrentUser, showNip: showNip);

    if (clip) {
      _child = RepaintBoundary(
        child: ClipPath(clipper: clipper, child: _child),
      );
    }

    if (hasQuoteMessage || showBubble) {
      _child = CustomPaint(
        painter: BubblePainter(color: bubbleColor, clipper: clipper),
        child: _child,
      );
    }

    if (isPinnedPage) {
      final pinArrow = ActionButton(
        size: 16,
        name: Resources.assetsImagesPinArrowSvg,
        onTap: () {
          final message = context.message;
          context.read<BlinkCubit>().blinkByMessageId(message.messageId);
          ConversationStateNotifier.selectConversation(
            context,
            message.conversationId,
            initIndexMessageId: message.messageId,
          );
          // pop to chat page if current pin page is modal.
          if (ModalRoute.of(context)?.canPop == true) {
            Navigator.maybePop(context);
          }
        },
      );

      _child = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isCurrentUser) pinArrow,
          Flexible(child: _child),
          if (!isCurrentUser) pinArrow,
        ],
      );
    }

    if (isDisappearingMessage) {
      Widget icon = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: SvgPicture.asset(
          context.brightness == Brightness.dark
              ? Resources.assetsImagesExpiringDarkSvg
              : Resources.assetsImagesExpiringSvg,
          width: 16,
          height: 16,
        ),
      );

      if (!kReleaseMode) {
        icon = GestureDetector(
          child: icon,
          onTap: () async {
            final message = context.message;
            final expireAt = await context
                .accountServer
                .database
                .expiredMessageDao
                .getMessageExpireAt([message.messageId]);
            final time =
                (expireAt[message.messageId] ?? 0) -
                DateTime.now().millisecondsSinceEpoch ~/ 1000;
            showToast(
              'expire in: ${message.expireIn}. '
              'will delete after: ${time < 0 ? 0 : time} seconds',
            );
          },
        );
      }

      _child = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isCurrentUser) icon,
          Flexible(child: _child),
          if (!isCurrentUser) icon,
        ],
      );
    }

    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _child,
          if (outerTimeAndStatusWidget != null)
            Padding(
              padding: const EdgeInsets.only(right: 10, left: 10, top: 4),
              child: outerTimeAndStatusWidget,
            ),
        ],
      ),
    );
  }
}

class MessageBubbleNipPadding extends StatelessWidget {
  const MessageBubbleNipPadding({
    required this.currentUser,
    required this.child,
    super.key,
  });

  final bool currentUser;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      left: currentUser ? 0 : _nipWidth,
      right: currentUser ? _nipWidth : 0,
    ),
    child: child,
  );
}

class BubbleClipper extends CustomClipper<Path> with EquatableMixin {
  BubbleClipper({
    required this.currentUser,
    required this.showNip,
    this.nipPadding = true,
  });

  final bool currentUser;
  final bool showNip;
  final bool nipPadding;

  @override
  Path getClip(Size size) {
    final nipWidth = nipPadding ? _nipWidth : 0.0;

    final bubblePath = _bubblePath(
      Size(size.width - nipWidth, size.height),
    ).shift(Offset(currentUser ? 0 : nipWidth, 0));

    if (!showNip) return bubblePath;

    final nipPath = currentUser ? _rightNipPath(size) : _leftNipPath(size);
    return Path.combine(PathOperation.union, bubblePath, nipPath);
  }

  Path _bubblePath(Size size) => Path()
    ..addRRect(
      const BorderRadius.all(Radius.circular(8)).toRRect(Offset.zero & size),
    );

  Path _leftNipPath(Size bubbleSize) {
    const size = Size(_nipWidth, 12);
    final path = Path()
      ..lineTo(size.width * 1.04, size.height)
      ..cubicTo(
        size.width * 1.04,
        size.height,
        size.width * 1.04,
        0,
        size.width * 1.04,
        0,
      )
      ..cubicTo(
        size.width * 1.04,
        0,
        size.width * 1.04,
        size.height * 0.12,
        size.width,
        size.height * 0.19,
      )
      ..cubicTo(
        size.width * 0.81,
        size.height * 0.41,
        size.width / 2,
        size.height * 0.59,
        size.width * 0.14,
        size.height * 0.67,
      )
      ..cubicTo(
        size.width * 0.03,
        size.height * 0.69,
        size.width * 0.01,
        size.height * 0.79,
        size.width * 0.11,
        size.height * 0.84,
      )
      ..cubicTo(
        size.width * 0.12,
        size.height * 0.84,
        size.width * 0.13,
        size.height * 0.85,
        size.width * 0.13,
        size.height * 0.85,
      )
      ..cubicTo(
        size.width * 0.36,
        size.height * 0.94,
        size.width * 0.62,
        size.height,
        size.width * 0.91,
        size.height,
      )
      ..cubicTo(
        size.width * 0.95,
        size.height,
        size.width * 1.04,
        size.height,
        size.width * 1.04,
        size.height,
      )
      ..cubicTo(
        size.width * 1.04,
        size.height,
        size.width * 1.04,
        size.height,
        size.width * 1.04,
        size.height,
      );

    return path.shift(Offset(-0.38, bubbleSize.height - 9 - 12));
  }

  Path _rightNipPath(Size bubbleSize) {
    const size = Size(_nipWidth, 12);
    final path = Path()
      ..lineTo(0, size.height)
      ..cubicTo(0, size.height, 0, 0, 0, 0)
      ..cubicTo(
        0,
        0,
        0,
        size.height * 0.12,
        size.width * 0.05,
        size.height * 0.19,
      )
      ..cubicTo(
        size.width * 0.24,
        size.height * 0.41,
        size.width * 0.54,
        size.height * 0.59,
        size.width * 0.9,
        size.height * 0.67,
      )
      ..cubicTo(
        size.width * 1.02,
        size.height * 0.69,
        size.width * 1.04,
        size.height * 0.79,
        size.width * 0.94,
        size.height * 0.84,
      )
      ..cubicTo(
        size.width * 0.92,
        size.height * 0.84,
        size.width * 0.91,
        size.height * 0.85,
        size.width * 0.91,
        size.height * 0.85,
      )
      ..cubicTo(
        size.width * 0.68,
        size.height * 0.94,
        size.width * 0.42,
        size.height,
        size.width * 0.13,
        size.height,
      )
      ..cubicTo(
        size.width * 0.09,
        size.height,
        0,
        size.height,
        0,
        size.height,
      )
      ..cubicTo(0, size.height, 0, size.height, 0, size.height);

    return path.shift(
      Offset(bubbleSize.width - 9 - 0.05, bubbleSize.height - 9 - 12),
    );
  }

  @override
  bool shouldReclip(covariant BubbleClipper oldClipper) => this != oldClipper;

  @override
  List<Object?> get props => [currentUser, showNip];
}

class BubblePainter extends CustomPainter with EquatableMixin {
  BubblePainter({
    required this.clipper,
    required Color color,
    this.elevation = 0.6,
    this.shadowColor = Colors.black,
  }) : _fillPaint = Paint()
         ..color = color
         ..style = PaintingStyle.fill;

  final CustomClipper<Path> clipper;
  final double elevation;
  final Color shadowColor;

  final Paint _fillPaint;

  @override
  void paint(Canvas canvas, Size size) {
    final clip = clipper.getClip(size);

    if (elevation != 0.0) {
      canvas.drawShadow(clip, shadowColor, elevation, false);
    }

    canvas.drawPath(clip, _fillPaint);
  }

  @override
  bool shouldRepaint(covariant BubblePainter oldDelegate) =>
      this != oldDelegate;

  @override
  List<Object?> get props => [clipper, elevation, shadowColor, _fillPaint];
}
