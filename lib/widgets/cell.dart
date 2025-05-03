import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../constants/resources.dart';
import '../ui/provider/responsive_navigator_provider.dart';
import '../utils/extension/extension.dart';
import 'interactive_decorated_box.dart';

class CellGroup extends StatelessWidget {
  const CellGroup({
    required this.child,
    super.key,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.padding = const EdgeInsets.only(right: 10, left: 10, bottom: 10),
    this.cellBackgroundColor,
  });

  final BorderRadius borderRadius;
  final Widget child;
  final EdgeInsetsGeometry padding;

  final Color? cellBackgroundColor;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 600),
    child: Padding(
      padding: padding,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: _CellItemStyle(
          backgroundColor: cellBackgroundColor ?? context.theme.listSelected,
          child: child,
        ),
      ),
    ),
  );
}

class _CellItemStyle extends InheritedWidget {
  const _CellItemStyle({required super.child, required this.backgroundColor});

  final Color backgroundColor;

  static _CellItemStyle of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<_CellItemStyle>();
    assert(result != null, 'No _CellItemStyle found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(_CellItemStyle old) =>
      old.backgroundColor == backgroundColor;
}

class CellItem extends HookConsumerWidget {
  const CellItem({
    required this.title,
    super.key,
    this.leading,
    this.color,
    this.onTap,
    this.selected = false,
    this.trailing = const Arrow(),
    this.description,
  });

  final Widget? leading;
  final Widget title;
  final Color? color;
  final VoidCallback? onTap;
  final bool selected;
  final Widget? trailing;
  final Widget? description;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dynamicColor = color ?? context.theme.text;
    final backgroundColor = _CellItemStyle.of(context).backgroundColor;
    var selectedBackgroundColor = backgroundColor;
    if (selected && !ref.watch(navigatorRouteModeProvider)) {
      selectedBackgroundColor = Color.alphaBlend(
        context.dynamicColor(
          const Color.fromRGBO(0, 0, 0, 0.05),
          darkColor: const Color.fromRGBO(255, 255, 255, 0.06),
        ),
        backgroundColor,
      );
    }
    return InteractiveDecoratedBox(
      decoration: BoxDecoration(color: selectedBackgroundColor),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(
          top: 17,
          bottom: 17,
          left: 16,
          right: 10,
        ),
        child: Row(
          children: [
            if (leading != null) leading!,
            if (leading != null) const SizedBox(width: 8),
            Expanded(
              child: DefaultTextStyle.merge(
                style: TextStyle(fontSize: 16, color: dynamicColor),
                child: title,
              ),
            ),
            if (description != null) const SizedBox(width: 4),
            if (description != null)
              DefaultTextStyle.merge(
                style: TextStyle(
                  color: context.theme.secondaryText,
                  fontSize: 14,
                ),
                child: description!,
              ),
            if (trailing != null) const SizedBox(width: 4),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class Arrow extends StatelessWidget {
  const Arrow({super.key});

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    Resources.assetsImagesIcArrowRightSvg,
    colorFilter: ColorFilter.mode(context.theme.secondaryText, BlendMode.srcIn),
    width: 30,
    height: 30,
  );
}
