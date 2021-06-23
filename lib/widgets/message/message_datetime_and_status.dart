import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';

import '../../bloc/minute_timer_cubit.dart';
import '../../constants/resources.dart';
import '../../enum/message_status.dart';
import '../../utils/hook.dart';
import '../brightness_observer.dart';

class MessageDatetimeAndStatus extends StatelessWidget {
  const MessageDatetimeAndStatus({
    Key? key,
    required this.isCurrentUser,
    required this.createdAt,
    required this.status,
    this.color,
  }) : super(key: key);

  final bool isCurrentUser;
  final DateTime createdAt;
  final Color? color;
  final MessageStatus status;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MessageDatetime(
            dateTime: createdAt,
            color: color,
          ),
          if (isCurrentUser) _MessageStatusWidget(status: status),
        ],
      );
}

class _MessageDatetime extends HookWidget {
  const _MessageDatetime({
    Key? key,
    required this.dateTime,
    this.color,
  }) : super(key: key);

  final DateTime dateTime;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final text = useBlocStateConverter<MinuteTimerCubit, DateTime, String>(
      converter: (_) => DateFormat.Hm().format(dateTime.toLocal()),
    );
    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        color: color ??
            BrightnessData.dynamicColor(
              context,
              const Color.fromRGBO(131, 145, 158, 1),
              darkColor: const Color.fromRGBO(128, 131, 134, 1),
            ),
      ),
    );
  }
}

class _MessageStatusWidget extends StatelessWidget {
  const _MessageStatusWidget({
    Key? key,
    required this.status,
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
