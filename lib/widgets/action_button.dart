import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_app/widgets/interacter_decorated_box.dart';

class ActionButton extends StatelessWidget {
  const ActionButton({
    this.name,
    this.onTap,
    this.padding = const EdgeInsets.all(8),
    this.size = 24,
    this.color,
    this.onEnter,
    this.onExit,
    this.onHover,
  });

  final String name;
  final Function onTap;
  final EdgeInsets padding;
  final double size;
  final Color color;
  final PointerEnterEventListener onEnter;
  final PointerExitEventListener onExit;
  final PointerHoverEventListener onHover;

  @override
  Widget build(BuildContext context) => InteractableDecoratedBox.color(
        onTap: onTap,
        onEnter: onEnter,
        onExit: onExit,
        onHover: onHover,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        hoveringColor: BrightnessData.dynamicColor(
          context,
          const Color.fromRGBO(0, 0, 0, 0.03),
          darkColor: const Color.fromRGBO(255, 255, 255, 0.2),
        ),
        child: Padding(
          padding: padding,
          child: Image.asset(
            name,
            width: size,
            height: size,
            color: color,
          ),
        ),
      );
}
