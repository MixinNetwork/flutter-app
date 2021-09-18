import 'package:flutter/widgets.dart';

class AnimatedVisibility extends StatelessWidget {
  const AnimatedVisibility({
    Key? key,
    required this.child,
    required this.visible,
    this.duration = const Duration(milliseconds: 100),
  }) : super(key: key);

  final Widget child;
  final bool visible;
  final Duration duration;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder(
        tween: Tween<double>(end: visible ? 1 : 0),
        duration: duration,
        builder: (BuildContext context, double value, Widget? child) =>
            IgnorePointer(
          ignoring: value == 0,
          child: Opacity(
            opacity: value,
            child: child,
          ),
        ),
        child: child,
      );
}
