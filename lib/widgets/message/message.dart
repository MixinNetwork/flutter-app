import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../blaze/vo/pin_message_minimal.dart';
import '../../constants/resources.dart';
import '../../db/extension/message_category.dart';
import '../../db/mixin_database.dart' hide Offset, Message;
import '../../enum/message_category.dart';
import '../../enum/message_status.dart';
import '../../ui/home/bloc/blink_cubit.dart';
import '../../ui/home/bloc/conversation_cubit.dart';
import '../../ui/home/bloc/quote_message_cubit.dart';
import '../../ui/home/bloc/recall_message_bloc.dart';
import '../../ui/home/hook/pin_message.dart';
import '../../utils/datetime_format_utils.dart';
import '../../utils/extension/extension.dart';
import '../../utils/hook.dart';
import '../action_button.dart';
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
import 'item/pin_message.dart';
import 'item/post_message.dart';
import 'item/recall_message.dart';
import 'item/secret_message.dart';
import 'item/sticker_message.dart';
import 'item/stranger_message.dart';
import 'item/system_message.dart';
import 'item/text/text_message.dart';
import 'item/transcript_message.dart';
import 'item/transfer_message.dart';
import 'item/unknown_message.dart';
import 'item/video_message.dart';
import 'item/waiting_message.dart';
import 'message_day_time.dart';
import 'message_name.dart';

class _MessageIsTranscript extends Equatable {
  const _MessageIsTranscript(this.isTranscript);

  final bool isTranscript;

  @override
  List<Object?> get props => [isTranscript];
}

extension MessageIsTranscriptExtension on BuildContext {
  bool get isTranscript {
    try {
      return read<_MessageIsTranscript>().isTranscript;
    } catch (e) {
      return false;
    }
  }
}

const _pinArrowWidth = 32.0;

class MessageItemWidget extends HookWidget {
  const MessageItemWidget({
    Key? key,
    required this.message,
    this.prev,
    this.next,
    this.lastReadMessageId,
    this.isTranscript = false,
    this.blink = true,
    this.pinned = false,
  }) : super(key: key);

  final MessageItem message;
  final MessageItem? prev;
  final MessageItem? next;
  final String? lastReadMessageId;
  final bool isTranscript;
  final bool blink;
  final bool pinned;

  static const primaryFontSize = 16.0;
  static const secondaryFontSize = 14.0;
  static const tertiaryFontSize = 12.0;

  static const statusFontSize = 10.0;

