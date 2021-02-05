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
    var color = BrightnessData.themeOf(context).secondaryText;
    switch (status) {
      case MessageStatus.sent:
        assetName = Resources.assetsImagesSentSvg;
        break;
      case MessageStatus.delivered:
        assetName = Resources.assetsImagesDeliveredSvg;
        break;
      case MessageStatus.read:
        assetName = Resources.assetsImagesReadSvg;
        color = BrightnessData.themeOf(context).accent;
        break;
      default:
        break;
    }
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: SvgPicture.asset(
        assetName,
        color: color,
      ),
    );
  }
}

