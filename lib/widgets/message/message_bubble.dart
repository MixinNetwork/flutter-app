import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:provider/provider.dart' as provider;

import '../../constants/resources.dart';
import '../../ui/home/chat/message_jump.dart';
import '../../ui/home/notifier/blink_notifier.dart';
import '../../utils/extension/extension.dart';
import '../action_button.dart';
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
    final highlightEnabled = useMessageHighlightEnabled();
    final menuHighlighted = useMessageMenuHighlighted();

    final quoteId = useMessageConverter(converter: (state) => state.quoteId);

    final hasQuoteMessage = quoteId?.isNotEmpty ?? false;

    final isTranscriptPage = useIsTranscriptPage();

    final bubbleColor = context.messageBubbleColor(
      forceIsCurrentUserColor ?? isCurrentUser,
    );

    final messageType = useMessageConverter(converter: (state) => state.type);
    final highlightMedia =
        !showBubble &&
        !hasQuoteMessage &&
        (messageType.isImage ||
            messageType.isVideo ||
            messageType.isLive ||
            messageType.isSticker);

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

    final hasHighlightSurface = hasQuoteMessage || showBubble || highlightMedia;
    if (hasHighlightSurface && (highlightEnabled || menuHighlighted)) {
      _child = MessageBubbleHighlight(
        messageId: context.message.messageId,
        enabled: highlightEnabled,
        clipper: clipper,
        currentUser: isCurrentUser,
        media: highlightMedia,
        menuHighlighted: menuHighlighted,
        child: _child,
      );
    }

    if (isPinnedPage) {
      final pinArrow = ActionButton(
        size: 16,
        name: Resources.assetsImagesPinArrowSvg,
        onTap: () {
          final message = context.message;
          unawaited(
            context.jumpToMessageInChat(
              message.messageId,
              closeSideAfterJump: true,
            ),
          );
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

class MessageBubbleHighlight extends StatefulWidget {
  const MessageBubbleHighlight({
    required this.messageId,
    required this.enabled,
    required this.clipper,
    required this.currentUser,
    required this.media,
    required this.menuHighlighted,
    required this.child,
    super.key,
  });

  final String messageId;
  final bool enabled;
  final CustomClipper<Path> clipper;
  final bool currentUser;
  final bool media;
  final bool menuHighlighted;
  final Widget child;

  @override
  State<MessageBubbleHighlight> createState() => _MessageBubbleHighlightState();
}

class _MessageBubbleHighlightState extends State<MessageBubbleHighlight> {
  BlinkNotifier? _notifier;
  BlinkState _blinkState = const BlinkState();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final notifier = provider.Provider.of<BlinkNotifier?>(
      context,
      listen: false,
    );
    if (identical(_notifier, notifier)) return;
    _notifier?.removeListener(_onBlinkChanged);
    notifier?.addListener(_onBlinkChanged);
    _notifier = notifier;
    _blinkState = notifier?.value ?? const BlinkState();
  }

  void _onBlinkChanged() {
    final next = _notifier!.value;
    final shouldRebuild =
        widget.enabled &&
        (_blinkState.messageId == widget.messageId ||
            next.messageId == widget.messageId);
    _blinkState = next;
    if (shouldRebuild && mounted) setState(() {});
  }

  @override
  void dispose() {
    _notifier?.removeListener(_onBlinkChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final opacity = widget.menuHighlighted
        ? 1.0
        : widget.enabled && _blinkState.messageId == widget.messageId
        ? _blinkState.opacity
        : 0.0;
    return CustomPaint(
      foregroundPainter: opacity <= 0
          ? null
          : _MessageBubbleHighlightPainter(
              clipper: widget.clipper,
              color: _highlightColor(
                context,
                currentUser: widget.currentUser,
                media: widget.media,
              ),
              maxOpacity: _highlightOpacity(
                context,
                currentUser: widget.currentUser,
                media: widget.media,
              ),
              opacity: opacity,
            ),
      child: widget.child,
    );
  }
}

Color _highlightColor(
  BuildContext context, {
  required bool currentUser,
  required bool media,
}) {
  if (media || currentUser) return Colors.black;
  return Color.lerp(Colors.black, Colors.white, context.brightnessValue)!;
}

double _highlightOpacity(
  BuildContext context, {
  required bool currentUser,
  required bool media,
}) {
  if (media) return 0.2;
  final light = currentUser ? 0.16 : 0.13;
  final dark = currentUser ? 0.18 : 0.12;
  return light + (dark - light) * context.brightnessValue;
}

@visibleForTesting
double messageHighlightOpacityForTesting(
  BuildContext context, {
  required bool currentUser,
  required bool media,
}) => _highlightOpacity(context, currentUser: currentUser, media: media);

class _MessageBubbleHighlightPainter extends CustomPainter with Equatable {
  _MessageBubbleHighlightPainter({
    required this.clipper,
    required this.color,
    required this.maxOpacity,
    required this.opacity,
  });

  final CustomClipper<Path> clipper;
  final Color color;
  final double maxOpacity;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final clip = clipper.getClip(size);
    canvas.drawPath(
      clip,
      Paint()
        ..color = color.withValues(alpha: maxOpacity * opacity)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _MessageBubbleHighlightPainter oldDelegate) =>
      this != oldDelegate;

  @override
  List<Object?> get props => [clipper, color, maxOpacity, opacity];
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

/// A bubble shape: a rounded rectangle and a nip.
abstract class BubbleShapeClipper extends CustomClipper<Path> {
  const BubbleShapeClipper();

  /// The edges of a bubble of [size] that keep their shape when the bubble
  /// grows: the corners and the nip. The rest is straight.
  EdgeInsets fixedInsets(Size size);
}

class BubbleClipper extends BubbleShapeClipper with Equatable {
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
    final bubblePath = Path()..addRRect(bodyRRect(size));
    if (!showNip) return bubblePath;

    final nipPath = currentUser ? _rightNipPath(size) : _leftNipPath(size);
    return Path.combine(PathOperation.union, bubblePath, nipPath);
  }

  @override
  EdgeInsets fixedInsets(Size size) {
    final nipWidth = nipPadding ? _nipWidth : 0.0;
    // The nip spans the 21 points above the bottom at its side.
    return EdgeInsets.fromLTRB(
      currentUser ? 8 : nipWidth + 8,
      8,
      currentUser ? nipWidth + 8 : 8,
      21,
    );
  }

  /// The rounded rectangle of the bubble without its nip.
  RRect bodyRRect(Size size) {
    final nipWidth = nipPadding ? _nipWidth : 0.0;
    return const BorderRadius.all(Radius.circular(8)).toRRect(
      Offset(currentUser ? 0 : nipWidth, 0) &
          Size(size.width - nipWidth, size.height),
    );
  }

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
  List<Object?> get props => [currentUser, showNip, nipPadding];
}

// Impeller draws the shadow of a path that is not a rounded rectangle
// through an offscreen blur, in every frame for every bubble. So the shadow of
// each bubble shape is drawn once, and stretched along the straight edges
// between the corners and the nip, as the iOS and Android apps stretch their
// bubble images.
final _shadowImages = <Object, (ui.Image, Paint)>{};
const _shadowMargin = 4.0;

void _paintShadow(
  Canvas canvas,
  Size size,
  BubbleShapeClipper clipper,
  Color color,
  double elevation,
) {
  final dpr = ui.PlatformDispatcher.instance.views.first.devicePixelRatio;
  final fixed = clipper.fixedInsets(size);
  final template = Size(fixed.horizontal + 1, fixed.vertical + 1);
  final (
    image,
    paint,
  ) = _shadowImages[(clipper, template, color, elevation, dpr)] ??= () {
    final recorder = ui.PictureRecorder();
    Canvas(recorder)
      ..scale(dpr)
      ..translate(_shadowMargin, _shadowMargin)
      ..drawShadow(clipper.getClip(template), color, elevation, false);
    final picture = recorder.endRecording();
    final image = picture.toImageSync(
      ((template.width + _shadowMargin * 2) * dpr).ceil(),
      ((template.height + _shadowMargin * 2) * dpr).ceil(),
    );
    picture.dispose();
    return (
      image,
      Paint()
        ..shader = ImageShader(
          image,
          TileMode.clamp,
          TileMode.clamp,
          Matrix4.identity().storage,
        ),
    );
  }();
  final destination = (Offset.zero & size).inflate(_shadowMargin);
  // One mesh of nine quads, in device pixels so that the corners draw one
  // to one. Impeller draws a nine patch image as nine separate images.
  List<double> stops(double start, double end, double first, double last) {
    final scale = math.min(1, (end - start) / (first + last));
    return [start, start + first * scale, end - last * scale, end];
  }

  final left = (fixed.left + _shadowMargin) * dpr;
  final top = (fixed.top + _shadowMargin) * dpr;
  final right = image.width - left - dpr;
  final bottom = image.height - top - dpr;
  final xs = stops(
    destination.left * dpr,
    destination.right * dpr,
    left,
    right,
  );
  final ys = stops(
    destination.top * dpr,
    destination.bottom * dpr,
    top,
    bottom,
  );
  final us = [0.0, left, image.width - right, image.width.toDouble()];
  final vs = [0.0, top, image.height - bottom, image.height.toDouble()];
  final positions = <Offset>[
    for (final y in ys)
      for (final x in xs) Offset(x, y),
  ];
  final textures = <Offset>[
    for (final v in vs)
      for (final u in us) Offset(u, v),
  ];
  final indices = <int>[
    for (var row = 0; row < 3; row++)
      for (var column = 0; column < 3; column++) ...[
        row * 4 + column,
        row * 4 + column + 1,
        row * 4 + column + 4,
        row * 4 + column + 1,
        row * 4 + column + 5,
        row * 4 + column + 4,
      ],
  ];
  canvas
    ..save()
    ..scale(1 / dpr)
    ..drawVertices(
      ui.Vertices(
        ui.VertexMode.triangles,
        positions,
        textureCoordinates: textures,
        indices: indices,
      ),
      BlendMode.srcOver,
      paint,
    )
    ..restore();
}

class BubblePainter extends CustomPainter with Equatable {
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
      final clipper = this.clipper;
      if (clipper is BubbleShapeClipper) {
        _paintShadow(canvas, size, clipper, shadowColor, elevation);
      } else {
        canvas.drawShadow(clip, shadowColor, elevation, false);
      }
    }

    canvas.drawPath(clip, _fillPaint);
  }

  @override
  bool shouldRepaint(covariant BubblePainter oldDelegate) =>
      this != oldDelegate;

  @override
  List<Object?> get props => [clipper, elevation, shadowColor, _fillPaint];
}
