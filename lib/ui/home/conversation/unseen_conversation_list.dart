import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../provider/conversation_provider.dart';
import '../../provider/pending_jump_message_provider.dart';
import '../../provider/responsive_navigator_provider.dart';
import '../../provider/unseen_conversations_provider.dart';
import 'conversation_list.dart';
import 'menu_wrapper.dart';
import 'search_list.dart';

class UnseenConversationList extends HookConsumerWidget {
  const UnseenConversationList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unseenConversations = ref.watch(unseenConversationsProvider);

    final currentConversationId = ref.watch(currentConversationIdProvider);

    final routeMode = ref.watch(navigatorRouteModeProvider);

    if (unseenConversations == null) {
      return const SizedBox();
    }
    if (unseenConversations.isEmpty) {
      return const SearchEmptyWidget();
    }
    return ScrollablePositionedList.builder(
      itemBuilder: (context, index) {
        final conversation = unseenConversations[index];
        final selected =
            conversation.conversationId == currentConversationId && !routeMode;
        return ConversationMenuWrapper(
          conversation: conversation,
          removeChatFromCircle: true,
          child: ConversationItemWidget(
            conversation: conversation,
            selected: selected,
            onTap: () {
              if (selected) {
                ref.read(pendingJumpLatestProvider.notifier).state = Object();
                return;
              }
              ConversationStateNotifier.selectConversation(
                context,
                conversation.conversationId,
                conversation: conversation,
              );
            },
          ),
        );
      },
      itemCount: unseenConversations.length,
    );
  }
}
