import 'package:flutter/widgets.dart';

class AnimatedVisibility extends StatelessWidget {
  const AnimatedVisibility({
    required this.child,
    required this.visible,
    super.key,
    this.maintainSize = true,
    this.alignment = Alignment.center,
    this.duration = const Duration(milliseconds: 200),
  });

  final Widget child;
  final Duration duration;
  final bool visible;
  final bool maintainSize;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder(
        tween: Tween<double>(end: visible ? 1 : 0),
        duration: duration,
        builder: (BuildContext context, double value, Widget? child) {
          Widget result = IgnorePointer(
            ignoring: value == 0,
            child: Opacity(
              opacity: value,
              child: child,
            ),
          );
          if (!maintainSize) {
            result = ClipRect(
              child: Align(
                alignment: alignment,
                heightFactor: value,
                child: result,
              ),
            );
          }
          return result;
        },
        child: child,
      );
}
