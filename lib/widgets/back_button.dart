import 'package:flutter/widgets.dart';
import 'package:flutter_app/constants/assets.dart';
import 'package:flutter_app/widgets/action_button.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';

class MixinBackButton extends StatelessWidget {
  const MixinBackButton({
    Key key,
    this.color,
    this.onTap,
  }) : super(key: key);

  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: ActionButton(
          name: Assets.assetsImagesIcBackPng,
          color: color ??
              BrightnessData.dynamicColor(
                context,
                const Color.fromRGBO(47, 48, 50, 1),
                darkColor: const Color.fromRGBO(255, 255, 255, 0.9),
              ),
          onTap: () {
            if (onTap != null) return onTap?.call();
            Navigator.pop(context);
          },
        ),
      );
}
