import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/constants/resources.dart';
import 'package:flutter_app/enum/message_status.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_svg/svg.dart';

class MessageStatusWidget extends StatelessWidget {
  const MessageStatusWidget({
    Key key,
    @required this.status,
  }) : super(key: key);

  final MessageStatus status;

  @override
  Widget build(BuildContext context) {
    var assetName = Resources.assetsImagesSendingSvg;
    var lightColor = const Color.fromRGBO(184, 189, 199, 1);
    var darkColor = const Color.fromRGBO(255, 255, 255, 0.4);
    switch (status) {
      case MessageStatus.sent:
        assetName = Resources.assetsImagesSentSvg;
        break;
      case MessageStatus.delivered:
        assetName = Resources.assetsImagesDeliveredSvg;
        break;
      case MessageStatus.read:
        assetName = Resources.assetsImagesReadSvg;
        lightColor = const Color.fromRGBO(61, 117, 227, 1);
        darkColor = const Color.fromRGBO(65, 145, 255, 1);
        break;
      default:
        break;
    }
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: SvgPicture.asset(
        assetName,
        color: BrightnessData.dynamicColor(
          context,
          lightColor,
          darkColor: darkColor,
        ),
      ),
    );
  }
}

