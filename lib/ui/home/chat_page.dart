import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';

import '../../account/account_server.dart';
import '../../bloc/simple_cubit.dart';
import '../../bloc/subscribe_mixin.dart';
import '../../constants/resources.dart';
import '../../utils/hook.dart';
import '../../utils/list_utils.dart';
import '../../widgets/brightness_observer.dart';
import '../../widgets/chat_bar.dart';
import '../../widgets/clamping_custom_scroll_view/clamping_custom_scroll_view.dart';
import '../../widgets/input_container.dart';
import '../../widgets/interacter_decorated_box.dart';
import '../../widgets/message/item/text/mention_builder.dart';
import '../../widgets/message/message.dart';
import '../../widgets/message/message_bubble.dart';
import 'bloc/blink_cubit.dart';
import 'bloc/conversation_cubit.dart';
import 'bloc/message_bloc.dart';
import 'bloc/pending_jump_message_cubit.dart';
import 'bloc/quote_message_cubit.dart';
import 'chat_slide_page/chat_info_page.dart';
import 'chat_slide_page/circle_manager_page.dart';
import 'chat_slide_page/group_participants_page.dart';
import 'chat_slide_page/search_message_page.dart';
import 'chat_slide_page/shared_media_page.dart';
import 'home.dart';
import 'route/responsive_navigator.dart';
import 'route/responsive_navigator_cubit.dart';

class ChatSideCubit extends AbstractResponsiveNavigatorCubit {
  ChatSideCubit() : super(const ResponsiveNavigatorState());

