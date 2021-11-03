import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../blaze/vo/pin_message_minimal.dart';
import '../../bloc/simple_cubit.dart';
import '../../db/mixin_database.dart' hide Offset, Message;
import '../../enum/media_status.dart';
import '../../enum/message_category.dart';
import '../../enum/message_status.dart';
import '../../ui/home/bloc/blink_cubit.dart';
import '../../ui/home/bloc/quote_message_cubit.dart';
import '../../ui/home/bloc/recall_message_bloc.dart';
import '../../utils/datetime_format_utils.dart';
import '../../utils/extension/extension.dart';
import '../../utils/hook.dart';
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
import 'item/transfer/transfer_message.dart';
import 'item/unknown_message.dart';
import 'item/video_message.dart';
import 'item/waiting_message.dart';
import 'message_day_time.dart';
import 'message_name.dart';

class _MessageContextCubit extends SimpleCubit<_MessageContext> {
  _MessageContextCubit(_MessageContext initialState) : super(initialState);
}

class _MessageContext with EquatableMixin {
  _MessageContext({
    required this.isTranscriptPage,
    required this.isPinnedPage,
    required this.showNip,
    required this.isCurrentUser,
    required this.message,
  });

  final bool isTranscriptPage;
  final bool isPinnedPage;
  final bool showNip;
  final bool isCurrentUser;
  final MessageItem message;

  @override
  List<Object?> get props => [
        isTranscriptPage,
        isPinnedPage,
        showNip,
        isCurrentUser,
        message,
      ];
}

bool useIsTranscriptPage() =>
    useBlocStateConverter<_MessageContextCubit, _MessageContext, bool>(
        converter: (state) => state.isTranscriptPage);

bool useIsPinnedPage() =>
    useBlocStateConverter<_MessageContextCubit, _MessageContext, bool>(
        converter: (state) => state.isPinnedPage);

bool useShowNip() =>
    useBlocStateConverter<_MessageContextCubit, _MessageContext, bool>(
        converter: (state) => state.showNip);

bool useIsCurrentUser() =>
    useBlocStateConverter<_MessageContextCubit, _MessageContext, bool>(
        converter: (state) => state.isCurrentUser);

MessageItem useMessage() =>
    useMessageConverter<MessageItem>(converter: (state) => state);

T useMessageConverter<T>({required T Function(MessageItem) converter}) =>
    useBlocStateConverter<_MessageContextCubit, _MessageContext, T>(
        converter: (state) => converter(state.message));

extension MessageContext on BuildContext {
  MessageItem get message => read<_MessageContextCubit>().state.message;
}

const _pinArrowWidth = 32.0;

class MessageItemWidget extends HookWidget {
  const MessageItemWidget({
    Key? key,
    required this.message,
    this.prev,
    this.next,
    this.lastReadMessageId,
    this.isTranscriptPage = false,
    this.blink = true,
    this.isPinnedPage = false,
  }) : super(key: key);

  final MessageItem message;
  final MessageItem? prev;
  final MessageItem? next;
  final String? lastReadMessageId;
  final bool isTranscriptPage;
  final bool blink;
  final bool isPinnedPage;

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

    final showedMenuCubit = useBloc(() => SimpleCubit(false));

    final blinkColor = useMemoizedStream(
          () {
            final blinkCubit = context.read<BlinkCubit>();
            return Rx.combineLatest2(
              blinkCubit.stream.startWith(blinkCubit.state),
              showedMenuCubit.stream.startWith(showedMenuCubit.state),
              (BlinkState blinkState, bool showedMenu) {
                if (showedMenu) return context.theme.listSelected;
                if (blinkState.messageId == message.messageId && blink) {
                  return blinkState.color;
                }
                return Colors.transparent;
              },
            );
          },
          keys: [message.messageId],
        ).data ??
        Colors.transparent;

