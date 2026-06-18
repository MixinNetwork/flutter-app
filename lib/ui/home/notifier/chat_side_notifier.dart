import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:provider/provider.dart';

import '../../provider/abstract_responsive_navigator.dart';
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

class ChatSideNotifier extends ValueNotifier<ResponsiveNavigatorState>
    with ResponsiveNavigatorController {
  ChatSideNotifier() : super(const ResponsiveNavigatorState());

  static const infoPage = 'infoPage';
  static const circles = 'circles';
  static const searchMessageHistory = 'searchMessageHistory';
  static const sharedMedia = 'sharedMedia';
  static const participants = 'participants';
  static const pinMessages = 'pinMessages';
  static const sharedApps = 'sharedApps';
  static const groupsInCommon = 'groupsInCommon';
  static const disappearMessages = 'disappearMessages';

  var _disposed = false;

  ResponsiveNavigatorState get state => value;

  set state(ResponsiveNavigatorState newState) {
    if (_disposed || newState == value) return;
    value = newState;
  }

  @override
  ResponsiveNavigatorState get navigatorState => state;

  @override
  set navigatorState(ResponsiveNavigatorState value) => state = value;

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
      state = state.copyWith(pages: [route(ChatSideNotifier.infoPage, null)]);
      return;
    }
    clear();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class SearchConversationKeywordNotifier
    extends ValueNotifier<(String?, String)> {
  SearchConversationKeywordNotifier({
    required ChatSideNotifier chatSideNotifier,
  }) : super(const (null, '')) {
    _searchPageVisible = _isSearchPageVisible(chatSideNotifier.value);
    _chatSideListener = () {
      final visible = _isSearchPageVisible(chatSideNotifier.value);
      if (visible == _searchPageVisible) return;
      _searchPageVisible = visible;
      value = const (null, '');
    };
    chatSideNotifier.addListener(_chatSideListener!);
    _chatSideNotifier = chatSideNotifier;
  }

  ChatSideNotifier? _chatSideNotifier;
  VoidCallback? _chatSideListener;
  var _searchPageVisible = false;

  static bool _isSearchPageVisible(ResponsiveNavigatorState state) =>
      state.pages.any(
        (element) => element.name == ChatSideNotifier.searchMessageHistory,
      );

  static void updateKeyword(BuildContext context, String keyword) {
    final notifier = context.read<SearchConversationKeywordNotifier>();
    notifier.value = (notifier.value.$1, keyword);
  }

  static void updateSelectedUser(BuildContext context, String? userId) {
    final notifier = context.read<SearchConversationKeywordNotifier>();
    notifier.value = (userId, notifier.value.$2);
  }

  @override
  void dispose() {
    final chatSideNotifier = _chatSideNotifier;
    final chatSideListener = _chatSideListener;
    if (chatSideNotifier != null && chatSideListener != null) {
      chatSideNotifier.removeListener(chatSideListener);
    }
    super.dispose();
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
