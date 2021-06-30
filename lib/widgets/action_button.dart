import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';

import 'brightness_observer.dart';
import 'interacter_decorated_box.dart';

class ActionButton extends StatelessWidget {
  const ActionButton({
    this.name,
    this.child,
    this.onTap,
    this.onTapUp,
    this.padding = const EdgeInsets.all(8),
    this.size = 24,
    this.color,
    this.onEnter,
    this.onExit,
    this.onHover,
    Key? key,
  })  : assert(name != null || child != null),
        super(key: key);

  final String? name;
  final Widget? child;
  final VoidCallback? onTap;
  final GestureTapUpCallback? onTapUp;
  final EdgeInsets padding;
  final double size;
  final Color? color;
  final PointerEnterEventListener? onEnter;
  final PointerExitEventListener? onExit;
  final PointerHoverEventListener? onHover;

  @override
  Widget build(BuildContext context) {
    var _child = child;
    if (name?.isNotEmpty ?? false) {
      _child = SvgPicture.asset(
        name!,
        width: size,
        height: size,
        color: color,
      );
    }
    return InteractableDecoratedBox.color(
      onTap: onTap,
      onTapUp: onTapUp,
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
        child: _child,
      ),
    );
  }
}
