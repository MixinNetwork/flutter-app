import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/account/account_server.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/ui/home/home.dart';
import 'package:flutter_app/ui/home/route/responsive_navigator.dart';
import 'package:flutter_app/ui/home/route/responsive_navigator_cubit.dart';
import 'package:flutter_app/utils/hook.dart';
import 'package:flutter_app/utils/list_utils.dart';
import 'package:flutter_app/ui/home/bloc/conversation_cubit.dart';
import 'package:flutter_app/ui/home/bloc/message_bloc.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_app/widgets/chat_bar.dart';
import 'package:flutter_app/widgets/chat_info_page.dart';
import 'package:flutter_app/widgets/clamping_custom_scroll_view/clamping_custom_scroll_view.dart';
import 'package:flutter_app/widgets/input_container.dart';
import 'package:flutter_app/widgets/message/message.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';

import 'bloc/quote_message_cubit.dart';

class ChatSideCubit extends AbstractResponsiveNavigatorCubit {
  ChatSideCubit() : super(const ResponsiveNavigatorState());

  static const infoPage = 'infoPage';

  @override
  MaterialPage route(String name, Object? arguments) {
    switch (name) {
      case infoPage:
        return const MaterialPage(
          key: ValueKey(infoPage),
          name: infoPage,
          child: ChatInfoPage(),
        );

      default:
        throw ArgumentError('Invalid route');
    }
  }

  void toggleInfoPage() {
    if (state.pages.isEmpty)
      return emit(state.copyWith(pages: [route(ChatSideCubit.infoPage, null)]));
    return emit(state.copyWith(pages: []));
  }
}

const sidePageWidth = 300.0;

class ChatPage extends HookWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final chatContainerPageKey = useMemoized(() => GlobalKey());
    final conversationId =
        useBlocState<ConversationCubit, ConversationItem?>()?.conversationId;
    final chatSideCubit = useBloc(() => ChatSideCubit(), keys: [
      conversationId,
    ]);
    final navigatorState = useBlocState(bloc: chatSideCubit);

    final chatContainerPage = MaterialPage(
      key: const ValueKey('chatContainer'),
      name: 'chatContainer',
      child: ChatContainer(
        key: chatContainerPageKey,
      ),
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: chatSideCubit),
      ],
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: BrightnessData.themeOf(context).primary,
        ),
        child: LayoutBuilder(
          builder: (context, boxConstraints) {
            final navigationMode = boxConstraints.maxWidth <
                (responsiveNavigationMinWidth + sidePageWidth);

            final hasPage = navigatorState.pages.isNotEmpty;
            return Row(
              children: [
                if (!navigationMode)
                  SizedBox(
                    width:
                        boxConstraints.maxWidth - (hasPage ? sidePageWidth : 0),
                    child: chatContainerPage.child,
                  ),
                if (navigationMode || hasPage)
                  SizedBox(
                    width: navigationMode
                        ? boxConstraints.maxWidth
                        : sidePageWidth,
                    child: ClipRect(
                      child: Navigator(
                        transitionDelegate: WithoutAnimationDelegate(
                          routeWithoutAnimation: {
                            chatContainerPage.name,
                          },
                        ),
                        onPopPage: (Route<dynamic> route, dynamic result) {
                          chatSideCubit.onPopPage();
                          return route.didPop(result);
                        },
                        pages: [
                          if (navigationMode) chatContainerPage,
                          ...navigatorState.pages,
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class ChatContainer extends StatelessWidget {
  const ChatContainer({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final database = Provider.of<AccountServer>(context).database;
    final messagesDao = database.messagesDao;
    final windowHeight = MediaQuery.of(context).size.height;
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
          create: (context) => QuoteMessageCubit(),
        ),
      ],
      child: Builder(
        builder: (context) {
          BlocProvider.of<MessageBloc>(context).limit =
              MediaQuery.of(context).size.height ~/ 20;
          return Column(
            children: [
              const ChatBar(),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: BrightnessData.themeOf(context).chatBackground,
                  ),
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
                                      if (notification.scrollDelta == null)
                                        return false;

                                      if (notification.scrollDelta! > 0) {
                                        // down
                                        if (notification
                                                    .metrics.maxScrollExtent -
                                                notification.metrics.pixels <
                                            dimension) {
                                          BlocProvider.of<MessageBloc>(context)
                                              .after();
                                        }
                                      } else if (notification.scrollDelta! <
                                          0) {
                                        // up
                                        if ((notification.metrics
                                                        .minScrollExtent -
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
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => BlocBuilder<MessageBloc, MessageState>(
        buildWhen: (a, b) => b.conversationId != null,
        builder: (context, state) {
          final key = ValueKey(
            Tuple2(
              state.conversationId,
              state.initUUID,
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
                child: Container(
                  color: Colors.red,
                  child: Builder(builder: (context) {
                    if (center == null) return const SizedBox();
                    return MessageItemWidget(
                      prev: top.lastOrNull,
                      message: center,
                      next: bottom.firstOrNull,
                    );
                  }),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) => MessageItemWidget(
                    prev:
                        bottom.getOrNull(index - 1) ?? center ?? top.lastOrNull,
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
