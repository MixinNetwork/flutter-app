import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:vector_graphics/vector_graphics_compat.dart'
    show RenderingStrategy;

import '../../constants/resources.dart';
import '../../utils/extension/extension.dart';
import '../mixin_image.dart';

class BadgesWidget extends StatelessWidget {
  const BadgesWidget({
    required this.verified,
    required this.isBot,
    required this.membership,
    super.key,
    this.isGroup = false,
  });
  final bool verified;
  final bool isBot;
  final Membership? membership;
  final bool isGroup;

  @override
  Widget build(BuildContext context) {
    Widget child;

    switch ((verified, isBot, membership?.isValid, membership?.plan)) {
      case _ when isGroup:
        child = SvgPicture.asset(
          Resources.assetsImagesGroupBadgeSvg,
          renderingStrategy: RenderingStrategy.raster,
          colorFilter: ColorFilter.mode(
            context.theme.secondaryText,
            BlendMode.srcIn,
          ),
          width: 14,
          height: 14,
        );
      case (_, _, true, final plan?) when plan != Plan.none:
        child = MixinImage.asset(
          {
            Plan.basic: Resources.assetsImagesPlanBasicPng,
            Plan.standard: Resources.assetsImagesPlanStandardPng,
            Plan.premium: Resources.assetsImagesPlanPremiumGif,
          }[plan]!,
          width: 14,
          height: 14,
          isAntiAlias: true,
        );
      case (true, _, _, _):
        child = SvgPicture.asset(
          Resources.assetsImagesVerifiedSvg,
          renderingStrategy: RenderingStrategy.raster,
          width: 12,
          height: 12,
        );
      case (_, true, _, _):
        child = SvgPicture.asset(
          Resources.assetsImagesBotFillSvg,
          renderingStrategy: RenderingStrategy.raster,
          width: 12,
          height: 12,
        );

      default:
        return const SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: child,
    );
  }
}
