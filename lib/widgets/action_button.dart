import 'package:flutter/material.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_app/widgets/interacter_decorated_box.dart';

class ActionButton extends StatelessWidget {
  const ActionButton({
    this.name,
    this.onTap,
    this.padding = const EdgeInsets.all(8),
    this.size = 24,
    this.color,
  });

  final String name;
  final Function onTap;
  final EdgeInsets padding;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    const boxDecoration = BoxDecoration(shape: BoxShape.circle);
    return InteractableDecoratedBox(
      onTap: onTap,
      hoveringDecoration: boxDecoration.copyWith(
        color: BrightnessData.dynamicColor(
          context,
          const Color.fromRGBO(0, 0, 0, 0.03),
          darkColor: const Color.fromRGBO(255, 255, 255, 0.2),
        ),
      ),
      decoration: boxDecoration,
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
}