  static const infoPage = 'infoPage';
  static const circles = 'circles';
  static const searchMessageHistory = 'searchMessageHistory';
  static const sharedMedia = 'sharedMedia';
  static const participants = 'members';

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
        return const MaterialPage(
          key: ValueKey(circles),
          name: circles,
          child: CircleManagerPage(),
        );
      case searchMessageHistory:
        return const MaterialPage(
          key: ValueKey(searchMessageHistory),
          name: searchMessageHistory,
          child: SearchMessagePage(),
        );
      case sharedMedia:
        return const MaterialPage(
          key: ValueKey(sharedMedia),
          name: sharedMedia,
          child: SharedMediaPage(),
        );
      case participants:
        return const MaterialPage(
          key: ValueKey(participants),
          name: participants,
          child: GroupParticipantsPage(),
        );
      default:
        throw ArgumentError('Invalid route');
    }
  }

  void toggleInfoPage() {
    if (state.pages.isEmpty) {
      return emit(state.copyWith(pages: [route(ChatSideCubit.infoPage, null)]));
    }
    return clear();
  }
}

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
    final conversationState =
        useBlocState<ConversationCubit, ConversationState?>();

    final chatSideCubit = useBloc(() => ChatSideCubit(), keys: [
      conversationState?.conversationId,
    ]);
    final searchConversationKeywordCubit = useBloc(
        () => SearchConversationKeywordCubit(chatSideCubit: chatSideCubit),
        keys: [conversationState?.conversationId]);

    final initialSidePage = conversationState?.initialSidePage;
    useEffect(() {
      if (initialSidePage != null) {
        chatSideCubit.pushPage(initialSidePage);
      }
    }, [initialSidePage, chatSideCubit]);

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

    return MultiProvider(
      providers: [
        BlocProvider.value(value: chatSideCubit),
        BlocProvider.value(value: searchConversationKeywordCubit),
        BlocProvider(
          create: (context) => MessageBloc(
            accountServer: context.read<AccountServer>(),
            database: context.read<AccountServer>().database,
            conversationCubit: context.read<ConversationCubit>(),
            mentionCache: context.read<MentionCache>(),
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
                (kResponsiveNavigationMinWidth + kChatSidePageWidth);
            chatSideCubit.updateNavigationMode(navigationMode);

            return Row(
              children: [
                if (!navigationMode)
                  Expanded(
                    child: chatContainerPage.child,
                  ),
                if (!navigationMode)
                  Container(
                    width: 1,
                    color: BrightnessData.themeOf(context).divider,
                  ),
                _SideRouter(
                  chatSideCubit: chatSideCubit,
                  constraints: boxConstraints,
                  onPopPage: (Route<dynamic> route, dynamic result) {
                    chatSideCubit.onPopPage();
                    return route.didPop(result);
                  },
                  pages: [
                    if (navigationMode) chatContainerPage,
                    ...navigatorState.pages,
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SideRouter extends StatelessWidget {
  const _SideRouter({
    Key? key,
    required this.chatSideCubit,
    required this.pages,
    this.onPopPage,
    required this.constraints,
  }) : super(key: key);

  final ChatSideCubit chatSideCubit;

  final List<Page<dynamic>> pages;

  final PopPageCallback? onPopPage;

  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context) {
    final navigationMode = chatSideCubit.state.navigationMode;
    if (navigationMode) {
      return SizedBox(
        width: constraints.maxWidth,
        child: Navigator(
          pages: pages,
          onPopPage: onPopPage,
        ),
      );
    } else {
      return _AnimatedChatSlide(
        constraints: constraints,
        pages: pages,
        onPopPage: onPopPage,
      );
    }
  }
}

class _AnimatedChatSlide extends HookWidget {
  const _AnimatedChatSlide({
    Key? key,
    required this.pages,
    required this.constraints,
    required this.onPopPage,
  }) : super(key: key);

  final List<Page<dynamic>> pages;

  final PopPageCallback? onPopPage;

  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: const Duration(milliseconds: 300),
      lowerBound: 0,
      upperBound: 1,
    );

    final _pages = useState(<Page<dynamic>>[]);

    useEffect(() {
      if (pages.isNotEmpty) {
        _pages.value = pages;
        controller.forward();
      } else {
        controller.reverse().whenComplete(() {
          _pages.value = pages;
        });
      }
    }, [pages, controller]);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) => SizedBox(
        width: kChatSidePageWidth *
            Curves.easeInOut.transform(
              controller.value,
            ),
        height: constraints.maxHeight,
        child: controller.value != 0 ? child : null,
      ),
      child: ClipRect(
        child: OverflowBox(
          alignment: AlignmentDirectional.centerStart,
          maxHeight: constraints.maxHeight,
          minHeight: constraints.maxHeight,
          maxWidth: kChatSidePageWidth,
          minWidth: kChatSidePageWidth,
          child: Navigator(
            pages: _pages.value,
            onPopPage: onPopPage,
          ),
        ),
      ),
    );
  }
}

class ChatContainer extends HookWidget {
  const ChatContainer({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final quoteMessageCubit = useBloc(() => QuoteMessageCubit());
    BlocProvider.of<MessageBloc>(context).limit =
        MediaQuery.of(context).size.height ~/ 20;

    final tickerProvider = useSingleTickerProvider();

    final blinkCubit = useBloc(
      () => BlinkCubit(
        tickerProvider,
        BrightnessData.themeOf(context).accent.withOpacity(0.5),
      ),
    );

    final pendingJumpMessageCubit = useBloc(() => PendingJumpMessageCubit());

    return MultiProvider(
      providers: [
        BlocProvider.value(value: blinkCubit),
        BlocProvider.value(value: quoteMessageCubit),
        BlocProvider.value(value: pendingJumpMessageCubit),
      ],
      child: Column(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: BrightnessData.themeOf(context).divider,
                ),
              ),
            ),
            child: const ChatBar(),
          ),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: BrightnessData.themeOf(context).chatBackground,
                image: DecorationImage(
                  image: const ExactAssetImage(
                    Resources.assetsImagesChatBackgroundPng,
                  ),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    BrightnessData.of(context) == 1.0
                        ? Colors.white.withOpacity(0.02)
                        : Colors.black.withOpacity(0.03),
                    BlendMode.srcIn,
                  ),
                ),
              ),
              child: Navigator(
                onPopPage: (Route<dynamic> route, dynamic result) =>
                    route.didPop(result),
                pages: [
                  MaterialPage(
                    child: Column(
                      children: [
                        Expanded(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color:
                                      BrightnessData.themeOf(context).divider,
                                ),
                              ),
                            ),
                            child: Stack(
                              children: [
                                const _NotificationListener(
                                  child: _List(),
                                ),
                                Positioned(
                                  bottom: 16,
                                  right: 16,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      _JumpMentionButton(),
                                      _JumpCurrentButton(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const InputContainer(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationListener extends StatelessWidget {
  const _NotificationListener({
    required this.child,
    Key? key,
  }) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification notification) {
          final dimension = notification.metrics.viewportDimension / 2;

          if (notification is ScrollUpdateNotification) {
            if (notification.scrollDelta == null) return false;

            if (notification.scrollDelta! > 0) {
              // down
              if (notification.metrics.maxScrollExtent -
                      notification.metrics.pixels <
                  dimension) {
                BlocProvider.of<MessageBloc>(context).after();
              }
            } else if (notification.scrollDelta! < 0) {
              // up
              if ((notification.metrics.minScrollExtent -
                          notification.metrics.pixels)
                      .abs() <
                  dimension) {
                BlocProvider.of<MessageBloc>(context).before();
              }
            }
          }

          return false;
        },
        child: child,
      );
}

class _List extends HookWidget {
  const _List({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = useBlocState<MessageBloc, MessageState>(
      when: (state) => state.conversationId != null,
    );

    final key = ValueKey(
      Tuple2(
        state.conversationId,
        state.refreshKey,
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
                lastReadMessageId: state.lastReadMessageId,
              );
            },
            childCount: top.length,
          ),
        ),
        SliverToBoxAdapter(
          key: key,
          child: Builder(builder: (context) {
            if (center == null) return const SizedBox();
            return MessageItemWidget(
              prev: top.lastOrNull,
              message: center,
              next: bottom.firstOrNull,
              lastReadMessageId: state.lastReadMessageId,
            );
          }),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) => MessageItemWidget(
              prev: bottom.getOrNull(index - 1) ?? center ?? top.lastOrNull,
              message: bottom[index],
              next: bottom.getOrNull(index + 1),
              lastReadMessageId: state.lastReadMessageId,
            ),
            childCount: bottom.length,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 10)),
      ],
    );
  }
}

class _JumpCurrentButton extends HookWidget {
  const _JumpCurrentButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final messageBloc = context.read<MessageBloc>();
    final conversationId =
        useBlocStateConverter<ConversationCubit, ConversationState?, String?>(
      converter: (state) => state?.conversationId,
      when: (conversationId) => conversationId != null,
    )!;

    final state = useBlocState<MessageBloc, MessageState>();
    final scrollController = useListenable(messageBloc.scrollController);

    final listPositionIsLatest = useState(false);

    double? pixels;
    try {
      pixels = scrollController.position.pixels;
    } catch (_) {}

    useEffect(() {
      WidgetsBinding.instance?.addPostFrameCallback((timeStamp) =>
          listPositionIsLatest.value = scrollController.hasClients &&
              (scrollController.position.maxScrollExtent -
                      scrollController.position.pixels) >
                  40);
    }, [
      scrollController.hasClients,
      pixels,
      conversationId,
      state.refreshKey,
    ]);

    final enable =
        (!state.isEmpty && !state.isLatest) || listPositionIsLatest.value;

    final pendingJumpMessageCubit = context.read<PendingJumpMessageCubit>();

    if (!enable) {
      pendingJumpMessageCubit.emit(null);
      return const SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: InteractableDecoratedBox(
        onTap: () {
          final messageId = pendingJumpMessageCubit.state;
          if (messageId != null) {
            messageBloc.scrollTo(messageId);
            context.read<BlinkCubit>().blinkByMessageId(messageId);
            pendingJumpMessageCubit.emit(null);
            return;
          }
          messageBloc.jumpToCurrent();
        },
        child: ClipOval(
          child: Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: context.messageBubbleColor(false),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.15),
                  offset: Offset(0, 2),
                  blurRadius: 10,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: SvgPicture.asset(
              Resources.assetsImagesJumpCurrentArrowSvg,
              color: BrightnessData.themeOf(context).text,
            ),
          ),
        ),
      ),
    );
  }
}

