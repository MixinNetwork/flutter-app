import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/account/account_server.dart';
import 'package:flutter_app/bloc/bloc_converter.dart';
import 'package:flutter_app/db/mixin_database.dart' hide Offset, Message;
import 'package:flutter_app/utils/list_utils.dart';
import 'package:flutter_app/ui/home/bloc/conversation_cubit.dart';
import 'package:flutter_app/ui/home/bloc/message_bloc.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_app/widgets/chat_bar.dart';
import 'package:flutter_app/widgets/clamping_custom_scroll_view/clamping_custom_scroll_view.dart';
import 'package:flutter_app/widgets/input_container.dart';
import 'package:flutter_app/widgets/message/message.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';

import 'bloc/mention_bloc.dart';
import 'bloc/multi_auth_cubit.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: BrightnessData.themeOf(context).chatBackground,
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
    final database = Provider.of<AccountServer>(context).database;
    final messagesDao = database.messagesDao;
    final userDao = database.userDao;
    final windowHeight = MediaQuery.of(context).size.height;
    final multiAuthCubit = BlocProvider.of<MultiAuthCubit>(context);
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => MessageBloc(
            messagesDao: messagesDao,
            conversationCubit: BlocProvider.of<ConversationCubit>(context),
            limit: windowHeight ~/ 20,
          ),
        ),
        BlocProvider(
          create: (context) => MentionCubit(
            userDao: userDao,
            conversationCubit: BlocProvider.of<ConversationCubit>(context),
            multiAuthCubit: multiAuthCubit,
          ),
        ),
      ],
      child: Builder(
        builder: (context) {
          BlocProvider.of<MessageBloc>(context)?.limit =
              MediaQuery.of(context).size.height ~/ 20;
          return Column(
            children: [
              ChatBar(onPressed: onPressed, isSelected: isSelected),
              Expanded(
                child: Navigator(
                  onPopPage: (Route<dynamic> route, dynamic result) =>
                      route.didPop(result),
                  pages: [
                    MaterialPage(
                      child: Column(
                        children: [
                          Expanded(
                            child: Builder(
                              builder: (context) =>
                                  NotificationListener<ScrollNotification>(
                                onNotification:
                                    (ScrollNotification notification) {
                                  final dimension =
                                      notification.metrics.viewportDimension /
                                          3;

                                  if (notification
                                      is ScrollUpdateNotification) {
                                    if (notification.scrollDelta > 0) {
                                      // down
                                      if (notification.metrics.maxScrollExtent -
                                              notification.metrics.pixels <
                                          dimension) {
                                        BlocProvider.of<MessageBloc>(context)
                                            .after();
                                      }
                                    } else if (notification.scrollDelta < 0) {
                                      // up
                                      if ((notification
                                                      .metrics.minScrollExtent -
                                                  notification.metrics.pixels)
                                              .abs() <
                                          dimension) {
                                        BlocProvider.of<MessageBloc>(context)
                                            .before();
                                      }
                                    }
                                  }

                                  return false;
                                },
                                child: const _List(),
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

class _List extends StatelessWidget {
  const _List({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MessageBloc, MessageState>(
      buildWhen: (a, b) => b.conversationId != null,
      builder: (context, state) {
        final key = ValueKey(
          Tuple2(
            state.conversationId,
            state.center?.messageId,
          ),
        );
        final top = state.top;
        final center = state.center;
        final bottom = state.bottom;

        return ClampingCustomScrollView(
          key: key,
          center: key,
          controller: BlocProvider.of<MessageBloc>(context).scrollController,
          anchor: 0.3,
          slivers: [
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  final actualIndex = top.length - index - 1;
                  return MessageItemWidget(
                    prev: top.getOrNull(actualIndex - 1),
                    message: top[actualIndex],
                    next: top.getOrNull(actualIndex + 1) ??
                        center ??
                        bottom.lastOrNull,
                  );
                },
                childCount: top.length,
              ),
            ),
            SliverToBoxAdapter(
              key: key,
              child: Builder(builder: (context) {
                if (center == null) return const SizedBox();
                return ColoredBox(
                  color: Colors.red,
                  child: MessageItemWidget(
                    prev: top.lastOrNull,
                    message: center,
                    next: bottom.firstOrNull,
                  ),
                );
              }),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) => MessageItemWidget(
                  prev: bottom.getOrNull(index - 1) ?? center ?? top.lastOrNull,
                  message: bottom[index],
                  next: bottom.getOrNull(index + 1),
                ),
                childCount: bottom.length,
              ),
            ),
          ],
        );
      },
    );
  }
}
