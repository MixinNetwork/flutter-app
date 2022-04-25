import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';

import '../../bloc/minute_timer_cubit.dart';
import '../../constants/resources.dart';
import '../../db/mixin_database.dart';
import '../../ui/home/bloc/conversation_cubit.dart';
import '../../utils/extension/extension.dart';
import '../../utils/hook.dart';
import '../message_status_icon.dart';
import 'message.dart';

bool _isRepresentative(
  MessageItem message,
  ConversationState? conversation,
  String userId,
) =>
    conversation != null &&
    (conversation.isBot ?? false) &&
    (conversation.user?.userId != message.userId) &&
    (message.userId != userId);

class MessageDatetimeAndStatus extends HookWidget {
  const MessageDatetimeAndStatus({
    Key? key,
    this.color,
  }) : super(key: key);

  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isTranscriptPage = useIsTranscriptPage();
    final isPinnedPage = useIsPinnedPage();
    final isCurrentUser = useIsCurrentUser();
    final pinned = useMessageConverter(converter: (state) => state.pinned);
    final isSecret = useMessageConverter(converter: (state) => state.isSecret);
    final isRepresentative = useMessageConverter(
        converter: (state) => _isRepresentative(
              state,
              context.read<ConversationCubit>().state,
              context.accountServer.userId,
            ));
    final createdAt =
        useMessageConverter(converter: (state) => state.createdAt);

    return SizedBox(
      height: 12,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pinned)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: _ChatIcon(
                color: color,
                assetName: Resources.assetsImagesMessagePinSvg,
              ),
            ),
          if (isSecret)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: _ChatIcon(
                color: color,
                assetName: Resources.assetsImagesMessageSecretSvg,
              ),
            ),
          if (isRepresentative)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: _ChatIcon(
                color: color,
                assetName: Resources.assetsImagesMessageRepresentativeSvg,
              ),
            ),
          _MessageDatetime(
            dateTime: createdAt,
            color: color,
          ),
          if (isCurrentUser && !isTranscriptPage && !isPinnedPage)
            HookBuilder(builder: (context) {
              final status =
                  useMessageConverter(converter: (state) => state.status);
              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: MessageStatusIcon(
                  status: status,
                  color: color,
                ),
              );
            }),
        ],
      ),
    );
  }
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
            context.dynamicColor(
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
        fontSize: MessageItemWidget.statusFontSize,
        color: color ??
            context.dynamicColor(
              const Color.fromRGBO(131, 145, 158, 1),
              darkColor: const Color.fromRGBO(128, 131, 134, 1),
            ),
      ),
    );
  }
}
