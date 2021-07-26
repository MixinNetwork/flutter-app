import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../account/account_server.dart';
import '../../db/extension/message_category.dart';
import '../../db/mixin_database.dart' hide Offset, Message;
import '../../enum/message_category.dart';
import '../../enum/message_status.dart';
import '../../generated/l10n.dart';
import '../../ui/home/bloc/blink_cubit.dart';
import '../../ui/home/bloc/conversation_cubit.dart';
import '../../ui/home/bloc/quote_message_cubit.dart';
import '../../utils/datetime_format_utils.dart';
import '../../utils/hook.dart';
import '../brightness_observer.dart';
import '../menu.dart';
import '../user_selector/conversation_selector.dart';
import 'item/action/action_message.dart';
import 'item/action_card/action_card_data.dart';
import 'item/action_card/action_message.dart';
import 'item/audio_message.dart';
import 'item/contact_message_widget.dart';
import 'item/file_message.dart';
import 'item/image/image_message.dart';
import 'item/location/location_message_widget.dart';
import 'item/post_message.dart';
import 'item/recall_message.dart';
import 'item/secret_message.dart';
import 'item/sticker_message.dart';
import 'item/stranger_message.dart';
import 'item/system_message.dart';
import 'item/text/text_message.dart';
import 'item/transfer_message.dart';
import 'item/unknown_message.dart';
import 'item/video_message.dart';
import 'item/waiting_message.dart';
import 'message_day_time.dart';
import 'message_name.dart';

class MessageItemWidget extends HookWidget {
  const MessageItemWidget({
    Key? key,
    required this.message,
    this.prev,
    this.next,
    this.lastReadMessageId,
  }) : super(key: key);

  final MessageItem message;
  final MessageItem? prev;
  final MessageItem? next;
  final String? lastReadMessageId;

