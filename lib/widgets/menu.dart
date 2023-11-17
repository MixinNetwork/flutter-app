// ignore_for_file: implementation_imports

import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart' hide Provider;
import 'package:mixin_logger/mixin_logger.dart';
import 'package:provider/provider.dart';
import 'package:super_context_menu/src/default_builder/desktop_menu_widget_builder.dart';
import 'package:super_context_menu/src/default_builder/group_intrinsic_width.dart';
import 'package:super_context_menu/src/scaffold/desktop/menu_widget_builder.dart';
import 'package:super_context_menu/super_context_menu.dart';

import '../bloc/simple_cubit.dart';
import '../constants/resources.dart';
import '../utils/extension/extension.dart';
import '../utils/hook.dart';
import 'action_button.dart';
import 'hover_overlay.dart';
import 'interactive_decorated_box.dart';
import 'portal_providers.dart';

class MenusWithSeparator extends Menu {
  MenusWithSeparator({
    required List<List<MenuElement>> childrens,
    super.title,
    super.image,
  }) : super(
          children: childrens
              .where((element) => element.isNotEmpty)
              .joinList([MenuSeparator()])
              .expand((element) => element.toList())
              .toList(),
        );
}

class _OffsetCubit extends SimpleCubit<Offset?> {
  _OffsetCubit(super.state);
}

extension ContextMenuPortalEntrySender on BuildContext {
  void sendMenuPosition(Offset offset) => read<_OffsetCubit>().emit(offset);

  void closeMenu() => read<_OffsetCubit?>()?.emit(null);
}

typedef CustomPopupMenuItemBuilder<T> = List<CustomPopupMenuItem<T>> Function(
    BuildContext context);

class CustomPopupMenuButton<T> extends HookConsumerWidget {
  const CustomPopupMenuButton({
    required this.itemBuilder,
    super.key,
    this.onSelected,
    this.child,
    this.icon,
    this.color,
    this.alignment,
  });

  final CustomPopupMenuItemBuilder<T> itemBuilder;
  final PopupMenuItemSelected<T>? onSelected;
  final String? icon;
  final Widget? child;
  final Color? color;
  final Alignment? alignment;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ContextMenuPortalEntry(
        interactive: false,
        buildMenus: () => itemBuilder(context)
            .map(
              (e) => ContextMenu(
                title: e.title,
                onTap: () => onSelected?.call(e.value),
                isDestructiveAction: e.isDestructiveAction,
                icon: e.icon,
              ),
            )
            .toList(),
        child: Builder(
            builder: (context) => ActionButton(
                  name: icon,
                  color: color ?? context.theme.icon,
                  onTapUp: (details) {
                    d('onTapUp: $alignment');
                    if (alignment == null) {
                      context.sendMenuPosition(details.globalPosition);
                      return;
                    }
                    final renderBox = context.findRenderObject() as RenderBox?;
                    if (renderBox != null) {
                      var position =
                          alignment!.withinRect(renderBox.paintBounds);
                      position = renderBox.localToGlobal(position);
                      context.sendMenuPosition(position);
                    } else {
                      context.sendMenuPosition(details.globalPosition);
                    }
                  },
                  child: child,
                )),
      );
}

class CustomPopupMenuItem<T> {
  CustomPopupMenuItem({
    required this.title,
    required this.value,
    this.isDestructiveAction = false,
    this.icon,
  });

  final String title;
  final T value;
  final bool isDestructiveAction;
  final String? icon;
}

class ContextMenuPortalEntry extends HookConsumerWidget {
  const ContextMenuPortalEntry({
    required this.child,
    required this.buildMenus,
    super.key,
    this.showedMenu,
    this.enable = true,
    this.onTap,
    this.interactive = true,
  });

  final Widget child;
  final List<Widget> Function() buildMenus;
  final ValueChanged<bool>? showedMenu;
  final bool enable;
  final VoidCallback? onTap;

  /// Whether right click or long press to show menu
  final bool interactive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    useEffect(() {
      if (!enable) {
        offsetCubit.emit(null);
      }
    }, [enable]);

