import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart'
    hide ChangeNotifierProvider, Provider;
import 'package:provider/provider.dart';

import '../../../constants/resources.dart';
import '../../../utils/extension/extension.dart';
import '../../../widgets/actions/actions.dart';
import '../../provider/conversation_provider.dart';
import '../../provider/mention_cache_provider.dart';
import '../../provider/message_selection_provider.dart';
import '../desktop_shell_layout.dart';
import '../hook/pin_message.dart';
import '../notifier/blink_notifier.dart';
import '../notifier/chat_side_notifier.dart';
import '../notifier/message_controller.dart';
import 'chat_bar.dart';
import 'chat_content_overlays.dart';
import 'chat_drop_overlay.dart';
import 'chat_menu_handler.dart';
import 'chat_scroll_coordinator.dart';
import 'chat_side_router.dart';
import 'input_container.dart';
import 'selection_bottom_bar.dart';

class ChatPage extends HookConsumerWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatContainerPageKey = useMemoized(GlobalKey.new);
    final (conversationId, initialSidePage) = ref.watch(
      conversationProvider.select(
        (value) => (value?.conversationId, value?.initialSidePage),
      ),
    );

    final chatSideNotifier = useMemoized(
      ChatSideNotifier.new,
      [conversationId],
    );
    useEffect(() => chatSideNotifier.dispose, [chatSideNotifier]);

    final searchConversationKeywordNotifier = useMemoized(
      () => SearchConversationKeywordNotifier(
        chatSideNotifier: chatSideNotifier,
      ),
      [conversationId, chatSideNotifier],
    );
    useEffect(
      () => searchConversationKeywordNotifier.dispose,
      [searchConversationKeywordNotifier],
    );

    useEffect(() {
      if (initialSidePage != null) {
        chatSideNotifier.openDestination(initialSidePage);
      }
    }, [initialSidePage, chatSideNotifier]);

    useValueListenable(chatSideNotifier);

    ref.listen(hasSelectedMessageProvider, (previous, hasSelectedMessage) {
      if (!hasSelectedMessage) return;
      chatSideNotifier.clear();
    });

    final chatContainerPage = MaterialPage(
      key: const ValueKey('chatContainer'),
      name: 'chatContainer',
      child: ChatContainer(key: chatContainerPageKey),
    );

    final windowHeight = MediaQuery.sizeOf(context).height;

    final tickerProvider = useSingleTickerProvider();
    final blinkNotifier = useMemoized(
      () => BlinkNotifier(
        tickerProvider,
        context.theme.accent.withValues(alpha: 0.5),
      ),
    );
    useEffect(() => blinkNotifier.dispose, [blinkNotifier]);
    final pinMessageState = usePinMessageState(conversationId);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<BlinkNotifier>.value(value: blinkNotifier),
        ChangeNotifierProvider<ChatSideNotifier>.value(
          value: chatSideNotifier,
        ),
        ChangeNotifierProvider<SearchConversationKeywordNotifier>.value(
          value: searchConversationKeywordNotifier,
        ),
        ChangeNotifierProvider(
          create: (context) => MessageController(
            accountServer: context.accountServer,
            database: context.database,
            conversationNotifier: ref.read(conversationProvider.notifier),
            mentionCache: context.providerContainer.read(
              mentionCacheProvider,
            ),
            limit: windowHeight ~/ 20,
          ),
        ),
        Provider(
          create: (_) => ChatScrollCoordinator(),
          dispose: (_, coordinator) => coordinator.dispose(),
        ),
        Provider.value(value: pinMessageState),
      ],
      child: DecoratedBox(
        decoration: BoxDecoration(color: context.theme.primary),
        child: LayoutBuilder(
          builder: (context, boxConstraints) {
            final routeMode = DesktopShellLayout.useChatSideRouteMode(
              boxConstraints.maxWidth,
            );
            chatSideNotifier.routeMode = routeMode;

            return DesktopShellLayout.chatSideRouteMode(
              routeMode: routeMode,
              child: ChatMenuHandler(
                child: Row(
                  children: [
                    if (!routeMode) Expanded(child: chatContainerPage.child),
                    if (!routeMode)
                      Container(width: 1, color: context.theme.divider),
                    FocusableActionDetector(
                      shortcuts: const {
                        SingleActivator(LogicalKeyboardKey.escape):
                            EscapeIntent(),
                      },
                      actions: {
                        EscapeIntent: CallbackAction<EscapeIntent>(
                          onInvoke: (intent) => chatSideNotifier.pop(),
                        ),
                      },
                      child: ChatSideRouter(
                        constraints: boxConstraints,
                        routeMode: routeMode,
                        onDidRemovePage: (page) {
                          chatSideNotifier.onPopPage();
                        },
                        leadingPages: [
                          if (routeMode) chatContainerPage,
                        ],
                        destinations: chatSideNotifier.state.destinations,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class ChatContainer extends HookConsumerWidget {
  const ChatContainer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    context.read<MessageController>().limit =
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
          ),
        },
        child: Column(
          children: [
            Container(
              height: 64,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: context.theme.divider),
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
                          ? Colors.white.withValues(alpha: 0.02)
                          : Colors.black.withValues(alpha: 0.03),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                child: Navigator(
                  onDidRemovePage: (page) {},
                  pages: [
                    MaterialPage(
                      child: ChatDropOverlay(
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
                                child: const ChatContentOverlays(),
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
