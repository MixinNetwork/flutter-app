import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import '../../../constants/resources.dart';
import '../../utils/app_lifecycle.dart';
import '../cache_image.dart';

class BadgesWidget extends HookWidget {
  const BadgesWidget({
    required this.verified,
    required this.isBot,
    required this.membership,
    super.key,
  });
  final bool? verified;
  final bool isBot;
  final Membership? membership;

  @override
  Widget build(BuildContext context) {
    Widget child;

    switch ((verified, isBot, membership?.isValid, membership?.plan)) {
      case (_, _, true, final plan?) when plan != Plan.none:
        child = Image(
          image: MixinAssetImage(
            {
              Plan.basic: Resources.assetsImagesPlanBasicPng,
              Plan.standard: Resources.assetsImagesPlanStandardPng,
              Plan.premium: Resources.assetsImagesPlanPremiumGif,
            }[plan]!,
            controller: appActiveListener,
          ),
          width: 14,
          height: 14,
          isAntiAlias: true,
        );
      case (true, _, _, _):
        child = SvgPicture.asset(
          Resources.assetsImagesVerifiedSvg,
          width: 12,
          height: 12,
        );
      case (_, true, _, _):
        child = SvgPicture.asset(
          Resources.assetsImagesBotFillSvg,
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
