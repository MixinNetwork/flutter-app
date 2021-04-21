import 'package:flutter/widgets.dart';
import 'package:flutter_app/constants/resources.dart';
import 'package:flutter_app/ui/home/route/responsive_navigator_cubit.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import 'interacter_decorated_box.dart';

class CellGroup extends StatelessWidget {
  const CellGroup({
    Key? key,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    required this.child,
    this.padding = const EdgeInsets.only(right: 10, left: 10, bottom: 10),
  }) : super(key: key);

  final BorderRadius borderRadius;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: padding,
          child: ClipRRect(
            borderRadius: borderRadius,
            child: child,
          ),
        ),
      );
}

class CellItem extends StatelessWidget {
  const CellItem({
    Key? key,
    this.leading,
    required this.title,
    this.color,
    this.onTap,
    this.selected = false,
    this.trailing = const _Arrow(),
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
    final dynamicColor = color ?? BrightnessData.themeOf(context).text;
    final backgroundColor = BrightnessData.themeOf(context).listSelected;
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
                  color: BrightnessData.themeOf(context).secondaryText,
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

class _Arrow extends StatelessWidget {
  const _Arrow({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      Resources.assetsImagesIcArrowRightSvg,
      width: 30,
      height: 30,
    );
  }
}
