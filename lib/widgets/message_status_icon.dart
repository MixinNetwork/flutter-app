import 'package:flutter/widgets.dart';
import 'package:flutter_app/constants/resources.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MessageStatusIcon extends StatelessWidget {
  const MessageStatusIcon({
    Key key,
    @required this.status,
  }) : super(key: key);

  final String status;

  @override
  Widget build(BuildContext context) {
    var lightColor = const Color.fromRGBO(184, 189, 199, 1);
    var darkColor = const Color.fromRGBO(255, 255, 255, 0.4);
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
        lightColor = const Color.fromRGBO(0, 122, 255, 1);
        darkColor = const Color.fromRGBO(65, 145, 255, 1);
        break;
      case 'SENDING':
      default:
        icon = Resources.assetsImagesSendingSvg;
        break;
    }
    return SvgPicture.asset(
      icon,
      color: BrightnessData.dynamicColor(
        context,
        lightColor,
        darkColor: darkColor,
      ),
    );
  }
}
