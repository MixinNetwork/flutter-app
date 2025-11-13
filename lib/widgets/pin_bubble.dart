import 'package:flutter/cupertino.dart';

import '../utils/extension/extension.dart';
import 'message/message_bubble.dart';

const _nipWidth = 7.0;

class PinMessageBubble extends StatelessWidget {
  const PinMessageBubble({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    const clipper = _PinBubbleClipper();
    return CustomPaint(
      painter: BubblePainter(
        color: context.messageBubbleColor(false),
        clipper: clipper,
      ),
      child: Padding(
        padding: padding.add(const EdgeInsets.only(right: _nipWidth)),
        child: SizedBox.expand(
          child: DefaultTextStyle.merge(
            style: TextStyle(color: context.theme.text),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _PinBubbleClipper extends CustomClipper<Path> {
  const _PinBubbleClipper();

  @override
  Path getClip(Size size) {
    final bubblePath = _bubblePath(Size(size.width - _nipWidth, size.height));
    final nipPath = _rightNipPath(size);
    return Path.combine(PathOperation.union, bubblePath, nipPath);
  }

  Path _bubblePath(Size size) => Path()
    ..addRRect(
      const BorderRadius.all(Radius.circular(8)).toRRect(Offset.zero & size),
    );

  Path _rightNipPath(Size bubbleSize) {
    const size = Size(_nipWidth, 10);
    final path = Path()
      ..lineTo(0, 0)
      ..cubicTo(
        0,
        0,
        size.width * 0.85,
        size.height / 3,
        size.width * 0.85,
        size.height / 3,
      )
      ..cubicTo(
        size.width * 1.05,
        size.height * 0.41,
        size.width * 1.05,
        size.height * 0.59,
        size.width * 0.85,
        size.height * 0.67,
      )
      ..cubicTo(
        size.width * 0.85,
        size.height * 0.67,
        0,
        size.height,
        0,
        size.height,
      )
      ..cubicTo(0, size.height, 0, 0, 0, 0)
      ..cubicTo(0, 0, 0, 0, 0, 0);
    return path.shift(
      Offset(
        bubbleSize.width - size.width,
        bubbleSize.height / 2 - (size.height / 2),
      ),
    );
  }

  @override
  bool shouldReclip(covariant _PinBubbleClipper oldClipper) =>
      this != oldClipper;
}
