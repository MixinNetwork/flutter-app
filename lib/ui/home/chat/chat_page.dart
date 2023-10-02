import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart' hide Provider;
import 'package:provider/provider.dart';

import '../../../account/scam_warning_key_value.dart';
import '../../../account/show_pin_message_key_value.dart';
import '../../../bloc/simple_cubit.dart';
import '../../../bloc/subscribe_mixin.dart';
import '../../../constants/resources.dart';
import '../../../db/database_event_bus.dart';
import '../../../db/mixin_database.dart' hide Offset;
import '../../../utils/extension/extension.dart';
import '../../../utils/hook.dart';
import '../../../widgets/action_button.dart';
import '../../../widgets/actions/actions.dart';
import '../../../widgets/animated_visibility.dart';
import '../../../widgets/clamping_custom_scroll_view/clamping_custom_scroll_view.dart';
import '../../../widgets/conversation/mute_dialog.dart';
import '../../../widgets/dash_path_border.dart';
import '../../../widgets/dialog.dart';
import '../../../widgets/high_light_text.dart';
import '../../../widgets/interactive_decorated_box.dart';
import '../../../widgets/message/message.dart';
import '../../../widgets/message/message_bubble.dart';
import '../../../widgets/message/message_day_time.dart';
import '../../../widgets/pin_bubble.dart';
import '../../../widgets/toast.dart';
import '../../../widgets/window/menus.dart';
import '../../provider/abstract_responsive_navigator.dart';
import '../../provider/conversation_provider.dart';
import '../../provider/mention_cache_provider.dart';
import '../../provider/message_selection_provider.dart';
import '../../provider/pending_jump_message_provider.dart';
import '../bloc/blink_cubit.dart';
import '../bloc/message_bloc.dart';
import '../chat_slide_page/chat_info_page.dart';
import '../chat_slide_page/circle_manager_page.dart';
import '../chat_slide_page/disappear_message_page.dart';
import '../chat_slide_page/group_participants_page.dart';
import '../chat_slide_page/groups_in_common_page.dart';
import '../chat_slide_page/pin_messages_page.dart';
import '../chat_slide_page/search_message_page.dart';
import '../chat_slide_page/shared_apps_page.dart';
import '../chat_slide_page/shared_media_page.dart';
import '../home.dart';
import '../hook/pin_message.dart';
import '../route/responsive_navigator.dart';
import 'chat_bar.dart';
import 'files_preview.dart';
import 'input_container.dart';
import 'selection_bottom_bar.dart';

class ChatSideCubit extends AbstractResponsiveNavigatorCubit {
  ChatSideCubit() : super(const ResponsiveNavigatorState());

  static const infoPage = 'infoPage';
  static const circles = 'circles';
  static const searchMessageHistory = 'searchMessageHistory';
  static const sharedMedia = 'sharedMedia';
  static const participants = 'participants';
  static const pinMessages = 'pinMessages';
  static const sharedApps = 'sharedApps';
  static const groupsInCommon = 'groupsInCommon';
  static const disappearMessages = 'disappearMessages';

