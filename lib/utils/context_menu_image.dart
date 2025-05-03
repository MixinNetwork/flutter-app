import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:super_native_extensions/raw_menu.dart';

class MenuSvg extends MenuImage {
  MenuSvg(String assetName)
    : _menuImage = MenuImage.withImage((theme, devicePixelRatio) async {
        assert(theme.size != null, 'IconThemeData.size must not be null!');
        assert(theme.color != null, 'IconThemeData.color must not be null!');

        final size = theme.size!;
        final color = theme.color!;

        final pictureInfo = await vg.loadPicture(
          SvgAssetLoader(
            assetName,
            theme: SvgTheme(currentColor: color, fontSize: size),
          ),
          null,
        );

        final image = await pictureInfo.picture.toImage(
          (size * devicePixelRatio).round(),
          (size * devicePixelRatio).round(),
        );

        image.devicePixelRatio = devicePixelRatio.toDouble();

        return image;
      });

  final MenuImage _menuImage;

  @override
  FutureOr<ui.Image?> asImage(IconThemeData theme, double devicePixelRatio) =>
      _menuImage.asImage(theme, devicePixelRatio);

  @override
  Widget? asWidget(IconThemeData theme) => _menuImage.asWidget(theme);
}
