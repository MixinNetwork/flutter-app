import 'package:flutter/widgets.dart';
import '../constants/resources.dart';
import 'action_button.dart';
import 'brightness_observer.dart';

class MixinBackButton extends StatelessWidget {
  const MixinBackButton({
    Key? key,
    this.color,
    this.onTap,
  }) : super(key: key);

  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: ActionButton(
          name: Resources.assetsImagesIcBackSvg,
          color: color ?? BrightnessData.themeOf(context).icon,
          onTap: () {
            if (onTap != null) return onTap?.call();
            Navigator.pop(context);
          },
        ),
      );
}
