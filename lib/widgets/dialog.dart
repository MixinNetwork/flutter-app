import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/utils/list_utils.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_app/widgets/interacter_decorated_box.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

Future<T?> _showDialog<T>({
  required BuildContext context,
  bool barrierDismissible = true,
  Color barrierColor = const Color(0x80000000),
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
  required RoutePageBuilder pageBuilder,
}) =>
    showGeneralDialog(
      context: context,
      pageBuilder: (BuildContext buildContext, Animation<double> animation,
              Animation<double> secondaryAnimation) =>
          InheritedTheme.capture(
                  from: context,
                  to: Navigator.of(context, rootNavigator: useRootNavigator)
                      .context)
              .wrap(
        Builder(
          builder: (context) =>
              pageBuilder(context, animation, secondaryAnimation),
        ),
      ),
      barrierDismissible: barrierDismissible,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: barrierColor,
      transitionDuration: const Duration(milliseconds: 80),
      useRootNavigator: useRootNavigator,
      routeSettings: routeSettings,
    );

Future<T?> showMixinDialog<T>({
  required BuildContext context,
  RouteSettings? routeSettings,
  required Widget child,
}) =>
    _showDialog(
      context: context,
      routeSettings: routeSettings,
      pageBuilder: (BuildContext buildContext, Animation<double> animation,
              Animation<double> secondaryAnimation) =>
          Center(
        child: _DialogPage(
          child: child,
        ),
      ),
    );

class AlertDialogLayout extends StatelessWidget {
  const AlertDialogLayout({
    Key? key,
    this.title,
    this.titleMarginBottom = 48,
    required this.content,
    this.actions = const [],
    this.minWidth = 400,
    this.minHeight = 210,
  }) : super(key: key);

  final Widget? title;
  final double titleMarginBottom;
  final Widget content;
  final List<Widget> actions;
  final double minWidth;
  final double minHeight;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: minWidth,
            minHeight: minHeight,
          ),
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: IntrinsicWidth(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (title != null)
                    DefaultTextStyle(
                      style: TextStyle(
                        fontSize: 16,
                        color: BrightnessData.themeOf(context).text,
                      ),
                      child: title!,
                    ),
                  if (title != null) const SizedBox(height: 48),
                  DefaultTextStyle(
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: BrightnessData.themeOf(context).text,
                    ),
                    child: content,
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: actions.joinList(const SizedBox(width: 4)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _DialogPage extends StatelessWidget {
  const _DialogPage({
    Key? key,
    required this.child,
  }) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: const Color.fromRGBO(255, 255, 255, 0.08),
          ),
          boxShadow: [
            const BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.15),
              offset: Offset(0, 8),
              blurRadius: 40,
            ),
            BoxShadow(
              color: const Color.fromRGBO(0, 0, 0, 0.07),
              offset: const Offset(0, 4),
              blurRadius: lerpDouble(16, 6, BrightnessData.of(context))!,
            ),
          ],
          color: BrightnessData.dynamicColor(
            context,
            const Color.fromRGBO(255, 255, 255, 1),
            darkColor: const Color.fromRGBO(62, 65, 72, 1),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: child,
        ),
      );
}

/// default onTap is Navigator.pop
abstract class DialogInteracterEntry<T> extends StatelessWidget {
  const DialogInteracterEntry({
    Key? key,
    this.value,
  }) : super(key: key);

  final T? value;

  void handleTap(BuildContext context) => Navigator.pop<T>(context, value);
}

/// default onTap is Navigator.pop
class MixinButton<T> extends DialogInteracterEntry<T> {
  const MixinButton({
    Key? key,
    T? value,
    this.backgroundTransparent = false,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(
      vertical: 8,
      horizontal: 16,
    ),
  }) : super(
          key: key,
          value: value,
        );

  final bool backgroundTransparent;
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final boxDecoration = backgroundTransparent
        ? const BoxDecoration()
        : BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: BrightnessData.themeOf(context).accent,
          );
    final textColor = backgroundTransparent
        ? BrightnessData.themeOf(context).accent
        : BrightnessData.dynamicColor(
            context,
            const Color.fromRGBO(255, 255, 255, 1),
          );
    return InteractableDecoratedBox.color(
      decoration: boxDecoration,
      onTap: () => onTap != null ? onTap?.call() : handleTap(context),
      child: DefaultTextStyle(
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
          color: textColor,
        ),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

class DialogTextField extends HookWidget {
  const DialogTextField({
    Key? key,
    required this.textEditingController,
    required this.hintText,
  }) : super(key: key);

  final TextEditingController textEditingController;
  final String hintText;

  @override
  Widget build(BuildContext context) => Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(5),
        ),
        alignment: Alignment.center,
        child: TextField(
          controller: textEditingController,
          style: const TextStyle(
            color: Colors.white,
          ),
          scrollPadding: EdgeInsets.zero,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.all(0),
            isDense: true,
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.08)),
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
          ),
        ),
      );
}
