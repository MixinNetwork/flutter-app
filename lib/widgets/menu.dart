import 'package:flutter/material.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart' hide Provider;
import 'package:super_context_menu/super_context_menu.dart';

import '../utils/extension/extension.dart';

class MenusWithSeparator extends Menu {
  MenusWithSeparator({
    super.title,
    super.image,
    required List<List<MenuElement>> childrens,
  }) : super(
          children: childrens
              .where((element) => element.isNotEmpty)
              .joinList([MenuSeparator()])
              .expand((element) => element.toList())
              .toList(),
        );
}

class PopupMenuPageButton<T> extends HookConsumerWidget {
  const PopupMenuPageButton({
    super.key,
    required this.itemBuilder,
    this.onSelected,
    this.child,
    this.icon,
    this.enabled = true,
    this.popupMenuButtonKey,
  });

  final PopupMenuItemBuilder<T> itemBuilder;
  final PopupMenuItemSelected<T>? onSelected;
  final Widget? child;
  final Widget? icon;
  final bool enabled;
  final Key? popupMenuButtonKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) => PopupMenuButton(
        key: popupMenuButtonKey,
        color: context.theme.popUp,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 160),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(11))),
        itemBuilder: itemBuilder,
        onSelected: onSelected,
        enabled: enabled,
        icon: icon,
        child: child,
      );
}

class CustomPopupMenuButton<T> extends PopupMenuItem<T> {
  CustomPopupMenuButton({
    super.key,
    super.value,
    String? icon,
    required String title,
  }) : super(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Builder(
            builder: (context) => Row(
              children: [
                if (icon != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: SvgPicture.asset(
                      icon,
                      colorFilter:
                          ColorFilter.mode(context.theme.text, BlendMode.srcIn),
                      width: 20,
                      height: 20,
                    ),
                  ),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: context.theme.text,
                    ),
                  ),
                )
              ],
            ),
          ),
        );
}

class Barrier extends StatelessWidget {
  const Barrier({
    super.key,
    required this.onClose,
    required this.visible,
    required this.child,
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
