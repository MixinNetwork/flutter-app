import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/constants/resources.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    Key? key,
    required this.isCurrentUser,
    required this.child,
    this.showNip = true,
    this.showBubble = true,
    this.padding = const EdgeInsets.all(10),
  }) : super(key: key);

  final Widget child;
  final bool isCurrentUser;
  final bool showNip;
  final bool showBubble;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isCurrentUser
        ? BrightnessData.dynamicColor(
      context,
      const Color.fromRGBO(177, 218, 236, 1),
      darkColor: const Color.fromRGBO(59, 79, 103, 1),
    )
        : BrightnessData.dynamicColor(
      context,
      const Color.fromRGBO(255, 255, 255, 1),
      darkColor: const Color.fromRGBO(52, 59, 67, 1),
    );
    final isDark = BrightnessData.of(context) == 1;
    Widget _child = Padding(
      padding: padding,
      child: child,
    );
    if (!showNip) {
      _child = ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 38),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: bubbleColor,
            boxShadow: [
              const BoxShadow(
                offset: Offset(0, 1),
                color: Color.fromRGBO(0, 0, 0, 0.16),
                blurRadius: 2,
              ),
            ],
          ),
          child: _child,
        ),
      );
    }

    _child = Padding(
      padding: EdgeInsets.only(
        left: isCurrentUser ? 0 : 10,
        right: !isCurrentUser ? 0 : 10,
      ),
      child: _child,
    );

    if (showNip) {
      _child = ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 38),
        child: DecoratedBox(
          decoration: BoxDecoration(
            image: showBubble
                ? DecorationImage(
              image: AssetImage(
                isCurrentUser
                    ? isDark
                    ? Resources.assetsImagesDarkSenderNipBubblePng
                    : Resources.assetsImagesLightSenderNipBubblePng
                    : isDark
                    ? Resources.assetsImagesDarkReceiverNipBubblePng
                    : Resources.assetsImagesLightReceiverNipBubblePng,
              ),
              centerSlice: Rect.fromCenter(
                center: const Offset(21, 22),
                width: 1,
                height: 1,
              ),
            )
                : null,
          ),
          child: _child,
        ),
      );
    }

    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 42,
          minHeight: 44,
        ),
        child: _child,
      ),
    );
  }
}