  @override
  Widget build(BuildContext context) {
    final isCurrentUser = message.relationship == UserRelationship.me;

    final sameDayPrev = isSameDay(prev?.createdAt, message.createdAt);
    final prevIsSystem = prev?.type.isSystem ?? false;
    final sameUserPrev = !prevIsSystem && prev?.userId == message.userId;

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
        if (state.messageId == message.messageId && blink) return state.color;
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

              if (message.type.isPin) {
                return PinMessageWidget(
                  showNip: showNip,
                  isCurrentUser: isCurrentUser,
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
                pinArrowWidth: pinned ? _pinArrowWidth : 0,
                buildMenus: () => [
                  if (!isTranscript && message.type.canReply && !pinned)
                    ContextMenu(
                      title: context.l10n.reply,
                      onTap: () =>
                          context.read<QuoteMessageCubit>().emit(message),
                    ),
                  if (!isTranscript &&
                      message.type.canReply &&
                      const [
                        MessageStatus.delivered,
                        MessageStatus.read,
                        MessageStatus.sent
                      ].contains(message.status))
                    _PinMenu(message: message),
                  if (!isTranscript && message.canForward)
                    ContextMenu(
                      title: context.l10n.forward,
                      onTap: () async {
                        final result = await showConversationSelector(
                          context: context,
                          singleSelect: true,
                          title: context.l10n.forward,
                          onlyContact: false,
                        );
                        if (result.isEmpty) return;
                        await context.accountServer.forwardMessage(
                          message.messageId,
                          result.first.encryptCategory!,
                          conversationId: result.first.conversationId,
                          recipientId: result.first.userId,
                        );
                      },
                    ),
                  if (message.type.isText)
                    ContextMenu(
                      title: context.l10n.copy,
                      onTap: () => Clipboard.setData(
                          ClipboardData(text: message.content)),
                    ),
                  if (!isTranscript &&
                      isCurrentUser &&
                      !message.type.isRecall &&
                      DateTime.now().isBefore(
                          message.createdAt.add(const Duration(minutes: 30))))
                    ContextMenu(
                      title: context.l10n.deleteForEveryone,
                      isDestructiveAction: true,
                      onTap: () async {
                        String? content;
                        if (message.type.isText) {
                          content = message.content;
                        }
                        await context.accountServer.sendRecallMessage(
                            [message.messageId],
                            conversationId: message.conversationId);
                        if (content != null) {
                          context
                              .read<RecallMessageReeditCubit>()
                              .onRecalled(message.messageId, content);
                        }
                      },
                    ),
                  if (!isTranscript)
                    ContextMenu(
                      title: context.l10n.deleteForMe,
                      isDestructiveAction: true,
                      onTap: () => context.accountServer
                          .deleteMessage(message.messageId),
                    ),
                  if (!kReleaseMode)
                    ContextMenu(
                      title: 'Copy message',
                      onTap: () => Clipboard.setData(
                          ClipboardData(text: message.toString())),
                    ),
                ],
                builder: (BuildContext context) {
                  final pinArrow = pinned
                      ? ActionButton(
                          size: 16,
                          name: Resources.assetsImagesPinArrowSvg,
                          onTap: () {
                            context
                                .read<BlinkCubit>()
                                .blinkByMessageId(message.messageId);
                            ConversationCubit.selectConversation(
                              context,
                              message.conversationId,
                              initIndexMessageId: message.messageId,
                            );
                          },
                        )
                      : null;

                  if (message.type.isIllegalMessageCategory ||
                      message.status == MessageStatus.unknown) {
                    return UnknownMessage(
                      showNip: showNip,
                      isCurrentUser: isCurrentUser,
                      message: message,
                    );
                  }

                  if (message.type.isTranscript) {
                    return TranscriptMessageWidget(
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
                      pinArrow: pinArrow,
                    );
                  }

                  if (message.type.isPost) {
                    return PostMessage(
                      showNip: showNip,
                      isCurrentUser: isCurrentUser,
                      message: message,
                      pinArrow: pinArrow,
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
                      pinArrow: pinArrow,
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
                      pinArrow: pinArrow,
                    );
                  }

                  if (message.type.isData) {
                    return FileMessage(
                      showNip: showNip,
                      isCurrentUser: isCurrentUser,
                      message: message,
                      pinArrow: pinArrow,
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
                      pinArrow: pinArrow,
                    );
                  }
                  if (message.type.isSticker) {
                    return StickerMessageWidget(
                      message: message,
                      isCurrentUser: isCurrentUser,
                      pinArrow: pinArrow,
                    );
                  }
                  if (message.type.isImage) {
                    return ImageMessageWidget(
                      showNip: showNip,
                      message: message,
                      isCurrentUser: isCurrentUser,
                      pinArrow: pinArrow,
                    );
                  }
                  if (message.type.isVideo || message.type.isLive) {
                    return VideoMessageWidget(
                      showNip: showNip,
                      message: message,
                      isCurrentUser: isCurrentUser,
                      pinArrow: pinArrow,
                    );
                  }

                  if (message.type.isAudio) {
                    return AudioMessage(
                      showNip: showNip,
                      isCurrentUser: isCurrentUser,
                      message: message,
                      pinArrow: pinArrow,
                    );
                  }
                  if (message.type.isRecall) {
                    return RecallMessage(
                      showNip: showNip,
                      isCurrentUser: isCurrentUser,
                      message: message,
                      pinArrow: pinArrow,
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
          context.accountServer
              .markMentionRead(message.messageId, message.conversationId);
        },
        key: ValueKey(message.messageId),
        child: child,
      );
    }

    return Provider(
      create: (context) => _MessageIsTranscript(isTranscript),
      child: Padding(
        padding: sameUserPrev ? EdgeInsets.zero : const EdgeInsets.only(top: 8),
        child: child,
      ),
    );
  }
}

class _PinMenu extends HookWidget {
  const _PinMenu({
    Key? key,
    required this.message,
  }) : super(key: key);

  final MessageItem message;

  @override
  Widget build(BuildContext context) {
    final role = useMemoizedStream(
      () {
        if (message.conversionCategory == ConversationCategory.contact) {
          return Stream.value(ParticipantRole.owner);
        }
        return context.database.participantDao
            .participantById(
                message.conversationId, context.multiAuthState.currentUserId!)
            .watchSingleOrNull()
            .map((event) => event?.role);
      },
      keys: [message.conversionCategory, message.conversationId],
    ).data;

    if (role == null) return const SizedBox();

    return HookBuilder(builder: (context) {
      final pined = useMemoized(
          () => context
              .watch<PinMessageState>()
              .messageIds
              .contains(message.messageId),
          [message.messageId]);

      return ContextMenu(
        title: pined ? context.l10n.unPin : context.l10n.pin,
        onTap: () async {
          final pinMessageMinimal = PinMessageMinimal(
            messageId: message.messageId,
            type: message.type,
            content: message.type.isText ? message.content : null,
          );
          if (pined) {
            await context.accountServer.unpinMessage(
              conversationId: message.conversationId,
              pinMessageMinimals: [pinMessageMinimal],
            );
            return;
          }
          await context.accountServer.pinMessage(
            conversationId: message.conversationId,
            pinMessageMinimals: [pinMessageMinimal],
          );
        },
      );
    });
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
    required this.pinArrowWidth,
  }) : super(key: key);

  final bool isCurrentUser;
  final String? userName;
  final String? userId;
  final WidgetBuilder builder;
  final List<Widget> Function() buildMenus;
  final double pinArrowWidth;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(
          left: isCurrentUser ? 65 - pinArrowWidth : 16,
          right: !isCurrentUser ? 65 - pinArrowWidth : 16,
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
        color: context.theme.background,
        padding: const EdgeInsets.symmetric(vertical: 4),
        margin: const EdgeInsets.symmetric(vertical: 6),
        alignment: Alignment.center,
        child: Text(
          context.l10n.unread,
          style: TextStyle(
            color: context.theme.secondaryText,
            fontSize: MessageItemWidget.secondaryFontSize,
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
          AppCardData.fromJson(jsonDecode(content!) as Map<String, dynamic>)
              .shareable);
}
