import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_app/widgets/interacter_decorated_box.dart';

class ContextMenuRoute extends PopupRoute {
  ContextMenuRoute({
    this.menus,
    this.capturedThemes,
    this.position,
  }) : assert(menus?.isNotEmpty == true);

  final CapturedThemes capturedThemes;
  final Offset position;
  final List<ContextMenu> menus;

  @override
  Color get barrierColor => null;

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  final String barrierLabel = 'context menu';

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation) =>
      CustomSingleChildLayout(
        delegate: _PositionedLayoutDelegate(
          position: position,
        ),
        child: capturedThemes.wrap(
          _ContextMenuPage(menus: menus),
        ),
      );

  @override
  bool get maintainState => true;

  @override
  bool get barrierDismissible => true;

  static Future<void> show(
    BuildContext context, {
    List<ContextMenu> menus,
    Offset pointerPosition,
  }) {
    final navigator = Navigator.of(context, rootNavigator: true);
    return navigator.push(ContextMenuRoute(
      position: pointerPosition,
      capturedThemes:
          InheritedTheme.capture(from: context, to: navigator.context),
      menus: menus,
    ));
  }
}

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

class ContextMenu extends StatelessWidget {
  const ContextMenu({
    Key key,
    this.title,
    this.onTap,
    this.isDestructiveAction = false,
  }) : super(key: key);

  final String title;
  final VoidCallback onTap;
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
          BrightnessData.dynamicColor(
            context,
            const Color.fromRGBO(246, 247, 250, 1),
            darkColor: const Color.fromRGBO(255, 255, 255, 0.06),
          ),
          backgroundColor,
        ),
        onTap: () {
          onTap?.call();
          Navigator.of(context, rootNavigator: true).pop();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: isDestructiveAction
                  ? BrightnessData.dynamicColor(
                      context,
                      const Color.fromRGBO(246, 112, 112, 1),
                      darkColor: const Color.fromRGBO(246, 112, 112, 1),
                    )
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
