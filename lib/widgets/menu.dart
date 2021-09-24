import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:provider/provider.dart';

import '../bloc/simple_cubit.dart';
import '../utils/extension/extension.dart';
import '../utils/hook.dart';
import 'interacter_decorated_box.dart';

class _OffsetCubit extends SimpleCubit<Offset?> {
  _OffsetCubit(Offset? state) : super(state);
}

extension ContextMenuPortalEntrySender on BuildContext {
  void sendMenuPosition(Offset offset) => read<_OffsetCubit>().emit(offset);

  void closeMenu() => read<_OffsetCubit>().emit(null);
}

class ContextMenuPortalEntry extends HookWidget {
  const ContextMenuPortalEntry({
    Key? key,
    required this.child,
    required this.buildMenus,
    this.showedMenu,
  }) : super(key: key);

  final Widget child;
  final List<Widget> Function() buildMenus;
  final ValueChanged<bool>? showedMenu;

  @override
  Widget build(BuildContext context) {
    final offsetCubit = useBloc(() => _OffsetCubit(null));
    final offset = useBlocState<_OffsetCubit, Offset?>(
      bloc: offsetCubit,
      when: (state) => state != null,
    );
    final visible = useBlocStateConverter<_OffsetCubit, Offset?, bool>(
      bloc: offsetCubit,
      converter: (state) => state != null,
    );

    void updateOffset(Offset? value) {
      offsetCubit.emit(value);
      if (showedMenu == null) return;
      showedMenu!(value != null);
    }

    return Provider.value(
      value: offsetCubit,
      child: Barrier(
        duration: const Duration(milliseconds: 100),
        visible: visible,
        onClose: () => updateOffset(null),
        child: PortalEntry(
          visible: visible,
          closeDuration: const Duration(milliseconds: 100),
          portal: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: visible ? 1 : 0),
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
            builder: (context, progress, child) => Opacity(
              opacity: progress,
              child: child,
            ),
            child: Builder(builder: (context) {
              if (offset != null) {
                return CustomSingleChildLayout(
                  delegate: PositionedLayoutDelegate(
                    position: offset,
                  ),
                  child: ContextMenuPage(menus: buildMenus()),
                );
              }

              return const SizedBox();
            }),
          ),
          child: InteractiveDecoratedBox(
            onRightClick: (PointerUpEvent pointerUpEvent) =>
                updateOffset(pointerUpEvent.position),
            onLongPress: (details) {
              if (Platform.isAndroid || Platform.isIOS) {
                updateOffset(details.globalPosition);
              }
            },
            child: child,
          ),
        ),
      ),
    );
  }
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

  final List<Widget> menus;

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
        color: context.dynamicColor(
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
    final backgroundColor = context.dynamicColor(
      const Color.fromRGBO(255, 255, 255, 1),
      darkColor: const Color.fromRGBO(62, 65, 72, 1),
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 160),
      child: InteractiveDecoratedBox.color(
        decoration: BoxDecoration(
          color: backgroundColor,
        ),
        tapDowningColor: Color.alphaBlend(
          context.theme.listSelected,
          backgroundColor,
        ),
        onTap: () {
          onTap?.call();
          context.closeMenu();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: isDestructiveAction
                  ? context.theme.red
                  : context.dynamicColor(
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
