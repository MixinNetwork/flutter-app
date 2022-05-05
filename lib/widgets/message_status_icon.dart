import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import '../constants/resources.dart';
import '../utils/extension/extension.dart';

class MessageStatusIcon extends StatelessWidget {
  const MessageStatusIcon({
    Key? key,
    required this.status,
    this.color,
  }) : super(key: key);

  final MessageStatus? status;

  final Color? color;

  @override
  Widget build(BuildContext context) {
    var color = this.color ?? context.theme.secondaryText;
    String icon;
    switch (status) {
      case MessageStatus.sent:
        icon = Resources.assetsImagesSentSvg;
        break;
      case MessageStatus.delivered:
        icon = Resources.assetsImagesDeliveredSvg;
        break;
      case MessageStatus.read:
        icon = Resources.assetsImagesReadSvg;
        color = context.theme.accent;
        break;
      case MessageStatus.sending:
      case MessageStatus.failed:
      case MessageStatus.unknown:
      case null:
        return _AnimatedMessageSendingIcon(color: color);
    }
    return SvgPicture.asset(
      icon,
      color: color,
    );
  }
}

class _AnimatedMessageSendingIcon extends HookWidget {
  const _AnimatedMessageSendingIcon({
    Key? key,
    required this.color,
  }) : super(key: key);

  final Color color;

  @override
  Widget build(BuildContext context) {
    final tickerProvider = useSingleTickerProvider();

    final time = useState(0);

    useEffect(() {
      final ticker = tickerProvider.createTicker((elapsed) {
        time.value = elapsed.inMilliseconds;
      })
        ..start();
      return ticker.dispose;
    }, [tickerProvider]);

    // small is slow, big is fast
    const scale = 1 / 10;
    final hour = (time.value * scale) / 20 % 12;
    final minute = (time.value * scale) % 60;
    return CustomPaint(
      painter: _MessageSendingIconPainter(
        color: color,
        hour: hour,
        minute: minute,
      ),
      child: const SizedBox.square(dimension: 14),
    );
  }
}

class _MessageSendingIconPainter extends CustomPainter {
  _MessageSendingIconPainter({
    required this.color,
    required this.hour,
    required this.minute,
  });

  final Color color;

  final double hour;

  final double minute;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1;

    final center = Offset(size.width / 2, size.height / 2);

    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: 11, height: 9),
      const Radius.circular(2.15),
    );
    canvas.drawRRect(rect, paint);

    // draw hour hand
    const hourHandLength = 3;
    final hourAngle = 2 * math.pi * (1 - hour / 12);
    final hourHand = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(
        center.dx + math.sin(hourAngle) * hourHandLength,
        center.dy + math.cos(hourAngle) * hourHandLength,
      );
    canvas.drawPath(hourHand, paint);

    // draw minute hand
    const minuteHandLength = 4;
    final minuteAngle = 2 * math.pi * (1 - minute / 60);
    final minuteHand = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(
        center.dx + math.sin(minuteAngle) * minuteHandLength,
        center.dy + math.cos(minuteAngle) * minuteHandLength,
      );
    canvas.drawPath(minuteHand, paint);
  }

  @override
  bool shouldRepaint(covariant _MessageSendingIconPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.hour != hour ||
      oldDelegate.minute != minute;
}
