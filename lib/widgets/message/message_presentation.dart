import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import '../../db/mixin_database.dart';
import 'message_rows.dart';

class MessagePresentation {
  const MessagePresentation({
    required this.isCurrentUser,
    required this.isGroupOrBotGroupConversation,
    required this.showAvatar,
    required this.showNip,
    required this.showUnreadBar,
    this.userName,
    this.userId,
    this.userAvatarUrl,
  });

  factory MessagePresentation.fromRow({
    required MessageRowModel row,
    required bool isGroupOrBotGroupConversation,
    required bool enableShowAvatar,
    required bool canShowUnreadBar,
    required String? lastReadMessageId,
  }) {
    final message = row.message;
    final isCurrentUser = message.relationship == UserRelationship.me;
    final showAvatar = isGroupOrBotGroupConversation && enableShowAvatar;
    final showNip =
        !(row.sameUserNext && row.sameDayNext) &&
        (!showAvatar || isCurrentUser);
    final showSender =
        isGroupOrBotGroupConversation &&
        !isCurrentUser &&
        (!row.sameUserPrev || !row.sameDayPrev);

    return MessagePresentation(
      isCurrentUser: isCurrentUser,
      isGroupOrBotGroupConversation: isGroupOrBotGroupConversation,
      showAvatar: showAvatar,
      showNip: showNip,
      showUnreadBar:
          canShowUnreadBar &&
          message.messageId == lastReadMessageId &&
          row.next != null,
      userName: showSender ? message.userFullName : null,
      userId: showSender ? message.userId : null,
      userAvatarUrl: showSender ? message.avatarUrl : null,
    );
  }

  final bool isCurrentUser;
  final bool isGroupOrBotGroupConversation;
  final bool showAvatar;
  final bool showNip;
  final bool showUnreadBar;
  final String? userName;
  final String? userId;
  final String? userAvatarUrl;
}

bool resolveGroupOrBotGroupConversation({
  required MessageItem message,
  required bool isBotGroupConversation,
}) =>
    message.conversionCategory == ConversationCategory.group ||
    message.userId != message.conversationOwnerId ||
    isBotGroupConversation;