class _JumpMentionButton extends HookWidget {
  const _JumpMentionButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final conversationId =
        useBlocStateConverter<ConversationCubit, ConversationState?, String?>(
      converter: (state) => state?.conversationId,
      when: (conversationId) => conversationId != null,
    )!;
    final messageMentions = useStream(
          useMemoized(
              () => context
                  .read<AccountServer>()
                  .database
                  .messageMentionsDao
                  .unreadMentionMessageByConversationId(conversationId)
                  .watch(),
              [conversationId]),
        ).data ??
        [];

    if (messageMentions.isEmpty) return const SizedBox();

    return InteractableDecoratedBox(
      onTap: () {
        final mention = messageMentions.first;
        context.read<MessageBloc>().scrollTo(mention.messageId);
        context
            .read<AccountServer>()
            .markMentionRead(mention.messageId, mention.conversationId);
      },
      child: SizedBox(
        height: 52,
        width: 40,
        child: Stack(
          children: [
            Positioned(
              top: 12,
              child: ClipOval(
                child: Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: context.messageBubbleColor(false),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.15),
                        offset: Offset(0, 2),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '@',
                    style: TextStyle(
                      fontSize: 17,
                      height: 1,
                      color: BrightnessData.themeOf(context).text,
                    ),
                  ),
                ),
              ),
            ),
            Container(
              width: 40,
              alignment: Alignment.topCenter,
              child: Container(
                decoration: BoxDecoration(
                  color: BrightnessData.themeOf(context).accent,
                  shape: BoxShape.circle,
                ),
                width: 20,
                height: 20,
                alignment: Alignment.center,
                child: Text(
                  '${messageMentions.length}',
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
