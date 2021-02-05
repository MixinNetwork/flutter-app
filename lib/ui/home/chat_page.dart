import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/account/account_server.dart';
import 'package:flutter_app/bloc/bloc_converter.dart';
import 'package:flutter_app/bloc/paging/paging_bloc.dart';
import 'package:flutter_app/constants/resources.dart';
import 'package:flutter_app/db/mixin_database.dart' hide Offset, Message;
import 'package:flutter_app/enum/message_status.dart';
import 'package:flutter_app/ui/home/bloc/conversation_cubit.dart';
import 'package:flutter_app/ui/home/bloc/message_bloc.dart';
import 'package:flutter_app/ui/home/bloc/multi_auth_cubit.dart';
import 'package:flutter_app/utils/datetime_format_utils.dart';
import 'package:flutter_app/utils/dp_utils.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_app/widgets/cache_image.dart';
import 'package:flutter_app/widgets/chat_bar.dart';
import 'package:flutter_app/widgets/dialog.dart';
import 'package:flutter_app/widgets/input_container.dart';
import 'package:flutter_app/widgets/interacter_decorated_box.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:tuple/tuple.dart';
import 'package:flutter_app/generated/l10n.dart';
import 'package:flutter_app/db/extension/message_category.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: BrightnessData.dynamicColor(
            context,
            const Color.fromRGBO(237, 238, 238, 1),
            darkColor: const Color.fromRGBO(35, 39, 43, 1),
          ),
        ),
        child: BlocConverter<ConversationCubit, ConversationItem, bool>(
          converter: (state) => state != null,
          builder: (context, selected) => ChatContainer(
            onPressed: () {},
          ),
        ),
      );
}

class ChatContainer extends StatelessWidget {
  const ChatContainer({
    Key key,
    this.onPressed,
    this.isSelected,
  }) : super(key: key);

