import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/bloc/bloc_converter.dart';
import 'package:flutter_app/bloc/paging/paging_bloc.dart';
import 'package:flutter_app/db/mixin_database.dart' hide Offset, Message;
import 'package:flutter_app/enum/message_category.dart';
import 'package:flutter_app/ui/home/bloc/message_bloc.dart';
import 'package:flutter_app/ui/home/bloc/multi_auth_cubit.dart';
import 'package:flutter_app/utils/datetime_format_utils.dart';
import 'package:flutter_app/widgets/dialog.dart';
import 'package:flutter_app/widgets/interacter_decorated_box.dart';
import 'package:flutter_app/widgets/message/item/sticker_message.dart';
import 'package:flutter_app/widgets/message/item/stranger_message.dart';
import 'package:flutter_app/widgets/message/item/text_message.dart';
import 'package:flutter_app/widgets/message/message_bubble_margin.dart';
import 'package:flutter_app/widgets/message/message_day_time.dart';
import 'package:flutter_app/widgets/message/message_name.dart';
import 'package:tuple/tuple.dart';
import 'package:flutter_app/generated/l10n.dart';
import 'package:flutter_app/db/extension/message_category.dart';

class MessageItemWidget extends StatelessWidget {
  const MessageItemWidget({
    Key key,
    this.index,
  }) : super(key: key);

  final int index;

  @override
  Widget build(BuildContext context) {
    final authId = MultiAuthCubit.of(context).state.current.account.userId;
    return BlocConverter<MessageBloc, PagingState<MessageItem>,
        Tuple3<MessageItem, MessageItem, MessageItem>>(
      converter: (state) {
        final message = state.map[index];
        final prev = state.map[index - 1];
        final next = state.map[index + 1];

        return Tuple3(prev, message, next);
      },
      builder: (context, Tuple3<MessageItem, MessageItem, MessageItem> tuple) {
        final message = tuple.item2;
        final prev = tuple.item1;
        final next = tuple.item3;

        if (message == null) return const SizedBox(height: 40);

        final isCurrentUser = message.userId == authId;

        final sameDayPrev = isSameDay(prev?.createdAt, message.createdAt);
        final sameUserPrev = prev?.userId == message.userId;
        final sameUserNext = next?.userId == message.userId;

        final showNip = !(sameUserPrev && sameDayPrev);
        final sameDayNext = isSameDay(next?.createdAt, message.createdAt);
        final datetime = sameDayNext ? null : message.createdAt;
        final user = !isCurrentUser && (!sameUserNext || !sameDayNext)
            ? message.userFullName
            : null;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (datetime != null) MessageDayTime(dateTime: datetime),
            Builder(
              builder: (context) {
                if (message.type == MessageCategory.stranger)
                  return StrangerMessage(
                    message: message,
                  );

                return _MessageBubbleMargin(
                  userName: user,
                  isCurrentUser: isCurrentUser,
                  builder: (BuildContext context) {
                    if (message.type.isSticker)
                      return StickerMessageWidget(
                        message: message,
                        isCurrentUser: isCurrentUser,
                      );
                    return TextMessage(
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
      },
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
