import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import '../constants/resources.dart';
import '../ui/home/route/responsive_navigator_cubit.dart';
import '../utils/extension/extension.dart';
import 'brightness_observer.dart';

import 'interacter_decorated_box.dart';

class CellGroup extends StatelessWidget {
  const CellGroup(
      {Key? key,
      this.borderRadius = const BorderRadius.all(Radius.circular(8)),
      required this.child,
      this.padding = const EdgeInsets.only(right: 10, left: 10, bottom: 10),
      this.cellBackgroundColor})
      : super(key: key);

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
              backgroundColor:
                  cellBackgroundColor ?? context.theme.listSelected,
              child: child,
            ),
          ),
        ),
      );
}

class _CellItemStyle extends InheritedWidget {
  const _CellItemStyle({
    Key? key,
    required Widget child,
    required this.backgroundColor,
  }) : super(key: key, child: child);

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

class CellItem extends StatelessWidget {
  const CellItem({
    Key? key,
    this.leading,
    required this.title,
    this.color,
    this.onTap,
    this.selected = false,
    this.trailing = const Arrow(),
    this.description,
  }) : super(key: key);

  final Widget? leading;
  final Widget title;
  final Color? color;
  final VoidCallback? onTap;
  final bool selected;
  final Widget? trailing;
  final Widget? description;

  @override
  Widget build(BuildContext context) {
    final dynamicColor = color ?? context.theme.text;
    final backgroundColor = _CellItemStyle.of(context).backgroundColor;
    var selectedBackgroundColor = backgroundColor;
    if (selected &&
        !context.read<ResponsiveNavigatorCubit>().state.navigationMode) {
      selectedBackgroundColor = Color.alphaBlend(
        BrightnessData.dynamicColor(
          context,
          const Color.fromRGBO(0, 0, 0, 0.05),
          darkColor: const Color.fromRGBO(255, 255, 255, 0.06),
        ),
        backgroundColor,
      );
    }
    return InteractableDecoratedBox(
      decoration: BoxDecoration(
        color: selectedBackgroundColor,
      ),
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
              child: DefaultTextStyle(
                style: TextStyle(
                  fontSize: 16,
                  color: dynamicColor,
                ),
                child: title,
              ),
            ),
            if (description != null) const SizedBox(width: 4),
            if (description != null)
              DefaultTextStyle(
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
  const Arrow({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
        Resources.assetsImagesIcArrowRightSvg,
        color: context.theme.secondaryText,
        width: 30,
        height: 30,
      );
}