    Widget child = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (datetime != null) MessageDayTime(dateTime: datetime),
        ColoredBox(
          color: blinkColor,
          child: Builder(
            builder: (context) {
              if (message.type == MessageCategory.systemConversation) {
                return const SystemMessage();
              }

              if (message.type.isPin) {
                return const PinMessageWidget();
              }

              if (message.type == MessageCategory.secret) {
                return const SecretMessage();
              }

              if (message.type == MessageCategory.stranger) {
                return const StrangerMessage();
              }

              return _MessageBubbleMargin(
                userName: userName,
                userId: userId,
                isCurrentUser: isCurrentUser,
                pinArrowWidth: isPinnedPage ? _pinArrowWidth : 0,
                showedMenu: showedMenuCubit.emit,
                buildMenus: () => [
                  if (!isTranscriptPage &&
                      message.type.canReply &&
                      !isPinnedPage)
                    ContextMenu(
                      title: context.l10n.reply,
                      onTap: () =>
                          context.read<QuoteMessageCubit>().emit(message),
                    ),
                  if (!isTranscriptPage &&
                      message.type.canReply &&
                      const [
                        MessageStatus.delivered,
                        MessageStatus.read,
                        MessageStatus.sent
                      ].contains(message.status))
                    _PinMenu(message: message),
                  if (!isTranscriptPage && message.canForward)
                    ContextMenu(
                      title: context.l10n.forward,
                      onTap: () async {
                        final result = await showConversationSelector(
                          context: context,
                          singleSelect: true,
                          title: context.l10n.forward,
                          onlyContact: false,
                        );
                        if (result == null || result.isEmpty) return;
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
                  if (!isTranscriptPage &&
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
                  if (!isTranscriptPage)
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
                  if (message.type.isIllegalMessageCategory ||
                      message.status == MessageStatus.unknown) {
                    return const UnknownMessage();
                  }

                  if (message.status == MessageStatus.failed) {
                    return const WaitingMessage();
                  }

                  if (message.type.isTranscript) {
                    return const TranscriptMessageWidget();
                  }

                  if (message.type.isLocation) {
                    return const LocationMessageWidget();
                  }

                  if (message.type.isPost) {
                    return const PostMessage();
                  }

                  if (message.type == MessageCategory.systemAccountSnapshot) {
                    return const TransferMessage();
                  }

                  if (message.type.isContact) {
                    return const ContactMessageWidget();
                  }

                  if (message.type == MessageCategory.appButtonGroup) {
                    return const ActionMessage();
                  }

                  if (message.type == MessageCategory.appCard) {
                    return const ActionCardMessage();
                  }

                  if (message.type.isData) {
                    return const FileMessage();
                  }

                  if (message.type.isText) {
                    return const TextMessage();
                  }

                  if (message.type.isSticker) {
                    return const StickerMessageWidget();
                  }

                  if (message.type.isImage) {
                    return const ImageMessageWidget();
                  }

                  if (message.type.isVideo || message.type.isLive) {
                    return const VideoMessageWidget();
                  }

                  if (message.type.isAudio) {
                    return const AudioMessage();
                  }

                  if (message.type.isRecall) {
                    return const RecallMessage();
                  }

                  return const UnknownMessage();
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
      child = VisibilityDetector(
        onVisibilityChanged: (VisibilityInfo info) {
          if (info.visibleFraction < 1) return;
          context.accountServer
              .markMentionRead(message.messageId, message.conversationId);
        },
        key: ValueKey(message.messageId),
        child: child,
      );
    }

    _MessageContext newMessageContext() => _MessageContext(
          isTranscriptPage: isTranscriptPage,
          isPinnedPage: isPinnedPage,
          showNip: showNip,
          isCurrentUser: isCurrentUser,
          message: message,
        );

    final messageContextCubit =
        useBloc(() => _MessageContextCubit(newMessageContext()));

    useEffect(() {
      messageContextCubit.emit(newMessageContext());
    }, [isTranscriptPage, isPinnedPage, showNip, isCurrentUser, message]);

    return Provider.value(
      value: messageContextCubit,
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
            .watchSingleOrNullThrottle()
            .map((event) => event?.role);
      },
      keys: [message.conversionCategory, message.conversationId],
    ).data;

    if (role == null) return const SizedBox();

    return ContextMenu(
      title: message.pinned ? context.l10n.unPin : context.l10n.pin,
      onTap: () async {
        final pinMessageMinimal = PinMessageMinimal(
          messageId: message.messageId,
          type: message.type,
          content: message.type.isText ? message.content : null,
        );
        if (message.pinned) {
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
    this.showedMenu,
  }) : super(key: key);

  final bool isCurrentUser;
  final String? userName;
  final String? userId;
  final WidgetBuilder builder;
  final List<Widget> Function() buildMenus;
  final double pinArrowWidth;
  final ValueChanged<bool>? showedMenu;

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
              showedMenu: showedMenu,
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
              .shareable) ||
      (type.isTranscript && mediaStatus == MediaStatus.done);
}
