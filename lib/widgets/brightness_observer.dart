import 'dart:ui';

import 'package:flutter/widgets.dart';

class BrightnessObserver extends StatelessWidget {
  const BrightnessObserver({
    Key key,
    this.duration = const Duration(milliseconds: 200),
    this.curve = Curves.linear,
    this.onEnd,
    @required this.child,
    this.forceBrightness,
  }) : super(key: key);

  final Duration duration;
  final Curve curve;
  final VoidCallback onEnd;
  final Widget child;
  final Brightness forceBrightness;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        duration: duration,
        curve: curve,
        onEnd: onEnd,
        tween: Tween<double>(
            end: {
          Brightness.light: 0.0,
          Brightness.dark: 1.0,
        }[forceBrightness ?? MediaQuery.platformBrightnessOf(context)]),
        child: child,
        builder: (BuildContext context, double value, Widget child) =>
            BrightnessData(
          value: value,
          child: child,
        ),
      );
}

class BrightnessData extends InheritedWidget {
  const BrightnessData({
    this.value,
    Widget child,
    Key key,
  }) : super(key: key, child: child);

  final double value;

  @override
  bool updateShouldNotify(covariant BrightnessData oldWidget) =>
      value != oldWidget.value;

  static double of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<BrightnessData>()?.value;

  static Color dynamicColor(
    BuildContext context,
    Color color, {
    Color darkColor,
  }) {
    if (darkColor == null) return color;
    return Color.lerp(color, darkColor, of(context));
  }
}
