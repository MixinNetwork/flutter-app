import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../constants/resources.dart';

class VerifiedOrBotWidget extends StatelessWidget {
  const VerifiedOrBotWidget({
    required this.verified,
    required this.isBot,
    super.key,
  });
  final bool? verified;
  final bool isBot;

  @override
  Widget build(BuildContext context) {
    final _verified = verified ?? false;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_verified || isBot) const SizedBox(width: 4),
        if (_verified)
          SvgPicture.asset(
            Resources.assetsImagesVerifiedSvg,
            width: 12,
            height: 12,
          )
        else if (isBot)
          SvgPicture.asset(
            Resources.assetsImagesBotFillSvg,
            width: 12,
            height: 12,
          ),
        if (_verified || isBot) const SizedBox(width: 4),
      ],
    );
  }
}
