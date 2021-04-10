import 'package:flutter/widgets.dart';
import 'package:flutter_app/constants/resources.dart';
import 'package:flutter_app/ui/home/route/responsive_navigator_cubit.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_svg/svg.dart';

import 'interacter_decorated_box.dart';

class CellGroup extends StatelessWidget {
  const CellGroup({
    Key? key,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    required this.child,
  }) : super(key: key);

  final BorderRadius borderRadius;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: child,
        ),
      );
}

class CellItem extends StatelessWidget {
  const CellItem({
    Key? key,
    this.assetName,
    required this.title,
    this.color,
    this.onTap,
    this.selected = false,
    this.action = const _Arrow(),
    this.description,
  }) : super(key: key);

  final String? assetName;
  final String title;
  final Color? color;
  final VoidCallback? onTap;
  final bool selected;
  final Widget? action;
  final Widget? description;

  @override
  Widget build(BuildContext context) {
    final dynamicColor = color ?? BrightnessData.themeOf(context).text;
    final backgroundColor = BrightnessData.themeOf(context).listSelected;
    var selectedBackgroundColor = backgroundColor;
    if (selected &&
        !ResponsiveNavigatorCubit.of(context).state.navigationMode) {
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
            if (assetName != null)
              SvgPicture.asset(
                assetName!,
                width: 24,
                height: 24,
                color: dynamicColor,
              ),
            if (assetName != null) const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: dynamicColor,
                ),
              ),
            ),
            if (description != null) const SizedBox(width: 4),
            if (description != null) description!,
            if (action != null) const SizedBox(width: 4),
            if (action != null) action!,
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
