import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../constants/resources.dart';
import '../../db/mixin_database.dart';
import '../../ui/provider/conversation_provider.dart';
import '../../utils/extension/extension.dart';
import '../message_status_icon.dart';
import 'message.dart';
import 'message_style.dart';

bool _isRepresentative(
  MessageItem message,
  ConversationState? conversation,
  String userId,
) =>
    conversation != null &&
    (conversation.isBot ?? false) &&
    (conversation.user?.userId != message.userId) &&
    (message.userId != userId);

class MessageDatetimeAndStatus extends HookConsumerWidget {
  const MessageDatetimeAndStatus(
      {super.key, this.color, this.hideStatus = false});

  final Color? color;
  final bool hideStatus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTranscriptPage = useIsTranscriptPage();
    final isPinnedPage = useIsPinnedPage();
    final isCurrentUser = useIsCurrentUser();
    final pinned = useMessageConverter(converter: (state) => state.pinned);
    final isSecret = useMessageConverter(converter: (state) => state.isSecret);
    final isRepresentative = useMessageConverter(
        converter: (state) => _isRepresentative(
              state,
              ref.read(conversationProvider),
              context.accountServer.userId,
            ));
    final createdAt =
        useMessageConverter(converter: (state) => state.createdAt);

    return SelectionContainer.disabled(
      child: SizedBox(
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
            if (isCurrentUser &&
                !isTranscriptPage &&
                !isPinnedPage &&
                !hideStatus)
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
      ),
    );
  }
}

class _ChatIcon extends StatelessWidget {
  const _ChatIcon({
    this.color,
    required this.assetName,
  });

  final Color? color;
  final String assetName;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
        assetName,
        width: 8,
        height: 8,
        colorFilter: ColorFilter.mode(
          color ??
              context.dynamicColor(
                const Color.fromRGBO(131, 145, 158, 1),
                darkColor: const Color.fromRGBO(128, 131, 134, 1),
              ),
          BlendMode.srcIn,
        ),
      );
}

class _MessageDatetime extends HookConsumerWidget {
  const _MessageDatetime({
    required this.dateTime,
    this.color,
  });

  final DateTime dateTime;
  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = useMemoized(
        () => DateFormat.Hm().format(dateTime.toLocal()), [dateTime]);

    return Text(
      text,
      style: TextStyle(
        fontSize: context.messageStyle.statusFontSize,
        color: color ??
            context.dynamicColor(
              const Color.fromRGBO(131, 145, 158, 1),
              darkColor: const Color.fromRGBO(128, 131, 134, 1),
            ),
      ),
    );
  }
}
