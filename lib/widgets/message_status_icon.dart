import 'package:flutter/widgets.dart';
import 'package:flutter_app/constants/resources.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MessageStatusIcon extends StatelessWidget {
  const MessageStatusIcon({
    Key? key,
    required this.status,
  }) : super(key: key);

  final String status;

  @override
  Widget build(BuildContext context) {
    var color = BrightnessData.themeOf(context).secondaryText;
    String icon;
    switch (status) {
      case 'SENT':
        icon = Resources.assetsImagesSentSvg;
        break;
      case 'DELIVERED':
        icon = Resources.assetsImagesDeliveredSvg;
        break;
      case 'READ':
        icon = Resources.assetsImagesReadSvg;
        color = BrightnessData.themeOf(context).accent;
        break;
      case 'SENDING':
      default:
        icon = Resources.assetsImagesSendingSvg;
        break;
    }
    return SvgPicture.asset(
      icon,
      color: color,
    );
  }
}
