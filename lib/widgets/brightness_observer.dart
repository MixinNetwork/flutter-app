import 'dart:ui';

import 'package:flutter/widgets.dart';

class BrightnessObserver extends StatelessWidget {
  const BrightnessObserver({
    Key? key,
    this.duration = const Duration(milliseconds: 200),
    this.curve = Curves.linear,
    this.onEnd,
    required this.child,
    this.forceBrightness,
    required this.lightThemeData,
    required this.darkThemeData,
  }) : super(key: key);

  final Duration duration;
  final Curve curve;
  final VoidCallback? onEnd;
  final Widget child;
  final Brightness? forceBrightness;
  final BrightnessThemeData lightThemeData;
  final BrightnessThemeData darkThemeData;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        duration: duration,
        curve: curve,
        onEnd: onEnd,
        tween: Tween<double>(
          end: {
            Brightness.light: 0.0,
            Brightness.dark: 1.0,
          }[forceBrightness ?? MediaQuery.platformBrightnessOf(context)],
        ),
        child: child,
        builder: (BuildContext context, double value, Widget? child) =>
            BrightnessData(
          value: value,
          brightnessThemeData:
              BrightnessThemeData.lerp(lightThemeData, darkThemeData, value),
          child: child!,
        ),
      );
}

class BrightnessData extends InheritedWidget {
  const BrightnessData({
    required this.value,
    required Widget child,
    Key? key,
    required this.brightnessThemeData,
  }) : super(key: key, child: child);

  final double value;
  final BrightnessThemeData brightnessThemeData;

  @override
  bool updateShouldNotify(covariant BrightnessData oldWidget) =>
      value != oldWidget.value;

  static double of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<BrightnessData>()!.value;

  static BrightnessThemeData themeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<BrightnessData>()!
      .brightnessThemeData;

  static Color dynamicColor(
    BuildContext context,
    Color color, {
    Color? darkColor,
  }) {
    if (darkColor == null) return color;
    return Color.lerp(color, darkColor, of(context))!;
  }
}

class BrightnessThemeData {
  const BrightnessThemeData({
    required this.primary,
    required this.accent,
    required this.text,
    required this.icon,
    required this.secondaryText,
    required this.sidebarSelected,
    required this.listSelected,
    required this.chatBackground,
    required this.background,
    required this.red,
    required this.green,
    required this.warning,
    required this.highlight,
    required this.dateTime,
    required this.encrypt,
    required this.popUp,
    required this.statusBackground,
  });

  final Color primary;
  final Color accent;
  final Color text;
  final Color icon;
  final Color secondaryText;
  final Color sidebarSelected;
  final Color listSelected;
  final Color chatBackground;
  final Color background;
  final Color red;
  final Color green;
  final Color warning;
  final Color highlight;
  final Color dateTime;
  final Color encrypt;
  final Color popUp;
  final Color statusBackground;

  static BrightnessThemeData lerp(
          BrightnessThemeData begin, BrightnessThemeData end, double t) =>
      BrightnessThemeData(
        primary: Color.lerp(begin.primary, end.primary, t)!,
        accent: Color.lerp(begin.accent, end.accent, t)!,
        text: Color.lerp(begin.text, end.text, t)!,
        icon: Color.lerp(begin.icon, end.icon, t)!,
        secondaryText: Color.lerp(begin.secondaryText, end.secondaryText, t)!,
        sidebarSelected:
            Color.lerp(begin.sidebarSelected, end.sidebarSelected, t)!,
        listSelected: Color.lerp(begin.listSelected, end.listSelected, t)!,
        chatBackground:
            Color.lerp(begin.chatBackground, end.chatBackground, t)!,
        background: Color.lerp(begin.background, end.background, t)!,
        red: Color.lerp(begin.red, end.red, t)!,
        green: Color.lerp(begin.green, end.green, t)!,
        warning: Color.lerp(begin.warning, end.warning, t)!,
        highlight: Color.lerp(begin.highlight, end.highlight, t)!,
        dateTime: Color.lerp(begin.dateTime, end.dateTime, t)!,
        encrypt: Color.lerp(begin.encrypt, end.encrypt, t)!,
        popUp: Color.lerp(begin.popUp, end.popUp, t)!,
        statusBackground:
            Color.lerp(begin.statusBackground, end.statusBackground, t)!,
      );
}
