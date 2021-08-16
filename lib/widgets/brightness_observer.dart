import 'dart:ui';

import 'package:flutter/widgets.dart';

class BrightnessObserver extends StatelessWidget {
  const BrightnessObserver({
    Key? key,
    this.duration = const Duration(milliseconds: 200),
    this.curve = Curves.linear,
    this.onEnd,
    required this.child,
    required this.lightThemeData,
    required this.darkThemeData,
    this.forceBrightness,
  }) : super(key: key);

  final Duration duration;
  final Curve curve;
  final VoidCallback? onEnd;
  final Widget child;
  final BrightnessThemeData lightThemeData;
  final BrightnessThemeData darkThemeData;
  final Brightness? forceBrightness;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        duration: duration,
        curve: curve,
        onEnd: onEnd,
        tween: Tween<double>(
          end: const {
            Brightness.light: 0.0,
            Brightness.dark: 1.0,
          }[forceBrightness ?? MediaQuery.platformBrightnessOf(context)],
        ),
        builder: (BuildContext context, double value, Widget? child) =>
            BrightnessData(
          value: value,
          brightnessThemeData:
              BrightnessThemeData.lerp(lightThemeData, darkThemeData, value),
          child: child!,
        ),
        child: child,
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
      value != oldWidget.value ||
      brightnessThemeData != oldWidget.brightnessThemeData;

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

@immutable
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
    required this.divider,
    required this.red,
    required this.green,
    required this.warning,
    required this.highlight,
    required this.dateTime,
    required this.encrypt,
    required this.popUp,
    required this.statusBackground,
    required this.stickerPlaceholderColor,
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
  final Color divider;
  final Color red;
  final Color green;
  final Color warning;
  final Color highlight;
  final Color dateTime;
  final Color encrypt;
  final Color popUp;
  final Color statusBackground;
  final Color stickerPlaceholderColor;

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
        divider: Color.lerp(begin.divider, end.divider, t)!,
        red: Color.lerp(begin.red, end.red, t)!,
        green: Color.lerp(begin.green, end.green, t)!,
        warning: Color.lerp(begin.warning, end.warning, t)!,
        highlight: Color.lerp(begin.highlight, end.highlight, t)!,
        dateTime: Color.lerp(begin.dateTime, end.dateTime, t)!,
        encrypt: Color.lerp(begin.encrypt, end.encrypt, t)!,
        popUp: Color.lerp(begin.popUp, end.popUp, t)!,
        statusBackground:
            Color.lerp(begin.statusBackground, end.statusBackground, t)!,
        stickerPlaceholderColor: Color.lerp(
            begin.stickerPlaceholderColor, end.stickerPlaceholderColor, t)!,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BrightnessThemeData &&
          runtimeType == other.runtimeType &&
          primary == other.primary &&
          accent == other.accent &&
          text == other.text &&
          icon == other.icon &&
          secondaryText == other.secondaryText &&
          sidebarSelected == other.sidebarSelected &&
          listSelected == other.listSelected &&
          chatBackground == other.chatBackground &&
          background == other.background &&
          red == other.red &&
          green == other.green &&
          warning == other.warning &&
          highlight == other.highlight &&
          dateTime == other.dateTime &&
          encrypt == other.encrypt &&
          popUp == other.popUp &&
          statusBackground == other.statusBackground;

  @override
  int get hashCode =>
      primary.hashCode ^
      accent.hashCode ^
      text.hashCode ^
      icon.hashCode ^
      secondaryText.hashCode ^
      sidebarSelected.hashCode ^
      listSelected.hashCode ^
      chatBackground.hashCode ^
      background.hashCode ^
      red.hashCode ^
      green.hashCode ^
      warning.hashCode ^
      highlight.hashCode ^
      dateTime.hashCode ^
      encrypt.hashCode ^
      popUp.hashCode ^
      statusBackground.hashCode;
}
