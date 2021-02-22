import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/db/mixin_database.dart' hide Offset, Message;
import 'package:flutter_app/enum/message_category.dart';
import 'package:flutter_app/enum/message_status.dart';
import 'package:flutter_app/utils/datetime_format_utils.dart';
import 'package:flutter_app/widgets/dialog.dart';
import 'package:flutter_app/widgets/interacter_decorated_box.dart';
import 'package:flutter_app/widgets/message/item/sticker_message.dart';
import 'package:flutter_app/widgets/message/item/stranger_message.dart';
import 'package:flutter_app/widgets/message/item/text_message.dart';
import 'package:flutter_app/widgets/message/message_bubble_margin.dart';
import 'package:flutter_app/widgets/message/message_day_time.dart';
import 'package:flutter_app/widgets/message/message_name.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:flutter_app/generated/l10n.dart';
import 'package:flutter_app/db/extension/message_category.dart';

import 'item/action/action_message.dart';
import 'item/file_message.dart';
import 'item/secret_message.dart';
import 'item/system_message.dart';
import 'item/unknown_message.dart';
import 'item/waiting_message.dart';

class MessageItemWidget extends StatelessWidget {
  const MessageItemWidget({
    Key key,
    this.message,
    this.prev,
    this.next,
  }) : super(key: key);

  final MessageItem message;
  final MessageItem prev;
  final MessageItem next;

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox(height: 40);

    final isCurrentUser = message.relationship == UserRelationship.me;

    final sameDayPrev = isSameDay(prev?.createdAt, message.createdAt);
    final sameUserPrev = prev?.userId == message.userId;

    final sameDayNext = isSameDay(next?.createdAt, message.createdAt);
    final sameUserNext = next?.userId == message.userId;

    final showNip = !(sameUserNext && sameDayNext);
    final datetime = sameDayPrev ? null : message.createdAt;
    final user = !isCurrentUser && (!sameUserPrev || !sameDayPrev)
        ? message.userFullName
        : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (datetime != null) MessageDayTime(dateTime: datetime),
        Builder(
          builder: (context) {
            if (message.type == MessageCategory.appButtonGroup)
              return ActionMessage(
                message: MessageItem(
                  content: message.content,
                ),
              );

            if (message.type == MessageCategory.systemConversation)
              return SystemMessage(
                message: message,
              );

            if (message.type == MessageCategory.secret) return SecretMessage();

            if (message.type == MessageCategory.stranger)
              return StrangerMessage(
                message: message,
              );

            return _MessageBubbleMargin(
              userName: user,
              isCurrentUser: isCurrentUser,
              builder: (BuildContext context) {
                if (message.type.isData)
                  return FileMessage(
                    showNip: showNip,
                    isCurrentUser: isCurrentUser,
                    message: message,
                  );
                if (message.status == MessageStatus.failed)
                  return WaitingMessage(
                    showNip: showNip,
                    isCurrentUser: isCurrentUser,
                    message: message,
                  );
                if (message.type.isText)
                  return TextMessage(
                    showNip: showNip,
                    isCurrentUser: isCurrentUser,
                    message: message,
                  );
                if (message.type.isSticker)
                  return StickerMessageWidget(
                    message: message,
                    isCurrentUser: isCurrentUser,
                  );
                return UnknownMessage(
                  showNip: showNip,
                  isCurrentUser: isCurrentUser,
                  message: message,
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _MessageBubbleMargin extends StatelessWidget {
  const _MessageBubbleMargin({
    Key key,
    @required this.isCurrentUser,
    @required this.userName,
    @required this.builder,
  }) : super(key: key);

  final bool isCurrentUser;
  final String userName;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return MessageBubbleMargin(
      isCurrentUser: isCurrentUser,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (userName != null) MessageName(userName: userName),
          InteractableDecoratedBox(
            onRightClick: (pointerUpEvent) => showContextMenu(
              context: context,
              pointerPosition: pointerUpEvent.position,
              menus: [
                ContextMenu(
                  title: Localization.of(context).reply,
                ),
                ContextMenu(
                  title: Localization.of(context).forward,
                ),
                ContextMenu(
                  title: Localization.of(context).copy,
                ),
                ContextMenu(
                  title: Localization.of(context).delete,
                  isDestructiveAction: true,
                ),
              ],
            ),
            child: Builder(builder: builder),
          ),
        ],
      ),
    );
  }
}
