import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../provider/conversation_provider.dart';
import '../chat_slide_page/chat_info_page.dart';
import '../chat_slide_page/circle_manager_page.dart';
import '../chat_slide_page/disappear_message_page.dart';
import '../chat_slide_page/group_participants_page.dart';
import '../chat_slide_page/groups_in_common_page.dart';
import '../chat_slide_page/pin_messages_page.dart';
import '../chat_slide_page/search_message_page.dart';
import '../chat_slide_page/shared_apps_page.dart';
import '../chat_slide_page/shared_media_page.dart';
import '../conversation_info_destination.dart';
import '../desktop_shell_layout.dart';

class ChatSideRouter extends StatelessWidget {
  const ChatSideRouter({
    required this.destinations,
    required this.constraints,
    required this.routeMode,
    super.key,
    this.leadingPages = const [],
    this.onDidRemovePage,
  });

  final List<ConversationInfoDestination> destinations;
  final List<Page<dynamic>> leadingPages;
  final DidRemovePageCallback? onDidRemovePage;
  final BoxConstraints constraints;
  final bool routeMode;

  @override
  Widget build(BuildContext context) {
    final pages = [
      ...leadingPages,
      ...destinations.map(_pageFor),
    ];
    return routeMode
        ? SizedBox(
            width: constraints.maxWidth,
            child: Navigator(pages: pages, onDidRemovePage: onDidRemovePage),
          )
        : _AnimatedChatSlide(
            constraints: constraints,
            pages: pages,
            onDidRemovePage: onDidRemovePage,
          );
  }
}

MaterialPage _pageFor(ConversationInfoDestination destination) {
  switch (destination) {
    case ConversationInfoDestination.infoPage:
      return const MaterialPage(
        key: ValueKey(ConversationInfoDestination.infoPage),
        name: 'infoPage',
        child: _ChatSidePageBuilder(ChatInfoPage.new),
      );
    case ConversationInfoDestination.circles:
      return const MaterialPage(
        key: ValueKey(ConversationInfoDestination.circles),
        name: 'circles',
        child: _ChatSidePageBuilder(CircleManagerPage.new),
      );
    case ConversationInfoDestination.searchMessageHistory:
      return const MaterialPage(
        key: ValueKey(ConversationInfoDestination.searchMessageHistory),
        name: 'searchMessageHistory',
        child: _ChatSidePageBuilder(SearchMessagePage.new),
      );
    case ConversationInfoDestination.sharedMedia:
      return const MaterialPage(
        key: ValueKey(ConversationInfoDestination.sharedMedia),
        name: 'sharedMedia',
        child: _ChatSidePageBuilder(SharedMediaPage.new),
      );
    case ConversationInfoDestination.participants:
      return const MaterialPage(
        key: ValueKey(ConversationInfoDestination.participants),
        name: 'participants',
        child: _ChatSidePageBuilder(GroupParticipantsPage.new),
      );
    case ConversationInfoDestination.pinMessages:
      return const MaterialPage(
        key: ValueKey(ConversationInfoDestination.pinMessages),
        name: 'pinMessages',
        child: _ChatSidePageBuilder(PinMessagesPage.new),
      );
    case ConversationInfoDestination.sharedApps:
      return const MaterialPage(
        key: ValueKey(ConversationInfoDestination.sharedApps),
        name: 'sharedApps',
        child: _ChatSidePageBuilder(SharedAppsPage.new),
      );
    case ConversationInfoDestination.groupsInCommon:
      return const MaterialPage(
        key: ValueKey(ConversationInfoDestination.groupsInCommon),
        name: 'groupsInCommon',
        child: _ChatSidePageBuilder(GroupsInCommonPage.new),
      );
    case ConversationInfoDestination.disappearMessages:
      return const MaterialPage(
        key: ValueKey(ConversationInfoDestination.disappearMessages),
        name: 'disappearMessages',
        child: _ChatSidePageBuilder(DisappearMessagePage.new),
      );
  }
}

class _ChatSidePageBuilder extends HookConsumerWidget {
  const _ChatSidePageBuilder(this.builder);

  final Widget Function(ConversationState conversationState) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationId = useMemoized(
      () => ref.read(lastConversationIdProvider),
      [],
    );

    final filter = useCallback<bool Function(ConversationState?)>(
      (state) => state?.conversationId == conversationId,
      [conversationId],
    );

    final conversationState = ref.watch(filterLastConversationProvider(filter));

    if (conversationId == null || conversationState == null) {
      return const SizedBox();
    }

    return builder(conversationState);
  }
}

class _AnimatedChatSlide extends HookWidget {
  const _AnimatedChatSlide({
    required this.pages,
    required this.constraints,
    required this.onDidRemovePage,
  });

  final List<Page<dynamic>> pages;
  final DidRemovePageCallback? onDidRemovePage;
  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: const Duration(milliseconds: 300),
    );

    final displayedPages = useState(<Page<dynamic>>[]);

    useEffect(() {
      if (pages.isNotEmpty) {
        displayedPages.value = pages;
        controller.forward();
      } else {
        controller.reverse().whenComplete(() {
          displayedPages.value = pages;
        });
      }
      return null;
    }, [pages, controller]);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) => SizedBox(
        width:
            kChatSidePageWidth * Curves.easeInOut.transform(controller.value),
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
            pages: displayedPages.value,
            onDidRemovePage: onDidRemovePage,
          ),
        ),
      ),
    );
  }
}
