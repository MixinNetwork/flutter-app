import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_app/bloc/bloc_converter.dart';
import 'package:flutter_app/constants/assets.dart';
import 'package:flutter_app/ui/home/bloc/conversation_cubit.dart';
import 'package:flutter_app/ui/home/bloc/conversation_list_cubit.dart';
import 'package:flutter_app/ui/home/bloc/message_bloc.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_app/widgets/chat_bar.dart';
import 'package:flutter_app/widgets/input_container.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

class ChatPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
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
  Widget build(BuildContext context) => BlocProvider(
        create: (context) =>
            MessageBloc(BlocProvider.of<ConversationCubit>(context).state),
        child: Column(
          children: [
            ChatBar(onPressed: onPressed, isSelected: isSelected),
            Expanded(
              child: BlocConverter<MessageBloc, MessageState, int>(
                converter: (state) => state.messages?.length ?? 0,
                builder: (context, itemCount) =>
                    NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification notification) {
                    if (notification.metrics.pixels >
                        notification.metrics.maxScrollExtent -
                            max(notification.metrics.viewportDimension / 3,
                                200)) {
                      BlocProvider.of<MessageBloc>(context).loadMore();
                    }
                    return false;
                  },
                  child: ListView.builder(
                    reverse: true,
                    itemCount: itemCount,
                    itemBuilder: (BuildContext context, int index) =>
                        _Message(index: index),
                  ),
                ),
              ),
            ),
            const InputContainer()
          ],
        ),
      );
}

class _Message extends StatelessWidget {
  const _Message({
    Key key,
    this.index,
  }) : super(key: key);

  final int index;

  @override
  Widget build(BuildContext context) =>
      BlocConverter<MessageBloc, MessageState, bool>(
        converter: (state) => state.messages[index].isCurrentUser,
        builder: (context, isCurrentUser) => _MessageBubbleMargin(
          isCurrentUser: isCurrentUser,
          child: _MessageBubble(
            isCurrentUser: isCurrentUser,
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
                        darkColor: const Color.fromRGBO(255, 255, 255, 0.9),
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
                        darkColor: const Color.fromRGBO(128, 131, 134, 1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
  const _MessageBubble({Key key, this.isCurrentUser, this.child})
      : super(key: key);

  final Widget child;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    // final bubbleColor = isCurrentUser
    //     ? BrightnessData.dynamicColor(
    //         context,
    //         const Color.fromRGBO(177, 218, 236, 1),
    //         darkColor: const Color.fromRGBO(59, 79, 103, 1),
    //       )
    //     : BrightnessData.dynamicColor(
    //         context,
    //         const Color.fromRGBO(255, 255, 255, 1),
    //         darkColor: const Color.fromRGBO(52, 59, 67, 1),
    //       );
    final isDark = BrightnessData.of(context) == 1;
    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: DecoratedBox(
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
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 42,
            minHeight: 44,
          ),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Padding(
              padding: EdgeInsets.only(
                left: isCurrentUser ? 0 : 10,
                right: !isCurrentUser ? 0 : 10,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
