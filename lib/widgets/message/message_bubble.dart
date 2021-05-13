import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../brightness_observer.dart';
import 'item/quote_message.dart';

const _nipWidth = 9.0;
const _lightCurrentBubble = Color.fromRGBO(197, 237, 253, 1);
const _darkCurrentBubble = Color.fromRGBO(59, 79, 103, 1);
const _lightOtherBubble = Color.fromRGBO(255, 255, 255, 1);
const _darkOtherBubble = Color.fromRGBO(52, 59, 67, 1);

extension BubbleColor on BuildContext {
  Color messageBubbleColor(bool isCurrentUser) => isCurrentUser
      ? BrightnessData.dynamicColor(this, _lightCurrentBubble,
          darkColor: _darkCurrentBubble)
      : BrightnessData.dynamicColor(this, _lightOtherBubble,
          darkColor: _darkOtherBubble);
}

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    Key? key,
    required this.isCurrentUser,
    required this.child,
    this.showNip = true,
    this.showBubble = true,
    this.includeNip = false,
    this.padding = const EdgeInsets.all(8),
    this.outerTimeAndStatusWidget,
    this.quoteMessageId,
    this.quoteMessageContent,
  }) : super(key: key);

  final Widget child;
  final bool isCurrentUser;
  final bool showNip;
  final bool showBubble;
  final bool includeNip;
  final EdgeInsetsGeometry padding;
  final Widget? outerTimeAndStatusWidget;
  final String? quoteMessageContent;
  final String? quoteMessageId;

  @override
  Widget build(BuildContext context) {
    final bubbleColor = context.messageBubbleColor(isCurrentUser);

    var _child = child;

    if (!includeNip)
      _child = _MessageBubbleNipPadding(
        currentUser: isCurrentUser,
        child: child,
      );

    _child = Padding(
      padding: padding,
      child: _child,
    );

    if (quoteMessageId != null && quoteMessageContent?.isNotEmpty == true)
      _child = IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _MessageBubbleNipPadding(
              currentUser: isCurrentUser,
              child: QuoteMessage(
                id: quoteMessageId,
                content: quoteMessageContent,
              ),
            ),
            _child,
          ],
        ),
      );

    final clipper = _BubbleClipper(
      currentUser: isCurrentUser,
      showNip: showNip,
    );

    _child = ClipPath(
      clipper: clipper,
      child: _child,
    );

    if (showBubble)
      _child = CustomPaint(
        painter: _BubblePainter(
          color: showBubble ? bubbleColor : Colors.transparent,
          clipper: clipper,
        ),
        child: _child,
      );

    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 42,
              minHeight: 38,
            ),
            child: _child,
          ),
          if (outerTimeAndStatusWidget != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: outerTimeAndStatusWidget,
            ),
        ],
      ),
    );
  }
}

class _MessageBubbleNipPadding extends StatelessWidget {
  const _MessageBubbleNipPadding({
    Key? key,
    required this.currentUser,
    required this.child,
  }) : super(key: key);

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

class _BubbleClipper extends CustomClipper<Path> with EquatableMixin {
  _BubbleClipper({
    required this.currentUser,
    required this.showNip,
  });

  final bool currentUser;
  final bool showNip;

  @override
  Path getClip(Size size) {
    final bubblePath = _bubblePath(Size(size.width - _nipWidth, size.height))
        .shift(Offset(currentUser ? 0 : _nipWidth, 0));

    if (!showNip) return bubblePath;

    final nipPath = currentUser ? _rightNipPath(size) : _leftNipPath(size);
    return Path.combine(PathOperation.union, bubblePath, nipPath);
  }

  Path _bubblePath(Size size) =>
      Path()..addRRect(BorderRadius.circular(8).toRRect(Offset.zero & size));

  Path _leftNipPath(Size bubbleSize) {
    const size = Size(_nipWidth, 12);
    final path = Path()
      ..lineTo(size.width * 1.04, size.height)
      ..cubicTo(size.width * 1.04, size.height, size.width * 1.04, 0,
          size.width * 1.04, 0)
      ..cubicTo(size.width * 1.04, 0, size.width * 1.04, size.height * 0.12,
          size.width, size.height * 0.19)
      ..cubicTo(size.width * 0.81, size.height * 0.41, size.width / 2,
          size.height * 0.59, size.width * 0.14, size.height * 0.67)
      ..cubicTo(size.width * 0.03, size.height * 0.69, size.width * 0.01,
          size.height * 0.79, size.width * 0.11, size.height * 0.84)
      ..cubicTo(size.width * 0.12, size.height * 0.84, size.width * 0.13,
          size.height * 0.85, size.width * 0.13, size.height * 0.85)
      ..cubicTo(size.width * 0.36, size.height * 0.94, size.width * 0.62,
          size.height, size.width * 0.91, size.height)
      ..cubicTo(size.width * 0.95, size.height, size.width * 1.04, size.height,
          size.width * 1.04, size.height)
      ..cubicTo(size.width * 1.04, size.height, size.width * 1.04, size.height,
          size.width * 1.04, size.height);

    return path.shift(Offset(-0.38, bubbleSize.height - 9 - 12));
  }

  Path _rightNipPath(Size bubbleSize) {
    const size = Size(_nipWidth, 12);
    final path = Path()
      ..lineTo(0, size.height)
      ..cubicTo(0, size.height, 0, 0, 0, 0)
      ..cubicTo(
          0, 0, 0, size.height * 0.12, size.width * 0.05, size.height * 0.19)
      ..cubicTo(size.width * 0.24, size.height * 0.41, size.width * 0.54,
          size.height * 0.59, size.width * 0.9, size.height * 0.67)
      ..cubicTo(size.width * 1.02, size.height * 0.69, size.width * 1.04,
          size.height * 0.79, size.width * 0.94, size.height * 0.84)
      ..cubicTo(size.width * 0.92, size.height * 0.84, size.width * 0.91,
          size.height * 0.85, size.width * 0.91, size.height * 0.85)
      ..cubicTo(size.width * 0.68, size.height * 0.94, size.width * 0.42,
          size.height, size.width * 0.13, size.height)
      ..cubicTo(size.width * 0.09, size.height, 0, size.height, 0, size.height)
      ..cubicTo(0, size.height, 0, size.height, 0, size.height);

    return path
        .shift(Offset(bubbleSize.width - 9 - 0.05, bubbleSize.height - 9 - 12));
  }

  @override
  bool shouldReclip(covariant _BubbleClipper oldClipper) => this != oldClipper;

  @override
  List<Object?> get props => [currentUser, showNip];
}

class _BubblePainter extends CustomPainter with EquatableMixin {
  _BubblePainter({
    required this.clipper,
    required Color color,
    this.elevation = 1.0,
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

    if (elevation != 0.0)
      canvas.drawShadow(clip, shadowColor, elevation, false);

    canvas.drawPath(clip, _fillPaint);
  }

  @override
  bool shouldRepaint(covariant _BubblePainter oldDelegate) =>
      this != oldDelegate;

  @override
  List<Object?> get props => [
        clipper,
        elevation,
        shadowColor,
        _fillPaint,
      ];
}
