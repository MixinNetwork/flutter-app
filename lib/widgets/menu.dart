import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import '../bloc/simple_cubit.dart';
import '../constants/resources.dart';
import '../utils/extension/extension.dart';
import '../utils/hook.dart';
import 'hover_overlay.dart';
import 'interactive_decorated_box.dart';
import 'portal_providers.dart';

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
    this.interactiveForTap = false,
  }) : super(key: key);

  final Widget child;
  final List<Widget> Function() buildMenus;
  final ValueChanged<bool>? showedMenu;
  final bool interactiveForTap;

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

    useEffect(() {
      showedMenu?.call(visible);
    }, [visible]);

    return Provider.value(
      value: offsetCubit,
      child: Barrier(
        visible: visible,
        onClose: () => offsetCubit.emit(null),
        child: PortalTarget(
          visible: visible,
          portalFollower: Builder(builder: (context) {
            if (offset != null && visible) {
              return CustomSingleChildLayout(
                delegate: PositionedLayoutDelegate(position: offset),
                child: ContextMenuPage(menus: buildMenus()),
              );
            }

            return const SizedBox();
          }),
          child: InteractiveDecoratedBox(
            onRightClick: (PointerUpEvent pointerUpEvent) =>
                offsetCubit.emit(pointerUpEvent.position),
            onLongPress: (details) {
              if (Platform.isAndroid || Platform.isIOS) {
                offsetCubit.emit(details.globalPosition);
              }
            },
            onTapUp: interactiveForTap
                ? (details) => offsetCubit.emit(details.globalPosition)
                : null,
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
    this.duration,
  }) : super(key: key);

  final Widget child;
  final VoidCallback onClose;
  final bool visible;
  final Duration? duration;

  @override
  Widget build(BuildContext context) => PortalTarget(
        visible: visible,
        closeDuration: duration,
        portalFollower: GestureDetector(
          behavior:
              visible ? HitTestBehavior.opaque : HitTestBehavior.deferToChild,
          onTap: onClose,
        ),
        child: child,
      );
}

class PositionedLayoutDelegate extends SingleChildLayoutDelegate {
  PositionedLayoutDelegate({required this.position});

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
    this.icon,
  })  : _subMenuMode = false,
        super(key: key);

  const ContextMenu._sub({
    Key? key,
    required this.title,
    this.isDestructiveAction = false,
    this.icon,
  })  : _subMenuMode = true,
        onTap = null,
        super(key: key);

  final String? icon;
  final String title;
  final bool isDestructiveAction;
  final bool _subMenuMode;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = context.dynamicColor(
      const Color.fromRGBO(255, 255, 255, 1),
      darkColor: const Color.fromRGBO(62, 65, 72, 1),
    );
    final color = isDestructiveAction
        ? context.theme.red
        : context.dynamicColor(
            const Color.fromRGBO(0, 0, 0, 1),
            darkColor: const Color.fromRGBO(255, 255, 255, 0.9),
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
          if (!_subMenuMode) context.closeMenu();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              if (icon != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: SvgPicture.asset(icon!, color: color),
                ),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    color: color,
                  ),
                ),
              ),
              if (_subMenuMode)
                SvgPicture.asset(
                  Resources.assetsImagesIcArrowRightSvg,
                  width: 30,
                  height: 30,
                  color: context.theme.secondaryText,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class SubContextMenu extends StatelessWidget {
  const SubContextMenu({
    Key? key,
    required this.title,
    required this.menus,
    this.icon,
    this.isDestructiveAction = false,
  }) : super(key: key);

  final String? icon;
  final String title;
  final bool isDestructiveAction;
  final List<Widget> menus;

  @override
  Widget build(BuildContext context) => HoverOverlay(
        closeDuration: Duration.zero,
        duration: Duration.zero,
        portalCandidateLabels: const [secondPortal],
        anchor: const Aligned(
          follower: Alignment.centerLeft,
          target: Alignment.centerRight,
          offset: Offset(-8, 0),
        ),
        portal: ContextMenuPage(menus: menus),
        child: ContextMenu._sub(
          icon: icon,
          title: title,
          isDestructiveAction: isDestructiveAction,
        ),
      );
}