  final Function onPressed;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final messagesDao =
        Provider.of<AccountServer>(context).database.messagesDao;
    final windowHeight = MediaQuery.of(context).size.height;
    final itemScrollController = ItemScrollController();
    return BlocProvider(
      create: (context) => MessageBloc(
        messagesDao: messagesDao,
        conversationCubit: BlocProvider.of<ConversationCubit>(context),
        limit: windowHeight ~/ 20,
        jumpTo: ({index, alignment}) {
          if (itemScrollController.isAttached)
            itemScrollController.jumpTo(index: index, alignment: alignment);
        },
        // offset: 100,
        // index: 120,
        // alignment: 0.5,
      ),
      child: Builder(
        builder: (context) {
          BlocProvider.of<MessageBloc>(context)?.limit =
              MediaQuery.of(context).size.height ~/ 20;
          return Column(
            children: [
              ChatBar(onPressed: onPressed, isSelected: isSelected),
              Expanded(
                child: Navigator(
                  pages: [
                    MaterialPage(
                      child: Column(
                        children: [
                          Expanded(
                            child: Builder(
                              builder: (context) => BlocConverter<MessageBloc,
                                  PagingState<MessageItem>, int>(
                                // int.MaxValue
                                converter: (state) =>
                                    state?.count ?? 9223372036854775807,
                                builder: (context, count) =>
                                    ScrollablePositionedList.builder(
                                  key: Key(BlocProvider.of<MessageBloc>(context)
                                      .conversationId),
                                  initialScrollIndex:
                                      BlocProvider.of<MessageBloc>(context)
                                          .state
                                          .index,
                                  initialAlignment:
                                      BlocProvider.of<MessageBloc>(context)
                                          .state
                                          .alignment,
                                  addAutomaticKeepAlives: false,
                                  itemScrollController: itemScrollController,
                                  itemPositionsListener:
                                      BlocProvider.of<MessageBloc>(context)
                                          .itemPositionsListener,
                                  reverse: true,
                                  itemCount: count,
                                  itemBuilder:
                                      (BuildContext context, int index) =>
                                          _Message(index: index),
                                ),
                              ),
                            ),
                          ),
                          const InputContainer()
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
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
            if (datetime != null) _DayTime(dateTime: datetime),
            _MessageBubbleMargin(
              isCurrentUser: isCurrentUser,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (user != null) _Name(user: user),
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
                    child: Builder(builder: (context) {
                      if (message.type.isSticker) {
                        return _StickerMessage(
                          message: message,
                          isCurrentUser: isCurrentUser,
                        );
                      }
                      return _TextMessage(
                        showNip: showNip,
                        isCurrentUser: isCurrentUser,
                        message: message,
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StickerMessage extends StatelessWidget {
  const _StickerMessage({
    Key key,
    @required this.message,
    @required this.isCurrentUser,
  }) : super(key: key);

  final MessageItem message;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    double width;
    double height;
    if (message.assetWidth == null || message.assetHeight == null) {
      height = 120;
      width = 120;
    } else if (message.assetWidth * 2 < dpToPx(context, 48) ||
        message.assetHeight * 2 < dpToPx(context, 48)) {
      if (message.assetWidth < message.assetHeight) {
        if (dpToPx(context, 48) * message.assetHeight / message.assetWidth >
            dpToPx(context, 120)) {
          height = 120;
          width = 120 * message.assetWidth / message.assetHeight;
        } else {
          width = 48;
          height = 48 * message.assetHeight / message.assetWidth;
        }
      } else {
        if (dpToPx(context, 48) * message.assetWidth / message.assetHeight >
            dpToPx(context, 120)) {
          width = 120;
          height = 120 * message.assetHeight / message.assetWidth;
        } else {
          height = 48;
          width = 48 * message.assetWidth / message.assetHeight;
        }
      }
    } else if (message.assetWidth * 2 < dpToPx(context, 120) ||
        message.assetHeight * 2 > dpToPx(context, 120)) {
      if (message.assetWidth > message.assetHeight) {
        width = 120;
        height = 120 * message.assetHeight / message.assetWidth;
      } else {
        height = 120;
        width = 120 * message.assetWidth / message.assetHeight;
      }
    } else {
      width = pxToDp(context, message.assetWidth * 2);
      height = pxToDp(context, message.assetHeight * 2);
    }
    return _MessageBubble(
      showNip: true,
      isCurrentUser: isCurrentUser,
      showBubble: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (message.assetUrl == null)
            SizedBox(
              height: height,
              width: width,
            ),
          if (message.assetUrl != null)
            CacheImage(
              message.assetUrl,
              height: height,
              width: width,
            ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DateTime(dateTime: message.createdAt),
              _MessageStatus(status: message.status),
            ],
          ),
        ],
      ),
    );
  }
}

class _TextMessage extends StatelessWidget {
  const _TextMessage({
    Key key,
    @required this.showNip,
    @required this.isCurrentUser,
    @required this.message,
  }) : super(key: key);

  final bool showNip;
  final bool isCurrentUser;
  final MessageItem message;

  @override
  Widget build(BuildContext context) {
    return _MessageBubble(
      showNip: showNip,
      isCurrentUser: isCurrentUser,
      child: Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.end,
        children: [
          Text(
            message.content,
            style: TextStyle(
              fontSize: 16,
              color: BrightnessData.dynamicColor(
                context,
                const Color.fromRGBO(51, 51, 51, 1),
                darkColor: const Color.fromRGBO(255, 255, 255, 0.9),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DateTime(dateTime: message.createdAt),
              if (isCurrentUser) _MessageStatus(status: message.status),
            ],
          ),
        ],
      ),
    );
  }
}

class _DateTime extends StatelessWidget {
  const _DateTime({
    Key key,
    @required this.dateTime,
  }) : super(key: key);

  final DateTime dateTime;

  @override
  Widget build(BuildContext context) {
    return Text(
      DateFormat.jm().format(dateTime),
      style: TextStyle(
        fontSize: 10,
        color: BrightnessData.dynamicColor(
          context,
          const Color.fromRGBO(131, 145, 158, 1),
          darkColor: const Color.fromRGBO(128, 131, 134, 1),
        ),
      ),
    );
  }
}

class _MessageStatus extends StatelessWidget {
  const _MessageStatus({
    Key key,
    @required this.status,
  }) : super(key: key);

  final MessageStatus status;

  @override
  Widget build(BuildContext context) {
    var assetName = Resources.assetsImagesSendingSvg;
    var lightColor = const Color.fromRGBO(184, 189, 199, 1);
    var darkColor = const Color.fromRGBO(255, 255, 255, 0.4);
    switch (status) {
      case MessageStatus.sent:
        assetName = Resources.assetsImagesSentSvg;
        break;
      case MessageStatus.delivered:
        assetName = Resources.assetsImagesDeliveredSvg;
        break;
      case MessageStatus.read:
        assetName = Resources.assetsImagesReadSvg;
        lightColor = const Color.fromRGBO(61, 117, 227, 1);
        darkColor = const Color.fromRGBO(65, 145, 255, 1);
        break;
      default:
        break;
    }
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: SvgPicture.asset(
        assetName,
        color: BrightnessData.dynamicColor(
          context,
          lightColor,
          darkColor: darkColor,
        ),
      ),
    );
  }
}

class _Name extends StatelessWidget {
  const _Name({
    Key key,
    this.user,
  }) : super(key: key);

  final String user;

  @override
  Widget build(BuildContext context) => Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(
          left: 10,
          bottom: 2,
        ),
        child: Text(
          user,
          style: TextStyle(
            fontSize: 15,
            color: BrightnessData.dynamicColor(
              context,
              const Color.fromRGBO(0, 122, 255, 1),
            ),
          ),
        ),
      );
}

class _DayTime extends StatelessWidget {
  const _DayTime({
    Key key,
    this.dateTime,
  }) : super(key: key);

  final DateTime dateTime;

  @override
  Widget build(BuildContext context) => Container(
        height: 60,
        alignment: Alignment.center,
        child: Container(
          height: 22,
          width: 90,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: BrightnessData.dynamicColor(
              context,
              const Color.fromRGBO(213, 211, 243, 1),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            DateFormat.MEd().format(dateTime),
          ),
        ),
      );
}

class _MessageBubbleMargin extends StatelessWidget {
  const _MessageBubbleMargin({
    Key key,
    this.child,
    this.isCurrentUser,
  }) : super(key: key);

  final Widget child;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(
          left: isCurrentUser ? 65 : 16,
          right: !isCurrentUser ? 65 : 16,
          top: 2,
          bottom: 2,
        ),
        child: child,
      );
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    Key key,
    this.isCurrentUser,
    this.child,
    this.showNip = true,
    this.showBubble = true,
  }) : super(key: key);

  final Widget child;
  final bool isCurrentUser;
  final bool showNip;
  final bool showBubble;

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isCurrentUser
        ? BrightnessData.dynamicColor(
            context,
            const Color.fromRGBO(177, 218, 236, 1),
            darkColor: const Color.fromRGBO(59, 79, 103, 1),
          )
        : BrightnessData.dynamicColor(
            context,
            const Color.fromRGBO(255, 255, 255, 1),
            darkColor: const Color.fromRGBO(52, 59, 67, 1),
          );
    final isDark = BrightnessData.of(context) == 1;
    Widget _child = Padding(
      padding: const EdgeInsets.all(10.0),
      child: child,
    );
    if (!showNip) {
      _child = ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 38),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: bubbleColor,
            boxShadow: [
              const BoxShadow(
                offset: Offset(0, 1),
                color: Color.fromRGBO(0, 0, 0, 0.16),
                blurRadius: 2,
              ),
            ],
          ),
          child: _child,
        ),
      );
    }

    _child = Padding(
      padding: EdgeInsets.only(
        left: isCurrentUser ? 0 : 10,
        right: !isCurrentUser ? 0 : 10,
      ),
      child: _child,
    );

    if (showNip) {
      _child = ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 38),
        child: DecoratedBox(
          decoration: BoxDecoration(
            image: showBubble
                ? DecorationImage(
                    image: AssetImage(
                      isCurrentUser
                          ? isDark
                              ? Resources.assetsImagesDarkSenderNipBubblePng
                              : Resources.assetsImagesLightSenderNipBubblePng
                          : isDark
                              ? Resources.assetsImagesDarkReceiverNipBubblePng
                              : Resources.assetsImagesLightReceiverNipBubblePng,
                    ),
                    centerSlice: Rect.fromCenter(
                      center: const Offset(21, 22),
                      width: 1,
                      height: 1,
                    ),
                  )
                : null,
          ),
          child: _child,
        ),
      );
    }

    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 42,
          minHeight: 44,
        ),
        child: _child,
      ),
    );
  }
}
