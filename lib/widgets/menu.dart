import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_portal/flutter_portal.dart';

import '../bloc/simple_cubit.dart';
import '../utils/extension/extension.dart';
import 'brightness_observer.dart';

import 'interacter_decorated_box.dart';

class ContextMenuPortalEntry extends StatelessWidget {
  const ContextMenuPortalEntry({
    Key? key,
    required this.child,
    required this.buildMenus,
  }) : super(key: key);

  final Widget child;
  final List<ContextMenu> Function() buildMenus;

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (context) => OffsetCubit(null),
        child: Builder(
          builder: (context) => BlocBuilder<OffsetCubit, Offset?>(
            builder: (context, offset) => Barrier(
              duration: const Duration(milliseconds: 100),
              visible: offset != null,
              onClose: () => BlocProvider.of<OffsetCubit>(context).emit(null),
              child: PortalEntry(
                visible: offset != null,
                closeDuration: const Duration(milliseconds: 100),
                portal: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: offset != null ? 1 : 0),
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.easeOut,
                  builder: (context, progress, child) => Opacity(
                    opacity: progress,
                    child: child,
                  ),
                  child: BlocBuilder<OffsetCubit, Offset?>(
                    buildWhen: (a, b) => b != null,
                    builder: (context, offset) => CustomSingleChildLayout(
                      delegate: PositionedLayoutDelegate(
                        position: offset!,
                      ),
                      child: ContextMenuPage(menus: buildMenus()),
                    ),
                  ),
                ),
                child: InteractableDecoratedBox(
                  onRightClick: (PointerUpEvent pointerUpEvent) {
                    BlocProvider.of<OffsetCubit>(context)
                        .emit(pointerUpEvent.position);
                  },
                  child: child,
                ),
              ),
            ),
          ),
        ),
      );
}

class Barrier extends StatelessWidget {
  const Barrier({
    Key? key,
    required this.onClose,
    required this.visible,
    required this.child,
    required this.duration,
  }) : super(key: key);

  final Widget child;
  final VoidCallback onClose;
  final bool visible;
  final Duration duration;

  @override
  Widget build(BuildContext context) => PortalEntry(
        visible: visible,
        closeDuration: duration,
        portal: GestureDetector(
          behavior:
              visible ? HitTestBehavior.opaque : HitTestBehavior.deferToChild,
          onTap: onClose,
        ),
        child: child,
      );
}

class PositionedLayoutDelegate extends SingleChildLayoutDelegate {
  PositionedLayoutDelegate({
    required this.position,
  });

  final Offset position;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints.loose(constraints.biggest);

  static const double _pointerPadding = 1;

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    var dx = position.dx + _pointerPadding, dy = position.dy + _pointerPadding;

    if ((size.width - position.dx) < childSize.width) {
      dx = position.dx - childSize.width;
    }

    if ((size.height - position.dy) < childSize.height) {
      dy = position.dy - childSize.height;
    }

    return Offset(dx, dy);
  }

  @override
  bool shouldRelayout(covariant PositionedLayoutDelegate oldDelegate) =>
      position != oldDelegate.position;
}

class ContextMenuPage extends StatelessWidget {
  const ContextMenuPage({
    Key? key,
    required this.menus,
  }) : super(key: key);

  final List<ContextMenu> menus;

  @override
  Widget build(BuildContext context) {
    final brightnessData = context.brightnessValue;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: Color.lerp(
            Colors.transparent,
            const Color.fromRGBO(255, 255, 255, 0.08),
            brightnessData,
          )!,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.15),
            offset: Offset(0, lerpDouble(0, 2, brightnessData)!),
            blurRadius: lerpDouble(16, 40, brightnessData)!,
          ),
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.07),
            offset: Offset(0, lerpDouble(4, 0, brightnessData)!),
            blurRadius: lerpDouble(6, 12, brightnessData)!,
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
    Key? key,
    required this.title,
    this.isDestructiveAction = false,
    this.onTap,
  }) : super(
          key: key,
        );

  final String title;
  final bool isDestructiveAction;
  final VoidCallback? onTap;

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
          context.theme.listSelected,
          backgroundColor,
        ),
        onTap: () {
          onTap?.call();
          BlocProvider.of<OffsetCubit>(context).emit(null);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: isDestructiveAction
                  ? context.theme.red
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
