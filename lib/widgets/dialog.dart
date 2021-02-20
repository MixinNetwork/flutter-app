import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/utils/list_utils.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_app/widgets/interacter_decorated_box.dart';

Future<T> _showDialog<T>({
  @required BuildContext context,
  bool barrierDismissible = true,
  Color barrierColor,
  bool useRootNavigator = true,
  RouteSettings routeSettings,
  @required RoutePageBuilder pageBuilder,
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

Future<T> showMixinDialog<T>({
  @required BuildContext context,
  RouteSettings routeSettings,
  @required Widget child,
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
    Key key,
    @required this.content,
    this.actions,
    this.minWidth = 400,
    this.minHeight = 210,
  }) : super(key: key);

  final Widget content;
  final List<Widget> actions;
  final double minWidth;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
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
    );
  }
}

Future<T> showContextMenu<T>({
  @required BuildContext context,
  RouteSettings routeSettings,
  @required List<ContextMenu> menus,
  @required Offset pointerPosition,
}) =>
    _showDialog(
      context: context,
      pageBuilder: (BuildContext buildContext, Animation<double> animation,
              Animation<double> secondaryAnimation) =>
          CustomSingleChildLayout(
        delegate: _PositionedLayoutDelegate(
          position: pointerPosition,
        ),
        child: _ContextMenuPage(menus: menus),
      ),
      routeSettings: routeSettings,
    );

class _ContextMenuPage extends StatelessWidget {
  const _ContextMenuPage({
    Key key,
    @required this.menus,
  }) : super(key: key);

  final List<ContextMenu> menus;

  @override
  Widget build(BuildContext context) {
    final brightnessData = BrightnessData.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: Color.lerp(
            Colors.transparent,
            const Color.fromRGBO(255, 255, 255, 0.08),
            brightnessData,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.15),
            offset: Offset(0, lerpDouble(0, 2, brightnessData)),
            blurRadius: lerpDouble(16, 40, brightnessData),
          ),
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.07),
            offset: Offset(0, lerpDouble(4, 0, brightnessData)),
            blurRadius: lerpDouble(6, 12, brightnessData),
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
        child: IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: menus,
          ),
        ),
      ),
    );
  }
}

class _DialogPage extends StatelessWidget {
  const _DialogPage({
    Key key,
    @required this.child,
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
              blurRadius: lerpDouble(16, 6, BrightnessData.of(context)),
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

abstract class DialogInteracterEntry<T> extends StatelessWidget {
  const DialogInteracterEntry({Key key, this.value}) : super(key: key);

  final T value;

  void handleTap(BuildContext context) => Navigator.pop<T>(context, value);
}

class MixinButton<T> extends DialogInteracterEntry<T> {
  const MixinButton({
    Key key,
    T value,
    this.backgroundTransparent = false,
    @required this.child,
    this.onTap,
  }) : super(
          key: key,
          value: value,
        );

  final bool backgroundTransparent;
  final Widget child;
  final VoidCallback onTap;

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
      onTap: () => onTap != null ? onTap() : handleTap(context),
      child: DefaultTextStyle(
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
          color: textColor,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 8,
              horizontal: 16,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class ContextMenu<T> extends DialogInteracterEntry<T> {
  const ContextMenu({
    Key key,
    this.title,
    this.isDestructiveAction = false,
    T value,
  }) : super(
          key: key,
          value: value,
        );

  final String title;
  final bool isDestructiveAction;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = BrightnessData.dynamicColor(
      context,
      const Color.fromRGBO(255, 255, 255, 1),
      darkColor: const Color.fromRGBO(62, 65, 72, 1),
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 160),
      child: InteractableDecoratedBox.color(
        decoration: BoxDecoration(
          color: backgroundColor,
        ),
        tapDowningColor: Color.alphaBlend(
          BrightnessData.themeOf(context).listSelected,
          backgroundColor,
        ),
        onTap: () => handleTap(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: isDestructiveAction
                  ? BrightnessData.themeOf(context).red
                  : BrightnessData.dynamicColor(
                      context,
                      const Color.fromRGBO(0, 0, 0, 1),
                      darkColor: const Color.fromRGBO(255, 255, 255, 0.9),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PositionedLayoutDelegate extends SingleChildLayoutDelegate {
  _PositionedLayoutDelegate({this.position});

  final Offset position;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints.loose(constraints.biggest);

  static const double _pointerPadding = 1;

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    var dx = position.dx + _pointerPadding, dy = position.dy + _pointerPadding;

    if ((size.width - position.dx) < childSize.width)
      dx = position.dx - childSize.width;

    if ((size.height - position.dy) < childSize.height)
      dy = position.dy - childSize.height;

    return Offset(dx, dy);
  }

  @override
  bool shouldRelayout(covariant _PositionedLayoutDelegate oldDelegate) =>
      position != oldDelegate.position;
}