    if (!enable) {
      return child;
    }
    return Provider.value(
      value: offsetCubit,
      child: Barrier(
        visible: visible,
        onClose: () => offsetCubit.emit(null),
        child: PortalTarget(
          visible: visible,
          portalFollower: Builder(builder: (context) {
            final show = offset != null && visible;
            if (show) {
              return CustomSingleChildLayout(
                delegate: PositionedLayoutDelegate(position: offset),
                child: ContextMenuPage(menus: buildMenus()),
              );
            }
            return const SizedBox();
          }),
          child: InteractiveDecoratedBox(
            onRightClick: (event) {
              if (!interactive) {
                return;
              }
              offsetCubit.emit(event.globalPosition);
            },
            onLongPress: (details) {
              if (!interactive) {
                return;
              }
              if (Platform.isAndroid || Platform.isIOS) {
                offsetCubit.emit(details.globalPosition);
              }
            },
            onTap: onTap,
            child: Focus(
              onKeyEvent: (node, key) {
                final show = offset != null && visible;
                if (show && key.logicalKey == LogicalKeyboardKey.escape) {
                  offsetCubit.emit(null);
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class Barrier extends StatelessWidget {
  const Barrier({
    required this.onClose,
    required this.visible,
    required this.child,
    super.key,
    this.duration,
  });

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
    var dx = position.dx + _pointerPadding;
    var dy = position.dy + _pointerPadding;

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
    required this.menus,
    super.key,
  });

  final List<Widget> menus;

  @override
  Widget build(BuildContext context) => _ContextMenuContainerLayout(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: menus,
        ),
      );
}

class _ContextMenuContainerLayout extends StatelessWidget {
  const _ContextMenuContainerLayout({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final brightnessData = context.brightnessValue;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(11)),
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
        borderRadius: const BorderRadius.all(Radius.circular(11)),
        child: Material(
          color: Colors.transparent,
          child: IntrinsicWidth(child: child),
        ),
      ),
    );
  }
}

class ContextMenu extends StatelessWidget {
  const ContextMenu({
    required this.title,
    super.key,
    this.isDestructiveAction = false,
    this.onTap,
    this.icon,
  }) : _subMenuMode = false;

  const ContextMenu._sub({
    required this.title,
    this.isDestructiveAction = false,
    this.icon,
  })  : _subMenuMode = true,
        onTap = null;

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
        onTapUp: (details) {
          if (_subMenuMode && details.kind == PointerDeviceKind.touch) {
            const SubMenuClickedByTouchNotification().dispatch(context);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (icon != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: SvgPicture.asset(
                    icon!,
                    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                    width: 20,
                    height: 20,
                  ),
                ),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: color,
                  ),
                ),
              ),
              if (_subMenuMode)
                SvgPicture.asset(
                  Resources.assetsImagesIcArrowRightSvg,
                  width: 20,
                  height: 20,
                  colorFilter: ColorFilter.mode(
                    context.theme.secondaryText,
                    BlendMode.srcIn,
                  ),
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
    required this.title,
    required this.menus,
    super.key,
    this.icon,
    this.isDestructiveAction = false,
  });

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

class SubMenuClickedByTouchNotification extends Notification {
  const SubMenuClickedByTouchNotification();
}

class CustomDesktopMenuWidgetBuilder extends DefaultDesktopMenuWidgetBuilder {
  CustomDesktopMenuWidgetBuilder();

  static DefaultDesktopMenuTheme _themeForContext(BuildContext context) =>
      DefaultDesktopMenuTheme.themeForBrightness(context.brightness);

  @override
  Widget buildMenuContainer(
      BuildContext context, DesktopMenuInfo menuInfo, Widget child) {
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final theme = _themeForContext(context);
    return Container(
      decoration: theme.decorationOuter.copyWith(
          borderRadius: BorderRadius.circular(6.0 + 1.0 / pixelRatio)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: EdgeInsets.all(1.0 / pixelRatio),
          child: Container(
            decoration: theme.decorationInner,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: DefaultTextStyle.merge(
              style: TextStyle(
                color: Colors.black,
                fontSize: 14,
                decoration: TextDecoration.none,
                fontWeight: FontWeight.w500,
                fontFamilyFallback:
                    Platform.isWindows ? ['Microsoft Yahei'] : null,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: GroupIntrinsicWidthContainer(child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget buildSeparator(
    BuildContext context,
    DesktopMenuInfo menuInfo,
    MenuSeparator separator,
  ) {
    final theme = _themeForContext(context);
    final paddingLeft = 10.0 + (menuInfo.hasAnyCheckedItems ? (16 + 6) : 0);
    const paddingRight = 10.0;
    return Container(
      height: 1,
      margin: EdgeInsets.only(
        left: paddingLeft,
        right: paddingRight,
        top: 5,
        bottom: 6,
      ),
      color: theme.separatorColor,
    );
  }

  IconData? _stateToIcon(MenuActionState state) {
    switch (state) {
      case MenuActionState.none:
        return null;
      case MenuActionState.checkOn:
        return Icons.check;
      case MenuActionState.checkOff:
        return null;
      case MenuActionState.checkMixed:
        return Icons.remove;
      case MenuActionState.radioOn:
        return Icons.radio_button_on;
      case MenuActionState.radioOff:
        return Icons.radio_button_off;
    }
  }

  @override
  Widget buildMenuItem(
    BuildContext context,
    DesktopMenuInfo menuInfo,
    Key innerKey,
    DesktopMenuButtonState state,
    MenuElement element,
  ) {
    final theme = _themeForContext(context);
    final itemInfo = DesktopMenuItemInfo(
      destructive: element is MenuAction && element.attributes.destructive,
      disabled: element is MenuAction && element.attributes.disabled,
      menuFocused: menuInfo.focused,
      selected: state.selected,
    );
    final textStyle = theme.textStyleForItem(itemInfo);
    final iconTheme = menuInfo.iconTheme.copyWith(
      size: 16,
      color: textStyle.color,
    );
    final stateIcon =
        element is MenuAction ? _stateToIcon(element.state) : null;
    final Widget? prefix;
    if (stateIcon != null) {
      prefix = Icon(
        stateIcon,
        size: 16,
        color: iconTheme.color,
      );
    } else if (menuInfo.hasAnyCheckedItems) {
      prefix = const SizedBox(width: 16);
    } else {
      prefix = null;
    }
    final image = element.image?.asWidget(iconTheme);

    final Widget? suffix;
    if (element is Menu) {
      suffix = Icon(
        Icons.chevron_right_outlined,
        size: 18,
        color: iconTheme.color,
      );
    } else if (element is MenuAction) {
      final activator = element.activator?.stringRepresentation();
      if (activator != null) {
        suffix = Padding(
          padding: const EdgeInsetsDirectional.only(end: 6),
          child: Text(
            activator,
            style: theme.textStyleForItemActivator(itemInfo, textStyle),
          ),
        );
      } else {
        suffix = null;
      }
    } else {
      suffix = null;
    }

    final child = element is DeferredMenuElement
        ? const Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.grey,
              ),
            ),
          )
        : Text(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            element.title ?? '',
            style: textStyle,
          );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Container(
        key: innerKey,
        padding: const EdgeInsets.all(5),
        decoration: theme.decorationForItem(itemInfo),
        child: Row(
          children: [
            if (prefix != null) prefix,
            if (prefix != null) const SizedBox(width: 6),
            if (image != null) image,
            if (image != null) const SizedBox(width: 4),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: child,
              ),
            ),
            GroupIntrinsicWidth(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (suffix != null) const SizedBox(width: 6),
                  if (suffix != null) suffix,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on DesktopMenuInfo {
  bool get hasAnyCheckedItems => resolvedChildren.any((element) =>
      element is MenuAction && element.state != MenuActionState.none);
}

extension on SingleActivator {
  String stringRepresentation() => [
        if (control) 'Ctrl',
        if (alt) 'Alt',
        if (meta)
          defaultTargetPlatform == TargetPlatform.macOS ? 'Cmd' : 'Meta',
        if (shift) 'Shift',
        trigger.keyLabel,
      ].join('+');
}
