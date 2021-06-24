import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../account/account_server.dart';
import '../../bloc/minute_timer_cubit.dart';
import '../../constants/resources.dart';
import '../../db/extension/message.dart';
import '../../db/mixin_database.dart';
import '../../enum/message_status.dart';
import '../../ui/home/bloc/conversation_cubit.dart';
import '../../utils/hook.dart';
import '../brightness_observer.dart';

bool _isRepresentative(
  MessageItem message,
  ConversationState? conversation,
  String userId,
) {
  assert(conversation != null);
  return conversation != null &&
      (conversation.isBot ?? false) &&
      (conversation.user?.userId != message.userId) &&
      (message.userId != userId);
}

class MessageDatetimeAndStatus extends StatelessWidget {
  const MessageDatetimeAndStatus({
    Key? key,
    required this.isCurrentUser,
    this.color,
    required this.message,
  }) : super(key: key);

  final bool isCurrentUser;
  final Color? color;
  final MessageItem message;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (message.isSignal)
            Padding(
              padding: const EdgeInsets.only(right: 4.0),
              child: _ChatIcon(
                color: color,
                assetName: Resources.assetsImagesChatSecretSvg,
              ),
            ),
          if (_isRepresentative(
              message,
              context.read<ConversationCubit>().state,
              context.read<AccountServer>().userId))
            Padding(
              padding: const EdgeInsets.only(right: 4.0),
              child: _ChatIcon(
                color: color,
                assetName: Resources.assetsImagesChatRepresentativeSvg,
              ),
            ),
          _MessageDatetime(
            dateTime: message.createdAt,
            color: color,
          ),
          if (isCurrentUser)
            _MessageStatusWidget(
              status: message.status,
              color: color,
            ),
        ],
      );
}

class _ChatIcon extends StatelessWidget {
  const _ChatIcon({
    Key? key,
    this.color,
    required this.assetName,
  }) : super(key: key);

  final Color? color;
  final String assetName;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
        assetName,
        width: 8,
        height: 8,
        color: color ??
            BrightnessData.dynamicColor(
              context,
              const Color.fromRGBO(131, 145, 158, 1),
              darkColor: const Color.fromRGBO(128, 131, 134, 1),
            ),
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
  const _MessageStatusWidget({Key? key, required this.status, this.color})
      : super(key: key);

  final MessageStatus status;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    var assetName = Resources.assetsImagesSendingSvg;
    var color = this.color ?? BrightnessData.themeOf(context).secondaryText;
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
