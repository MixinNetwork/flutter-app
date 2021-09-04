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

import '../../db/extension/message_category.dart';
import '../../db/mixin_database.dart' hide Offset, Message;
import '../../enum/message_category.dart';
import '../../enum/message_status.dart';
import '../../ui/home/bloc/blink_cubit.dart';
import '../../ui/home/bloc/quote_message_cubit.dart';
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

class MessageItemWidget extends HookWidget {
  const MessageItemWidget({
    Key? key,
    required this.message,
    this.prev,
    this.next,
    this.lastReadMessageId,
    this.isTranscript = false,
  }) : super(key: key);

  final MessageItem message;
  final MessageItem? prev;
  final MessageItem? next;
  final String? lastReadMessageId;
  final bool isTranscript;

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
                  if (!isTranscript &&
                      (message.type.isText ||
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
                          message.type == MessageCategory.appButtonGroup))
                    ContextMenu(
                      title: context.l10n.reply,
                      onTap: () =>
                          context.read<QuoteMessageCubit>().emit(message),
                    ),
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
                      onTap: () => context.accountServer.sendRecallMessage(
                          [message.messageId],
                          conversationId: message.conversationId),
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
                // MessageItem(messageId: 53e5f2b4-1c75-4f7e-8292-8e51cf9f60e9, conversationId: 68a31f2a-daed-4208-8e89-f2d59b19f3df, userId: 0cff62ca-f654-46af-a7fe-2c8089d6755d, conversationOwnerId: 0cff62ca-f654-46af-a7fe-2c8089d6755d, conversionCategory: ConversationCategory.group, userFullName: YeungKC, userIdentityNumber: 1092176, appId: null, type: SIGNAL_TRANSCRIPT, content: [{"user_full_name":"YeungKC","category":"SIGNAL_IMAGE","message_id":"3baf4049-f26c-4099-95a8-9dbdd6cf90a8","media_mime_type":"image\/png","media_key":"49+MTMeIGU2hN\/zyjYxTeAw9bFbNYlcfFjRf9m9w4rkeEAWKsEcR3QTWN799qbaJkq2xii1dEoTjlLJLa3moTQ==","transcript_id":"53e5f2b4-1c75-4f7e-8292-8e51cf9f60e9","created_at":"2021-08-14T11:01:22.519457Z","media_width":1662,"thumb_image":"L268Q._44T00tkozs:njD$WBoft7","user_id":"0cff62ca-f654-46af-a7fe-2c8089d6755d","media_digest":"RjUpCXpxb5fRSIXB5pC353IRfaAezRS16SX\/Ff0VjBA=","media_height":1724,"media_created_at":"2021-08-18T08:44:47.801539484Z","quote_id":"","media_size":720009,"content":"3c837c03-da43-4c9b-af73-c16b1434b43a"},{"category":"SIGNAL_STICKER","user_full_name":"YeungKC","media_height":360,"sticker_id":"cf6bd6cd-aac2-437c-b0dd-9c8aa787e733","created_at":"2021-08-14T16:21:11.359895Z","message_id":"5d8b02d4-6ac9-436e-aa0d-99d7a4d01d70","media_width":360,"user_id":"0cff62ca-f654-46af-a7fe-2c8089d6755d","transcript_id":"53e5f2b4-1c75-4f7e-8292-8e51cf9f60e9"},{"category":"SIGNAL_TEXT","user_full_name":"YeungKC","content":"test","created_at":"2021-08-18T08:44:26.193449Z","message_id":"8b4d4ab6-ff8b-44ac-8c47-79a481f60412","user_id":"0cff62ca-f654-46af-a7fe-2c8089d6755d","transcript_id":"53e5f2b4-1c75-4f7e-8292-8e51cf9f60e9"},{"category":"SIGNAL_TEXT","user_full_name":"YeungKC","content":"test","quote_content":"{\"user_full_name\":\"YeungKC\",\"message_id\":\"3baf4049-f26c-4099-95a8-9dbdd6cf90a8\",\"media_mime_type\":\"image\\\/png\",\"media_size\":720009,\"created_at\":\"2021-08-14T11:01:22.519457Z\",\"media_width\":1662,\"thumb_image\":\"L268Q._34T00b]ozxar]D$R%ofxu\",\"user_id\":\"0cff62ca-f654-46af-a7fe-2c8089d6755d\",\"conversation_id\":\"68a31f2a-daed-4208-8e89-f2d59b19f3df\",\"type\":\"SIGNAL_IMAGE\",\"media_status\":\"DONE\",\"user_avatar_url\":\"https:\\\/\\\/mixin-images.zeromesh.net\\\/MHmwRoQaZ5WbVK7lkTHHfEJZ6ec3iOo8Lnwr5mdCRmV6wsIxnI1cb3HLLnPCsHJE8G03PuzqzL0rQCsXgTjw5NMWWWa79ZcWDpMn=s256\",\"media_url\":\"3baf4049-f26c-4099-95a8-9dbdd6cf90a8.png\",\"media_height\":1724,\"user_identity_number\":\"1092176\",\"media_duration\":\"0\",\"status\":\"DELIVERED\",\"content\":\"eyJjcmVhdGVkX2F0IjoiMjAyMS0wOC0xNFQxMTowMToxOS41NjYyNTQ3ODhaIiwiYXR0YWNobWVudF9pZCI6ImY3MTVmZjcwLTU3OWQtNDA3Yy04MzM0LTRkYWZhZTA4MjYwNCJ9\"}","created_at":"2021-08-16T10:37:48.031632Z","message_id":"dc7b87ad-f10e-40c3-9d4e-bc32e11f98bd","user_id":"0cff62ca-f654-46af-a7fe-2c8089d6755d","quote_id":"3baf4049-f26c-4099-95a8-9dbdd6cf90a8","transcript_id":"53e5f2b4-1c75-4f7e-8292-8e51cf9f60e9"},{"category":"SIGNAL_TEXT","user_full_name":"YeungKC","content":"test","quote_content":"{\"status\":\"SENT\",\"user_full_name\":\"YeungKC\",\"content\":\"test\",\"message_id\":\"dc7b87ad-f10e-40c3-9d4e-bc32e11f98bd\",\"created_at\":\"2021-08-16T10:37:48.031632Z\",\"conversation_id\":\"68a31f2a-daed-4208-8e89-f2d59b19f3df\",\"user_id\":\"0cff62ca-f654-46af-a7fe-2c8089d6755d\",\"type\":\"SIGNAL_TEXT\",\"user_avatar_url\":\"https:\\\/\\\/mixin-images.zeromesh.net\\\/MHmwRoQaZ5WbVK7lkTHHfEJZ6ec3iOo8Lnwr5mdCRmV6wsIxnI1cb3HLLnPCsHJE8G03PuzqzL0rQCsXgTjw5NMWWWa79ZcWDpMn=s256\",\"user_identity_number\":\"1092176\",\"media_duration\":\"0\"}","created_at":"2021-08-16T10:37:53.791761Z","message_id":"f9fdfea4-494e-4ae3-9efb-d20ac61a3d49","user_id":"0cff62ca-f654-46af-a7fe-2c8089d6755d","quote_id":"dc7b87ad-f10e-40c3-9d4e-bc32e11f98bd","transcript_id":"53e5f2b4-1c75-4f7e-8292-8e51cf9f60e9"}], createdAt: 2021-08-18 08:44:53.162Z, status: MessageStatus.sent, mediaStatus: null, mediaWaveform: null, mediaName: null, mediaMimeType: null, mediaSize: null, mediaWidth: null, mediaHeight: null, thumbImage: null, thumbUrl: null, mediaUrl: null, mediaDuration: null, quoteId: null, quoteContent: null, participantFullName: null, actionName: null, participantUserId: null, snapshotId: null, snapshotType: null, snapshotAmount: null, assetSymbol: null, assetId: null, assetIcon: null, assetUrl: null, assetWidth: null, assetHeight: null, stickerId: null, assetName: null, assetType: null, siteName: null, siteTitle: null, siteDescription: null, siteImage: null, sharedUserId: null, sharedUserFullName: null, sharedUserIdentityNumber: null, sharedUserAvatarUrl: null, sharedUserIsVerified: null, sharedUserAppId: null, mentionRead: null, groupName: test attachment, relationship: UserRelationship.me, avatarUrl: https://mixin-images.zeromesh.net/MHmwRoQaZ5WbVK7lkTHHfEJZ6ec3iOo8Lnwr5mdCRmV6wsIxnI1cb3HLLnPCsHJE8G03PuzqzL0rQCsXgTjw5NMWWWa79ZcWDpMn=s256)
                builder: (BuildContext context) {
                  if (message.type.isIllegalMessageCategory) {
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

                  if (message.type.isAudio) {
                    return AudioMessage(
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
