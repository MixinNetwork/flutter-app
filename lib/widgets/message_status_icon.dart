import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../constants/resources.dart';
import '../enum/message_status.dart';
import '../utils/extension/extension.dart';

class MessageStatusIcon extends StatelessWidget {
  const MessageStatusIcon({
    Key? key,
    required this.status,
  }) : super(key: key);

  final MessageStatus? status;

  @override
  Widget build(BuildContext context) {
    var color = context.theme.secondaryText;
    String icon;
    switch (status) {
      case MessageStatus.sent:
        icon = Resources.assetsImagesSentSvg;
        break;
      case MessageStatus.delivered:
        icon = Resources.assetsImagesDeliveredSvg;
        break;
      case MessageStatus.read:
        icon = Resources.assetsImagesReadSvg;
        color = context.theme.accent;
        break;
      case MessageStatus.sending:
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
