import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_app/bloc/bloc_converter.dart';
import 'package:flutter_app/constants/assets.dart';
import 'package:flutter_app/ui/home/bloc/conversation_cubit.dart';
import 'package:flutter_app/ui/home/bloc/conversation_list_cubit.dart';
import 'package:flutter_app/ui/home/bloc/message_bloc.dart';
import 'package:flutter_app/utils/datetime_format_utils.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_app/widgets/chat_bar.dart';
import 'package:flutter_app/widgets/input_container.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:tuple/tuple.dart';

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
        child: BlocConverter<ConversationCubit, Conversation, bool>(
          converter: (state) => state != null,
          builder: (context, selected) {
            if (!selected) return const _Empty();
            return ChatContainer(
              onPressed: () {},
            );
          },
        ),
      );
}

class _Empty extends StatelessWidget {
  const _Empty({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Center(
        child: Text(
          'Select a group to start messaging',
          style: TextStyle(
            color: BrightnessData.dynamicColor(
              context,
              const Color.fromRGBO(184, 189, 199, 1),
              darkColor: const Color.fromRGBO(184, 189, 199, 1),
            ),
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
    final conversationCubit = BlocProvider.of<ConversationCubit>(context);
    final messageBloc = MessageBloc(conversationCubit.state);
    return BlocListener<ConversationCubit, Conversation>(
      listener: (context, conversation) =>
          messageBloc.setConversation(conversation),
      child: BlocProvider(
        create: (context) => messageBloc,
        child: Column(
          children: [
            ChatBar(onPressed: onPressed, isSelected: isSelected),
            Expanded(
              child: Builder(
                builder: (context) => NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification notification) {
                    final dimension =
                        max(notification.metrics.viewportDimension / 3, 200);
                    if (notification.metrics.pixels >
                        notification.metrics.maxScrollExtent - dimension) {
                      BlocProvider.of<MessageBloc>(context).loadMore();
                    }
                    return false;
                  },
                  child: BlocConverter<MessageBloc, MessageState,
                      Tuple2<Conversation, int>>(
                    converter: (state) =>
                        Tuple2(state.conversation, state.messages?.length ?? 0),
                    builder: (context, tuple2) => ListView.builder(
                      key: ValueKey(tuple2.item1),
                      controller: ScrollController(keepScrollOffset: false),
                      reverse: true,
                      itemCount: tuple2.item2,
                      itemBuilder: (BuildContext context, int index) =>
                          _Message(index: index),
                    ),
                  ),
                ),
              ),
            ),
            const InputContainer()
          ],
        ),
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
  Widget build(BuildContext context) => BlocConverter<MessageBloc, MessageState,
          Tuple4<bool, DateTime, String, bool>>(
        converter: (state) {
          final messages = state.messages;
          final message = messages[index];
          final prev = index == 0 ? null : messages[index - 1];
          final next =
              messages.length == index + 1 ? null : messages[index + 1];

          final isCurrentUser = message.isCurrentUser;

          final sameDayPrev = isSameDay(prev?.createdAt, message.createdAt);
          final sameUserPrev = prev?.isCurrentUser == isCurrentUser;
          final sameUserNext = next?.isCurrentUser == isCurrentUser;

          final showNip = !(sameUserPrev && sameDayPrev);
          final sameDayNext = isSameDay(next?.createdAt, message.createdAt);
          final datetime = sameDayNext ? null : message.createdAt;
          final user = !isCurrentUser && (!sameUserNext || !sameDayNext)
              ? message.user
              : null;

          return Tuple4(isCurrentUser, datetime, user, showNip);
        },
        builder: (context, Tuple4<bool, DateTime, String, bool> tuple) =>
            Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (tuple.item2 != null) _DayTime(dateTime: tuple.item2),
            _MessageBubbleMargin(
              isCurrentUser: tuple.item1,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (tuple.item3 != null) _Name(user: tuple.item3),
                  _MessageBubble(
                    showNip: tuple.item4,
                    isCurrentUser: tuple.item1,
                    child: BlocConverter<MessageBloc, MessageState, Message>(
                      converter: (state) => state.messages[index],
                      builder: (context, message) => Wrap(
                        alignment: WrapAlignment.end,
                        crossAxisAlignment: WrapCrossAlignment.end,
                        children: [
                          Text(
                            message.message,
                            style: TextStyle(
                              fontSize: 16,
                              color: BrightnessData.dynamicColor(
                                context,
                                const Color.fromRGBO(51, 51, 51, 1),
                                darkColor:
                                    const Color.fromRGBO(255, 255, 255, 0.9),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat.jm().format(message.createdAt),
                            style: TextStyle(
                              fontSize: 10,
                              color: BrightnessData.dynamicColor(
                                context,
                                const Color.fromRGBO(131, 145, 158, 1),
                                darkColor:
                                    const Color.fromRGBO(128, 131, 134, 1),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
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
  const _MessageBubble({Key key, this.isCurrentUser, this.child, this.showNip})
      : super(key: key);

  final Widget child;
  final bool isCurrentUser;
  final bool showNip;

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
      _child = DecoratedBox(
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
      _child = DecoratedBox(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              isCurrentUser
                  ? isDark
                      ? Assets.assetsImagesDarkSenderNipBubblePng
                      : Assets.assetsImagesLightSenderNipBubblePng
                  : isDark
                      ? Assets.assetsImagesDarkReceiverNipBubblePng
                      : Assets.assetsImagesLightReceiverNipBubblePng,
            ),
            centerSlice: Rect.fromCenter(
                center: const Offset(21, 22), width: 1, height: 1),
          ),
        ),
        child: _child,
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