  @override
  Widget build(BuildContext context) {
    final isCurrentUser = message.relationship == UserRelationship.me;

    final sameDayPrev = isSameDay(prev?.createdAt, message.createdAt);
    final sameUserPrev = prev?.userId == message.userId;

    final sameDayNext = isSameDay(next?.createdAt, message.createdAt);
    final sameUserNext = next?.userId == message.userId;

    final showNip = !(sameUserNext && sameDayNext);
    final datetime = sameDayPrev ? null : message.createdAt;
    String? userName;
    String? userId;

    if ((message.conversionCategory == ConversationCategory.group ||
            message.userId != message.conversationOwnerId) &&
        !isCurrentUser &&
        (!sameUserPrev || !sameDayPrev)) {
      userName = message.userFullName;
      userId = message.userId;
    }

    final blinkColor = useBlocStateConverter<BlinkCubit, BlinkState, Color>(
      converter: (state) {
        if (state.messageId == message.messageId) return state.color;
        return Colors.transparent;
      },
    );

    final child = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (datetime != null) MessageDayTime(dateTime: datetime),
        ColoredBox(
          color: blinkColor,
          child: Builder(
            builder: (context) {
              if (message.type == MessageCategory.systemConversation) {
                return SystemMessage(
                  message: message,
                );
              }

              if (message.type == MessageCategory.secret) {
                return const SecretMessage();
              }

              if (message.type == MessageCategory.stranger) {
                return StrangerMessage(
                  message: message,
                );
              }

              return _MessageBubbleMargin(
                userName: userName,
                userId: userId,
                isCurrentUser: isCurrentUser,
                buildMenus: () => [
                  if (message.type.isText ||
                      message.type.isImage ||
                      message.type.isVideo ||
                      message.type.isLive ||
                      message.type.isData ||
                      message.type.isPost ||
                      message.type.isLocation ||
                      message.type.isAudio ||
                      message.type.isSticker ||
                      message.type.isContact ||
                      message.type == MessageCategory.appCard ||
                      message.type == MessageCategory.appButtonGroup)
                    ContextMenu(
                      title: Localization.of(context).reply,
                      onTap: () =>
                          context.read<QuoteMessageCubit>().emit(message),
                    ),
                  if (message.canForward)
                    ContextMenu(
                      title: Localization.of(context).forward,
                      onTap: () async {
                        final result = await showConversationSelector(
                          context: context,
                          singleSelect: true,
                          title: Localization.of(context).forward,
                          onlyContact: false,
                        );
                        if (result.isEmpty) return;
                        await context.read<AccountServer>().forwardMessage(
                              message.messageId,
                              isPlain(result.first.isGroup, result.first.isBot),
                              conversationId: result.first.conversationId,
                              recipientId: result.first.userId,
                            );
                      },
                    ),
                  if (message.type.isText)
                    ContextMenu(
                      title: Localization.of(context).copy,
                      onTap: () => Clipboard.setData(
                          ClipboardData(text: message.content)),
                    ),
                  if (isCurrentUser &&
                      !message.type.isRecall &&
                      DateTime.now().isBefore(
                          message.createdAt.add(const Duration(minutes: 30))))
                    ContextMenu(
                      title: Localization.of(context).deleteForEveryone,
                      isDestructiveAction: true,
                      onTap: () => context
                          .read<AccountServer>()
                          .sendRecallMessage([message.messageId],
                              conversationId: message.conversationId),
                    ),
                  ContextMenu(
                    title: Localization.of(context).deleteForMe,
                    isDestructiveAction: true,
                    onTap: () => context
                        .read<AccountServer>()
                        .deleteMessage(message.messageId),
                  ),
                ],
                builder: (BuildContext context) {
                  if (message.type.isIllegalMessageCategory) {
                    return UnknownMessage(
                      showNip: showNip,
                      isCurrentUser: isCurrentUser,
                      message: message,
                    );
                  }
                  if (message.type.isLocation) {
                    return LocationMessageWidget(
                      showNip: showNip,
                      isCurrentUser: isCurrentUser,
                      message: message,
                    );
                  }

                  if (message.type.isPost) {
                    return PostMessage(
                      showNip: showNip,
                      isCurrentUser: isCurrentUser,
                      message: message,
                    );
                  }

                  if (message.type == MessageCategory.systemAccountSnapshot) {
                    return TransferMessage(
                      showNip: showNip,
                      isCurrentUser: isCurrentUser,
                      message: message,
                    );
                  }

                  if (message.type.isContact) {
                    return ContactMessageWidget(
                      showNip: showNip,
                      isCurrentUser: isCurrentUser,
                      message: message,
                    );
                  }

                  if (message.type == MessageCategory.appButtonGroup) {
                    return ActionMessage(
                      isCurrentUser: isCurrentUser,
                      message: message,
                    );
                  }

                  if (message.type == MessageCategory.appCard) {
                    return ActionCardMessage(
                      showNip: showNip,
                      isCurrentUser: isCurrentUser,
                      message: message,
                    );
                  }

                  if (message.type.isData) {
                    return FileMessage(
                      showNip: showNip,
                      isCurrentUser: isCurrentUser,
                      message: message,
                    );
                  }
                  if (message.status == MessageStatus.failed) {
                    return WaitingMessage(
                      showNip: showNip,
                      isCurrentUser: isCurrentUser,
                      message: message,
                    );
                  }
                  if (message.type.isText) {
                    return TextMessage(
                      showNip: showNip,
                      isCurrentUser: isCurrentUser,
                      message: message,
                    );
                  }
                  if (message.type.isSticker) {
                    return StickerMessageWidget(
                      message: message,
                      isCurrentUser: isCurrentUser,
                    );
                  }
                  if (message.type.isImage) {
                    return ImageMessageWidget(
                      showNip: showNip,
                      message: message,
                      isCurrentUser: isCurrentUser,
                    );
                  }
                  if (message.type.isVideo || message.type.isLive) {
                    return VideoMessageWidget(
                      showNip: showNip,
                      message: message,
                      isCurrentUser: isCurrentUser,
                    );
                  }
                  if (message.type.notSupportedYet) {
                    return NotSupportedMessage(
                      showNip: showNip,
                      isCurrentUser: isCurrentUser,
                      message: message,
                    );
                  }
                  if (message.type.isRecall) {
                    return RecallMessage(
                      showNip: showNip,
                      isCurrentUser: isCurrentUser,
                      message: message,
                    );
                  }
                  return UnknownMessage(
                    showNip: showNip,
                    isCurrentUser: isCurrentUser,
                    message: message,
                  );
                },
              );
            },
          ),
        ),
        if (message.messageId == lastReadMessageId && next != null)
          const _UnreadMessageBar(),
      ],
    );

    if (message.mentionRead == false) {
      return VisibilityDetector(
        onVisibilityChanged: (VisibilityInfo info) {
          if (info.visibleFraction < 1) return;
          context
              .read<AccountServer>()
              .markMentionRead(message.messageId, message.conversationId);
        },
        key: ValueKey(message.messageId),
        child: child,
      );
    }

    return Padding(
      padding: sameUserPrev ? EdgeInsets.zero : const EdgeInsets.only(top: 8),
      child: child,
    );
  }
}

class _MessageBubbleMargin extends StatelessWidget {
  const _MessageBubbleMargin({
    Key? key,
    required this.isCurrentUser,
    required this.userName,
    required this.userId,
    required this.builder,
    required this.buildMenus,
  }) : super(key: key);

  final bool isCurrentUser;
  final String? userName;
  final String? userId;
  final WidgetBuilder builder;
  final List<ContextMenu> Function() buildMenus;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(
          left: isCurrentUser ? 65 : 16,
          right: !isCurrentUser ? 65 : 16,
          top: 2,
          bottom: 2,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (userName != null && userId != null)
              MessageName(
                userName: userName!,
                userId: userId!,
              ),
            ContextMenuPortalEntry(
              buildMenus: buildMenus,
              child: Builder(builder: builder),
            ),
          ],
        ),
      );
}

class _UnreadMessageBar extends StatelessWidget {
  const _UnreadMessageBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Container(
        color: BrightnessData.themeOf(context).background,
        padding: const EdgeInsets.symmetric(vertical: 4),
        margin: const EdgeInsets.symmetric(vertical: 6),
        alignment: Alignment.center,
        child: Text(
          Localization.of(context).unread,
          style: TextStyle(
            color: BrightnessData.themeOf(context).secondaryText,
            fontSize: 14,
          ),
        ),
      );
}

extension _MessageForward on MessageItem {
  bool get canForward =>
      type.isText ||
      type.isImage ||
      type.isVideo ||
      type.isAudio ||
      type.isData ||
      type.isSticker ||
      type.isContact ||
      type.isLive ||
      type.isPost ||
      type.isLocation ||
      (type == MessageCategory.appCard &&
          AppCardData.fromJson(jsonDecode(content!)).shareable);
}
