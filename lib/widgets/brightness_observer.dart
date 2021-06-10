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

  BrightnessThemeData copyWith({
    Color? primary,
    Color? accent,
    Color? text,
    Color? icon,
    Color? secondaryText,
    Color? sidebarSelected,
    Color? listSelected,
    Color? chatBackground,
    Color? background,
    Color? red,
    Color? green,
    Color? warning,
    Color? highlight,
    Color? dateTime,
    Color? encrypt,
    Color? popUp,
    Color? statusBackground,
  }) {
    if ((primary == null || identical(primary, this.primary)) &&
        (accent == null || identical(accent, this.accent)) &&
        (text == null || identical(text, this.text)) &&
        (icon == null || identical(icon, this.icon)) &&
        (secondaryText == null ||
            identical(secondaryText, this.secondaryText)) &&
        (sidebarSelected == null ||
            identical(sidebarSelected, this.sidebarSelected)) &&
        (listSelected == null || identical(listSelected, this.listSelected)) &&
        (chatBackground == null ||
            identical(chatBackground, this.chatBackground)) &&
        (background == null || identical(background, this.background)) &&
        (red == null || identical(red, this.red)) &&
        (green == null || identical(green, this.green)) &&
        (warning == null || identical(warning, this.warning)) &&
        (highlight == null || identical(highlight, this.highlight)) &&
        (dateTime == null || identical(dateTime, this.dateTime)) &&
        (encrypt == null || identical(encrypt, this.encrypt)) &&
        (popUp == null || identical(popUp, this.popUp)) &&
        (statusBackground == null ||
            identical(statusBackground, this.statusBackground))) {
      return this;
    }
    return BrightnessThemeData(
      primary: primary ?? this.primary,
      accent: accent ?? this.accent,
      text: text ?? this.text,
      icon: icon ?? this.icon,
      secondaryText: secondaryText ?? this.secondaryText,
      sidebarSelected: sidebarSelected ?? this.sidebarSelected,
      listSelected: listSelected ?? this.listSelected,
      chatBackground: chatBackground ?? this.chatBackground,
      background: background ?? this.background,
      red: red ?? this.red,
      green: green ?? this.green,
      warning: warning ?? this.warning,
      highlight: highlight ?? this.highlight,
      dateTime: dateTime ?? this.dateTime,
      encrypt: encrypt ?? this.encrypt,
      popUp: popUp ?? this.popUp,
      statusBackground: statusBackground ?? this.statusBackground,
    );
  }

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
