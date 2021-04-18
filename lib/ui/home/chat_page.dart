import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/account/account_server.dart';
import 'package:flutter_app/bloc/simple_cubit.dart';
import 'package:flutter_app/bloc/subscribe_mixin.dart';
import 'package:flutter_app/ui/home/home.dart';
import 'package:flutter_app/ui/home/route/responsive_navigator.dart';
import 'package:flutter_app/ui/home/route/responsive_navigator_cubit.dart';
import 'package:flutter_app/utils/hook.dart';
import 'package:flutter_app/utils/list_utils.dart';
import 'package:flutter_app/ui/home/bloc/conversation_cubit.dart';
import 'package:flutter_app/ui/home/bloc/message_bloc.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_app/widgets/chat_bar.dart';
import 'package:flutter_app/ui/home/chat_slide_page/chat_info_page.dart';
import 'package:flutter_app/widgets/clamping_custom_scroll_view/clamping_custom_scroll_view.dart';
import 'package:flutter_app/widgets/input_container.dart';
import 'package:flutter_app/widgets/message/message.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';

import 'bloc/quote_message_cubit.dart';
import 'chat_slide_page/circle_manager_page.dart';
import 'chat_slide_page/search_message_page.dart';

class ChatSideCubit extends AbstractResponsiveNavigatorCubit {
  ChatSideCubit() : super(const ResponsiveNavigatorState());

  static const infoPage = 'infoPage';
  static const circles = 'circles';
  static const searchMessageHistory = 'searchMessageHistory';

  @override
  MaterialPage route(String name, Object? arguments) {
    switch (name) {
      case infoPage:
        return const MaterialPage(
          key: ValueKey(infoPage),
          name: infoPage,
          child: ChatInfoPage(),
        );
      case circles:
        if (arguments == null || !(arguments is Tuple2<String, String>))
          throw ArgumentError('Invalid route');
        return MaterialPage(
          key: const ValueKey(circles),
          name: circles,
          child: CircleManagerPage(
            name: arguments.item1,
            conversationId: arguments.item2,
          ),
        );
      case searchMessageHistory:
        return const MaterialPage(
          key: ValueKey(searchMessageHistory),
          name: searchMessageHistory,
          child: SearchMessagePage(),
        );
      default:
        throw ArgumentError('Invalid route');
    }
  }

  void toggleInfoPage() {
    if (state.pages.isEmpty)
      return emit(state.copyWith(pages: [route(ChatSideCubit.infoPage, null)]));
    return clear();
  }
}

const sidePageWidth = 300.0;

class SearchConversationKeywordCubit extends SimpleCubit<String>
    with SubscribeMixin {
  SearchConversationKeywordCubit({required ChatSideCubit chatSideCubit})
      : super('') {
    addSubscription(chatSideCubit.stream
        .map((event) => event.pages.any(
            (element) => element.name == ChatSideCubit.searchMessageHistory))
        .distinct()
        .where((event) => !event)
        .listen((event) => emit('')));
  }
}

class ChatPage extends HookWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final chatContainerPageKey = useMemoized(() => GlobalKey());
    final conversationId =
        useBlocStateConverter<ConversationCubit, ConversationState?, String?>(
      converter: (state) => state?.conversationId,
    );
    final chatSideCubit = useBloc(() => ChatSideCubit(), keys: [
      conversationId,
    ]);
    final navigatorState =
        useBlocState<ChatSideCubit, ResponsiveNavigatorState>(
            bloc: chatSideCubit);

    final chatContainerPage = MaterialPage(
      key: const ValueKey('chatContainer'),
      name: 'chatContainer',
      child: ChatContainer(
        key: chatContainerPageKey,
      ),
    );

    final windowHeight = MediaQuery.of(context).size.height;

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: chatSideCubit),
        BlocProvider(
          create: (context) => SearchConversationKeywordCubit(
            chatSideCubit: chatSideCubit,
          ),
        ),
        BlocProvider(
          create: (context) => MessageBloc(
            messagesDao: context.read<AccountServer>().database.messagesDao,
            conversationCubit: context.read<ConversationCubit>(),
            limit: windowHeight ~/ 20,
          ),
        ),
      ],
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: BrightnessData.themeOf(context).primary,
        ),
        child: LayoutBuilder(
          builder: (context, boxConstraints) {
            final navigationMode = boxConstraints.maxWidth <
                (responsiveNavigationMinWidth + sidePageWidth);
            chatSideCubit.updateNavigationMode(navigationMode);

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
  Widget build(BuildContext context) => MultiBlocProvider(
        providers: [
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
                                      final dimension = notification
                                              .metrics.viewportDimension /
                                          2;

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
                                            BlocProvider.of<MessageBloc>(
                                                    context)
                                                .after();
                                          }
                                        } else if (notification.scrollDelta! <
                                            0) {
                                          // up
                                          if ((notification.metrics
                                                          .minScrollExtent -
                                                      notification
                                                          .metrics.pixels)
                                                  .abs() <
                                              dimension) {
                                            BlocProvider.of<MessageBloc>(
                                                    context)
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
