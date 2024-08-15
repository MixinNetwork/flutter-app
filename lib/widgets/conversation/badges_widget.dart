import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import '../../../constants/resources.dart';
import '../../utils/extension/extension.dart';

class BadgesWidget extends StatelessWidget {
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
    var children = <Widget>[];

    switch ((verified, isBot)) {
      case (true, _):
        children.add(
          SvgPicture.asset(
            Resources.assetsImagesVerifiedSvg,
            width: 12,
            height: 12,
          ),
        );
      case (_, true):
        children.add(
          SvgPicture.asset(
            Resources.assetsImagesBotFillSvg,
            width: 12,
            height: 12,
          ),
        );
      default:
    }

    switch ((membership?.isValid, membership?.plan)) {
      case (true, final plan) when plan != Plan.none:
        children.add(
          Image.asset(
            {
              Plan.basic: Resources.assetsImagesPlanBasicPng,
              Plan.standard: Resources.assetsImagesPlanStandardPng,
              Plan.premium: Resources.assetsImagesPlanPremiumPng,
            }[plan]!,
            width: 16,
            height: 16,
          ),
        );
      default:
    }

    children = children.joinList(const SizedBox(width: 4));

    if (children.isNotEmpty) {
      children.insert(0, const SizedBox(width: 4));
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}