  @override
  MaterialPage route(String name, Object? arguments) {
    switch (name) {
      case infoPage:
        return const MaterialPage(
          key: ValueKey(infoPage),
          name: infoPage,
          child: _ChatSidePageBuilder(ChatInfoPage.new),
        );
      case circles:
        return const MaterialPage(
          key: ValueKey(circles),
          name: circles,
          child: _ChatSidePageBuilder(CircleManagerPage.new),
        );
      case searchMessageHistory:
        return const MaterialPage(
          key: ValueKey(searchMessageHistory),
          name: searchMessageHistory,
          child: _ChatSidePageBuilder(SearchMessagePage.new),
        );
      case sharedMedia:
        return const MaterialPage(
          key: ValueKey(sharedMedia),
          name: sharedMedia,
          child: _ChatSidePageBuilder(SharedMediaPage.new),
        );
      case participants:
        return const MaterialPage(
          key: ValueKey(participants),
          name: participants,
          child: _ChatSidePageBuilder(GroupParticipantsPage.new),
        );
      case pinMessages:
        return const MaterialPage(
          key: ValueKey(pinMessages),
          name: pinMessages,
          child: _ChatSidePageBuilder(PinMessagesPage.new),
        );
      case sharedApps:
        return const MaterialPage(
          key: ValueKey(sharedApps),
          name: sharedApps,
          child: _ChatSidePageBuilder(SharedAppsPage.new),
        );
      case groupsInCommon:
        return const MaterialPage(
          key: ValueKey(groupsInCommon),
          name: groupsInCommon,
          child: _ChatSidePageBuilder(GroupsInCommonPage.new),
        );
      case disappearMessages:
        return const MaterialPage(
          key: ValueKey(disappearMessages),
          name: disappearMessages,
          child: _ChatSidePageBuilder(DisappearMessagePage.new),
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

class SearchConversationKeywordCubit extends SimpleCubit<(String?, String)>
    with SubscribeMixin {
  SearchConversationKeywordCubit({required ChatSideCubit chatSideCubit})
      : super(const (null, '')) {
    addSubscription(chatSideCubit.stream
        .map((event) => event.pages.any(
            (element) => element.name == ChatSideCubit.searchMessageHistory))
        .distinct()
        .listen((event) => emit(const (null, ''))));
  }

  static void updateKeyword(BuildContext context, String keyword) {
    final cubit = context.read<SearchConversationKeywordCubit>();
    cubit.emit((cubit.state.$1, keyword));
  }

  static void updateSelectedUser(BuildContext context, String? userId) {
    final cubit = context.read<SearchConversationKeywordCubit>();
    cubit.emit((userId, cubit.state.$2));
  }
}

class _ChatSidePageBuilder extends HookConsumerWidget {
  const _ChatSidePageBuilder(this.builder);

  final Widget Function(ConversationState conversationState) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationId =
        useMemoized(() => ref.read(lastConversationIdProvider), []);

    final filter = useCallback(
        (ConversationState? state) => state?.conversationId == conversationId,
        [conversationId]);

    final conversationState = ref.watch(filterLastConversationProvider(filter));

    if (conversationId == null || conversationState == null) {
      return const SizedBox();
    }

    return builder(conversationState);
  }
}

class ChatPage extends HookConsumerWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatContainerPageKey = useMemoized(GlobalKey.new);
    final (conversationId, initialSidePage) = ref.watch(
      conversationProvider
          .select((value) => (value?.conversationId, value?.initialSidePage)),
    );

    final chatSideCubit = useBloc(ChatSideCubit.new, keys: [conversationId]);

    final searchConversationKeywordCubit = useBloc(
        () => SearchConversationKeywordCubit(chatSideCubit: chatSideCubit),
        keys: [conversationId]);

    useEffect(() {
      if (initialSidePage != null) {
        chatSideCubit.pushPage(initialSidePage);
      }
    }, [initialSidePage, chatSideCubit]);

    final navigatorState =
        useBlocState<ChatSideCubit, ResponsiveNavigatorState>(
            bloc: chatSideCubit);

    ref.listen(hasSelectedMessageProvider, (previous, hasSelectedMessage) {
      if (!hasSelectedMessage) return;
      chatSideCubit.clear();
    });

    final chatContainerPage = MaterialPage(
      key: const ValueKey('chatContainer'),
      name: 'chatContainer',
      child: ChatContainer(
        key: chatContainerPageKey,
      ),
    );

    final windowHeight = MediaQuery.sizeOf(context).height;

    final tickerProvider = useSingleTickerProvider();
    final blinkCubit = useBloc(
      () => BlinkCubit(
        tickerProvider,
        context.theme.accent.withOpacity(0.5),
      ),
    );
    final pinMessageState = usePinMessageState(conversationId);

    return MultiProvider(
      providers: [
        BlocProvider.value(value: blinkCubit),
        BlocProvider.value(value: chatSideCubit),
        BlocProvider.value(value: searchConversationKeywordCubit),
        BlocProvider(
          create: (context) => MessageBloc(
            accountServer: context.accountServer,
            database: context.database,
            conversationNotifier: ref.read(conversationProvider.notifier),
            mentionCache: context.providerContainer.read(mentionCacheProvider),
            limit: windowHeight ~/ 20,
          ),
        ),
        Provider.value(value: pinMessageState),
      ],
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.theme.primary,
        ),
        child: LayoutBuilder(
          builder: (context, boxConstraints) {
            final routeMode = boxConstraints.maxWidth <
                (kResponsiveNavigationMinWidth + kChatSidePageWidth);
            chatSideCubit.updateRouteMode(routeMode);

            return _ChatMenuHandler(
              child: Row(
                children: [
                  if (!routeMode)
                    Expanded(
                      child: chatContainerPage.child,
                    ),
                  if (!routeMode)
                    Container(
                      width: 1,
                      color: context.theme.divider,
                    ),
                  FocusableActionDetector(
                    shortcuts: const {
                      SingleActivator(LogicalKeyboardKey.escape):
                          EscapeIntent(),
                    },
                    actions: {
                      EscapeIntent: CallbackAction<EscapeIntent>(
                        onInvoke: (intent) => chatSideCubit.pop(),
                      )
                    },
                    child: _SideRouter(
                      chatSideCubit: chatSideCubit,
                      constraints: boxConstraints,
                      onPopPage: (Route<dynamic> route, dynamic result) {
                        chatSideCubit.onPopPage();
                        return route.didPop(result);
                      },
                      pages: [
                        if (routeMode) chatContainerPage,
                        ...navigatorState.pages,
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SideRouter extends StatelessWidget {
  const _SideRouter({
    required this.chatSideCubit,
    required this.pages,
    this.onPopPage,
    required this.constraints,
  });

  final ChatSideCubit chatSideCubit;

  final List<Page<dynamic>> pages;

  final PopPageCallback? onPopPage;

  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context) {
    final routeMode = chatSideCubit.state.routeMode;
    return routeMode
        ? SizedBox(
            width: constraints.maxWidth,
            child: Navigator(pages: pages, onPopPage: onPopPage))
        : _AnimatedChatSlide(
            constraints: constraints, pages: pages, onPopPage: onPopPage);
  }
}

class _AnimatedChatSlide extends HookConsumerWidget {
  const _AnimatedChatSlide({
    required this.pages,
    required this.constraints,
    required this.onPopPage,
  });

  final List<Page<dynamic>> pages;

  final PopPageCallback? onPopPage;

  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useAnimationController(
      duration: const Duration(milliseconds: 300),
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

class ChatContainer extends HookConsumerWidget {
  const ChatContainer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    BlocProvider.of<MessageBloc>(context).limit =
        MediaQuery.sizeOf(context).height ~/ 20;

    final inMultiSelectMode = ref.watch(hasSelectedMessageProvider);

    return RepaintBoundary(
      child: FocusableActionDetector(
        autofocus: true,
        shortcuts: {
          if (inMultiSelectMode)
            const SingleActivator(LogicalKeyboardKey.escape):
                const EscapeIntent(),
        },
        actions: {
          EscapeIntent: CallbackAction<EscapeIntent>(
            onInvoke: (intent) {
              ref.read(messageSelectionProvider).clearSelection();
            },
          )
        },
        child: Column(
          children: [
            Container(
              height: 64,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: context.theme.divider,
                  ),
                ),
              ),
              child: const ChatBar(),
            ),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: context.theme.chatBackground,
                  image: DecorationImage(
                    image: const ExactAssetImage(
                      Resources.assetsImagesChatBackgroundPng,
                    ),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      context.brightnessValue == 1.0
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
                      child: _ChatDropOverlay(
                        enable: !inMultiSelectMode,
                        child: Column(
                          children: [
                            Expanded(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: context.theme.divider,
                                    ),
                                  ),
                                ),
                                child: const Stack(
                                  children: [
                                    RepaintBoundary(
                                      child: _NotificationListener(
                                        child: _List(),
                                      ),
                                    ),
                                    Positioned(
                                      left: 6,
                                      right: 6,
                                      bottom: 6,
                                      child: _BottomBanner(),
                                    ),
                                    Positioned(
                                      bottom: 16,
                                      right: 16,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _JumpMentionButton(),
                                          _JumpCurrentButton(),
                                        ],
                                      ),
                                    ),
                                    _PinMessagesBanner(),
                                  ],
                                ),
                              ),
                            ),
                            AnimatedCrossFade(
                              firstChild: const InputContainer(),
                              secondChild: const SelectionBottomBar(),
                              crossFadeState: inMultiSelectMode
                                  ? CrossFadeState.showSecond
                                  : CrossFadeState.showFirst,
                              duration: const Duration(milliseconds: 300),
                            ),
                          ],
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
    );
  }
}

class _NotificationListener extends StatelessWidget {
  const _NotificationListener({
    required this.child,
  });

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

class _List extends HookConsumerWidget {
  const _List();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = useBlocState<MessageBloc, MessageState>(
      when: (state) => state.conversationId != null,
    );

    final key = ValueKey(
      (
        state.conversationId,
        state.refreshKey,
      ),
    );
    final top = state.top;
    final center = state.center;
    final bottom = state.bottom;

    final ref = useRef<Map<String, Key>>({});

    final ids = state.list.map((e) => e.messageId);

    useMemoized(() {
      ref.value.removeWhere((key, value) => !ids.contains(key));
      ids.forEach((id) {
        ref.value[id] = ref.value[id] ?? GlobalKey(debugLabel: id);
      });
    }, [ids]);

    final topKey = useMemoized(() => GlobalKey(debugLabel: 'chat list top'));
    final bottomKey =
        useMemoized(() => GlobalKey(debugLabel: 'chat list bottom'));

    final scrollController =
        BlocProvider.of<MessageBloc>(context).scrollController;

    return MessageDayTimeViewportWidget.chatPage(
      key: key,
      bottomKey: bottomKey,
      center: center,
      topKey: topKey,
      scrollController: scrollController,
      centerKey:
          center == null ? null : ref.value[center.messageId] as GlobalKey?,
      child: ClampingCustomScrollView(
        key: key,
        center: key,
        controller: scrollController,
        anchor: 0.3,
        physics: const ClampingScrollPhysics(),
        slivers: [
          SliverList(
            key: topKey,
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                final actualIndex = top.length - index - 1;
                final messageItem = top[actualIndex];
                return MessageItemWidget(
                  key: ref.value[messageItem.messageId],
                  prev: top.getOrNull(actualIndex - 1),
                  message: messageItem,
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
                key: ref.value[center.messageId],
                prev: top.lastOrNull,
                message: center,
                next: bottom.firstOrNull,
                lastReadMessageId: state.lastReadMessageId,
              );
            }),
          ),
          SliverList(
            key: bottomKey,
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                final messageItem = bottom[index];
                return MessageItemWidget(
                  key: ref.value[messageItem.messageId],
                  prev: bottom.getOrNull(index - 1) ?? center ?? top.lastOrNull,
                  message: messageItem,
                  next: bottom.getOrNull(index + 1),
                  lastReadMessageId: state.lastReadMessageId,
                );
              },
              childCount: bottom.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 10)),
        ],
      ),
    );
  }
}

class _JumpCurrentButton extends HookConsumerWidget {
  const _JumpCurrentButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messageBloc = context.read<MessageBloc>();
    final conversationId = ref.watch(currentConversationIdProvider);

    final state = useBlocState<MessageBloc, MessageState>();
    final scrollController = useListenable(messageBloc.scrollController);

    final listPositionIsLatest = useState(false);

    double? pixels;
    try {
      pixels = scrollController.position.pixels;
    } catch (_) {}

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) =>
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

    final pendingJumpMessageController =
        ref.read(pendingJumpMessageProvider.notifier);

    if (!enable) {
      Future(() => pendingJumpMessageController.state = null);
      return const SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: InteractiveDecoratedBox(
        onTap: () {
          final messageId = pendingJumpMessageController.state;
          if (messageId != null) {
            messageBloc.scrollTo(messageId);
            context.read<BlinkCubit>().blinkByMessageId(messageId);
            pendingJumpMessageController.state = null;
            return;
          }
          messageBloc.jumpToCurrent();
        },
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
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: SvgPicture.asset(
            Resources.assetsImagesJumpCurrentArrowSvg,
            colorFilter: ColorFilter.mode(context.theme.text, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }
}

class _BottomBanner extends HookConsumerWidget {
  const _BottomBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (userId, isScam) = ref.watch(
      conversationProvider
          .select((value) => (value?.userId, (value?.user?.isScam ?? 0) > 0)),
    );

    final showScamWarning = useMemoizedStream(
          () {
            if (userId == null || !isScam) return Stream.value(false);
            return ScamWarningKeyValue.instance.watch(userId);
          },
          initialData: false,
          keys: [userId],
        ).data ??
        false;

    return AnimatedVisibility(
      visible: showScamWarning,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(4)),
          color: context.messageBubbleColor(false),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.15),
              offset: Offset(0, 2),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: 8,
                right: 16,
                top: 8,
                bottom: 8,
              ),
              child: SvgPicture.asset(
                Resources.assetsImagesTriangleWarningSvg,
                colorFilter:
                    ColorFilter.mode(context.theme.red, BlendMode.srcIn),
                width: 26,
                height: 26,
              ),
            ),
            Expanded(
              child: Text(
                context.l10n.scamWarning,
                style: TextStyle(
                  color: context.theme.text,
                  fontSize: 14,
                ),
              ),
            ),
            ActionButton(
              name: Resources.assetsImagesIcCloseSvg,
              color: context.theme.icon,
              size: 20,
              onTap: () {
                if (userId == null) return;
                ScamWarningKeyValue.instance.dismiss(userId);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PinMessagesBanner extends HookConsumerWidget {
  const _PinMessagesBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPinMessageIds = context.watchCurrentPinMessageIds;
    final lastMessage = context.lastMessage;

    final showLastPinMessage = lastMessage?.isNotEmpty ?? false;

    return Positioned(
      top: 12,
      right: 16,
      left: 10,
      height: 64,
      child: AnimatedVisibility(
        visible: showLastPinMessage || currentPinMessageIds.isNotEmpty,
        child: Row(
          children: [
            Expanded(
              child: AnimatedVisibility(
                visible: showLastPinMessage,
                child: PinMessageBubble(
                  child: Row(
                    children: [
                      ActionButton(
                        name: Resources.assetsImagesIcCloseSvg,
                        color: context.theme.icon,
                        size: 20,
                        onTap: () {
                          final conversationId =
                              ref.read(currentConversationIdProvider);
                          if (conversationId == null) return;
                          ShowPinMessageKeyValue.instance
                              .dismiss(conversationId);
                        },
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: CustomText(
                          (lastMessage ?? '').overflow,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedVisibility(
              visible: currentPinMessageIds.isNotEmpty,
              child: InteractiveDecoratedBox(
                onTap: () {
                  final cubit = context.read<ChatSideCubit>();
                  if (cubit.state.pages.lastOrNull?.name ==
                      ChatSideCubit.pinMessages) {
                    return cubit.pop();
                  }

                  cubit.replace(ChatSideCubit.pinMessages);
                },
                child: Container(
                  height: 34,
                  width: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
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
                    Resources.assetsImagesChatPinSvg,
                    width: 34,
                    height: 34,
                    colorFilter:
                        ColorFilter.mode(context.theme.text, BlendMode.srcIn),
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

class _JumpMentionButton extends HookConsumerWidget {
  const _JumpMentionButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationId = ref.watch(currentConversationIdProvider);
    final messageMentions = useMemoizedStream(() {
          if (conversationId == null) return Stream.value(<MessageMention>[]);
          return context.database.messageMentionDao
              .unreadMentionMessageByConversationId(conversationId)
              .watchWithStream(
            eventStreams: [
              DataBaseEventBus.instance.watchUpdateMessageMention(
                conversationIds: [conversationId],
              )
            ],
            duration: kSlowThrottleDuration,
          );
        }, keys: [conversationId]).data ??
        [];

    if (messageMentions.isEmpty) return const SizedBox();

    return InteractiveDecoratedBox(
      onTap: () {
        if (messageMentions.isEmpty) return;

        final mention = messageMentions.first;
        context.read<MessageBloc>().scrollTo(mention.messageId);
        context.accountServer
            .markMentionRead(mention.messageId, mention.conversationId);
      },
      child: SizedBox(
        height: 52,
        width: 40,
        child: Stack(
          children: [
            Positioned(
              top: 12,
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
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '@',
                  style: TextStyle(
                    fontSize: 17,
                    height: 1,
                    color: context.theme.text,
                  ),
                ),
              ),
            ),
            Container(
              width: 40,
              alignment: Alignment.topCenter,
              child: Container(
                constraints: const BoxConstraints(
                  minWidth: 20,
                  maxWidth: 40,
                  maxHeight: 20,
                  minHeight: 20,
                ),
                decoration: BoxDecoration(
                  color: context.theme.accent,
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  children: [
                    // Use column + spacer to vertical center the text.
                    // since the width is not fixed, we can't use center widget.
                    const Spacer(),
                    Text(
                      messageMentions.length > 99
                          ? '99+'
                          : '${messageMentions.length}',
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatDropOverlay extends HookConsumerWidget {
  const _ChatDropOverlay({
    required this.child,
    required this.enable,
  });

  final Widget child;

  final bool enable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dragging = useState(false);
    final enable = useState(true);
    return DropTarget(
      onDragEntered: (_) => dragging.value = true,
      onDragExited: (_) => dragging.value = false,
      onDragDone: (details) async {
        final files = details.files.where((xFile) {
          final file = File(xFile.path);
          return file.existsSync();
        }).toList();
        if (files.isEmpty) {
          return;
        }
        enable.value = false;
        await showFilesPreviewDialog(
          context,
          files.map((e) => e.withMineType()).toList(),
        );
        enable.value = true;
      },
      enable: this.enable && enable.value,
      child: Stack(
        children: [
          child,
          if (dragging.value) const _ChatDragIndicator(),
        ],
      ),
    );
  }
}

class _ChatDragIndicator extends StatelessWidget {
  const _ChatDragIndicator();

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(color: context.theme.popUp),
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: context.theme.listSelected,
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              border: DashPathBorder.all(
                borderSide: BorderSide(
                  color: context.theme.divider,
                ),
                dashArray: CircularIntervalList([4, 4]),
              )),
          child: Center(
            child: Text(
              context.l10n.dragAndDropFileHere,
              style: TextStyle(
                fontSize: 14,
                color: context.theme.text,
              ),
            ),
          ),
        ),
      );
}

class _ChatMenuHandler extends HookConsumerWidget {
  const _ChatMenuHandler({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationId = ref.watch(currentConversationIdProvider);

    useEffect(() {
      final cubit = ref.read(macMenuBarProvider.notifier);
      if (conversationId == null) return null;

      final handle = _ConversationHandle(context, conversationId);
      Future(() => cubit.attach(handle));
      return () => Future(() => cubit.unAttach(handle));
    }, [conversationId]);

    return child;
  }
}

class _ConversationHandle extends ConversationMenuHandle {
  _ConversationHandle(this.context, this.conversationId);

  final BuildContext context;
  final String conversationId;

  @override
  Future<void> delete() async {
    final name =
        context.providerContainer.read(currentConversationNameProvider) ?? '';
    assert(name.isNotEmpty, 'name is empty');
    final ret = await showConfirmMixinDialog(
      context,
      context.l10n.conversationDeleteTitle(name),
      description: context.l10n.deleteChatDescription,
    );
    if (ret == null) return;
    await context.accountServer.deleteMessagesByConversationId(conversationId);
    await context.database.conversationDao.deleteConversation(conversationId);
    if (context.providerContainer.read(currentConversationIdProvider) ==
        conversationId) {
      context.providerContainer
          .read(conversationProvider.notifier)
          .unselected();
    }
  }

  @override
  Stream<bool> get isMuted => context.providerContainer
      .read(conversationProvider.notifier)
      .stream
      .map((event) => event?.conversation?.isMute == true);

  @override
  Stream<bool> get isPinned => context.providerContainer
      .read(conversationProvider.notifier)
      .stream
      .map((event) => event?.conversation?.pinTime != null);

  @override
  Future<void> mute() async {
    final result = await showMixinDialog<int?>(
        context: context, child: const MuteDialog());
    if (result == null) return;
    final conversationState =
        context.providerContainer.read(conversationProvider);
    if (conversationState == null) return;

    final isGroupConversation = conversationState.isGroup == true;
    await runFutureWithToast(
      context.accountServer.muteConversation(
        result,
        conversationId: isGroupConversation ? conversationId : null,
        userId: isGroupConversation
            ? null
            : conversationState.conversation?.ownerId,
      ),
    );
  }

  @override
  void pin() {
    runFutureWithToast(
      context.accountServer.pin(conversationId),
    );
  }

  @override
  void showSearch() {
    final cubit = context.read<ChatSideCubit>();
    if (cubit.state.pages.lastOrNull?.name ==
        ChatSideCubit.searchMessageHistory) {
      return cubit.pop();
    }

    cubit.replace(ChatSideCubit.searchMessageHistory);
  }

  @override
  void toggleSideBar() {
    context.read<ChatSideCubit>().toggleInfoPage();
  }

  @override
  void unPin() {
    runFutureWithToast(
      context.accountServer.unpin(conversationId),
    );
  }

  @override
  void unmute() {
    final conversationState =
        context.providerContainer.read(conversationProvider);
    if (conversationState == null) return;

    final isGroup = conversationState.isGroup == true;
    runFutureWithToast(
      context.accountServer.unMuteConversation(
        conversationId: isGroup ? conversationId : null,
        userId: isGroup ? null : conversationState.conversation?.ownerId,
      ),
    );
  }
}
