import 'package:flutter/cupertino.dart';

import '../../../constants/brightness_theme_data.dart';
import '../../../widgets/brightness_observer.dart';

class SettingPageTheme extends StatelessWidget {
  const SettingPageTheme({Key? key, required this.child}) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) => BrightnessData(
        value: BrightnessData.of(context),
        brightnessThemeData: BrightnessData.themeOf(context).copyWith(
          listSelected: BrightnessData.dynamicColor(
            context,
            lightBrightnessThemeData.primary,
            darkColor: darkBrightnessThemeData.listSelected,
          ),
        ),
        child: child,
      );
}
