import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:provider/provider.dart';

import '../../../db/dao/conversation_dao.dart';
import '../../../widgets/deferred_mount.dart';
import '../../provider/unseen_conversations_provider.dart';
import '../desktop_shell_layout.dart';
import '../notifier/conversation_list_controller.dart';
import 'conversation_list.dart';
import 'search_list.dart';

class UnseenConversationList extends HookConsumerWidget {
  const UnseenConversationList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unseenConversations = ref.watch(unseenConversationsProvider);
    // Each row watches whether it is the current conversation, so opening one
    // does not rebuild the list, and unchanged rows keep their widgets.
    final rowCache = useRef<Map<String, DeferredMount>>({});
    useMemoized(() {
      final ids = {
        for (final item in unseenConversations ?? const <ConversationItem>[])
          item.conversationId,
      };
      rowCache.value.removeWhere((id, _) => !ids.contains(id));
    }, [unseenConversations]);
    final avatarCache = context.read<ConversationListController>().avatarCache;

    final showsConversationSelection = !DesktopShellLayout.mainRouteModeOf(
      context,
    );

    if (unseenConversations == null) {
      return const SizedBox();
    }
    if (unseenConversations.isEmpty) {
      return const SearchEmptyWidget();
    }
    // Opening a conversation removes the one opened before from the list.
    // The rows after it move up, and the callback lets them keep their
    // elements instead of being built again at their new indexes.
    final indexes = {
      for (final (index, item) in unseenConversations.indexed)
        item.conversationId: index,
    };
    return ListView.builder(
      findChildIndexCallback: (key) =>
          key is ValueKey<String> ? indexes[key.value] : null,
      itemBuilder: (context, index) => conversationRow(
        rowCache.value,
        unseenConversations[index],
        avatarCache: avatarCache,
        showsSelection: showsConversationSelection,
      ),
      itemCount: unseenConversations.length,
    );
  }
}
